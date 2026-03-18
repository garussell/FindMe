import Foundation

@MainActor
final class RecentSearchStore {
    private let defaults: UserDefaults
    private let key = "recent-searches"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [String] {
        defaults.stringArray(forKey: key) ?? []
    }

    func save(request: JobSearchRequest) {
        let summary = [request.normalizedKeyword, request.normalizedLocation]
            .filter { !$0.isEmpty }
            .joined(separator: " in ")

        guard !summary.isEmpty else { return }

        var items = load().filter { $0.caseInsensitiveCompare(summary) != .orderedSame }
        items.insert(summary, at: 0)
        defaults.set(Array(items.prefix(6)), forKey: key)
    }
}
