import SwiftUI
import SwiftData

struct JobCardView: View {
    let job: JobListing
    let isSaved: Bool
    var onToggleSave: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bookmarkBounce = false

    /// True if the job was posted within the last 24 hours.
    private var isNew: Bool {
        guard let posted = job.postedDate else { return false }
        return posted.timeIntervalSinceNow > -86_400
    }

    /// True if the job was posted within the last 3 days (but not "new").
    private var isHot: Bool {
        guard let posted = job.postedDate else { return false }
        let age = -posted.timeIntervalSinceNow
        return age >= 86_400 && age < 259_200
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // MARK: - Top Row: Logo + Title + Bookmark
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                // Company logo placeholder
                companyAvatar

                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(job.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(job.company)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                if let onToggleSave {
                    Button {
                        onToggleSave()
                        if !reduceMotion {
                            withAnimation(Theme.Animation.springy) {
                                bookmarkBounce = true
                            }
                            Task {
                                try? await Task.sleep(for: .milliseconds(400))
                                bookmarkBounce = false
                            }
                        }
                    } label: {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.title3)
                            .foregroundStyle(isSaved ? .blue : .secondary)
                            .scaleEffect(bookmarkBounce ? 1.3 : 1.0)
                            .symbolEffect(.bounce, value: bookmarkBounce)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isSaved ? "Remove from saved" : "Save job")
                } else if isSaved {
                    Image(systemName: "bookmark.fill")
                        .foregroundStyle(.blue)
                }
            }

            // MARK: - Badges Row
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
                } else if isHot {
                    Label("Hot", systemImage: "flame.fill")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.Colors.hotBadge.opacity(0.15), in: Capsule())
                        .foregroundStyle(Theme.Colors.hotBadge)
                }
            }

            // MARK: - Details Row
            HStack(spacing: Theme.Spacing.lg) {
                Label(job.location, systemImage: "mappin.and.ellipse")

                if let salary = job.salaryText {
                    Label(salary, systemImage: "dollarsign.circle")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)

            if let employmentType = job.employmentType {
                Label(employmentType, systemImage: "briefcase")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // MARK: - Description Snippet
            Text(job.descriptionSnippet)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            // MARK: - Relative Date
            if let posted = job.postedRelativeText {
                Text("Posted \(posted)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(job.title) at \(job.company), \(job.location)")
    }

    // MARK: - Company Avatar

    private var companyAvatar: some View {
        let initials = job.company.prefix(2).uppercased()
        return Text(initials)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 40, height: 40)
            .background(
                LinearGradient(
                    colors: [job.source.tint, job.source.tint.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}

#Preview {
    JobCardView(
        job: JobListing(
            source: .arbeitnow,
            title: "Senior iOS Engineer",
            company: "Northstar Labs",
            location: "Denver, CO",
            isRemote: true,
            salaryMin: 140_000,
            salaryMax: 175_000,
            currency: "USD",
            employmentType: "Full-Time",
            descriptionSnippet: "Build mobile experiences that help people search jobs smarter across public APIs.",
            descriptionFull: nil,
            postedDate: .now,
            applyURL: nil,
            listingURL: nil,
            rawSourceID: "preview"
        ),
        isSaved: true,
        onToggleSave: {}
    )
    .padding()
}
