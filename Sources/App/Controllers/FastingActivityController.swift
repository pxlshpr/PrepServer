import Fluent
import Vapor
import PrepDataTypes
import FluentSQL
import APNS

struct FastingActivityController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("fastingActivity")
        group.on(.GET, "sendNotifications", use: sendNotifications)
        group.on(.GET, "sendTestNotification", use: sendTestNotification)
    }
    
    func sendTestNotification(req: Request) async throws -> HTTPStatus {
        do {
            print("getting first activity")
            guard let firstActivity = try await UserFastingActivity.query(on: req.db)
                .filter(\.$deletedAt == nil)
                .first() else {
                return .notFound
            }
            print("posting test notification to: \(firstActivity.pushToken)")
            try await sendNotification(for: firstActivity, application: req.application)
            return .ok
        } catch {
            return .badRequest
        }
    }
    
    func sendNotifications(req: Request) async throws -> HTTPStatus {
        let activities = try await getActivitiesPendingUpdate(on: req.db)
        //TODO: Send notifications and update lastNotificationAt fields
        print("We have \(activities.count) activities to send updates to")
        return .ok
    }
    
    func getActivitiesPendingUpdate(on db: Database) async throws -> [UserFastingActivity] {
        guard let sql = db as? SQLDatabase else {
            // The underlying database driver is _not_ SQL.
            return []
        }
        let updates = try await sql
            .raw("""
 SELECT
     x.id,
     x.user_id,
     x.last_meal_at,
     x.next_meal_at,
     x.next_meal_name,
     x.countdown_type,
     x.push_token,
     x.last_notification_sent_at
 FROM
 (
     SELECT
         *,
         FLOOR((last_notification_sent_at - last_meal_at) / 3600) as last_notification_hour,
         FLOOR((CAST(EXTRACT(epoch FROM NOW()) AS INT) - last_meal_at) / 3600) as elapsed_hours
     FROM user_fasting_activities
 ) AS x
 where x.elapsed_hours > x.last_notification_hour;
""")
            .all(decoding: UserFastingActivity.self)
        return updates
/**
 */
    }
}

enum FastingActivityError: Error {
    case userNotFound
}

public struct FastingActivityContentState: Codable, Hashable {
    // Dynamic stateful properties about your activity go here!
    public var fastingState: FastingTimerState
    
    public init(fastingState: FastingTimerState) {
        self.fastingState = fastingState
    }
}
