import Fluent
import Vapor
import CoreFoundation
import PrepDataTypes

class SearchCoordinator {
    let params: ServerFoodSearchParams
    let db: Database

    var position: Int
    
    init(params: ServerFoodSearchParams, db: Database) {
        self.params = params
        self.db = db
        
        self.position = params.startIndex
    }
    
    func searchFull() async throws -> Page<PresetFood> {
        
        var idsToIgnore: [UUID] = []
        var candidateResults: [PresetFood] = []
        var totalCount = 0
        
        let mainStart = CFAbsoluteTimeGetCurrent()
        for (name, query) in queries(string: params.string, db: db) {
            let provider = SearchResultsProvider(name: name, params: params, db: db, query: query)

            let start = CFAbsoluteTimeGetCurrent()
            
            let results = try await provider.resultsFull(
                startingFrom: position,
                totalCount: totalCount,
                previousResults: candidateResults,
                idsToIgnore: idsToIgnore
            )
            print ("  ⏱ results took \(CFAbsoluteTimeGetCurrent()-start)s")
            candidateResults += results.picked
            totalCount += results.count
            idsToIgnore += results.allIds
            position += results.picked.count
            
            /// If we have enough, stop getting the results (we're still getting the total count though)
            guard position < params.endIndex else {
                print("✅ Have enough results, ending early (\(CFAbsoluteTimeGetCurrent()-mainStart)s)")
                print(" ")
                break
            }
        }
        let metadata = PageMetadata(page: params.page, per: params.per, total: 1000000)
        return Page(items: candidateResults, metadata: metadata)
    }

    func search() async throws -> Page<FoodSearchResult> {
        let results = try await searchFull()
        
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return Page(
            items: results.items.map { FoodSearchResult($0) },
            metadata: results.metadata
        )
    }
    
    func search_() async throws -> Page<FoodSearchResult> {
        
        var idsToIgnore: [UUID] = []
        var candidateResults: [FoodSearchResult] = []
        var totalCount = 0
        
        let mainStart = CFAbsoluteTimeGetCurrent()
        for (name, query) in queries(string: params.string, db: db) {
            let provider = SearchResultsProvider(name: name, params: params, db: db, query: query)

            let start = CFAbsoluteTimeGetCurrent()
            
            let results = try await provider.results(
                startingFrom: position,
                totalCount: totalCount,
                previousResults: candidateResults,
                idsToIgnore: idsToIgnore
            )
            print ("  ⏱ results took \(CFAbsoluteTimeGetCurrent()-start)s")
            candidateResults += results.picked
            totalCount += results.count
            idsToIgnore += results.allIds
            position += results.picked.count
            
            /// If we have enough, stop getting the results (we're still getting the total count though)
            guard position < params.endIndex else {
                print("✅ Have enough results, ending early (\(CFAbsoluteTimeGetCurrent()-mainStart)s)")
                print(" ")
                break
            }
        }
        let metadata = PageMetadata(page: params.page, per: params.per, total: 1000000)
        return Page(items: candidateResults, metadata: metadata)
    }
}

extension SearchCoordinator {
    func search_legacy() async throws -> Page<FoodSearchResult> {

        var idsToIgnore: [UUID] = []
        var candidateResults: [FoodSearchResult] = []
        var totalCount = 0

        for (name, query) in queries(string: params.string, db: db) {
            let provider = SearchResultsProvider(name: name, params: params, db: db, query: query)
            let count = try await provider.count(idsToIgnore: idsToIgnore)
            let previousTotalCount = totalCount
            totalCount += count

            print("🔎 \(name) has \(count) matches")
            /// If we have enough, stop getting the results (we're still getting the total count though)
            guard position < params.endIndex else { continue }

            let preFetchedIdsToIgnore = try await provider.allResultIds(ignoring: [])

            let results = try await provider.results_legacy(startingFrom: position, totalCount: previousTotalCount, previousResults: candidateResults, idsToIgnore: idsToIgnore)
            candidateResults += results

            idsToIgnore += preFetchedIdsToIgnore
            print("✨ idsToIgnore: \(idsToIgnore.count)")

            position += results.count
        }
        let metadata = PageMetadata(page: params.page, per: params.per, total: totalCount)
        return Page(items: candidateResults, metadata: metadata)
    }
}
