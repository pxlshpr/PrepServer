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
        
        let activities = try await FastingActivityController().getActivitiesPendingUpdate(on: context.application.db)
        for activity in activities {
            print("💼 Updating activity")
            try await update(activity, app: context.application)
        }
        if activities.isEmpty {
            print("💼 No activities requiring an update")
        }
    }
    
    func update(_ activity: UserFastingActivity, app: Application) async throws {
        do {
            try await sendNotification(for: activity, app: app)
            
            activity.lastNotificationSentAt = Date().timeIntervalSince1970
            try await activity.update(on: app.db)
            
            print("💼 Posted notification and set lastNotificationSentAt")
        } catch {
            print("Error running job: \(error)")
        }
    }
}

extension UserFastingActivity {
    var fastingState: FastingTimerState {
        
        let nextMealTime: Date?
        if let nextMealAt {
            nextMealTime = Date(timeIntervalSince1970: nextMealAt)
        } else {
            nextMealTime = nil
        }
        
        return FastingTimerState(
            lastMealTime: Date(timeIntervalSince1970: lastMealAt),
            nextMealName: nextMealName,
            nextMealTime: nextMealTime,
            countdownType: countdownType
        )
    }

    var contentState: FastingActivityContentState {
        FastingActivityContentState(fastingState: fastingState)
    }
}

func sendNotification(for activity: UserFastingActivity, app: Application) async throws {
    try await app.apns.client.sendLiveActivityNotification(
        .init(
            expiration: .immediately,
            priority: .immediately,
            appID: "com.pxlshpr.Prep",
            contentState: activity.contentState,
            event: .update,
            timestamp: Int(Date().timeIntervalSince1970)
        ),
        deviceToken: activity.pushToken,
        deadline: .distantFuture
    )
    print("💌 PUSH SENT")
}
