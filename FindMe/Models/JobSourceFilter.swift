import Foundation

enum JobSourceFilter: String, CaseIterable, Codable, Identifiable, Sendable {
    case all
    case adzuna
    case jsearch
    case usajobs
    case arbeitnow
    case serpapi

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:
            "All Sources"
        case .adzuna:
            "Adzuna"
        case .jsearch:
            "JSearch"
        case .usajobs:
            "USAJobs"
        case .arbeitnow:
            "ArbeitNow"
        case .serpapi:
            "Google Jobs"
        }
    }

    var includedSources: [JobSource] {
        switch self {
        case .all:
            JobSource.allCases
        case .adzuna:
            [.adzuna]
        case .jsearch:
            [.jsearch]
        case .usajobs:
            [.usajobs]
        case .arbeitnow:
            [.arbeitnow]
        case .serpapi:
            [.serpapi]
        }
    }
}
