//import Foundation
//
//class Logger {
//
//    static var directoryURL: URL? {
//        let directoryPath = "\(FileManager.default.currentDirectoryPath)/Logs"
//        if !FileManager.default.fileExists(atPath: directoryPath) {
//            do {
//                print("Creating: \(directoryPath)")
//                try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
//            } catch {
//                print("Error creating directory: \(error.localizedDescription)");
//            }
//        }
//
//        return URL(fileURLWithPath: directoryPath)
//    }
//
//    static var logFile: URL? {
//        guard let directoryURL else { return nil }
//
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd"
//        let dateString = formatter.string(from: Date())
//        let fileName = "server_\(dateString).log"
//
//        return directoryURL.appendingPathComponent(fileName)
//    }
//
//    static func log(_ message: String, printToConsole: Bool = false) {
//        if !printToConsole {
//            print(message)
//        }
//
//        guard let logFile else {
//            return
//        }
//
//        let formatter = DateFormatter()
//        formatter.dateFormat = "HH:mm:ss"
//        formatter.timeZone = .init(secondsFromGMT: 5 * 3600)
//        let timestamp = formatter.string(from: Date())
//        let string =  "[\(timestamp)] " + message + "\n"
//        guard let data = string.data(using: String.Encoding.utf8) else { return }
//
//        do {
//            if FileManager.default.fileExists(atPath: logFile.path) {
//                let fileHandle = try FileHandle(forWritingTo: logFile)
//                fileHandle.seekToEndOfFile()
//                fileHandle.write(data)
//                fileHandle.closeFile()
//            } else {
//                try string.write(to: logFile, atomically: true, encoding: String.Encoding.utf8)
//            }
//            print("Wrote to: \(logFile)")
//        } catch {
//            print("Could not write to: \(logFile) – \(error)")
//        }
//    }
//}
