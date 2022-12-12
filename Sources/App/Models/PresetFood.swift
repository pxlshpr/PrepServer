import Fluent
import Vapor
import PrepDataTypes

final class PresetFood: Model, Content {
    static let schema = "preset_foods"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "created_at") var createdAt: Double
    @Field(key: "updated_at") var updatedAt: Double
    @OptionalField(key: "deleted_at") var deletedAt: Double?

    @Field(key: "name") var name: String
    @Field(key: "emoji") var emoji: String
    @Field(key: "amount") var amount: FoodValue
    @Field(key: "nutrients") var nutrients: FoodNutrients
    @Field(key: "sizes") var sizes: [FoodSize]
    @Field(key: "number_of_times_consumed") var numberOfTimesConsumed: Int32
    @Field(key: "dataset") var dataset: FoodDataset

    @OptionalField(key: "serving") var serving: FoodValue?
    @OptionalField(key: "detail") var detail: String?
    @OptionalField(key: "brand") var brand: String?
    @OptionalField(key: "density") var density: FoodDensity?
    @OptionalField(key: "dataset_food_id") var datasetFoodId: String?
    
    @Children(for: \.$presetFood) var barcodes: [Barcode]
    
    init() { }

    init(food: PrepDataTypes.Food, dataset: FoodDataset, datasetFoodId: String) {
        self.id = food.id
        self.createdAt = food.updatedAt
        self.updatedAt = food.updatedAt
        self.deletedAt = nil

        self.name = food.name
        self.emoji = food.emoji
        self.amount = food.info.amount
        self.nutrients = food.info.nutrients
        self.sizes = food.info.sizes
        self.numberOfTimesConsumed = 0
        self.dataset = dataset

        self.serving = food.info.serving
        self.detail = food.detail
        self.brand = food.brand
        self.density = food.info.density
        self.datasetFoodId = datasetFoodId
    }
}
