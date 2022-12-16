import Fluent
import Vapor
import CoreFoundation
import PrepDataTypes

extension PresetFoodController {
    func search(req: Request) async throws -> Page<FoodSearchResult> {
        let params = try req.content.decode(ServerFoodSearchParams.self)
        return try await SearchCoordinator(params: params, db: req.db).search2()
    }
}

extension ServerFoodSearchParams: Content { }
extension FoodSearchResult: Content { }

extension Array where Element == FoodSearchResult {
    var ids: [UUID] {
        map { $0.id }
    }
}

struct ServerFoodSearchParams {
    let string: String
    let page: Int
    let per: Int
}

extension ServerFoodSearchParams {
    var startIndex: Int {
        (page-1) * per
    }
    
    var endIndex: Int {
        (page * per) - 1
    }
}

extension FoodSearchResult {
    init(_ presetFood: PresetFood) {
        self.init(
            id: presetFood.id!,
            name: presetFood.name,
            emoji: presetFood.emoji,
            detail: presetFood.detail,
            brand: presetFood.brand,
            carb: presetFood.nutrients.carb,
            fat: presetFood.nutrients.fat,
            protein: presetFood.nutrients.protein
        )
    }
}
