import Fluent
import Vapor
import PrepDataTypes

struct CleanupController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let sync = routes.grouped("clean")
        sync.on(.GET, "dev", use: devCleanup)
    }
    
    func devCleanup(req: Request) async throws -> HTTPStatus {
        try await deletFoodItemsInDeletedMeals(on: req.db)
        return .ok
    }
}

extension CleanupController {
    func deletFoodItemsInDeletedMeals(on db: Database) async throws {
        let itemsToDelete = try await FoodItem.query(on: db)
            .join(Meal.self, on: \FoodItem.$meal.$id == \Meal.$id)
            .filter(Meal.self, \.$deletedAt > 0)
            .with(\.$userFood)
            .with(\.$meal)
            .filter(\.$deletedAt == nil)
            .all()
        
        print("Soft deleting \(itemsToDelete.count) food items belonging to deleted meals")
        for item in itemsToDelete {
            guard let meal = item.meal else {
                fatalError("No meal for: \(item.id!)")
            }
            
            item.deletedAt = meal.deletedAt
            try await item.update(on: db)
        }
    }
}
