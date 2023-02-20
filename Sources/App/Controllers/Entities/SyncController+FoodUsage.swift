import Fluent
import Vapor
import PrepDataTypes

extension SyncController {

    func processUpdatedDeviceFoodUsages(_ deviceFoodUsages: [PrepDataTypes.FoodUsage], on db: Database) async throws {
//        for deviceFoodUsage in deviceFoodUsages {
//            try await processUpdatedDeviceFoodUsage(deviceFoodUsage, on: db)
//        }
    }

//    func processUpdatedDeviceFoodUsage(_ deviceFoodUsage: PrepDataTypes.FoodUsage, on db: Database) async throws {
//        let serverFoodUsage = try await FoodUsage.query(on: db)
//            .filter(\.$id == deviceFoodUsage.id)
//            .with(\.$food)
//            .first()
//
//        if let serverFoodUsage {
//            try await updateServerFoodUsage(serverFoodUsage, with: deviceFoodUsage, on: db)
//        } else {
//            try await createNewServerFoodUsage(with: deviceFoodUsage, on: db)
//        }
//    }
//
//    func updateServerFoodUsage(
//        _ serverFoodUsage: FoodUsage,
//        with deviceFoodUsage: PrepDataTypes.FoodUsage,
//        on db: Database
//    ) async throws {
//
//        let newUserFood: UserFood?
//        let newPresetFood: PresetFood?
//        /// If the `Food` doesn't match (check both `UserFood` and `PresetFood` for a matching `id`)
//        if (deviceFoodItem.food.id != serverFoodItem.userFood?.id
//            || deviceFoodItem.food.id != serverFoodItem.presetFood?.id)
//        {
//            /// Try getting the `UserFood first`
//            guard let foodTuple = try await findFood(with: deviceFoodItem.food.id, on: db) else {
//                throw ServerSyncError.foodNotFound
//            }
//            if let userFood = foodTuple.0 {
//                newUserFood = userFood
//                newPresetFood = nil
//            } else {
//                newUserFood = nil
//                newPresetFood = foodTuple.1
//            }
//        } else {
//            newUserFood = nil
//            newPresetFood = nil
//        }
//
//        let newParentUserFood: UserFood?
//        if let deviceParentFoodId = deviceFoodItem.parentFood?.id,
//           let serverParentFoodId = serverFoodItem.parentUserFood?.id,
//           serverParentFoodId != deviceParentFoodId
//        {
//            /// Find the new parent `UserFood`
//            guard let parentUserFood = try await UserFood.find(deviceParentFoodId, on: db) else {
//                throw ServerSyncError.foodNotFound
//            }
//            newParentUserFood = parentUserFood
//        } else {
//            newParentUserFood = nil
//        }
//
//        let newMeal: Meal?
//        if let deviceMealId = deviceFoodItem.meal?.id,
//           let serverMealId = serverFoodItem.meal?.id,
//           serverMealId != deviceMealId
//        {
//            /// Find the new `Meal`
//            guard let meal = try await Meal.find(deviceMealId, on: db) else {
//                throw ServerSyncError.mealNotFound
//            }
//            newMeal = meal
//        } else {
//            newMeal = nil
//        }
//
//        try serverFoodItem.update(
//            with: deviceFoodItem,
//            newUserFoodId: try newUserFood?.requireID(),
//            newPresetFoodId: try newPresetFood?.requireID(),
//            newParentUserFoodId: try newParentUserFood?.requireID(),
//            newMealId: try newMeal?.requireID()
//        )
//
//        try await serverFoodItem.update(on: db)
//    }
//
//    func createNewServerFoodUsage(with deviceFoodUsage: PrepDataTypes.FoodUsage, on db: Database) async throws {
//        let userFood: UserFood?
//        let presetFood: PresetFood?
//
//        guard let foodTuple = try await findFood(with: deviceFoodUsage.food.id, on: db) else {
//            throw ServerSyncError.foodNotFound
//        }
//        if let serverFood = foodTuple.0 {
//            userFood = serverFood
//            presetFood = nil
//        } else {
//            userFood = nil
//            presetFood = foodTuple.1
//        }
//
//        let foodUsage = FoodUsage(
//            id: deviceFoodUsage.id,
//            numberOfTimesConsumed: deviceFoodUsage.numberOfTimesConsumed,
//            createdAt: deviceFoodUsage.createdAt,
//            updatedAt: deviceFoodUsage.updatedAt,
//            food:
//        )
//
//        let foodItem = FoodItem(
//            deviceFoodItem: deviceFoodItem,
//            userFoodId: try userFood?.requireID(),
//            presetFoodId: try presetFood?.requireID(),
//            parentUserFoodId: try parentUserFood?.requireID(),
//            mealId: try meal?.requireID()
//        )
//        try await foodItem.save(on: db)
//    }
}
