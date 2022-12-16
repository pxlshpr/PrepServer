import Fluent
import Vapor
import PrepDataTypes

func queries(string: String, db: Database) -> [(String, QueryBuilder<PresetFood>)] {
    [
        ("Name Match", queryNameMatch(string: string, db: db)),
        ("Name Component Match (All Components)", queryComponents(on: .name, string: string, db: db, strictMatch: true, joinOperator: .and)),
        ("Name Component Contains (All Components)", queryComponents(on: .name, string: string, db: db, strictMatch: false, joinOperator: .and)),

        ("Name and Detail Component Match (All Components)", queryComponents(on: .nameAndDetail, string: string, db: db, strictMatch: true, joinOperator: .and)),
        ("Name and Detail Component Contains (All Components)", queryComponents(on: .nameAndDetail, string: string, db: db, strictMatch: false, joinOperator: .and)),

        ("Name Component Match (Any Component)", queryComponents(on: .name, string: string, db: db, strictMatch: true, joinOperator: .or)),
        ("Name Component Contains (Any Component)", queryComponents(on: .name, string: string, db: db, strictMatch: false, joinOperator: .or)),
        ("Fuzzy Contains (All Components)", fuzzyComponentContains(string: string, db: db, joinOperator: .and)),
        ("Fuzzy Contains (Any Component)", fuzzyComponentContains(string: string, db: db, joinOperator: .or)),
    ]
}


func queryComponents(on fields: DetailFields, string: String, db: Database, strictMatch: Bool, joinOperator: JoinOperator) -> QueryBuilder<PresetFood> {
    PresetFood.query(on: db)
        .filter(.sql(raw: string.whereClauseForComponents(fields: fields, strictMatch: strictMatch, joinOperator: joinOperator)))
        .sort(.sql(raw: "CHAR_LENGTH(CONCAT(name,' ',detail,' ',brand))-CHAR_LENGTH('\(string)')"))
}

func queryNameMatch(string: String, db: Database) -> QueryBuilder<PresetFood> {
    PresetFood.query(on: db)
        .filter(.sql(raw: string.whereClauseForNameMatch))
        .sort(.sql(raw: "CHAR_LENGTH(CONCAT(name,' ',detail,' ',brand))-CHAR_LENGTH('\(string)')"))
}

/**
 SELECT name, detail FROM foods
 WHERE CONCAT(name,' ',detail,' ',brand) ILIKE '%chicken%'
     AND CONCAT(name,' ',detail,' ',brand) ILIKE '%breast%'
     AND CONCAT(name,' ',detail,' ',brand) ILIKE '%raw%'
 ORDER BY CHAR_LENGTH(CONCAT(name,' ',detail))-CHAR_LENGTH('chicken breast raw');
 */
func fuzzyComponentContains(string: String, db: Database, joinOperator: JoinOperator) -> QueryBuilder<PresetFood> {
    PresetFood.query(on: db)
        .filter(.sql(raw: string.whereClauseForComponents(fields: .all3, strictMatch: false, joinOperator: joinOperator)))
        .sort(.sql(raw: "CHAR_LENGTH(CONCAT(name,' ',detail,' ',brand))-CHAR_LENGTH('\(string)')"))
}

//
//func queryNamePrefix(string: String, db: Database) -> QueryBuilder<PresetFood> {
//    PresetFood.query(on: db)
//        .filter(\.$name, .custom("ILIKE"), "\(string.sqlSearchString)")
//}
//
//func queryDetailPrefix(string: String, db: Database) -> QueryBuilder<PresetFood> {
//    PresetFood.query(on: db)
//        .filter(\.$detail, .custom("ILIKE"), "\(string.sqlSearchString)")
//}
//
//func queryBrandPrefix(string: String, db: Database) -> QueryBuilder<PresetFood> {
//    PresetFood.query(on: db)
//        .filter(\.$brand, .custom("ILIKE"), "\(string.sqlSearchString)")
//}

//func queryNameWithDetailPrefix(string: String, db: Database) -> QueryBuilder<PresetFood> {
//    PresetFood.query(on: db)
//        .filter(.sql(raw: "CONCAT(name,' ',detail) ILIKE '\(string.sqlSearchString)'"))
//}
