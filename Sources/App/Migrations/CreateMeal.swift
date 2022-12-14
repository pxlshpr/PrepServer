import Fluent

struct CreateMeal: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("meals")
            .id()
            .field("day_id", .string, .references(Day.schema, .id), .required)
            .field("goal_set_id", .uuid, .references(GoalSet.schema, .id))
            .field("created_at", .double, .required)
            .field("updated_at", .double, .required)
            .field("deleted_at", .double)

            .field("name", .string, .required)
            .field("time", .double, .required)
            .field("marked_as_eaten_at", .double)
            .field("goal_workout_minutes", .int)

            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("meals").delete()
    }
}
