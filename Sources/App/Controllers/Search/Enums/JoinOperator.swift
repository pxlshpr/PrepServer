import Foundation

enum JoinOperator {
    case and, or
    var separator: String {
        switch self {
        case .and:
            return " AND "
        case .or:
            return " OR "
        }
    }
}
