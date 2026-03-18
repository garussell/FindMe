import Foundation

enum EmploymentTypeFilter: String, CaseIterable, Codable, Identifiable, Sendable {
    case any
    case fullTime
    case partTime

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .any:
            "Any Schedule"
        case .fullTime:
            "Full-Time"
        case .partTime:
            "Part-Time"
        }
    }
}
