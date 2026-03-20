import Foundation

// MARK: - SerpApi Response Models

/// Top-level response from SerpApi Google Jobs engine.
/// GET https://serpapi.com/search.json?engine=google_jobs&q={query}&location={location}&api_key={key}
struct SerpApiResponse: Decodable, Sendable {
    let jobsResults: [JobResult]?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case jobsResults = "jobs_results"
        case error
    }

    struct JobResult: Decodable, Sendable {
        let title: String?
        let companyName: String?
        let location: String?
        let via: String?
        let description: String?
        let jobId: String?
        let thumbnail: String?
        let extensions: [String]?
        let detectedExtensions: DetectedExtensions?
        let applyOptions: [ApplyOption]?

        enum CodingKeys: String, CodingKey {
            case title
            case companyName = "company_name"
            case location
            case via
            case description
            case jobId = "job_id"
            case thumbnail
            case extensions
            case detectedExtensions = "detected_extensions"
            case applyOptions = "apply_options"
        }
    }

    struct DetectedExtensions: Decodable, Sendable {
        let postedAt: String?
        let scheduleType: String?
        let salary: String?

        enum CodingKeys: String, CodingKey {
            case postedAt = "posted_at"
            case scheduleType = "schedule_type"
            case salary
        }
    }

    struct ApplyOption: Decodable, Sendable {
        let title: String?
        let link: String?
        let isDirect: Bool?

        enum CodingKeys: String, CodingKey {
            case title
            case link
            case isDirect = "is_direct"
        }
    }
}

// MARK: - In-Memory Response Cache

/// Thread-safe cache for SerpApi responses with a configurable TTL.
/// Key format: normalized "keyword|location" string.
///
/// This cache is critical because SerpApi's free tier only allows 100 searches/month.
/// Cache TTL defaults to 10 minutes (600 seconds) so repeated identical searches
/// don't burn quota. In dev, cache hits are logged to the console.
actor SerpApiCache {
    struct Entry: Sendable {
        let response: SerpApiResponse
        let timestamp: Date
    }

    private var store: [String: Entry] = [:]
    let ttl: TimeInterval

    init(ttl: TimeInterval = 600) {
        self.ttl = ttl
    }

    /// Normalizes keyword + location into a cache key.
    static func cacheKey(keyword: String, location: String) -> String {
        "\(keyword.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))|\(location.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))"
    }

    /// Returns a cached response if one exists and hasn't expired.
    func get(key: String, now: Date = .now) -> SerpApiResponse? {
        guard let entry = store[key] else { return nil }
        guard now.timeIntervalSince(entry.timestamp) < ttl else {
            return nil
        }
        #if DEBUG
        print("[SerpApi] Cache hit for: \(key)")
        #endif
        return entry.response
    }

    /// Stores a response in the cache.
    func set(key: String, response: SerpApiResponse, now: Date = .now) {
        store[key] = Entry(response: response, timestamp: now)
    }

    /// Clears all cached entries. Exposed for testing.
    func clearCache() {
        store.removeAll()
    }
}

// MARK: - SerpApi Service

/// Fetches job listings from Google Jobs via the SerpApi proxy.
///
/// **Quota awareness:** SerpApi's free tier allows only 100 searches/month.
/// Every successful response is cached in-memory for 10 minutes so that
/// repeated searches with the same keyword + location don't burn quota.
///
/// **Mock mode:** If SERPAPI_MOCK=true is set in environment variables,
/// the service returns MockJobData instead of making a real API call.
/// This lets the team develop locally without burning quota.
///
/// **Error handling:**
/// - HTTP 429 → user-friendly "temporarily unavailable" message + sample fallback
/// - Network/decoding errors → sample fallback with descriptive status message
/// - API-level `error` field in JSON → surfaced as status message + sample fallback
struct SerpApiService: JobListingProvider {
    let source: JobSource = .serpapi
    let client: HTTPClient
    let configuration: AppConfiguration
    let cache: SerpApiCache

    /// If true, returns mock data without calling the real API.
    /// Controlled by the SERPAPI_MOCK environment variable.
    let mockMode: Bool

    init(
        client: HTTPClient,
        configuration: AppConfiguration,
        cache: SerpApiCache = SerpApiCache(),
        mockMode: Bool? = nil
    ) {
        self.client = client
        self.configuration = configuration
        self.cache = cache
        // Default to environment variable; override with explicit parameter (for testing).
        self.mockMode = mockMode ?? (ProcessInfo.processInfo.environment["SERPAPI_MOCK"] == "true")
    }

