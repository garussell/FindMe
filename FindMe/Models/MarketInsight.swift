import Foundation

struct MarketInsight: Identifiable, Hashable, Sendable {
    struct Point: Identifiable, Hashable, Sendable {
        let id = UUID()
        let label: String
        let date: Date
        let value: Double
    }

    let id = UUID()
    let title: String
    let headlineValue: String
    let subtitle: String
    let detail: String
    let points: [Point]
    let sourceNote: String
}
