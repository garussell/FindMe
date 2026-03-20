import Charts
import SwiftUI

struct InsightCardView: View {
    let insight: MarketInsight

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(insight.title)
                    .font(.headline)
                Text(insight.headlineValue)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text(insight.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Chart(insight.points) { point in
                LineMark(
                    x: .value("Month", point.date),
                    y: .value("Value", point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(.blue.gradient)

                AreaMark(
                    x: .value("Month", point.date),
                    y: .value("Value", point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(.blue.opacity(0.18))
            }
            .frame(height: 160)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading)
            }

            Text(insight.detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(insight.sourceNote)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(Theme.Spacing.xl)
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(insight.title): \(insight.headlineValue)")
    }
}
