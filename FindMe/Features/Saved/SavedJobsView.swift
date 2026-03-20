import SwiftData
import SwiftUI

struct SavedJobsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppContainer.self) private var container
    @Query(sort: \SavedJob.savedAt, order: .reverse) private var savedJobs: [SavedJob]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    if savedJobs.isEmpty {
                        EmptyStateCard(
                            title: "No Saved Jobs",
                            message: "Tap the bookmark icon on any job card to save it for later.",
                            systemImage: "bookmark"
                        )
                    } else {
                        Text("\(savedJobs.count) saved")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        LazyVStack(spacing: 14) {
                            ForEach(Array(savedJobs.enumerated()), id: \.element.id) { index, savedJob in
                                NavigationLink(value: savedJob.jobListing) {
                                    AnimatedCardWrapper(index: index) {
                                        JobCardView(
                                            job: savedJob.jobListing,
                                            isSaved: true,
                                            onToggleSave: {
                                                removeSavedJob(savedJob)
                                            }
                                        )
                                        .contentShape(Rectangle())
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.04), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationDestination(for: JobListing.self) { job in
                JobDetailView(job: job)
            }
            .navigationTitle("Saved")
        }
    }

    private func removeSavedJob(_ savedJob: SavedJob) {
        let title = savedJob.title
        do {
            try SavedJobsStore.remove(savedJob: savedJob, in: modelContext)
            container.toastManager.show(.removed(title))
        } catch {
            container.toastManager.show(.error("Could not remove job"))
        }
    }
}
