import SwiftUI
import SwiftData

struct JobDetailView: View {
    let job: JobListing

    @Environment(\.modelContext) private var modelContext
    @Query private var savedJobs: [SavedJob]

    private var isSaved: Bool {
        SavedJobsStore.contains(jobID: job.id, in: savedJobs)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        SourceBadgeView(source: job.source)
                        if job.isRemote {
                            Text("Remote")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.blue.opacity(0.12), in: Capsule())
                                .foregroundStyle(.blue)
                        }
                    }

                    Text(job.title)
                        .font(.largeTitle.bold())

                    Text(job.company)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        Label(job.location, systemImage: "mappin.and.ellipse")
                        if let salary = job.salaryText {
                            Label(salary, systemImage: "dollarsign.circle")
                        }
                        if let employmentType = job.employmentType {
                            Label(employmentType, systemImage: "briefcase")
                        }
                        if let posted = job.postedDate {
                            Label(posted.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Button(isSaved ? "Remove Saved Job" : "Save Job") {
                        do {
                            try SavedJobsStore.toggle(job: job, in: modelContext)
                        } catch {
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    if let shareURL = job.listingURL ?? job.applyURL {
                        ShareLink(item: shareURL) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)
                    }

                    if let originalURL = job.listingURL ?? job.applyURL {
                        Link(destination: originalURL) {
                            Label("Open Original", systemImage: "arrow.up.right.square")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Description")
                        .font(.headline)
                    Text(job.effectiveDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .padding()
        }
        .navigationTitle("Job Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
