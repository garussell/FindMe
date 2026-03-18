import Foundation
import Observation

@MainActor
@Observable
final class JobSearchViewModel {
    var request = JobSearchRequest()
    var results: [JobListing] = []
    var statuses: [SourceFetchStatus] = []
    var recentSearches: [String] = []
    var isLoading = false
    var errorMessage: String?
    var canLoadMore = false
    var hasLoaded = false

    private var searchService: AggregatedJobSearchService?
    private var recentSearchStore: RecentSearchStore?

    func configureIfNeeded(searchService: AggregatedJobSearchService, recentSearchStore: RecentSearchStore) {
        guard self.searchService == nil else { return }
        self.searchService = searchService
        self.recentSearchStore = recentSearchStore
        recentSearches = recentSearchStore.load()
    }

    func search(reset: Bool) async {
        guard let searchService else { return }

        if reset {
            request.page = 1
        }

        isLoading = true
        errorMessage = nil

        let response = await searchService.search(request: request)
        if reset {
            results = response.listings
        } else {
            results = (results + response.listings).deduplicatedAndSorted()
        }

        statuses = response.statuses
        canLoadMore = response.canLoadMore
        isLoading = false
        hasLoaded = true

        if response.listings.isEmpty && response.statuses.allSatisfy({ $0.state == .empty }) {
            errorMessage = "No jobs matched your current filters."
        }

        if reset {
            recentSearchStore?.save(request: request)
            recentSearches = recentSearchStore?.load() ?? []
        }
    }

    func loadMore() async {
        guard !isLoading, canLoadMore else { return }
        request = request.copyForNextPage()
        await search(reset: false)
    }

    func applyRecentSearch(_ value: String) {
        request.keyword = value
        request.location = ""
    }
}
