import SwiftUI

struct ResultsListView: View {
    let jobs: [JobListing]
    let savedJobIDs: Set<String>
    var onToggleSave: ((JobListing) -> Void)?

    var body: some View {
        LazyVStack(spacing: 14) {
            ForEach(Array(jobs.enumerated()), id: \.element.id) { index, job in
                NavigationLink(value: job) {
                    AnimatedCardWrapper(index: index) {
                        JobCardView(
                            job: job,
                            isSaved: savedJobIDs.contains(job.id),
                            onToggleSave: onToggleSave.map { callback in { callback(job) } }
                        )
                        .contentShape(Rectangle())
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
