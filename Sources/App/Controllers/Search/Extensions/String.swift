import Foundation

extension String {
    
    /// Converts `chicken breast` to `%chicken%breast%`
    var sqlSearchString: String {
        "%\(replacingOccurrences(of: " ", with: "%"))%"
    }

    /// name ILIKE 'chicken breaks'
    var whereClauseForNameMatch: String {
        "name ILIKE '\(self)'"
    }

    func whereClauseForComponents(fields: DetailFields, strictMatch: Bool, joinOperator: JoinOperator) -> String {
        components(separatedBy: " ")
            .map { "\(fields.descriptor) ILIKE '\(!strictMatch ? "%" : "")\($0)\(!strictMatch ? "%" : "")'" }
            .joined(separator: " \(joinOperator.separator) ")
    }

    /**
     CONCAT(name,' ',detail,' ',brand) ILIKE '%chicken%'
     AND CONCAT(name,' ',detail,' ',brand) ILIKE '%breast%'
     AND CONCAT(name,' ',detail,' ',brand) ILIKE '%raw%'
     */
//    func whereClauseFuzzyComponent(joinOperator: JoinOperator) -> String {
//        components(separatedBy: " ")
//        .map { "CONCAT(name,' ',detail,' ',brand) ILIKE '%\($0)%'" }
//        .joined(separator: " \(joinOperator.separator) ")
//    }

//    /**
//     name ILIKE 'chicken'
//     OR name ILIKE 'breast'
//     */
//    func whereClauseForNameComponent(strictMatch: Bool, joinOperator: JoinOperator) -> String {
//        components(separatedBy: " ")
//            .map { "name ILIKE '\(!strictMatch ? "%" : "")\($0)\(!strictMatch ? "%" : "")'" }
//            .joined(separator: " \(joinOperator.separator) ")
//    }
}
