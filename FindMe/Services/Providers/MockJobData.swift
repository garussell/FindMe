import Foundation

enum MockJobData {
    static func jobs(for source: JobSource, request: JobSearchRequest) -> [JobListing] {
        let keyword = request.normalizedKeyword.isEmpty ? "Product" : request.normalizedKeyword
        let location = request.normalizedLocation.isEmpty ? "Remote / United States" : request.normalizedLocation

        let baseDate = Calendar.current.date(byAdding: .day, value: -request.page, to: .now) ?? .now

        let templates: [(String, String, Bool, Double?, Double?, String?)] = [
            ("\(keyword) Engineer", "Northstar Labs", true, 120_000, 160_000, "Full-Time"),
            ("Senior \(keyword) Analyst", "Brightline Talent", false, 95_000, 125_000, "Full-Time"),
            ("\(keyword) Coordinator", "Atlas Works", true, 65_000, 82_000, "Part-Time")
        ]

        return templates.enumerated().map { index, template in
            JobListing(
                source: source,
                title: template.0,
                company: template.1,
                location: location,
                isRemote: template.2 || request.remoteOnly,
                salaryMin: template.3,
                salaryMax: template.4,
                currency: "USD",
                employmentType: template.5,
                descriptionSnippet: "\(source.displayName) sample listing shown because live credentials or provider access are unavailable.",
                descriptionFull: """
                This is fallback sample data for \(source.displayName). Add the matching API credentials in APIConfig.plist or scheme environment variables to enable live results.
                """,
                postedDate: Calendar.current.date(byAdding: .hour, value: -index * 4, to: baseDate),
                applyURL: URL(string: "https://example.com/apply/\(source.rawValue)/\(index)"),
                listingURL: URL(string: "https://example.com/jobs/\(source.rawValue)/\(index)"),
                rawSourceID: "sample-\(request.page)-\(index)"
            )
        }
    }

    static func insights() -> [MarketInsight] {
        let calendar = Calendar.current
        let dates = (0..<6).compactMap { offset in
            calendar.date(byAdding: .month, value: -offset, to: .now)
        }.reversed()

        let unemploymentSeries = zip(dates, [4.1, 4.0, 4.0, 4.1, 4.2, 4.1]).map { date, value in
            MarketInsight.Point(
                label: date.formatted(.dateTime.month(.abbreviated)),
                date: date,
                value: value
            )
        }

        let wageSeries = zip(dates, [34.1, 34.3, 34.4, 34.5, 34.7, 34.8]).map { date, value in
            MarketInsight.Point(
                label: date.formatted(.dateTime.month(.abbreviated)),
                date: date,
                value: value
            )
        }

        return [
            MarketInsight(
                title: "National Unemployment",
                headlineValue: "4.1%",
                subtitle: "Six-month U.S. trend",
                detail: "Use this as quick labor-market context while comparing search results.",
                points: unemploymentSeries,
                sourceNote: "Fallback sample insight"
            ),
            MarketInsight(
                title: "Average Hourly Earnings",
                headlineValue: "$34.80",
                subtitle: "Private payroll trend",
                detail: "A simple wage trend helps anchor salary expectations for a lean MVP.",
                points: wageSeries,
                sourceNote: "Fallback sample insight"
            )
        ]
    }
}
