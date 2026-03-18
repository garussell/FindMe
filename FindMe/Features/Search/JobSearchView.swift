import SwiftUI
import SwiftData

struct JobSearchView: View {
    @Environment(AppContainer.self) private var container
    @Query private var savedJobs: [SavedJob]
    @State private var viewModel = JobSearchViewModel()

    private var savedJobIDs: Set<String> {
        Set(savedJobs.map(\.id))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SearchFiltersCard(viewModel: viewModel)

                    Button {
                        Task { await viewModel.search(reset: true) }
                    } label: {
                        Label("Search Jobs", systemImage: "magnifyingglass")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    if !viewModel.recentSearches.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent Searches")
                                .font(.headline)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(viewModel.recentSearches, id: \.self) { search in
                                        Button(search) {
                                            viewModel.applyRecentSearch(search)
                                            Task { await viewModel.search(reset: true) }
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                            }
                        }
                    }

                    if !viewModel.statuses.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Source Coverage")
                                .font(.headline)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(viewModel.statuses) { status in
                                        SourceStatusChipView(status: status)
                                    }
                                }
                            }

                            if let firstMessage = viewModel.statuses.compactMap(\.message).first {
                                Text(firstMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Unified Results")
                                .font(.title3.bold())
                            Text("\(viewModel.results.count) listings")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if viewModel.isLoading {
                            ProgressView()
                        }
                    }

                    if viewModel.results.isEmpty, viewModel.hasLoaded, let errorMessage = viewModel.errorMessage {
                        EmptyStateCard(
                            title: "No Results Yet",
                            message: errorMessage,
                            systemImage: "tray"
                        )
                    } else if viewModel.results.isEmpty, !viewModel.hasLoaded {
                        EmptyStateCard(
                            title: "Start Browsing",
                            message: "Run a search to pull live or sample listings from Adzuna, JSearch, USAJobs, and ArbeitNow.",
                            systemImage: "magnifyingglass.circle"
                        )
                    } else {
                        ResultsListView(jobs: viewModel.results, savedJobIDs: savedJobIDs)
                    }

                    if viewModel.canLoadMore, !viewModel.results.isEmpty {
                        Button {
                            Task { await viewModel.loadMore() }
                        } label: {
                            if viewModel.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Load More")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.cyan.opacity(0.06), Color.blue.opacity(0.03), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationDestination(for: JobListing.self) { job in
                JobDetailView(job: job)
            }
            .navigationTitle("Search")
        }
        .task {
            viewModel.configureIfNeeded(searchService: container.searchService, recentSearchStore: container.recentSearchStore)
            if !viewModel.hasLoaded {
                await viewModel.search(reset: true)
            }
        }
    }
}

#Preview {
    JobSearchView()
        .environment(AppContainer.makeLive())
        .modelContainer(for: SavedJob.self, inMemory: true)
}
