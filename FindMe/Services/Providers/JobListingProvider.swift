import Foundation

struct JobProviderResult: Sendable {
    let source: JobSource
    let listings: [JobListing]
    let status: SourceFetchStatus
    let hasMore: Bool
}

protocol JobListingProvider: Sendable {
    var source: JobSource { get }
    func search(request: JobSearchRequest) async -> JobProviderResult
}
