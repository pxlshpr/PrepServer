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
        print("Processing form: \(form.food.emoji) \(form.food.name)")
        
        let presetFood = PresetFood(food: form.food, dataset: form.dataset, datasetFoodId: form.id)
        print("Created PresetFood, saving")
        
        try await presetFood.save(on: req.db)

        /// Save any barcodes
        print("Saving Barcodes")
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
