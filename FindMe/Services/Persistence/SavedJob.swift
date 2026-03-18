import Foundation
import SwiftData

@Model
final class SavedJob {
    @Attribute(.unique) var id: String
    var sourceRawValue: String
    var title: String
    var company: String
    var location: String
    var isRemote: Bool
    var salaryMin: Double?
    var salaryMax: Double?
    var currency: String?
    var employmentType: String?
    var descriptionSnippet: String
    var descriptionFull: String?
    var postedDate: Date?
    var applyURLString: String?
    var listingURLString: String?
    var rawSourceID: String
    var savedAt: Date

    init(job: JobListing, savedAt: Date = .now) {
        id = job.id
        sourceRawValue = job.source.rawValue
        title = job.title
        company = job.company
        location = job.location
        isRemote = job.isRemote
        salaryMin = job.salaryMin
        salaryMax = job.salaryMax
        currency = job.currency
        employmentType = job.employmentType
        descriptionSnippet = job.descriptionSnippet
        descriptionFull = job.descriptionFull
        postedDate = job.postedDate
        applyURLString = job.applyURL?.absoluteString
        listingURLString = job.listingURL?.absoluteString
        rawSourceID = job.rawSourceID
        self.savedAt = savedAt
    }

    var jobListing: JobListing {
        JobListing(
            id: id,
            source: JobSource(rawValue: sourceRawValue) ?? .adzuna,
            title: title,
            company: company,
            location: location,
            isRemote: isRemote,
            salaryMin: salaryMin,
            salaryMax: salaryMax,
            currency: currency,
            employmentType: employmentType,
            descriptionSnippet: descriptionSnippet,
            descriptionFull: descriptionFull,
            postedDate: postedDate,
            applyURL: applyURLString.flatMap(URL.init(string:)),
            listingURL: listingURLString.flatMap(URL.init(string:)),
            rawSourceID: rawSourceID
        )
    }
}
