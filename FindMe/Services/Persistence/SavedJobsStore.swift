import Foundation
import SwiftData

@MainActor
enum SavedJobsStore {
    static func contains(jobID: String, in jobs: [SavedJob]) -> Bool {
        jobs.contains { $0.id == jobID }
    }

    static func toggle(job: JobListing, in context: ModelContext) throws {
        let descriptor = FetchDescriptor<SavedJob>(
            predicate: #Predicate { $0.id == job.id }
        )

        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
        } else {
            context.insert(SavedJob(job: job))
        }

        try context.save()
    }

    static func remove(savedJob: SavedJob, in context: ModelContext) throws {
        context.delete(savedJob)
        try context.save()
    }
}
