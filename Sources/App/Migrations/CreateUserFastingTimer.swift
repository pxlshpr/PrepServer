import Fluent

struct CreateUserFastingTimer: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("user_fasting_timers")
            .id()
            .field("user_id", .uuid, .references(User.schema, .id), .required)
            .field("last_meal_at", .double, .required)
            .field("next_meal_at", .double)
            .field("next_meal_name", .string)
            .field("last_notification_hour", .int, .required)

            .unique(on: "user_id")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("user_fasting_timers").delete()
    }
}
