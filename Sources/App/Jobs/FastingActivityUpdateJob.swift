import Vapor
import Foundation
import Queues
import FluentSQL
import PrepDataTypes

extension Date {
    var maldivesTime: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 3600 * 5)
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self).lowercased()
    }
}

/// Goes through all `UserFastingActivity` entires that are pending an update and pushes a notification to the devices of the `User` it belongs to.
///
/// Pending entires are determined by comparing the hours passed (since `lastMealAt`) to the stored `lastNotificationHour` field.
struct FastingActivityUpdateJob: AsyncScheduledJob {
    
    func run(context: QueueContext) async throws {

        print("💼 \(Date().maldivesTime) Running FastingActivityUpdateJob")

        let activities = try await FastingActivityController().getActivitiesPendingUpdate(on: context.application.db)
        for activity in activities {
            print("    • Updating activity")
            try await update(activity, app: context.application)
        }
        if activities.isEmpty {
            print("    • No activities requiring an update")
        }
    }
    
    func update(_ activity: UserFastingActivity, app: Application) async throws {
        do {
            
            /// We've disabled this for now, ensuring all updates are high-priority
//            let lowPriority = !activity.elapsedTimeBlocks.isMultiple(of: 12)
            let lowPriority = false

            try await sendNotification(
                for: activity,
                lowPriority: lowPriority,
                app: app
            )
            
            activity.lastNotificationSentAt = Date().timeIntervalSince1970
            try await activity.update(on: app.db)
            
            print("    • 💌 Notification Sent")
        } catch {
            print("    • ⚠️ Error running job")
            /// This implies the token is expired—delete it
            print("        • 🗑 Deleting activity \(activity.id!)")
            try await activity.delete(on: app.db)
        }
    }
}

extension UserFastingActivity {
    
    var lastMealAtDate: Date {
        Date(timeIntervalSince1970: lastMealAt)
    }
    
    var elapsedTimeBlocks: Int {
        Int(Date().timeIntervalSince(lastMealAtDate) / (3600.0 / 12.0))
    }
    
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

func sendNotification(
    for activity: UserFastingActivity,
    lowPriority: Bool = false,
    app: Application
) async throws {
    try await app.apns.client.sendLiveActivityNotification(
        .init(
            expiration: .immediately,
            priority: lowPriority ? .consideringDevicePower : .immediately,
            appID: "com.pxlshpr.Prep",
            contentState: activity.contentState,
            event: .update,
            timestamp: Int(Date().timeIntervalSince1970)
        ),
        deviceToken: activity.pushToken,
        deadline: .distantFuture
    )
}
