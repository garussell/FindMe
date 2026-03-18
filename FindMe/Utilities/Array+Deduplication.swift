import Foundation

extension Array where Element == JobListing {
    func deduplicatedAndSorted() -> [JobListing] {
        var seen = Set<String>()
        let filtered = filter { listing in
            seen.insert(listing.dedupeKey).inserted
        }

        return filtered.sorted { lhs, rhs in
            switch (lhs.postedDate, rhs.postedDate) {
            case let (left?, right?):
                return left > right
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return lhs.title < rhs.title
            }
        }
    }
}
