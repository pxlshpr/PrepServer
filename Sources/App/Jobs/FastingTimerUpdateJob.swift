import Vapor
import Foundation
import Queues
import FluentSQL

/// Goes through all `FastingTimer` entires that are pending an update and pushes a notification to the devices of the `User` it belongs to.
///
/// Pending entires are determined by comparing the hours passed (since `lastMealAt`) to the stored `lastNotificationHour` field.
struct FastingTimerUpdateJob: AsyncScheduledJob {
    
    func run(context: QueueContext) async throws {
        let updates = try await FastingTimerController().getUpdates(on: context.application.db)
        for update in updates {
            print("Send notification to: \(update.id)")
        }
    }
}
