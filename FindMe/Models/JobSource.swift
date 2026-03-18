import Foundation
import SwiftUI

enum JobSource: String, CaseIterable, Codable, Identifiable, Sendable {
    case adzuna
    case jsearch
    case usajobs
    case arbeitnow

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .adzuna:
            "Adzuna"
        case .jsearch:
            "JSearch"
        case .usajobs:
            "USAJobs"
        case .arbeitnow:
            "ArbeitNow"
        }
    }

    var tint: Color {
        switch self {
        case .adzuna:
            Color.orange
        case .jsearch:
            Color.blue
        case .usajobs:
            Color.indigo
        case .arbeitnow:
            Color.green
        }
    }
}