    func search(request: JobSearchRequest) async -> JobProviderResult {
        // Guard: credentials required
        guard !mockMode, configuration.hasSerpApiCredentials, let apiKey = configuration.serpApiKey else {
            let sample = MockJobData.jobs(for: source, request: request)
            let message = mockMode
                ? "SerpApi is in mock mode (SERPAPI_MOCK=true). Showing sample data."
                : "Add a SERPAPI_KEY in APIConfig.local.plist for live Google Jobs results."
            return JobProviderResult(
                source: source,
                listings: sample,
                status: SourceFetchStatus(source: source, state: .sample, resultCount: sample.count, message: message),
                hasMore: true
            )
        }

        // Build cache key from the search parameters
        let cacheKey = SerpApiCache.cacheKey(
            keyword: request.normalizedKeyword,
            location: request.normalizedLocation
        )

        // Check cache before hitting the network
        if let cached = await cache.get(key: cacheKey) {
            let listings = mapResponse(cached, request: request)
            return JobProviderResult(
                source: source,
                listings: listings,
                status: SourceFetchStatus(source: source, state: listings.isEmpty ? .empty : .live, resultCount: listings.count, message: nil),
                hasMore: false
            )
        }

        // Build URL: GET https://serpapi.com/search.json?engine=google_jobs&...
        var components = URLComponents(string: "https://serpapi.com/search.json")!
        var queryItems = [
            URLQueryItem(name: "engine", value: "google_jobs"),
            URLQueryItem(name: "api_key", value: apiKey)
        ]

        // Build the query string from keyword + location
        let keyword = request.remoteOnly && !request.normalizedKeyword.localizedCaseInsensitiveContains("remote")
            ? [request.normalizedKeyword, "remote"].filter { !$0.isEmpty }.joined(separator: " ")
            : request.normalizedKeyword

        let query = [keyword, request.normalizedLocation]
            .filter { !$0.isEmpty }
            .joined(separator: " in ")

        queryItems.append(URLQueryItem(name: "q", value: query.isEmpty ? "software engineer" : query))

        if !request.normalizedLocation.isEmpty {
            queryItems.append(URLQueryItem(name: "location", value: request.normalizedLocation))
            queryItems.append(URLQueryItem(name: "lrad", value: "30"))
        }

        // SerpApi pagination: start index (0, 10, 20, ...)
        if request.page > 1 {
            queryItems.append(URLQueryItem(name: "start", value: String((request.page - 1) * 10)))
        }

        components.queryItems = queryItems

        do {
            let response = try await client.get(SerpApiResponse.self, url: components.url!)

            // SerpApi sometimes returns errors in the JSON body rather than via HTTP status
            if let apiError = response.error {
                let sample = MockJobData.jobs(for: source, request: request)
                return JobProviderResult(
                    source: source,
                    listings: sample,
                    status: SourceFetchStatus(source: source, state: .sample, resultCount: sample.count, message: "Google Jobs: \(apiError)"),
                    hasMore: false
                )
            }

            // Cache the successful response
            await cache.set(key: cacheKey, response: response)

            let listings = mapResponse(response, request: request)
            return JobProviderResult(
                source: source,
                listings: listings,
                status: SourceFetchStatus(source: source, state: listings.isEmpty ? .empty : .live, resultCount: listings.count, message: listings.isEmpty ? "No Google Jobs matches for this search." : nil),
                hasMore: (response.jobsResults?.count ?? 0) >= 10
            )
        } catch let error as HTTPClient.HTTPError {
            return handleHTTPError(error, request: request)
        } catch {
            let sample = MockJobData.jobs(for: source, request: request)
            return JobProviderResult(
                source: source,
                listings: sample,
                status: SourceFetchStatus(source: source, state: .sample, resultCount: sample.count, message: "Google Jobs fetch failed. Showing sample data."),
                hasMore: true
            )
        }
    }

    // MARK: - Response Mapping

