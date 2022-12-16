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
        
        if let existingFood = try await PresetFood.query(on: req.db)
            .filter(\.$datasetFoodId == form.id)
            .filter(\.$dataset == form.dataset)
            .first()
        {
            existingFood.updateMetadata(with: form.food)
            try await existingFood.update(on: req.db)
            print("Updated: \(form.food.emoji) \(form.food.name)")
        } else {
            let presetFood = PresetFood(food: form.food, dataset: form.dataset, datasetFoodId: form.id)
            try await presetFood.save(on: req.db)
            print("Created: \(form.food.emoji) \(form.food.name)")
        }

        //TODO: Bring back barcodes when we handle existing barcodes first
//        /// Save any barcodes
//        for foodBarcode in form.food.info.barcodes {
//            let barcode = Barcode(
//                foodBarcode: foodBarcode,
//                presetFoodId: try presetFood.requireID()
//            )
//            try await barcode.save(on: req.db)
//        }
        
        return .ok
    }
}

extension PresetFood {
    func updateMetadata(with food: Food) {
        self.name = food.name
        self.emoji = food.emoji
        self.amount = food.info.amount
        self.nutrients = food.info.nutrients
        self.sizes = food.info.sizes
        self.serving = food.info.serving
        self.detail = food.detail
        self.brand = food.brand
        self.density = food.info.density
        
        self.updatedAt = Date().timeIntervalSince1970
    }
}
