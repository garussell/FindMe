import Foundation
import Observation

@MainActor
@Observable
final class InsightsViewModel {
    var insights: [MarketInsight] = []
    var isLoading = false
    var hasLoaded = false

    private var service: BLSInsightsService?

    func configureIfNeeded(service: BLSInsightsService) {
        guard self.service == nil else { return }
        self.service = service
    }

    func loadIfNeeded() async {
        guard !hasLoaded, let service else { return }
        isLoading = true
        insights = await service.loadInsights()
        isLoading = false
        hasLoaded = true
    }
}
