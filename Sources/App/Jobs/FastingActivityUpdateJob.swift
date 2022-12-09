import Vapor
import Foundation
import Queues
import FluentSQL
import PrepDataTypes

/// Goes through all `UserFastingActivity` entires that are pending an update and pushes a notification to the devices of the `User` it belongs to.
///
/// Pending entires are determined by comparing the hours passed (since `lastMealAt`) to the stored `lastNotificationHour` field.
struct FastingActivityUpdateJob: AsyncScheduledJob {
    
    func run(context: QueueContext) async throws {
        
//        let updates = try await FastingActivityController().getActivitiesPendingUpdate(on: context.application.db)
//        for update in updates {
//            print("Send notification to: \(update.id)")
//        }
        
        do {
            print("getting first activity")
            guard let firstActivity = try await UserFastingActivity.query(on: context.application.db)
                .filter(\.$deletedAt == nil)
                .first() else {
                return
            }
            print("posting test notification to: \(firstActivity.pushToken)")
            try await sendNotification(for: firstActivity, application: context.application)
            return
        } catch {
            print("Error running job: \(error)")
            return
        }

    }
}

func sendNotification(for activity: UserFastingActivity, application: Application) async throws {
    //TODO: Send actual lastMealTime
    let fastingState = FastingTimerState(
        lastMealTime: Date().moveDayBy(-2)
    )
    let contentState = FastingActivityContentState(fastingState: fastingState)
    
    try await application.apns.client.sendLiveActivityNotification(
        .init(
            expiration: .immediately,
            priority: .immediately,
            appID: "com.pxlshpr.Prep",
            contentState: contentState,
            event: .update,
            timestamp: Int(Date().timeIntervalSince1970)
        ),
        deviceToken: activity.pushToken,
        deadline: .distantFuture
    )
    print("💌 PUSH SENT")
}
