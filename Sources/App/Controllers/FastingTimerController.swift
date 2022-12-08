import Fluent
import Vapor
import PrepDataTypes

struct FastingTimerController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("fastingTimer")
        group.on(.POST, "", use: update)
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
}

enum FastingTimerError: Error {
    case userNotFound
}
