import Foundation

struct BLSInsightsService: Sendable {
    struct V2Request: Encodable, Sendable {
        let seriesid: [String]
        let startyear: String
        let endyear: String
        let registrationkey: String
    }

    struct Response: Decodable, Sendable {
        struct Results: Decodable, Sendable {
            struct Series: Decodable, Sendable {
                struct Entry: Decodable, Sendable {
                    let year: String
                    let period: String
                    let value: String
                }

                let seriesID: String
                let data: [Entry]

                enum CodingKeys: String, CodingKey {
                    case seriesID = "seriesID"
                    case data
                }
            }

            let series: [Series]
        }

        let results: Results

        enum CodingKeys: String, CodingKey {
            case results = "Results"
        }
    }

    let client: HTTPClient
    let configuration: AppConfiguration

    func loadInsights() async -> [MarketInsight] {
        async let unemployment = loadSeries(id: "LNS14000000")
        async let earnings = loadSeries(id: "CES0500000003")

        let unemploymentSeries = await unemployment
        let earningsSeries = await earnings

        guard !unemploymentSeries.isEmpty, !earningsSeries.isEmpty else {
            return MockJobData.insights()
        }

        let unemploymentPoints = Array(unemploymentSeries.suffix(6))
        let earningsPoints = Array(earningsSeries.suffix(6))

        let latestUnemployment = unemploymentPoints.last?.value ?? 0
        let latestEarnings = earningsPoints.last?.value ?? 0

        return [
            MarketInsight(
                title: "National Unemployment",
                headlineValue: "\(latestUnemployment.formatted(.number.precision(.fractionLength(1))))%",
                subtitle: "BLS seasonally adjusted headline trend",
                detail: "This gives users a fast national hiring-context signal beside current job listings.",
                points: unemploymentPoints,
                sourceNote: "BLS series LNS14000000"
            ),
            MarketInsight(
                title: "Average Hourly Earnings",
                headlineValue: "$\(latestEarnings.formatted(.number.precision(.fractionLength(2))))",
                subtitle: "Private payroll wage trend",
                detail: "A lightweight wage card makes the MVP feel more grounded without overbuilding analytics.",
                points: earningsPoints,
                sourceNote: "BLS series CES0500000003"
            )
        ]
    }

    private func loadSeries(id: String) async -> [MarketInsight.Point] {
        let series: [Response.Results.Series.Entry]

        if let apiKey = configuration.blsAPIKey,
           let url = URL(string: "https://api.bls.gov/publicAPI/v2/timeseries/data/") {
            let currentYear = Calendar.current.component(.year, from: .now)

            do {
                let response = try await client.post(
                    Response.self,
                    url: url,
                    body: V2Request(
                        seriesid: [id],
                        startyear: String(currentYear - 1),
                        endyear: String(currentYear),
                        registrationkey: apiKey
                    )
                )
                series = response.results.series.first?.data ?? []
            } catch {
                series = await loadSeriesV1(id: id)
            }
        } else {
            series = await loadSeriesV1(id: id)
        }

        return series
            .compactMap { entry in
                guard entry.period.hasPrefix("M"),
                      let month = Int(entry.period.dropFirst()),
                      let year = Int(entry.year),
                      let value = Double(entry.value),
                      let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) else {
                    return nil
                }

                return MarketInsight.Point(
                    label: date.formatted(.dateTime.month(.abbreviated)),
                    date: date,
                    value: value
                )
            }
            .sorted { $0.date < $1.date }
    }

    private func loadSeriesV1(id: String) async -> [Response.Results.Series.Entry] {
        guard let url = URL(string: "https://api.bls.gov/publicAPI/v1/timeseries/data/\(id)") else {
            return []
        }

        do {
            let response = try await client.get(Response.self, url: url)
            return response.results.series.first?.data ?? []
        } catch {
            return []
        }
    }
}
