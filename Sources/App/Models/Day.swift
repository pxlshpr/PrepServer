import Fluent
import Vapor
import PrepDataTypes

final class Day: Model, Content {
    static let schema = "days"
    
    @ID(custom: "id", generatedBy: .user) var id: String?
    @Parent(key: "user_id") var user: User
    @OptionalParent(key: "goal_set_id") var goalSet: GoalSet?
    @Field(key: "created_at") var createdAt: Double
    @Field(key: "updated_at") var updatedAt: Double

    @Field(key: "calendar_day_string") var calendarDayString: String
    @Field(key: "marked_as_fasted") var markedAsFasted: Bool

    @OptionalField(key: "biometrics") var biometrics: Biometrics?

    @Children(for: \.$day) var meals: [Meal]

    init() { }
    
    init(
        deviceDay: PrepDataTypes.Day,
        userId: User.IDValue,
        goalSetId: GoalSet.IDValue?
    ) {
        self.id = deviceDay.id
        self.$user.id = userId
        self.$goalSet.id = goalSetId
        
        let timestamp = Date().timeIntervalSince1970
        self.createdAt = timestamp
        self.updatedAt = timestamp

        self.calendarDayString = deviceDay.calendarDayString
        self.biometrics = deviceDay.biometrics
        self.markedAsFasted = deviceDay.markedAsFasted
    }
}

extension Day {
    func update(with deviceDay: PrepDataTypes.Day, newGoalSetId: GoalSet.IDValue?) throws {
        self.$goalSet.id = newGoalSetId
        self.biometrics = deviceDay.biometrics
        self.markedAsFasted = deviceDay.markedAsFasted
        self.updatedAt = Date().timeIntervalSince1970
    }
}


//MARK: - Day → PrepDataTypes.Day

extension PrepDataTypes.Day {
    init?(from serverDay: Day) {
        guard let id = serverDay.id else {
            return nil
        }
        
        let goalSet: PrepDataTypes.GoalSet?
        if let serverGoalSet = serverDay.goalSet,
           let deviceGoalSet = PrepDataTypes.GoalSet(from: serverGoalSet) {
            goalSet = deviceGoalSet
        } else {
            goalSet = nil
        }
        
        //TODO: Check that biometrics is being handled properly
        self.init(
            id: id,
            calendarDayString: serverDay.calendarDayString,
            goalSet: goalSet,
            biometrics: serverDay.biometrics,
            markedAsFasted: serverDay.markedAsFasted,
            meals: [],
            syncStatus: .synced,
            updatedAt: serverDay.updatedAt
        )
    }
}
