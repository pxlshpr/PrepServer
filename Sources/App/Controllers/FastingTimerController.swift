import Fluent
import Vapor
import PrepDataTypes
import FluentSQL
import APNS

struct FastingTimerController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("fastingTimer")
        group.on(.POST, "", use: update)
        group.on(.GET, "updates", use: updates)
    }
    
    func update(req: Request) async throws -> HTTPStatus {
        let form = try req.content.decode(FastingTimerForm.self)
        
        if let lastMealAt = form.lastMealAt {
            try await addOrUpdateEntry(at: lastMealAt, with: form, on: req.db)
        } else {
            try await removeEntry(forUserId: form.userId, on: req.db)
        }
        
        return .ok
    }
    
    func removeEntry(forUserId userId: UUID, on db: Database) async throws {
        /// Remove the row if it exists
        /// Sanity check that this would stop the notifications from being sent
    }
    
    func addOrUpdateEntry(at lastMealAt: Double, with form: FastingTimerForm, on db: Database) async throws {
        let existingTimer = try await UserFastingTimer.query(on: db)
            .join(User.self, on: \UserFastingTimer.$user.$id == \User.$id)
            .filter(User.self, \.$id == form.userId)
            .first()
        
        if let existingTimer {
            /// If we have an entry already, update it
            existingTimer.update(with: form)
            try await existingTimer.update(on: db)
        } else {
            /// Otherwise, add it
            guard let user = try await User.find(form.userId, on: db) else {
                throw FastingTimerError.userNotFound
            }
            // Otherwise, first check if the user exists
            // Then add it
            let newTimer = UserFastingTimer(form: form, userId: try user.requireID())
            try await newTimer.save(on: db)
        }
    }
    
    func updates(req: Request) async throws -> HTTPStatus {
        let _ = try await getUpdates(on: req.db)
        let contentState = FastingTimerContentState(fastingState: .init(lastMealTime: Date().moveDayBy(-2)))
        try await req.application.apns.client.sendLiveActivityNotification(
            .init(
                expiration: .immediately,
                priority: .immediately,
                appID: "com.pxlshpr.Prep",
                contentState: contentState,
                event: .update,
                timestamp: Int(Date().timeIntervalSince1970)
            ),
            deviceToken: "80ab9048784d14753a36f87dc7280e798eca2bf39023d87ef4aae614677ee5e4da5322aa3748f3f6023db389491d88c6855484dc0b0d7a034d3cdbda702ef87a4aee50814d097225ac19a3ccdea41b1d",
            deadline: .distantFuture
        )
        print("💌 PUSH SENT")
        return .ok
    }
    
    func getUpdates(on db: Database) async throws -> [FastingTimerUpdate] {
        guard let sql = db as? SQLDatabase else {
            // The underlying database driver is _not_ SQL.
            return []
        }
        let updates = try await sql
            .raw("""
 SELECT
     x.id,
     CAST(x.last_notification_hour AS Int),
     CAST(x.hours AS Int)
 FROM
 (
     SELECT
         *,
         FLOOR(((CAST(EXTRACT(epoch FROM NOW()) AS INT) - last_meal_at) / 3600)) as hours
     FROM user_fasting_timers
 ) AS x
 where x.hours > x.last_notification_hour;
""")
            .all(decoding: FastingTimerUpdate.self)
        return updates
    }
}

struct FastingTimerUpdate: Codable {
    let id: UUID
    let last_notification_hour: Int
    let hours: Int
}

enum FastingTimerError: Error {
    case userNotFound
}

public struct FastingTimerContentState: Codable, Hashable {
    // Dynamic stateful properties about your activity go here!
    public var fastingState: FastingTimerState
    
    public init(fastingState: FastingTimerState) {
        self.fastingState = fastingState
    }
}
