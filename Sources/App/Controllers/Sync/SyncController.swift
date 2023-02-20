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

    func performSync(req: Request) async throws -> SyncForm {
        let deviceSyncForm = try req.content.decode(SyncForm.self)

        try await processSyncForm(deviceSyncForm, db: req.db)
        return try await constructSyncForm(for: deviceSyncForm, db: req.db)
    }

    func processSyncForm(_ syncForm: SyncForm, db: Database) async throws {
        if !syncForm.isEmpty {
            print("📱→ Received \(syncForm.description)")
        }

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
            versionTimestamp: timestamp
        )
        if !syncForm.isEmpty {
            print("💧→ Sending \(syncForm.description)")
        } else {
            let message = "💧→ Empty response"
            print(message)
            Logger.log(message)
        }
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

func log(_ message: String) {
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    let filename = getDocumentsDirectory().appendingPathComponent("output.txt")

    do {
        try message.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
        print("Wrote to: \(filename)")
    } catch {
        // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
        print("Could not wrote to: \(filename) – \(error)")
    }
}


class Logger {

    static var logFile: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())
        let fileName = "server_\(dateString).log"
        return documentsDirectory.appendingPathComponent(fileName)
    }

    static func log(_ message: String) {
        guard let logFile = logFile else {
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        let string = timestamp + ": " + message
        guard let data = (string + "\n").data(using: String.Encoding.utf8) else { return }

        do {
            if FileManager.default.fileExists(atPath: logFile.path) {
                let fileHandle = try FileHandle(forWritingTo: logFile)
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            } else {
                try string.write(to: logFile, atomically: true, encoding: String.Encoding.utf8)
//                try data.write(to: logFile, options: .atomicWrite)
            }
            print("Wrote to: \(logFile)")
        } catch {
            print("Could not wrote to: \(logFile) – \(error)")
        }
    }
}
