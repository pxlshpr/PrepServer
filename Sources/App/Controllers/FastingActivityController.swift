import Fluent
import Vapor
import PrepDataTypes
import FluentSQL
import APNS

struct FastingActivityController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("fastingActivity")
        group.on(.POST, "", use: update)
        group.on(.GET, "sendNotifications", use: sendNotifications)
        group.on(.GET, "sendTestNotification", use: sendTestNotification)
    }
    
    func update(req: Request) async throws -> HTTPStatus {
        print("🛠 Decoding form")
        let form = try req.content.decode(FastingActivityForm.self)
        print("🛠 Form decoded")

        if let lastMealAt = form.lastMealAt {
            print("🛠 Calling addOrUpdateEntry")
            try await addOrUpdateEntry(at: lastMealAt, with: form, on: req.db)
        } else {
            print("🛠 Calling removeEntry")
            try await removeEntry(forUserId: form.userId, on: req.db)
        }
        
        return .ok
    }

    func sendTestNotification(req: Request) async throws -> HTTPStatus {
        do {
            guard let firstActivity = try await UserFastingActivity.query(on: req.db)
                .first() else {
                return .notFound
            }
            try await sendNotification(for: firstActivity, req: req)
            return .ok
        } catch {
            return .badRequest
        }
    }
    func sendNotification(for activity: UserFastingActivity, req: Request) async throws {
        //TODO: Send actual lastMealTime
        let fastingState = FastingTimerState(
            lastMealTime: Date().moveDayBy(-2)
        )
        let contentState = FastingActivityContentState(fastingState: fastingState)
        
        try await req.application.apns.client.sendLiveActivityNotification(
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
    
    func sendNotifications(req: Request) async throws -> HTTPStatus {
        let activities = try await getActivitiesPendingUpdate(on: req.db)
        //TODO: Send notifications and update lastNotificationAt fields
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
         FLOOR((last_notification_at - last_meal_at) / 3600) as last_notification_hour,
         FLOOR((CAST(EXTRACT(epoch FROM NOW()) AS INT) - last_meal_at) / 3600) as elapsed_hours
     FROM user_fasting_activities
 ) AS x
 where x.elapsed_hours > x.last_notification_hour;
""")
            .all(decoding: UserFastingActivity.self)
        return updates
    }
}

extension FastingActivityController {
    func removeEntry(forUserId userId: UUID, on db: Database) async throws {
        /// Remove the row if it exists
        /// Sanity check that this would stop the notifications from being sent
    }
    
    func addOrUpdateEntry(at lastMealAt: Double, with form: FastingActivityForm, on db: Database) async throws {
        print("🛠 Fetching existingActivity with \(form.pushToken)")
        let existingActivity = try await UserFastingActivity.query(on: db)
            .filter(\.$pushToken == form.pushToken)
            .first()
        
        if let existingActivity {
            print("🛠 Have existing activity, updating")
            /// If we have an entry already, update it
            existingActivity.update(with: form)
            try await existingActivity.update(on: db)
        } else {
            print("🛠 No existing activity, fetching user with: \(form.userId)")
            /// Otherwise, add it
            guard let user = try await User.find(form.userId, on: db) else {
                throw FastingActivityError.userNotFound
            }
            print("🛠 Creating new activity and saving")
            let newActivity = UserFastingActivity(form: form, userId: try user.requireID())
            try await newActivity.save(on: db)
        }
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
