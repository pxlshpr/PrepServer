import Fluent
import Vapor
import PrepDataTypes

struct PresetFoodController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("presetFoods")
        group.post(use: create)
    }
    
    func create(req: Request) async throws -> HTTPStatus {
        let form = try req.content.decode(PresetFoodForm.self)
        
        let presetFood = PresetFood(food: form.food, dataset: form.dataset, datasetFoodId: form.id)
        try await presetFood.save(on: req.db)

        /// Save any barcodes
        for foodBarcode in form.food.info.barcodes {
            let barcode = Barcode(
                foodBarcode: foodBarcode,
                presetFoodId: try presetFood.requireID()
            )
            try await barcode.save(on: req.db)
        }
        
        print("Created: \(form.food.emoji) \(form.food.name)")
        return .ok
    }
}
