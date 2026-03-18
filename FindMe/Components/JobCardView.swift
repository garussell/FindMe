import SwiftUI

struct JobCardView: View {
    let job: JobListing
    let isSaved: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(job.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(job.company)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                if isSaved {
                    Image(systemName: "bookmark.fill")
                        .foregroundStyle(.blue)
                }
            }

            HStack(spacing: 8) {
                SourceBadgeView(source: job.source)

                if job.isRemote {
                    Label("Remote", systemImage: "house")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.blue.opacity(0.12), in: Capsule())
                        .foregroundStyle(.blue)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Label(job.location, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let salary = job.salaryText {
                    Label(salary, systemImage: "dollarsign.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let employmentType = job.employmentType {
                    Label(employmentType, systemImage: "briefcase")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text(job.descriptionSnippet)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            if let posted = job.postedRelativeText {
                Text("Posted \(posted)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.thinMaterial)
        )
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
        isSaved: true
    )
    .padding()
}
