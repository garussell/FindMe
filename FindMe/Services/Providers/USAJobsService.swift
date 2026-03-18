import Foundation

struct USAJobsResponse: Decodable, Sendable {
    struct SearchResult: Decodable, Sendable {
        struct Item: Decodable, Sendable {
            struct MatchedObjectDescriptor: Decodable, Sendable {
                struct PositionLocation: Decodable, Sendable {
                    let locationName: String?

                    enum CodingKeys: String, CodingKey {
                        case locationName = "LocationName"
                    }
                }

                struct PositionRemuneration: Decodable, Sendable {
                    let minimumRange: String?
                    let maximumRange: String?

                    enum CodingKeys: String, CodingKey {
                        case minimumRange = "MinimumRange"
                        case maximumRange = "MaximumRange"
                    }
                }

                struct PositionSchedule: Decodable, Sendable {
                    let name: String?

                    enum CodingKeys: String, CodingKey {
                        case name = "Name"
                    }
                }

                let positionID: String?
                let positionTitle: String?
                let organizationName: String?
                let qualificationSummary: String?
                let userArea: UserArea?
                let positionURI: String?
                let applyURI: [String]?
                let publicationStartDate: String?
                let positionLocationDisplay: String?
                let positionLocation: [PositionLocation]?
                let positionRemuneration: [PositionRemuneration]?
                let positionSchedule: [PositionSchedule]?

                struct UserArea: Decodable, Sendable {
                    let details: Details?

                    enum CodingKeys: String, CodingKey {
                        case details = "Details"
                    }
                }

                struct Details: Decodable, Sendable {
                    let majorDuties: [String]?
                    let jobSummary: String?
                    let remoteIndicator: Bool?

                    enum CodingKeys: String, CodingKey {
                        case majorDuties = "MajorDuties"
                        case jobSummary = "JobSummary"
                        case remoteIndicator = "RemoteIndicator"
                    }
                }

                enum CodingKeys: String, CodingKey {
                    case positionID = "PositionID"
                    case positionTitle = "PositionTitle"
                    case organizationName = "OrganizationName"
                    case qualificationSummary = "QualificationSummary"
                    case userArea = "UserArea"
                    case positionURI = "PositionURI"
                    case applyURI = "ApplyURI"
                    case publicationStartDate = "PublicationStartDate"
                    case positionLocationDisplay = "PositionLocationDisplay"
                    case positionLocation = "PositionLocation"
                    case positionRemuneration = "PositionRemuneration"
                    case positionSchedule = "PositionSchedule"
                }
            }

            let matchedObjectDescriptor: MatchedObjectDescriptor

            enum CodingKeys: String, CodingKey {
                case matchedObjectDescriptor = "MatchedObjectDescriptor"
            }
        }

        let items: [Item]

        enum CodingKeys: String, CodingKey {
            case items = "SearchResultItems"
        }
    }

    let searchResult: SearchResult

    enum CodingKeys: String, CodingKey {
        case searchResult = "SearchResult"
    }
}

struct USAJobsService: JobListingProvider {
    let source: JobSource = .usajobs
    let client: HTTPClient
    let configuration: AppConfiguration

    func search(request: JobSearchRequest) async -> JobProviderResult {
        guard configuration.hasUSAJobsCredentials,
              let apiKey = configuration.usaJobsAPIKey,
              let userAgent = configuration.usaJobsUserAgent else {
            let sample = MockJobData.jobs(for: source, request: request)
            return JobProviderResult(
                source: source,
                listings: sample,
                status: SourceFetchStatus(source: source, state: .sample, resultCount: sample.count, message: "Add USAJobs API key and user agent for live federal jobs."),
                hasMore: true
            )
        }

        var components = URLComponents(string: "https://data.usajobs.gov/api/search")!
        var queryItems = [
            URLQueryItem(name: "Page", value: String(request.page)),
            URLQueryItem(name: "ResultsPerPage", value: String(request.pageSize))
        ]

        if !request.normalizedKeyword.isEmpty {
            queryItems.append(URLQueryItem(name: "Keyword", value: request.normalizedKeyword))
        }

        if !request.normalizedLocation.isEmpty {
            queryItems.append(URLQueryItem(name: "LocationName", value: request.normalizedLocation))
        }

        if request.remoteOnly {
            queryItems.append(URLQueryItem(name: "RemoteIndicator", value: "true"))
        }

        components.queryItems = queryItems

        do {
            let response = try await client.get(
                USAJobsResponse.self,
                url: components.url!,
                headers: [
                    "Authorization-Key": apiKey,
                    "User-Agent": userAgent,
                    "Host": "data.usajobs.gov"
                ]
            )

            let listings = response.searchResult.items.map { item in
                let descriptor = item.matchedObjectDescriptor
                let summary = descriptor.userArea?.details?.jobSummary
                    ?? descriptor.userArea?.details?.majorDuties?.joined(separator: "\n\n")
                    ?? descriptor.qualificationSummary
                    ?? ""

                let remuneration = descriptor.positionRemuneration?.first
                let location = descriptor.positionLocationDisplay
                    ?? descriptor.positionLocation?.compactMap(\.locationName).joined(separator: ", ")
                    ?? request.normalizedLocation.ifEmpty("United States")

                return JobListing(
                    source: source,
                    title: descriptor.positionTitle ?? "Federal Opportunity",
                    company: descriptor.organizationName ?? "USAJobs",
                    location: location,
                    isRemote: descriptor.userArea?.details?.remoteIndicator ?? false,
                    salaryMin: remuneration?.minimumRange.flatMap(Double.init),
                    salaryMax: remuneration?.maximumRange.flatMap(Double.init),
                    currency: "USD",
                    employmentType: descriptor.positionSchedule?.first?.name?.nilIfEmpty,
                    descriptionSnippet: String(summary.strippingHTML.prefix(180)),
                    descriptionFull: summary.strippingHTML,
                    postedDate: DateParsers.parse(descriptor.publicationStartDate),
                    applyURL: descriptor.applyURI?.first.flatMap(URL.init(string:)),
                    listingURL: descriptor.positionURI.flatMap(URL.init(string:)),
                    rawSourceID: descriptor.positionID ?? UUID().uuidString
                )
            }

            return JobProviderResult(
                source: source,
                listings: listings,
                status: SourceFetchStatus(source: source, state: listings.isEmpty ? .empty : .live, resultCount: listings.count, message: listings.isEmpty ? "No USAJobs matches for this search." : nil),
                hasMore: listings.count >= request.pageSize
            )
        } catch {
            let sample = MockJobData.jobs(for: source, request: request)
            return JobProviderResult(
                source: source,
                listings: sample,
                status: SourceFetchStatus(source: source, state: .sample, resultCount: sample.count, message: "USAJobs live fetch failed, so sample federal jobs are shown."),
                hasMore: true
            )
        }
    }
}
