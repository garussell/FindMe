import SwiftData
import SwiftUI

struct SavedJobsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedJob.savedAt, order: .reverse) private var savedJobs: [SavedJob]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if savedJobs.isEmpty {
                        EmptyStateCard(
                            title: "No Saved Jobs",
                            message: "Save promising roles from search results to revisit them later.",
                            systemImage: "bookmark"
                        )
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(savedJobs) { savedJob in
                                NavigationLink(value: savedJob.jobListing) {
                                    JobCardView(job: savedJob.jobListing, isSaved: true)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button("Remove", role: .destructive) {
                                        do {
                                            try SavedJobsStore.remove(savedJob: savedJob, in: modelContext)
                                        } catch {
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationDestination(for: JobListing.self) { job in
                JobDetailView(job: job)
            }
            .navigationTitle("Saved")
        }
    }
}
