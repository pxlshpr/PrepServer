import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field("cloud_kit_id", .string)
            .field("created_at", .double, .required)
            .field("updated_at", .double, .required)

            .field("options", .json, .required)
//            .field("biometrics", .json, .required)
            .field("biometrics", .json)

            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
