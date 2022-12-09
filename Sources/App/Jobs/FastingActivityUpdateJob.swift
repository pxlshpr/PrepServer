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
    }
    
    func update(_ activity: UserFastingActivity, app: Application) async throws {
        do {
            print("💼 Posting notification to: \(activity.pushToken)")
            try await sendNotification(for: activity, app: app)
            return
        } catch {
            print("Error running job: \(error)")
            return
        }
    }
}

extension UserFastingActivity {
    var fastingState: FastingTimerState {
        FastingTimerState(
            lastMealTime: <#T##Date#>,
            nextMeal: <#T##DayMeal?#>,
            countdownType: <#T##FastingTimerCountdownType#>
        )
    }

    var contentState: FastingActivityContentState {
        FastingActivityContentState(fastingState: fastingState)
    }
}

func sendNotification(for activity: UserFastingActivity, app: Application) async throws {
    //TODO: Send actual lastMealTime
    let fastingState = FastingTimerState(
        lastMealTime: Date().moveDayBy(-2)
    )
    let contentState = FastingActivityContentState(fastingState: fastingState)
    
    try await app.apns.client.sendLiveActivityNotification(
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
