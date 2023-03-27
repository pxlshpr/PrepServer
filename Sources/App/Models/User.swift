import Fluent
import Vapor
import PrepDataTypes

final class User: Model, Content {
    static let schema = "users"
    
    @ID(key: .id) var id: UUID?
    @OptionalField(key: "cloud_kit_id") var cloudKitId: String?
    @Field(key: "created_at") var createdAt: Double
    @Field(key: "updated_at") var updatedAt: Double

    @Field(key: "options") var options: UserOptions
//    @Field(key: "biometrics") var biometrics: Biometrics
    @OptionalField(key: "biometrics") var biometrics: Biometrics?

    @Children(for: \.$user) var days: [Day]
    @Children(for: \.$user) var foodUsages: [FoodUsage]
    @Children(for: \.$user) var goalSets: [GoalSet]
    @Children(for: \.$user) var tokenAwards: [TokenAward]
    @Children(for: \.$user) var tokenRedemptions: [TokenRedemption]
    @Children(for: \.$user) var userFoods: [UserFood]
    @Children(for: \.$user) var fastingActivities: [UserFastingActivity]
    
    init() { }
    
    init(
//        cloudKitId: String,
        options: UserOptions = .defaultOptions,
//        biometrics: Biometrics = Biometrics(),
        biometrics: Biometrics? = nil
    ) {
        self.id = UUID()
        self.cloudKitId = cloudKitId
        
        self.options = options
        self.biometrics = biometrics
        
        self.createdAt = Date().timeIntervalSince1970
        self.updatedAt = Date().timeIntervalSince1970
    }
    
    init(deviceUser: PrepDataTypes.User) {
        self.id = deviceUser.id
        self.cloudKitId = deviceUser.cloudKitId
        
        self.options = deviceUser.options
        self.biometrics = deviceUser.biometrics
        
        self.createdAt = deviceUser.updatedAt
        self.updatedAt = deviceUser.updatedAt
    }
}


//MARK: - User → PrepDataTypes.User

extension PrepDataTypes.User {
    init?(from serverUser: User) {
        guard let id = serverUser.id else {
            return nil
        }
        self.init(
            id: id,
            cloudKitId: serverUser.cloudKitId,
            options: serverUser.options,
            biometrics: serverUser.biometrics,
            syncStatus: .synced,
            updatedAt: serverUser.updatedAt
        )
    }
}
