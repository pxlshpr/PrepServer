import Foundation

import Vapor
import Foundation
import Queues

struct Email: Codable {
    let to: String
    let message: String
}

struct EmailJob: AsyncScheduledJob {
    // Add extra services here via dependency injection, if you need them.
    
    func run(context: QueueContext) async throws {
        // Do some work here, perhaps queue up another job.
        print("in email job")
    }
}

//struct EmailJob: AsyncJob {
//    typealias Payload = Email
//
//    func dequeue(_ context: QueueContext, _ payload: Email) async throws {
//        print("This is where you would send the email")
//    }
//
//    func error(_ context: QueueContext, _ error: Error, _ payload: Email) async throws {
//        // If you don't want to handle errors you can simply return. You can also omit this function entirely.
//    }
//}

extension Application.Queues {
    func scheduleEvery(_ job: ScheduledJob, minutes: Int) {
        for minuteOffset in stride(from: 0, to: 60, by: minutes) {
            schedule(job).hourly().at(.init(integerLiteral: minuteOffset))
        }
    }
}
