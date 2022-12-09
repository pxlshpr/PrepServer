import Fluent
import Vapor
import PrepDataTypes

extension SyncController {
    
    func processUpdatedDeviceFastingActivities(_ deviceFastingActivities: [PrepDataTypes.FastingActivity], user: User, on db: Database) async throws {
        for deviceFastingActivity in deviceFastingActivities {
            try await processUpdatedDeviceFastingActivity(deviceFastingActivity, user: user, on: db)
        }
    }
    
    func processUpdatedDeviceFastingActivity(_ deviceFastingActivity: PrepDataTypes.FastingActivity, user: User, on db: Database) async throws {
        let serverFastingActivity = try await UserFastingActivity.query(on: db)
            .filter(\.$pushToken == deviceFastingActivity.pushToken)
            .first()
        
        if let serverFastingActivity {
            try await updateServerFastingActivity(serverFastingActivity, with: deviceFastingActivity, on: db)
        } else {
            try await createNewServerFastingActivity(with: deviceFastingActivity, user: user, on: db)
        }
    }
    
    func updateServerFastingActivity(_ serverFastingActivity: UserFastingActivity, with deviceFastingActivity: PrepDataTypes.FastingActivity, on db: Database) async throws {
        print("🛠 Have existing activity, updating")
        /// If we have an entry already, update it
        serverFastingActivity.update(with: deviceFastingActivity)
        try await serverFastingActivity.update(on: db)
    }
    
    func createNewServerFastingActivity(with deviceFastingActivity: PrepDataTypes.FastingActivity, user: User, on db: Database) async throws {
        print("🛠 Creating new activity and saving")
        let newActivity = UserFastingActivity(with: deviceFastingActivity, userId: try user.requireID())
        try await newActivity.save(on: db)
    }

}
