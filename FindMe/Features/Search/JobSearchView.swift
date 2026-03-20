import SwiftUI
import SwiftData

struct JobSearchView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.modelContext) private var modelContext
    @Query private var savedJobs: [SavedJob]
    @State private var viewModel = JobSearchViewModel()

    private var savedJobIDs: Set<String> {
        Set(savedJobs.map(\.id))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    SearchFiltersCard(viewModel: viewModel)

                    // MARK: - Search Button
                    Button {
                        Task { await viewModel.search(reset: true) }
                    } label: {
                        Label("Search Jobs", systemImage: "magnifyingglass")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityLabel("Search for jobs")

                    // MARK: - Recent Searches
                    if !viewModel.recentSearches.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("Recent Searches")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Theme.Spacing.sm) {
                                    ForEach(viewModel.recentSearches, id: \.self) { search in
                                        Button(search) {
                                            viewModel.applyRecentSearch(search)
                                            Task { await viewModel.search(reset: true) }
                                        }
                                        .font(.subheadline)
                                        .buttonStyle(.bordered)
                                        .buttonBorderShape(.capsule)
                                    }
                                }
                            }
                        }
                    }

                    // MARK: - Source Coverage
                    if !viewModel.statuses.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("Source Coverage")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Theme.Spacing.sm) {
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

                    // MARK: - Results Header
                    HStack {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                            Text("Results")
                                .font(.title3.bold())
                            Text("\(viewModel.results.count) listings")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if viewModel.isLoading, !viewModel.results.isEmpty {
                            ProgressView()
                        }
                    }

                    // MARK: - Results Content
                    if viewModel.isLoading, viewModel.results.isEmpty, viewModel.hasLoaded {
                        SkeletonJobList(count: 3)
                    } else if viewModel.results.isEmpty, viewModel.hasLoaded, viewModel.errorMessage != nil {
                        EmptyStateCard(
                            title: "No Results Found",
                            message: viewModel.errorMessage ?? "Try adjusting your search or filters.",
                            systemImage: "tray",
                            suggestions: ["Try broader keywords", "Remove some filters", "Search a different location"]
                        )
                    } else if viewModel.results.isEmpty, !viewModel.hasLoaded {
                        if viewModel.isLoading {
                            SkeletonJobList(count: 4)
                        } else {
                            EmptyStateCard(
                                title: "Start Browsing",
                                message: "Run a search to pull live or sample listings from Adzuna, JSearch, USAJobs, and ArbeitNow.",
                                systemImage: "magnifyingglass.circle"
                            )
                        }
                    } else {
                        ResultsListView(
                            jobs: viewModel.results,
                            savedJobIDs: savedJobIDs,
                            onToggleSave: { job in toggleSave(job) }
                        )
                    }

                    // MARK: - Load More
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
                        .buttonBorderShape(.capsule)
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(
                LinearGradient(
                    colors: [Color.cyan.opacity(0.06), Color.blue.opacity(0.03), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationDestination(for: JobListing.self) { job in
                JobDetailView(job: job)
            }
            .navigationTitle("Search")
        }
        .task {
            viewModel.configureIfNeeded(searchService: container.searchService, recentSearchStore: container.recentSearchStore)
            container.locationManager.checkExistingAuthorization()
            if !viewModel.hasLoaded {
                await viewModel.search(reset: true)
            }
        }
    }

    private func toggleSave(_ job: JobListing) {
        let wasSaved = savedJobIDs.contains(job.id)
        do {
            try SavedJobsStore.toggle(job: job, in: modelContext)
            if wasSaved {
                container.toastManager.show(.removed(job.title))
            } else {
                container.toastManager.show(.saved(job.title))
            }
        } catch {
            container.toastManager.show(.error("Could not save job"))
        }
    }
}

#Preview {
    JobSearchView()
        .environment(AppContainer.makeLive())
        .modelContainer(for: SavedJob.self, inMemory: true)
}
