import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: SyncController())
    
    try app.register(collection: FastingActivityController())
    
    app.get("backup") { req in
        try shell("./backup.sh")
        return HTTPStatus.ok
    }
}
