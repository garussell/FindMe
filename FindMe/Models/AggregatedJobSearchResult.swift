import Foundation

struct AggregatedJobSearchResult: Sendable {
    let listings: [JobListing]
    let statuses: [SourceFetchStatus]
    let canLoadMore: Bool
}
