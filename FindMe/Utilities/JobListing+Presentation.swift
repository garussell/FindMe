import Foundation

extension JobListing {
    var salaryText: String? {
        guard salaryMin != nil || salaryMax != nil else { return nil }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        formatter.currencyCode = currency ?? "USD"

        let minText = salaryMin.flatMap { formatter.string(from: NSNumber(value: $0)) }
        let maxText = salaryMax.flatMap { formatter.string(from: NSNumber(value: $0)) }

        switch (minText, maxText) {
        case let (min?, max?):
            return "\(min) - \(max)"
        case let (min?, nil):
            return "From \(min)"
        case let (nil, max?):
            return "Up to \(max)"
        case (nil, nil):
            return nil
        }
    }

    var postedRelativeText: String? {
        guard let postedDate else { return nil }
        return postedDate.formatted(.relative(presentation: .named))
    }

    var effectiveDescription: String {
        (descriptionFull ?? descriptionSnippet).strippingHTML
    }
}
