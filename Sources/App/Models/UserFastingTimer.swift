import Fluent
import Vapor
import PrepDataTypes

final class UserFastingTimer: Model, Content {
    static let schema = "user_fasting_timers"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User

    @Field(key: "last_meal_at") var lastMealAt: Double
    @OptionalField(key: "next_meal_at") var nextMealAt: Double?
    @OptionalField(key: "next_meal_name") var nextMealName: String?

    @Field(key: "last_notification_hour") var lastNotificationHour: Int

    init() { }
    
    init(
        form: FastingTimerForm,
        userId: User.IDValue
    ) {
        guard let lastMealAt = form.lastMealAt else { return }
        
        self.lastMealAt = lastMealAt
        self.nextMealAt = form.nextMealAt
        self.nextMealName = form.nextMealName
        self.lastNotificationHour = 0
        
        self.$user.id = userId
    }
}

extension UserFastingTimer {
    func update(with form: FastingTimerForm) {
        guard let lastMealAt = form.lastMealAt else { return }
        self.lastMealAt = lastMealAt
        self.nextMealAt = form.nextMealAt
        self.nextMealName = form.nextMealName
    }
}
