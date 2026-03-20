import Foundation
import Observation

@MainActor
@Observable
final class AppContainer {
    let configuration: AppConfiguration
    let searchService: AggregatedJobSearchService
    let insightsService: BLSInsightsService
    let recentSearchStore: RecentSearchStore
    let locationManager: LocationManager
    let toastManager: ToastManager

    init(
        configuration: AppConfiguration,
        searchService: AggregatedJobSearchService,
        insightsService: BLSInsightsService,
        recentSearchStore: RecentSearchStore,
        locationManager: LocationManager,
        toastManager: ToastManager
    ) {
        self.configuration = configuration
        self.searchService = searchService
        self.insightsService = insightsService
        self.recentSearchStore = recentSearchStore
        self.locationManager = locationManager
        self.toastManager = toastManager
    }

    static func makeLive() -> AppContainer {
        let configuration = AppConfiguration()
        let client = HTTPClient()

        let providers: [any JobListingProvider] = [
            AdzunaService(client: client, configuration: configuration),
            JSearchService(client: client, configuration: configuration),
            USAJobsService(client: client, configuration: configuration),
            ArbeitNowService(client: client),
            SerpApiService(client: client, configuration: configuration)
        ]

        return AppContainer(
            configuration: configuration,
            searchService: AggregatedJobSearchService(providers: providers),
            insightsService: BLSInsightsService(client: client, configuration: configuration),
            recentSearchStore: RecentSearchStore(),
            locationManager: LocationManager(),
            toastManager: ToastManager()
        )
    }
}
