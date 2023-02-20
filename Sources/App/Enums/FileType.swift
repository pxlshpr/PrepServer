import Foundation

enum FileType {
    case image, json, log
    
    var directory: String {
        switch self {
        case .image: return "images"
        case .json: return "jsons"
        case .log: return "logs"
        }
    }
}
