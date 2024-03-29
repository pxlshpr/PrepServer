import Fluent
import Vapor
import PrepDataTypes

extension SyncController {

    /// Populate with all entities that have `server.updatedAt > device.versionTimestamp` (this will include new entities too)
    func constructUpdates(for syncForm: SyncForm, db: Database) async throws -> SyncForm.Updates {
        let days = try await updatedDays(for: syncForm, db: db)
        let meals = try await updatedMeals(for: syncForm, db: db)
        let foodItems = try await updatedFoodItems(for: syncForm, db: db)
        let foods = try await updatedFoods(for: syncForm, using: foodItems, db: db)
        let goalSets = try await updatedGoalSets(for: syncForm, db: db)
        let fastingActivities = try await updatedFastingActivities(for: syncForm, db: db)
        
        let user = try await updatedDeviceUser(for: syncForm, db: db)
        return SyncForm.Updates(
            user: user,
            days: days,
            foods: foods,
            foodItems: foodItems,
            goalSets: goalSets,
            meals: meals,
            fastingActivities: fastingActivities
        )
    }
    
    func userId(from syncForm: SyncForm, db: Database) async throws -> UUID {
        /// If we have a `cloudKitId`, use that in case the user just started using a new device
        let userId: UUID
        if let deviceUser = syncForm.updates?.user,
           let serverUser = try await user(forDeviceUser: deviceUser, db: db),
           let id = serverUser.id
        {
            userId = id
        } else {
            userId = syncForm.userId
        }
        return userId
    }

    func updatedFoods(for syncForm: SyncForm, using updatedFoodItems: [PrepDataTypes.FoodItem]?, db: Database) async throws -> [PrepDataTypes.Food]? {
        let userFoods = try await updatedUserFoods(for: syncForm, db: db) ?? []
        let presetFoods = try await updatedPresetFoods(for: syncForm, db: db) ?? []
        
        var foods = userFoods + presetFoods
        
        if let updatedFoodItems {
            /// If we have updated food items—get any `PresetFood`'s that aren't already in `foods` and
            /// send them across in case the device hasn't got them cached
            for foodItem in updatedFoodItems {
                guard foodItem.food.dataset != nil,
                      !foods.contains(where: { $0.id == foodItem.food.id})
                else { continue }
                foods.append(foodItem.food)
            }
        }
        
        return foods
    }
    
    func updatedUserFoods(for syncForm: SyncForm, db: Database) async throws -> [PrepDataTypes.Food]? {
        let userId = try await userId(from: syncForm, db: db)
        return try await UserFood.query(on: db)
            .filter(\.$user.$id == userId)
            .filter(\.$updatedAt > syncForm.versionTimestamp)
            .with(\.$barcodes)
            .all()
            .compactMap { userFood in
                PrepDataTypes.Food(from: userFood)
            }
    }
    
    /// Gets any updated `PresetFood`s that are relevant to keep locally. These include `FoodItem`s that either
    /// - belong to a `Meal` on a `Day` owned by the `User`, or
    /// - has a parent `UserFood` owned by the `User`
    func updatedPresetFoods(for syncForm: SyncForm, db: Database) async throws -> [PrepDataTypes.Food]? {
        let userId = try await userId(from: syncForm, db: db)
        let presetFoodsAsMealsItems = try await PresetFood.query(on: db)
            .join(FoodItem.self, on: \FoodItem.$presetFood.$id == \PresetFood.$id)
            .join(Meal.self, on: \FoodItem.$meal.$id == \Meal.$id)
            .join(Day.self, on: \Meal.$day.$id == \Day.$id)
            .filter(Day.self, \.$user.$id == userId)
            .filter(\.$updatedAt > syncForm.versionTimestamp)
            .with(\.$barcodes)
            .all()

        let presetFoodsAsChildFoods = try await PresetFood.query(on: db)
            .join(FoodItem.self, on: \FoodItem.$presetFood.$id == \PresetFood.$id)
            .join(UserFood.self, on: \FoodItem.$parentUserFood.$id == \UserFood.$id)
            .filter(UserFood.self, \.$user.$id == userId)
            .filter(\.$updatedAt > syncForm.versionTimestamp)
            .with(\.$barcodes)
            .all()
        let presetFoods = presetFoodsAsMealsItems + presetFoodsAsChildFoods
        return presetFoods
            .compactMap { userFood in
                PrepDataTypes.Food(from: userFood)
            }
    }
    
    func updatedDays(for syncForm: SyncForm, db: Database) async throws -> [PrepDataTypes.Day]? {
        
//        guard !syncForm.requestedCalendarDayStrings.isEmpty else { return [] }
        let userId = try await userId(from: syncForm, db: db)
        
        let query: QueryBuilder<Day>
        if syncForm.versionTimestamp > 0 {
            query = Day.query(on: db)
//                .filter(\.$calendarDayString ~~ syncForm.requestedCalendarDayStrings)
        } else {
            /// Get *all* the `Day`s when syncing a brand new app install (version is 0)
            query = Day.query(on: db)
        }
        
        return try await query
            .filter(\.$user.$id == userId)
            .filter(\.$updatedAt > syncForm.versionTimestamp)
            .with(\.$goalSet)
            .all()
            .compactMap { day in
                PrepDataTypes.Day(from: day)
            }
    }

