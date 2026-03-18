import Foundation

struct JobListing: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let source: JobSource
    let title: String
    let company: String
    let location: String
    let isRemote: Bool
    let salaryMin: Double?
    let salaryMax: Double?
    let currency: String?
    let employmentType: String?
    let descriptionSnippet: String
    let descriptionFull: String?
    let postedDate: Date?
    let applyURL: URL?
    let listingURL: URL?
    let rawSourceID: String

    init(
        id: String? = nil,
        source: JobSource,
        title: String,
        company: String,
        location: String,
        isRemote: Bool,
        salaryMin: Double? = nil,
        salaryMax: Double? = nil,
        currency: String? = nil,
        employmentType: String? = nil,
        descriptionSnippet: String,
        descriptionFull: String? = nil,
        postedDate: Date? = nil,
        applyURL: URL? = nil,
        listingURL: URL? = nil,
        rawSourceID: String
    ) {
        self.id = id ?? "\(source.rawValue)-\(rawSourceID)"
        self.source = source
        self.title = title
        self.company = company
        self.location = location
        self.isRemote = isRemote
        self.salaryMin = salaryMin
        self.salaryMax = salaryMax
        self.currency = currency
        self.employmentType = employmentType
        self.descriptionSnippet = descriptionSnippet
        self.descriptionFull = descriptionFull
        self.postedDate = postedDate
        self.applyURL = applyURL
        self.listingURL = listingURL
        self.rawSourceID = rawSourceID
    }

    var dedupeKey: String {
        [
            title.normalizedForMatching,
            company.normalizedForMatching,
            location.normalizedForMatching
        ].joined(separator: "|")
    }
}
