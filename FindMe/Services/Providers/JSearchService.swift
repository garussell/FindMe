import Foundation

struct JSearchResponse: Decodable, Sendable {
    struct Job: Decodable, Sendable {
        let jobID: String
        let employerName: String?
        let jobTitle: String
        let jobApplyLink: String?
        let jobDescription: String?
        let jobIsRemote: Bool?
        let jobPostedAtDatetimeUTC: String?
        let jobCity: String?
        let jobState: String?
        let jobCountry: String?
        let jobEmploymentType: String?
        let jobMinSalary: Double?
        let jobMaxSalary: Double?
        let jobSalaryCurrency: String?

        enum CodingKeys: String, CodingKey {
            case jobID = "job_id"
            case employerName = "employer_name"
            case jobTitle = "job_title"
            case jobApplyLink = "job_apply_link"
            case jobDescription = "job_description"
            case jobIsRemote = "job_is_remote"
            case jobPostedAtDatetimeUTC = "job_posted_at_datetime_utc"
            case jobCity = "job_city"
            case jobState = "job_state"
            case jobCountry = "job_country"
            case jobEmploymentType = "job_employment_type"
            case jobMinSalary = "job_min_salary"
            case jobMaxSalary = "job_max_salary"
            case jobSalaryCurrency = "job_salary_currency"
        }
    }

    let data: [Job]
}

struct JSearchService: JobListingProvider {
    let source: JobSource = .jsearch
    let client: HTTPClient
    let configuration: AppConfiguration

    private func fallbackMessage(for error: Error) -> String {
        guard let httpError = error as? HTTPClient.HTTPError else {
            return "JSearch live fetch failed, so sample jobs are shown."
        }

        switch httpError {
        case .badStatusCode(401), .badStatusCode(403):
            return "JSearch rejected the configured RapidAPI key. Check that this key is subscribed to JSearch."
        case .badStatusCode(429):
            return "JSearch rate-limited this request, so sample jobs are shown."
        default:
            return "JSearch live fetch failed, so sample jobs are shown."
        }
    }

    func search(request: JobSearchRequest) async -> JobProviderResult {
        guard configuration.hasJSearchCredentials,
              let apiKey = configuration.jsearchAPIKey else {
            let sample = MockJobData.jobs(for: source, request: request)
            return JobProviderResult(
                source: source,
                listings: sample,
                status: SourceFetchStatus(source: source, state: .sample, resultCount: sample.count, message: "Add JSearch API credentials for live listings."),
                hasMore: true
            )
        }

        var query = [request.normalizedKeyword, request.normalizedLocation]
            .filter { !$0.isEmpty }
            .joined(separator: " in ")

        if request.remoteOnly && !query.localizedCaseInsensitiveContains("remote") {
            query = [query, "remote"].filter { !$0.isEmpty }.joined(separator: " ")
        }

        if query.isEmpty {
            query = "software"
        }

        var components = URLComponents(string: "https://jsearch.p.rapidapi.com/search")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: String(request.page)),
            URLQueryItem(name: "num_pages", value: "1"),
            URLQueryItem(name: "country", value: "us")
        ]

        if request.remoteOnly {
            components.queryItems?.append(URLQueryItem(name: "remote_jobs_only", value: "true"))
        }

        if request.employmentType != .any {
            let value = request.employmentType == .fullTime ? "FULLTIME" : "PARTTIME"
            components.queryItems?.append(URLQueryItem(name: "employment_types", value: value))
        }

        do {
            let response = try await client.get(
                JSearchResponse.self,
                url: components.url!,
                headers: [
                    "x-rapidapi-host": "jsearch.p.rapidapi.com",
                    "x-rapidapi-key": apiKey
                ]
            )

            let listings = response.data.map { job in
                let locationParts = [job.jobCity, job.jobState, job.jobCountry].compactMap { $0 }.filter { !$0.isEmpty }

                return JobListing(
                    source: source,
                    title: job.jobTitle,
                    company: job.employerName ?? "Unknown Employer",
                    location: locationParts.isEmpty ? request.normalizedLocation.ifEmpty("United States") : locationParts.joined(separator: ", "),
                    isRemote: job.jobIsRemote ?? false,
                    salaryMin: job.jobMinSalary,
                    salaryMax: job.jobMaxSalary,
                    currency: job.jobSalaryCurrency ?? "USD",
                    employmentType: job.jobEmploymentType?.replacingOccurrences(of: "_", with: " ").capitalized,
                    descriptionSnippet: String((job.jobDescription ?? "").strippingHTML.prefix(180)),
                    descriptionFull: job.jobDescription?.strippingHTML,
                    postedDate: DateParsers.parse(job.jobPostedAtDatetimeUTC),
                    applyURL: job.jobApplyLink.flatMap(URL.init(string:)),
                    listingURL: job.jobApplyLink.flatMap(URL.init(string:)),
                    rawSourceID: job.jobID
                )
            }

            return JobProviderResult(
                source: source,
                listings: listings,
                status: SourceFetchStatus(source: source, state: listings.isEmpty ? .empty : .live, resultCount: listings.count, message: listings.isEmpty ? "No JSearch matches for this search." : nil),
                hasMore: listings.count >= request.pageSize
            )
        } catch {
            let sample = MockJobData.jobs(for: source, request: request)
            return JobProviderResult(
                source: source,
                listings: sample,
                status: SourceFetchStatus(source: source, state: .sample, resultCount: sample.count, message: fallbackMessage(for: error)),
                hasMore: true
            )
        }
    }
}
