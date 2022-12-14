import Fluent
import Vapor
import PrepDataTypes

final class Barcode: Model, Content {
    static let schema = "barcodes"
    
    @ID(key: .id) var id: UUID?
    @OptionalParent(key: "user_food_id") var userFood: UserFood?
    @OptionalParent(key: "preset_food_id") var presetFood: PresetFood?
    @Field(key: "created_at") var createdAt: Double
    @OptionalField(key: "deleted_at") var deletedAt: Double?

    @Field(key: "payload") var payload: String
    @Field(key: "symbology") var symbology: BarcodeSymbology

    init() { }
    
    init(payload: String, symbology: BarcodeSymbology, userFoodId: UserFood.IDValue?, presetFoodId: PresetFood.IDValue?) {
        self.id = UUID()
        self.payload = payload
        self.symbology = symbology
        self.$userFood.id = userFoodId
        self.$presetFood.id = presetFoodId
        self.createdAt = Date().timeIntervalSince1970
    }
    
    init(foodBarcode: FoodBarcode, userFoodId: UserFood.IDValue? = nil, presetFoodId: PresetFood.IDValue? = nil) {
        self.id = UUID()
        self.payload = foodBarcode.payload
        self.symbology = foodBarcode.symbology
        self.$userFood.id = userFoodId
        self.$presetFood.id = presetFoodId
        self.createdAt = Date().timeIntervalSince1970
    }
    
    init(deviceBarcode: PrepDataTypes.Barcode, userFoodId: UserFood.IDValue) {
        self.id = deviceBarcode.id
        self.payload = deviceBarcode.payload
        self.symbology = deviceBarcode.symbology
        self.$userFood.id = userFoodId
        self.$presetFood.id = nil
        self.createdAt = Date().timeIntervalSince1970
    }
}

//MARK: - Barcode → PrepDataTypes.Barcode

extension PrepDataTypes.Barcode {
    init?(from serverBarcode: Barcode) {
        guard let id = serverBarcode.id else {
            return nil
        }
        self.init(
            id: id,
            payload: serverBarcode.payload,
            symbology: serverBarcode.symbology
        )
    }
}
