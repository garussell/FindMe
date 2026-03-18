import Foundation

struct JobSearchRequest: Codable, Equatable, Sendable {
    var keyword = ""
    var location = ""
    var remoteOnly = false
    var employmentType: EmploymentTypeFilter = .any
    var sourceFilter: JobSourceFilter = .all
    var salaryMinimum: Int?
    var page = 1
    var pageSize = 20

    var normalizedKeyword: String {
        keyword.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedLocation: String {
        location.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isMeaningful: Bool {
        !normalizedKeyword.isEmpty || !normalizedLocation.isEmpty || remoteOnly || salaryMinimum != nil
    }

    func copyForNextPage() -> JobSearchRequest {
        var copy = self
        copy.page += 1
        return copy
    }
}
