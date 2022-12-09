import Fluent

struct CreateUserFastingActivity: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        try await database.schema("user_fasting_activities")
            .id()
            .field("user_id", .uuid, .references(User.schema, .id), .required)
            .field("last_meal_at", .double, .required)
            .field("next_meal_at", .double)
            .field("next_meal_name", .string)
            .field("countdown_type", .int16, .required)
        
            .field("push_token", .string, .required)
            .field("last_notification_sent_at", .double, .required)

            .unique(on: "user_id")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("user_fasting_activities").delete()
    }
}
