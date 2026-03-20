import SwiftUI
import SwiftData

struct JobDetailView: View {
    let job: JobListing

    @Environment(\.modelContext) private var modelContext
    @Environment(AppContainer.self) private var container
    @Query private var savedJobs: [SavedJob]
    @State private var appeared = false

    private var isSaved: Bool {
        SavedJobsStore.contains(jobID: job.id, in: savedJobs)
    }

    /// True if the job was posted within the last 24 hours.
    private var isNew: Bool {
        guard let posted = job.postedDate else { return false }
        return posted.timeIntervalSinceNow > -86_400
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                // MARK: - Header Card
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    HStack(spacing: Theme.Spacing.sm) {
                        SourceBadgeView(source: job.source)
                        if job.isRemote {
                            Label("Remote", systemImage: "house")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.blue.opacity(0.12), in: Capsule())
                                .foregroundStyle(.blue)
                        }
                        if isNew {
                            Text("New")
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.Colors.newBadge.opacity(0.15), in: Capsule())
                                .foregroundStyle(Theme.Colors.newBadge)
                        }
                    }

                    Text(job.title)
                        .font(.largeTitle.bold())

                    Text(job.company)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Label(job.location, systemImage: "mappin.and.ellipse")
                        if let salary = job.salaryText {
                            Label(salary, systemImage: "dollarsign.circle")
                        }
                        if let employmentType = job.employmentType {
                            Label(employmentType, systemImage: "briefcase")
                        }
                        if let posted = job.postedDate {
                            Label(posted.formatted(.relative(presentation: .named)), systemImage: "calendar")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                // MARK: - Actions
                HStack(spacing: Theme.Spacing.md) {
                    Button {
                        toggleSave()
                    } label: {
                        Label(isSaved ? "Saved" : "Save Job", systemImage: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.body.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isSaved ? .secondary : .blue)

                    if let shareURL = job.listingURL ?? job.applyURL {
                        ShareLink(item: shareURL) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)
                    }

                    if let originalURL = job.listingURL ?? job.applyURL {
                        Link(destination: originalURL) {
                            Label("Open", systemImage: "arrow.up.right.square")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                // MARK: - Description
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("Description")
                        .font(.headline)
                    Text(job.effectiveDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                .padding(Theme.Spacing.xl)
                .cardStyle()
            }
            .padding()
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
        }
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.04), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Job Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(Theme.Animation.smooth) {
                appeared = true
            }
        }
    }

    private func toggleSave() {
        let wasSaved = isSaved
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
