import Fluent
import Vapor
import PrepDataTypes

extension SyncController {
    
    func processUpdatedDeviceMeals(_ deviceMeals: [PrepDataTypes.Meal], on db: Database) async throws {
        for deviceMeal in deviceMeals {
            try await processUpdatedDeviceMeal(deviceMeal, on: db)
        }
    }
    
    func processUpdatedDeviceMeal(_ deviceMeal: PrepDataTypes.Meal, on db: Database) async throws {
        
        let serverMeal = try await Meal.query(on: db)
            .filter(\.$id == deviceMeal.id)
            .with(\.$day)
            .first()

        if let serverMeal {
            try await updateServerMeal(serverMeal, with: deviceMeal, on: db)
        } else {
            try await createNewServerMeal(with: deviceMeal, on: db)
        }
    }
    
    func updateServerMeal(_ serverMeal: Meal, with deviceMeal: PrepDataTypes.Meal, on db: Database) async throws {
        /// If the `Day`'s don't match, fetch the new one and supply it to the `updateServerMeal` function
        let newDay: Day?
        if serverMeal.day.id != deviceMeal.day.id {
            guard let day = try await Day.find(deviceMeal.day.id, on: db) else {
                throw ServerSyncError.dayNotFound
            }
            newDay = day
        } else {
            newDay = nil
        }
        
        /// If the `GoalSet`'s don't match, fetch the new one and supply it to the `updateServerMeal` function
        let newGoalSet: GoalSet?
        if let deviceGoalSetId = deviceMeal.goalSet?.id,
           serverMeal.goalSet?.id != deviceGoalSetId
        {
            guard let goalSet = try await GoalSet.find(deviceGoalSetId, on: db) else {
                throw ServerSyncError.goalSetNotFound
            }
            newGoalSet = goalSet
        } else {
            newGoalSet = nil
        }

        try serverMeal.update(
            with: deviceMeal,
            newDayId: newDay?.requireID(),
            newGoalSetId: newGoalSet?.requireID()
        )
        try await serverMeal.update(on: db)
    }
    
    func createNewServerMeal(with deviceMeal: PrepDataTypes.Meal, on db: Database) async throws {
        /// If the meal doesn't exist, add it
        guard let day = try await Day.find(deviceMeal.day.id, on: db) else {
            throw ServerSyncError.dayNotFound
        }
        
        let goalSet: GoalSet?
        /// If we were provided a `GoalSet`, make sure that we can fetch it first before creating the `Meal`
        if let goalSetId = deviceMeal.goalSet?.id {
            guard let serverGoalSet = try await GoalSet.find(goalSetId, on: db) else {
                throw ServerSyncError.goalSetNotFound
            }
            goalSet = serverGoalSet
        } else {
            goalSet = nil
        }

        let meal = Meal(
            deviceMeal: deviceMeal,
            dayId: try day.requireID(),
            goalSetId: try goalSet?.requireID()
        )
        try await meal.save(on: db)
    }
}
