import Vapor
import Foundation
import Queues
import FluentSQL
import PrepDataTypes

struct FastingActivityCleanupJob: AsyncScheduledJob {
    
    func run(context: QueueContext) async throws {

        print("🧹 \(Date().maldivesTime) Running FastingActivityCleanupJob")

        let staleActivities = try await FastingActivityController().getActivitiesDeletedMoreThanFiveMinutesAgo(on: context.application.db)
        for staleActivity in staleActivities {
            print("    • 🗑 Deleting activity \(staleActivity.id!)")
            try await staleActivity.delete(on: context.application.db)
        }
        if staleActivities.isEmpty {
            print("    • No activities requiring deletion")
        }
    }
}
