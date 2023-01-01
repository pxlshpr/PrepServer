import Fluent
import Vapor
import PrepDataTypes

struct UtilitiesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let sync = routes.grouped("utilities")
        sync.on(.GET, "deleteFoodItemsInDeletedMeals", use: deleteFoodItemsInDeletedMeals)
        sync.on(.GET, "setMissingLastUsedAtTimestamps", use: setMissingLastUsedAtTimestamps)
    }
}

extension UtilitiesController {
    func setMissingLastUsedAtTimestamps(req: Request) async throws -> HTTPStatus {
        print("We here")
        // Go through all Food's that don't has a lastUsedAt
        return .ok
    }
}
extension UtilitiesController {
    
    func deleteFoodItemsInDeletedMeals(req: Request) async throws -> HTTPStatus{
        let itemsToDelete = try await FoodItem.query(on: req.db)
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
            try await item.update(on: req.db)
        }
        return .ok
    }
    
}
