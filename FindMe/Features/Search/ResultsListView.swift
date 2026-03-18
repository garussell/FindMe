import SwiftUI

struct ResultsListView: View {
    let jobs: [JobListing]
    let savedJobIDs: Set<String>

    var body: some View {
        LazyVStack(spacing: 14) {
            ForEach(jobs) { job in
                NavigationLink(value: job) {
                    JobCardView(job: job, isSaved: savedJobIDs.contains(job.id))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
