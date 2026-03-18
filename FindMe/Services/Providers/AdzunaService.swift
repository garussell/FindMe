import Foundation

struct AdzunaSearchResponse: Decodable, Sendable {
    struct Result: Decodable, Sendable {
        struct Company: Decodable, Sendable {
            let displayName: String?

            enum CodingKeys: String, CodingKey {
                case displayName = "display_name"
            }
        }

        struct Location: Decodable, Sendable {
            let displayName: String?

            enum CodingKeys: String, CodingKey {
                case displayName = "display_name"
            }
        }

        let id: String
        let title: String
        let description: String
        let company: Company?
        let location: Location?
        let redirectURL: String?
        let created: String?
        let salaryMin: Double?
        let salaryMax: Double?
        let contractTime: String?

        enum CodingKeys: String, CodingKey {
            case id
            case title
            case description
            case company
            case location
            case redirectURL = "redirect_url"
            case created
            case salaryMin = "salary_min"
            case salaryMax = "salary_max"
            case contractTime = "contract_time"
        }
    }

    let results: [Result]
}

struct AdzunaService: JobListingProvider {
    let source: JobSource = .adzuna
    let client: HTTPClient
    let configuration: AppConfiguration

    func search(request: JobSearchRequest) async -> JobProviderResult {
        guard configuration.hasAdzunaCredentials,
              let appID = configuration.adzunaAppID,
              let appKey = configuration.adzunaAppKey else {
            let sample = MockJobData.jobs(for: source, request: request)
            return JobProviderResult(
                source: source,
                listings: sample,
                status: SourceFetchStatus(source: source, state: .sample, resultCount: sample.count, message: "Add Adzuna credentials for live listings."),
                hasMore: true
            )
        }

        var components = URLComponents(string: "https://api.adzuna.com/v1/api/jobs/us/search/\(request.page)")!
        var queryItems = [
            URLQueryItem(name: "app_id", value: appID),
            URLQueryItem(name: "app_key", value: appKey),
            URLQueryItem(name: "results_per_page", value: String(request.pageSize))
        ]

        let keyword = request.remoteOnly && !request.normalizedKeyword.localizedCaseInsensitiveContains("remote")
            ? [request.normalizedKeyword, "remote"].filter { !$0.isEmpty }.joined(separator: " ")
            : request.normalizedKeyword

        if !keyword.isEmpty {
            queryItems.append(URLQueryItem(name: "what", value: keyword))
        }

        if !request.normalizedLocation.isEmpty {
            queryItems.append(URLQueryItem(name: "where", value: request.normalizedLocation))
        }

        if let salaryMinimum = request.salaryMinimum {
            queryItems.append(URLQueryItem(name: "salary_min", value: String(salaryMinimum)))
        }

        switch request.employmentType {
        case .any:
            break
        case .fullTime:
            queryItems.append(URLQueryItem(name: "full_time", value: "1"))
        case .partTime:
            queryItems.append(URLQueryItem(name: "part_time", value: "1"))
        }

        components.queryItems = queryItems

        do {
            let response = try await client.get(AdzunaSearchResponse.self, url: components.url!)
            let listings = response.results.map { result in
                JobListing(
                    source: source,
                    title: result.title,
                    company: result.company?.displayName ?? "Unknown Employer",
                    location: result.location?.displayName ?? request.normalizedLocation.ifEmpty("United States"),
                    isRemote: result.title.localizedCaseInsensitiveContains("remote") || result.description.localizedCaseInsensitiveContains("remote"),
                    salaryMin: result.salaryMin,
                    salaryMax: result.salaryMax,
                    currency: "USD",
                    employmentType: result.contractTime?.replacingOccurrences(of: "_", with: " ").capitalized,
                    descriptionSnippet: String(result.description.strippingHTML.prefix(180)),
                    descriptionFull: result.description.strippingHTML,
                    postedDate: DateParsers.parse(result.created),
                    applyURL: result.redirectURL.flatMap(URL.init(string:)),
                    listingURL: result.redirectURL.flatMap(URL.init(string:)),
                    rawSourceID: result.id
                )
            }

            return JobProviderResult(
                source: source,
                listings: listings,
                status: SourceFetchStatus(source: source, state: listings.isEmpty ? .empty : .live, resultCount: listings.count, message: listings.isEmpty ? "No Adzuna matches for this search." : nil),
                hasMore: listings.count >= request.pageSize
            )
        } catch {
            let sample = MockJobData.jobs(for: source, request: request)
            return JobProviderResult(
                source: source,
                listings: sample,
                status: SourceFetchStatus(source: source, state: .sample, resultCount: sample.count, message: "Adzuna live fetch failed, so sample jobs are shown."),
                hasMore: true
            )
        }
    }
}