    func updatedMeals(for syncForm: SyncForm, db: Database) async throws -> [PrepDataTypes.Meal]? {
        let userId = try await userId(from: syncForm, db: db)
        
        let query: QueryBuilder<Meal>
        if syncForm.versionTimestamp > 0 {
            query = Meal.query(on: db)
                .join(Day.self, on: \Meal.$day.$id == \Day.$id)
                .filter(Day.self, \.$user.$id == userId)
//                .filter(Day.self, \.$calendarDayString ~~ syncForm.requestedCalendarDayStrings)
        } else {
            /// Get *all* the `Meal`s when syncing a brand new app install (version is 0)
            query = Meal.query(on: db)
                .join(Day.self, on: \Meal.$day.$id == \Day.$id)
                .filter(Day.self, \.$user.$id == userId)
        }

        return try await query
            .filter(\.$updatedAt > syncForm.versionTimestamp)
            .with(\.$day)
            .with(\.$goalSet)
            .all()
            .compactMap { meal in
                PrepDataTypes.Meal(from: meal)
            }
    }
    
    func updatedGoalSets(for syncForm: SyncForm, db: Database) async throws -> [PrepDataTypes.GoalSet]? {
        let userId = try await userId(from: syncForm, db: db)
        return try await GoalSet.query(on: db)
            .filter(\.$user.$id == userId)
            .filter(\.$updatedAt > syncForm.versionTimestamp)
            .all()
            .compactMap { goalSet in
                PrepDataTypes.GoalSet(from: goalSet)
            }
    }

    func updatedFastingActivities(for syncForm: SyncForm, db: Database) async throws -> [PrepDataTypes.FastingActivity]? {
        let userId = try await userId(from: syncForm, db: db)
        return try await UserFastingActivity.query(on: db)
            .filter(\.$user.$id == userId)
            .filter(\.$updatedAt > syncForm.versionTimestamp)
            .all()
            .compactMap { fastingActivity in
                PrepDataTypes.FastingActivity(from: fastingActivity)
            }
    }

    func updatedFoodItems(for syncForm: SyncForm, db: Database) async throws -> [PrepDataTypes.FoodItem]? {
        /// Similar to meals, get all the food items that have an attached meal within the requested date window
        /// Otherwise, if it has a parent food, return all of them irrespective of time
        /// So we need to create two separate queries here, and merge the results into one array

        let userId = try await userId(from: syncForm, db: db)
        
        let query: QueryBuilder<FoodItem>
        if syncForm.versionTimestamp > 0 {
            query = FoodItem.query(on: db)
                .join(Meal.self, on: \FoodItem.$meal.$id == \Meal.$id)
                .join(Day.self, on: \Meal.$day.$id == \Day.$id)
                .filter(Day.self, \.$user.$id == userId)
//                .filter(Day.self, \.$calendarDayString ~~ syncForm.requestedCalendarDayStrings)
        } else {
            /// Get *all* the `Meal`s when syncing a brand new app install (version is 0)
            query = FoodItem.query(on: db)
                .join(Meal.self, on: \FoodItem.$meal.$id == \Meal.$id)
                .join(Day.self, on: \Meal.$day.$id == \Day.$id)
                .filter(Day.self, \.$user.$id == userId)
        }
        
        let mealFoodItems = try await query
            .filter(\.$updatedAt > syncForm.versionTimestamp)
            .with(\.$meal) { meal in
                meal
                    .with(\.$day)
                    .with(\.$goalSet)
            }
            .with(\.$userFood) { userFood in
                userFood.with(\.$barcodes)
            }
            .with(\.$presetFood) { presetFood in
                presetFood.with(\.$barcodes)
            }
            .all()
            .compactMap { foodItem in
                PrepDataTypes.FoodItem(from: foodItem, db: db)
            }
        
        let childFoodItems = try await FoodItem.query(on: db)
            .join(UserFood.self, on: \FoodItem.$parentUserFood.$id == \UserFood.$id)
            .filter(UserFood.self, \.$user.$id == userId)
            .filter(\.$updatedAt > syncForm.versionTimestamp)
            .with(\.$parentUserFood) { parentUserFood in
                parentUserFood.with(\.$barcodes)
            }
            .with(\.$userFood) { userFood in
                userFood.with(\.$barcodes)
            }
            .with(\.$presetFood) { presetFood in
                presetFood.with(\.$barcodes)
            }
            .all()
            .compactMap { foodItem in
                
                PrepDataTypes.FoodItem(from: foodItem, db: db)
            }
        return mealFoodItems + childFoodItems
    }
    
    func updatedDeviceUser(for syncForm: SyncForm, db: Database) async throws -> PrepDataTypes.User? {
        
        let serverUser: App.User?
        if let deviceUser = syncForm.updates?.user {
            /// if we were provided with an updated user try and fetch it using that, as we may have a different `cloudKitId` being used on a new device (which will get subsequently updated)
            guard let user = try await user(forDeviceUser: deviceUser, db: db) else {
                return nil
            }
            serverUser = user
        } else {
            /// otherwise, grab the user from the provided user id in the sync form and return it if the `updatedAt` flag is later than the `versionTimestamp`
            guard let user = try await User.find(syncForm.userId, on: db) else {
                return nil
            }
            guard user.updatedAt > syncForm.versionTimestamp else {
                return nil
            }
            serverUser = user
        }
        
        guard let serverUser else { return nil }
        
        return PrepDataTypes.User(from: serverUser)
    }
}

