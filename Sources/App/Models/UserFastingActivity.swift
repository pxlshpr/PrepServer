import Fluent
import Vapor
import PrepDataTypes

final class UserFastingActivity: Model, Content {
    static let schema = "user_fasting_activities"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User
    @Field(key: "created_at") var createdAt: Double
    @Field(key: "updated_at") var updatedAt: Double
    @OptionalField(key: "deleted_at") var deletedAt: Double?

    @Field(key: "last_meal_at") var lastMealAt: Double
    @OptionalField(key: "next_meal_at") var nextMealAt: Double?
    @OptionalField(key: "next_meal_name") var nextMealName: String?
    @Field(key: "countdown_type") var countdownType: FastingTimerCountdownType

    @Field(key: "push_token") var pushToken: String
    @Field(key: "last_notification_sent_at") var lastNotificationSentAt: Double

    init() { }
    
    init(
        with deviceFastingActivity: PrepDataTypes.FastingActivity,
        userId: User.IDValue
    ) {
        self.id = deviceFastingActivity.id
        self.$user.id = userId
        self.pushToken = deviceFastingActivity.pushToken

        self.lastMealAt = deviceFastingActivity.lastMealAt
        self.nextMealAt = deviceFastingActivity.nextMealAt
        self.nextMealName = deviceFastingActivity.nextMealName
        self.countdownType = deviceFastingActivity.countdownType
        
        let timestamp = Date().timeIntervalSince1970
        self.lastNotificationSentAt = Date().timeIntervalSince1970
        self.createdAt = timestamp
        self.updatedAt = timestamp
        
        if deviceFastingActivity.isDeleted {
            self.deletedAt = timestamp
        } else {
            self.deletedAt = nil
        }
    }
}

extension UserFastingActivity {
    
        func update(with deviceFastingActivity: PrepDataTypes.FastingActivity) {
            
            /// `pushToken` never changes

            self.lastMealAt = deviceFastingActivity.lastMealAt
            self.nextMealAt = deviceFastingActivity.nextMealAt
            self.nextMealName = deviceFastingActivity.nextMealName
            self.countdownType = deviceFastingActivity.countdownType

            let timestamp = Date().timeIntervalSince1970
            self.lastNotificationSentAt = timestamp

        if deviceFastingActivity.isDeleted {
            self.deletedAt = timestamp
        } else {
            self.deletedAt = nil
        }
        self.updatedAt = timestamp

    }
}

//MARK: - UserFastingActivity → PrepDataTypes.FastingActivity

extension PrepDataTypes.FastingActivity {
    init?(from serverFastingActivity: UserFastingActivity) {
        guard let id = serverFastingActivity.id else {
            return nil
        }
        self.init(
            id: id,
            pushToken: serverFastingActivity.pushToken,
            lastMealAt: serverFastingActivity.lastMealAt,
            nextMealAt: serverFastingActivity.nextMealAt,
            nextMealName: serverFastingActivity.nextMealName,
            countdownType: serverFastingActivity.countdownType,
            syncStatus: .synced,
            updatedAt: serverFastingActivity.updatedAt,
            deletedAt: serverFastingActivity.deletedAt
        )
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
