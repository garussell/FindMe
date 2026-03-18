import SwiftUI

struct InsightsView: View {
    @Environment(AppContainer.self) private var container
    @State private var viewModel = InsightsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Labor Market Snapshot")
                        .font(.title2.bold())

                    Text("A lean BLS section helps users calibrate what the broader market looks like without turning the MVP into a full analytics product.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 220)
                    } else {
                        ForEach(viewModel.insights) { insight in
                            InsightCardView(insight: insight)
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
            )
            .navigationTitle("Insights")
        }
        .task {
            viewModel.configureIfNeeded(service: container.insightsService)
            await viewModel.loadIfNeeded()
        }
    }
}
