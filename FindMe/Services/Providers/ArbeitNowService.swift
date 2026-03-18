import Foundation

struct ArbeitNowResponse: Decodable, Sendable {
    struct Job: Decodable, Sendable {
        let slug: String
        let companyName: String
        let title: String
        let description: String
        let remote: Bool
        let url: String
        let tags: [String]
        let jobTypes: [String]
        let location: String
        let createdAt: TimeInterval

        enum CodingKeys: String, CodingKey {
            case slug
            case companyName = "company_name"
            case title
            case description
            case remote
            case url
            case tags
            case jobTypes = "job_types"
            case location
            case createdAt = "created_at"
        }
    }

    let data: [Job]
}

struct ArbeitNowService: JobListingProvider {
    let source: JobSource = .arbeitnow
    let client: HTTPClient

    func search(request: JobSearchRequest) async -> JobProviderResult {
        var components = URLComponents(string: "https://www.arbeitnow.com/api/job-board-api")!
        components.queryItems = [URLQueryItem(name: "page", value: String(request.page))]

        do {
            let response = try await client.get(ArbeitNowResponse.self, url: components.url!)
            let normalizedKeyword = request.normalizedKeyword.normalizedForMatching
            let normalizedLocation = request.normalizedLocation.normalizedForMatching

            let listings = response.data.compactMap { job -> JobListing? in
                let locationMatch = normalizedLocation.isEmpty || job.location.normalizedForMatching.contains(normalizedLocation)
                let keywordCorpus = [job.title, job.companyName, job.description, job.tags.joined(separator: " ")]
                    .joined(separator: " ")
                    .normalizedForMatching
                let keywordMatch = normalizedKeyword.isEmpty || keywordCorpus.contains(normalizedKeyword)

                guard locationMatch && keywordMatch else { return nil }

                return JobListing(
                    source: source,
                    title: job.title,
                    company: job.companyName,
                    location: job.location,
                    isRemote: job.remote,
                    salaryMin: nil,
                    salaryMax: nil,
                    currency: nil,
                    employmentType: job.jobTypes.first?.capitalized,
                    descriptionSnippet: String(job.description.strippingHTML.prefix(180)),
                    descriptionFull: job.description.strippingHTML,
                    postedDate: Date(timeIntervalSince1970: job.createdAt),
                    applyURL: URL(string: job.url),
                    listingURL: URL(string: job.url),
                    rawSourceID: job.slug
                )
            }

            return JobProviderResult(
                source: source,
                listings: listings,
                status: SourceFetchStatus(source: source, state: listings.isEmpty ? .empty : .live, resultCount: listings.count, message: listings.isEmpty ? "No ArbeitNow matches for this search." : nil),
                hasMore: response.data.count >= request.pageSize
            )
        } catch {
            let sample = MockJobData.jobs(for: source, request: request)
            return JobProviderResult(
                source: source,
                listings: sample,
                status: SourceFetchStatus(source: source, state: .sample, resultCount: sample.count, message: "ArbeitNow live fetch failed, so sample jobs are shown."),
                hasMore: true
            )
        }
    }
}
