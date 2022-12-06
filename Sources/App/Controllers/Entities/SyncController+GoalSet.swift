import Fluent
import Vapor
import PrepDataTypes

extension SyncController {
    
    func processUpdatedDeviceGoalSets(_ deviceGoalSets: [PrepDataTypes.GoalSet], user: User, on db: Database) async throws {
        for deviceGoalSet in deviceGoalSets {
            try await processUpdatedDeviceGoalSet(deviceGoalSet, user: user, on: db)
        }
    }
    
    func processUpdatedDeviceGoalSet(_ deviceGoalSet: PrepDataTypes.GoalSet, user: User, on db: Database) async throws {
        
        let serverGoalSet = try await GoalSet.query(on: db)
            .filter(\.$id == deviceGoalSet.id)
            .first()

        if let serverGoalSet {
            try await updateServerGoalSet(serverGoalSet, with: deviceGoalSet, on: db)
        } else {
            try await createNewServerGoalSet(with: deviceGoalSet, user: user, on: db)
        }
    }
    
    func updateServerGoalSet(_ serverGoalSet: GoalSet, with deviceGoalSet: PrepDataTypes.GoalSet, on db: Database) async throws {
        try serverGoalSet.update(with: deviceGoalSet)
        try await serverGoalSet.update(on: db)
    }
    
    func createNewServerGoalSet(with deviceGoalSet: PrepDataTypes.GoalSet, user: User, on db: Database) async throws {
        let goalSet = GoalSet(deviceGoalSet: deviceGoalSet, userId: try user.requireID())
        try await goalSet.save(on: db)
    }

}