    /// Maps SerpApi job results to the app's unified `JobListing` model.
    private func mapResponse(_ response: SerpApiResponse, request: JobSearchRequest) -> [JobListing] {
        guard let results = response.jobsResults else { return [] }

        return results.compactMap { result in
            let title = result.title ?? "Untitled Position"
            let company = result.companyName ?? "Unknown Employer"
            let location = result.location ?? request.normalizedLocation.ifEmpty("United States")

            // Detect remote from extensions or location text
            let isRemote = result.extensions?.contains(where: { $0.localizedCaseInsensitiveContains("remote") }) ?? false
                || location.localizedCaseInsensitiveContains("remote")
                || (result.detectedExtensions?.scheduleType?.localizedCaseInsensitiveContains("remote") ?? false)

            // Parse salary from detected_extensions.salary (e.g. "$120K–$180K a year")
            let (salaryMin, salaryMax) = parseSalary(result.detectedExtensions?.salary)

            // Parse relative date (e.g. "2 days ago") into approximate Date
            let postedDate = parseRelativeDate(result.detectedExtensions?.postedAt)

            // Use the first apply option link, preferring direct apply links
            let applyURL: URL? = result.applyOptions?
                .sorted { ($0.isDirect ?? false) && !($1.isDirect ?? false) }
                .first?.link
                .flatMap(URL.init(string:))

            let description = result.description ?? ""
            let jobID = result.jobId ?? "\(title)-\(company)".normalizedForMatching

            return JobListing(
                source: source,
                title: title,
                company: company,
                location: location,
                isRemote: isRemote,
                salaryMin: salaryMin,
                salaryMax: salaryMax,
                currency: "USD",
                employmentType: result.detectedExtensions?.scheduleType,
                descriptionSnippet: String(description.strippingHTML.prefix(180)),
                descriptionFull: description.strippingHTML,
                postedDate: postedDate,
                applyURL: applyURL,
                listingURL: applyURL,
                rawSourceID: jobID
            )
        }
    }

    // MARK: - Salary Parsing

    /// Parses salary strings like "$120K–$180K a year" or "$30–$45 an hour".
    private func parseSalary(_ salaryString: String?) -> (Double?, Double?) {
        guard let salary = salaryString else { return (nil, nil) }

        // Extract all numbers with optional K suffix
        let pattern = #"\$?([\d,]+\.?\d*)K?"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return (nil, nil)
        }

        let matches = regex.matches(in: salary, range: NSRange(salary.startIndex..., in: salary))
        let values: [Double] = matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: salary) else { return nil }
            let numberStr = salary[range].replacingOccurrences(of: ",", with: "")
            guard var value = Double(numberStr) else { return nil }

            // Check if the original match includes K
            let fullRange = Range(match.range, in: salary)!
            if salary[fullRange].uppercased().hasSuffix("K") {
                value *= 1000
            }

            return value
        }

        // If values look like hourly ($30-$45), convert to annual (approximate)
        let isHourly = salary.localizedCaseInsensitiveContains("hour")
        let multiplier: Double = isHourly ? 2080 : 1

        switch values.count {
        case 0:
            return (nil, nil)
        case 1:
            return (values[0] * multiplier, nil)
        default:
            return (values[0] * multiplier, values[1] * multiplier)
        }
    }

    // MARK: - Relative Date Parsing

    /// Converts SerpApi's relative date strings (e.g. "2 days ago", "1 hour ago") to Date.
    private func parseRelativeDate(_ relative: String?) -> Date? {
        guard let relative, !relative.isEmpty else { return nil }
        let lower = relative.lowercased()
        let now = Date.now

        if lower.contains("just") || lower.contains("moment") {
            return now
        }

        // Extract the number from strings like "2 days ago", "1 hour ago"
        let numberPattern = #"(\d+)\s*(hour|day|week|month)"#
        guard let regex = try? NSRegularExpression(pattern: numberPattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: lower, range: NSRange(lower.startIndex..., in: lower)),
              let numberRange = Range(match.range(at: 1), in: lower),
              let unitRange = Range(match.range(at: 2), in: lower),
              let count = Int(lower[numberRange]) else {
            return nil
        }

        let unit = String(lower[unitRange])
        let seconds: TimeInterval
        switch unit {
        case "hour": seconds = TimeInterval(count) * 3600
        case "day": seconds = TimeInterval(count) * 86400
        case "week": seconds = TimeInterval(count) * 604800
        case "month": seconds = TimeInterval(count) * 2_592_000
        default: return nil
        }

        return now.addingTimeInterval(-seconds)
    }

    // MARK: - HTTP Error Handling

    private func handleHTTPError(_ error: HTTPClient.HTTPError, request: JobSearchRequest) -> JobProviderResult {
        let sample = MockJobData.jobs(for: source, request: request)
        let message: String

        switch error {
        case .badStatusCode(429):
            message = "Google Jobs search is temporarily unavailable. Please try again later."
        case .badStatusCode(401), .badStatusCode(403):
            message = "SerpApi rejected the API key. Check that SERPAPI_KEY is valid."
        case .badStatusCode(let code):
            message = "Google Jobs returned status \(code). Showing sample data."
        case .invalidResponse:
            message = "Google Jobs returned an invalid response. Showing sample data."
        }

        return JobProviderResult(
            source: source,
            listings: sample,
            status: SourceFetchStatus(source: source, state: .sample, resultCount: sample.count, message: message),
            hasMore: true
        )
    }
}
