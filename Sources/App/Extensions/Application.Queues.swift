import Vapor
import Queues

extension Application.Queues {
    func scheduleEvery(_ job: ScheduledJob, minutes: Int) {
        for minuteOffset in stride(from: 0, to: 60, by: minutes) {
            schedule(job).hourly().at(.init(integerLiteral: minuteOffset))
        }
    }
}
