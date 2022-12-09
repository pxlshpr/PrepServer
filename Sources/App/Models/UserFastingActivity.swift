import Fluent
import Vapor
import PrepDataTypes

final class UserFastingActivity: Model, Content {
    static let schema = "user_fasting_activities"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User

    @Field(key: "last_meal_at") var lastMealAt: Double
    @OptionalField(key: "next_meal_at") var nextMealAt: Double?
    @OptionalField(key: "next_meal_name") var nextMealName: String?
    @Field(key: "countdown_type") var countdownType: FastingTimerCountdownType

    @Field(key: "push_token") var pushToken: String
    @Field(key: "last_notification_sent_at") var lastNotificationSentAt: Double

    init() { }
    
    init(
        form: FastingActivityForm,
        userId: User.IDValue
    ) {
        guard let lastMealAt = form.lastMealAt else { return }
        
        self.lastMealAt = lastMealAt
        self.nextMealAt = form.nextMealAt
        self.nextMealName = form.nextMealName
        self.countdownType = form.countdownType
        
        self.lastNotificationSentAt = Date().timeIntervalSince1970
//        self.lastNotificationSentAt = lastMealAt
        self.pushToken = form.pushToken
        
        self.$user.id = userId
    }
}

extension UserFastingActivity {
    func update(with form: FastingActivityForm) {
        guard let lastMealAt = form.lastMealAt else { return }
        
        self.lastMealAt = lastMealAt
        self.nextMealAt = form.nextMealAt
        self.nextMealName = form.nextMealName
        self.countdownType = form.countdownType
        
        self.lastNotificationSentAt = Date().timeIntervalSince1970
        
        /// `pushToken` is assumed to not change for the lifetime of the activity
    }
}

/**
 
 SQL:
 
 ```
 SELECT
     x.id,
     x.last_notification_hour,
     x.hours
 FROM
 (
     SELECT
         *,
         FLOOR(((CAST(EXTRACT(epoch FROM NOW()) AS INT) - last_meal_at) / 3600)) as hours
     FROM user_fasting_timers
 ) AS x
 where x.hours > x.last_notification_hour;
 ```
 
 */
