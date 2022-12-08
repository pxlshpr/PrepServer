import Fluent
import FluentPostgresDriver
import Vapor
import QueuesRedisDriver

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "pxlshpr",
        password: Environment.get("DATABASE_PASSWORD") ?? "Ch1ll0ut",
        database: Environment.get("DATABASE_NAME") ?? "prep"
    ), as: .psql)

    app.migrations.add(CreatePresetFood())
    app.migrations.add(CreateUser())
    
    /// prerequisite: User
    app.migrations.add(CreateGoalSet())
    
    /// prerequisite: User, PresetFood
    app.migrations.add(CreateUserFood())
    
    /// prerequisite: UserFood, PresetFood
    app.migrations.add(CreateBarcode())
    
    /// prerequisite: User, UserFood
    app.migrations.add(CreateTokenAward())
    
    /// prerequisite: User
    app.migrations.add(CreateTokenRedemption())
    
    /// prerequisite: User, Goal
    app.migrations.add(CreateDay())
    
    /// prerequisite: Day
    app.migrations.add(CreateMeal())

    /// prerequisite: UserFood, PresetFood, Meal
    app.migrations.add(CreateFoodItem())
    
    /// prerequisite: User, UserFood, PresetFood
    app.migrations.add(CreateFoodUsage())
    
    /// prerequisite: Meal
    app.migrations.add(CreateQuickMealItem())
    
    /// prerequisite: User
    app.migrations.add(CreateUserFastingTimer())
    
    app.http.server.configuration.port = 8083

    /// register routes
    try routes(app)
    
    /// Start Job Queue for
    try app.queues.use(.redis(url: "redis://127.0.0.1:6379"))
    app.queues.scheduleEvery(FastingTimerUpdateJob(), minutes: 1)
    
    try app.configurePush()
}

import APNS

extension Application {
    func configurePush() throws {
      let appleECP8PrivateKey =
"""
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgk8rTF7VIFsGuwr+l
zDhS+w46Wty+SL6rLyd+5+gjW+KgCgYIKoZIzj0DAQehRANCAAQVaxb/VQpMafZe
e0BWOKHudL5XM0V6apAfvcFSUSPp/IAai/xsW1lA5sxz39zlXm4ZAu0Ju3YPL5W1
uZF1zf2z
-----END PRIVATE KEY-----
"""
        let authenticationMethod = APNSClientConfiguration.AuthenticationMethod.jwt(
            privateKey: try .loadFrom(string: appleECP8PrivateKey),
            keyIdentifier: "Y8QK4K56CK",
            teamIdentifier: "3EQ4PU3P2V"
        )
        
        let config = APNSClientConfiguration(
            authenticationMethod: authenticationMethod,
            environment: .sandbox
        )
        apns.containers.use(
            config,
            eventLoopGroupProvider: .createNew,
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            backgroundActivityLogger: logger,
            as: .default
        )
        
//        apns.configuration = try .init(
//            authenticationMethod: .jwt(
//                key: .private(pem: Data(appleECP8PrivateKey.utf8)),
//                keyIdentifier: "Y8QK4K56CK",
//                teamIdentifier: "3EQ4PU3P2V"
//            ),
//            topic: "com.pxlshpr.Prep",
//            environment: .production
//        )
    }
}
