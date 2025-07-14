
import SwiftData
import SwiftUI

@Model
class Pomodoro {
    @Attribute(.unique) var id: UUID = UUID()
    var task: Task?
    var startDate: Date
    var endDate: Date?
    var status = PomodoroStatus.finished
    var estimatedMinutes: Int
    var finishedMinutes: Int?

    init(task: Task?, startDate: Date = Date(), estimatedMinutes: Int = 25) {
        self.task = task
        self.startDate = startDate
        self.estimatedMinutes = estimatedMinutes
    }
}

enum PomodoroStatus: String, Codable {
    case finished, abandoned
}
