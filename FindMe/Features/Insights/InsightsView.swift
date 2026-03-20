import SwiftUI

struct InsightsView: View {
    @Environment(AppContainer.self) private var container
    @State private var viewModel = InsightsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Labor Market Snapshot")
                            .font(.title2.bold())

                        Text("Broader market context to help calibrate your search and salary expectations.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if viewModel.isLoading {
                        VStack(spacing: Theme.Spacing.lg) {
                            ForEach(0..<2, id: \.self) { _ in
                                SkeletonInsightCard()
                            }
                        }
                    } else if viewModel.insights.isEmpty, viewModel.hasLoaded {
                        EmptyStateCard(
                            title: "No Insights Available",
                            message: "Market data could not be loaded. Check your connection and try again.",
                            systemImage: "chart.line.downtrend.xyaxis",
                            retryAction: {
                                viewModel.hasLoaded = false
                                Task { await viewModel.loadIfNeeded() }
                            }
                        )
                    } else {
                        ForEach(Array(viewModel.insights.enumerated()), id: \.element.id) { index, insight in
                            AnimatedCardWrapper(index: index) {
                                InsightCardView(insight: insight)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.mint.opacity(0.08), Color.blue.opacity(0.04), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Insights")
        }
        .task {
            viewModel.configureIfNeeded(service: container.insightsService)
            await viewModel.loadIfNeeded()
        }
    }
}

// MARK: - Skeleton Insight Card

private struct SkeletonInsightCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                skeletonRect(width: 160, height: 16)
                skeletonRect(width: 100, height: 28)
                skeletonRect(width: 200, height: 13)
            }

            skeletonRect(height: 160)

            skeletonRect(height: 12)
            skeletonRect(width: 120, height: 10)
        }
        .padding(Theme.Spacing.xl)
        .cardStyle()
        .shimmer()
    }

    private func skeletonRect(width: CGFloat? = nil, height: CGFloat = 14) -> some View {
        RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
            .fill(Color.primary.opacity(0.08))
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }
}
