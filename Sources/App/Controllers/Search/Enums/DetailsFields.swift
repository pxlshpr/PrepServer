import Foundation

enum DetailFields {
    case name
    case detail
    case brand
    case nameAndDetail
    case nameAndBrand
    case detailAndBrand
    case all3

    var descriptor: String {
        switch self {
        case .name:
            return "name"
        case .detail:
            return "detail"
        case .brand:
            return "brand"
        case .nameAndDetail:
            return "CONCAT(name,' ',detail)"
        case .nameAndBrand:
            return "CONCAT(name,' ',brand)"
        case .detailAndBrand:
            return "CONCAT(detail,' ',brand)"
        case .all3:
            return "CONCAT(name,' ',detail,' ',brand)"
        }
    }
}
