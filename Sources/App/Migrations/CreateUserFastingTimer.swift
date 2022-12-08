import Fluent

struct CreateUserFastingTimer: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("user_fasting_timers")
            .field("user_id", .uuid)
            .field("last_meal_at", .double, .required)
            .field("next_meal_at", .double)
            .field("next_meal_name", .string)
            .field("last_notification_at", .double)

            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("user_fasting_timers").delete()
    }
}
