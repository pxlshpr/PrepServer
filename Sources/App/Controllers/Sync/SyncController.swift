import Fluent
import Vapor
import PrepDataTypes

struct SyncController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let sync = routes.grouped("sync")
//        sync.post(use: performSync)
        sync.on(.POST, "", body: .collect(maxSize: "20mb"), use: performSync)
        sync.on(.POST, "image", body: .collect(maxSize: "20mb"), use: saveImage)
        sync.on(.POST, "json", body: .collect(maxSize: "20mb"), use: saveJSON)
        sync.on(.POST, "log", body: .collect(maxSize: "20mb"), use: saveLog)
    }
    
    func saveImage(req: Request) async throws -> String {
        let imageFile = try req.content.decode(FileContent.self)
        saveFile(imageFile, type: .image, to: .repository(.image))
        return ""
    }

    func saveJSON(req: Request) async throws -> String {
        let jsonFile = try req.content.decode(FileContent.self)
        saveFile(jsonFile, type: .json, to: .repository(.json))
        return ""
    }

    func saveLog(req: Request) async throws -> String {
        let logFile = try req.content.decode(FileContent.self)
        saveFile(logFile, type: .log, to: .repository(.log))
        return ""
    }

    func performSync(req: Request) async throws -> SyncForm {
        let requestSyncForm = try req.content.decode(SyncForm.self)

        try await processSyncForm(requestSyncForm, db: req.db)
        let responseSyncForm = try await constructSyncForm(for: requestSyncForm, db: req.db)
        
        /// If either request or response `SyncForm` is not empty, log it
        if !requestSyncForm.isEmpty || !responseSyncForm.isEmpty {
            
//            responseSyncForm.removeRedundantUpdates(from: responseSyncForm)
            requestSyncForm.log(emoji: "📱", isRequest: true, includeBreakdown: !requestSyncForm.isInitialSync)
            responseSyncForm.log(emoji: "💧", isRequest: false, includeBreakdown: !requestSyncForm.isInitialSync)
            PrepDataTypes.Logger.log("************************")
            PrepDataTypes.Logger.log(" ")
            PrepDataTypes.Logger.log(" ")
        }
        
        return responseSyncForm
    }

    func processSyncForm(_ syncForm: SyncForm, db: Database) async throws {
        if let updates = syncForm.updates {
            try await processUpdates(
                updates,
                for: syncForm.userId,
                version: syncForm.versionTimestamp,
                db: db
            )
        }

        if let deletions = syncForm.deletions {
            await processDeletions(deletions, version: syncForm.versionTimestamp)
        }
    }
    
    func constructSyncForm(for syncForm: SyncForm, db: Database) async throws -> SyncForm {
        
        let updates = try await constructUpdates(for: syncForm, db: db)
        let deletions = await constructDeletions(for: syncForm.versionTimestamp)
        let userId = try await userId(for: syncForm, db: db)
        
        /// Only update the timestamp if we're actually sending back information
        let timestamp = (updates.count > 0 || deletions.count > 0)
        ? Date().timeIntervalSince1970
        : syncForm.versionTimestamp
        
        let syncForm = SyncForm(
            updates: updates,
            deletions: deletions,
            userId: userId,
            deviceModelName: "server",
            versionTimestamp: timestamp
        )
        return syncForm
    }
    
    func userId(for syncForm: SyncForm, db: Database) async throws -> UUID {
        
        if let deviceCloudKitId = syncForm.updates?.user?.cloudKitId {
            /// If this syncForm contained a `User` update with a `cloudKitId`—find and return the `User` using that
            ///
            guard
                let user = try await user(forCloudKitId: deviceCloudKitId, db: db),
                let userId = user.id
            else {
                throw ServerSyncError.couldNotGetUserIdForCloudKitId(deviceCloudKitId)
            }
            return userId
        } else {
            
            /// Otherwise, just return the `userId` that was provided
            return syncForm.userId
        }
    }
}


enum ServerSyncError: Error {
    case newCloudKitIdReceivedForUser(String)
    case processUpdatesError(String? = nil)
    case couldNotGetUserIdForCloudKitId(String)

    case foodItemWithoutUserFoodOrPresetFood

    case userNotFound
    case dayNotFound
    case goalSetNotFound
    case foodNotFound    
    case mealNotFound
    case foodItemNotFound
    case userFoodNotFound
    case presetFoodNotFound
    
    case couldNotCreateFood
    case couldNotCreateGoalSet
    case missingId
}

extension SyncForm: Content {
    
}
