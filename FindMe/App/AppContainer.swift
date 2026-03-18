import Foundation
import Observation

@MainActor
@Observable
final class AppContainer {
    let configuration: AppConfiguration
    let searchService: AggregatedJobSearchService
    let insightsService: BLSInsightsService
    let recentSearchStore: RecentSearchStore

    init(
        configuration: AppConfiguration,
        searchService: AggregatedJobSearchService,
        insightsService: BLSInsightsService,
        recentSearchStore: RecentSearchStore
    ) {
        self.configuration = configuration
        self.searchService = searchService
        self.insightsService = insightsService
        self.recentSearchStore = recentSearchStore
    }

    static func makeLive() -> AppContainer {
        let configuration = AppConfiguration()
        let client = HTTPClient()

        let providers: [any JobListingProvider] = [
            AdzunaService(client: client, configuration: configuration),
            JSearchService(client: client, configuration: configuration),
            USAJobsService(client: client, configuration: configuration),
            ArbeitNowService(client: client)
        ]

        return AppContainer(
            configuration: configuration,
            searchService: AggregatedJobSearchService(providers: providers),
            insightsService: BLSInsightsService(client: client, configuration: configuration),
            recentSearchStore: RecentSearchStore()
        )
    }
}
