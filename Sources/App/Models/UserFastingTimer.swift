import Fluent
import Vapor
import PrepDataTypes

final class UserFastingTimer: Model, Content {
    static let schema = "user_fasting_timers"
    
    @ID(custom: "user_id", generatedBy: .user) var id: UUID?

    @Field(key: "last_meal_at") var lastMealAt: Double
    @OptionalField(key: "next_meal_at") var nextMealAt: Double?
    @OptionalField(key: "next_meal_name") var nextMealName: String?
    @OptionalField(key: "last_notification_at") var lastNotificationAt: Double?

    init() { }
}
