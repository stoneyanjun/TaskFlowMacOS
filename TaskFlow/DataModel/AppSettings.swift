
import Foundation
import SwiftData

@Model
class AppSettings {
    @Attribute(.unique) var id: UUID = UUID()

    var pomodoroWorkMinutes: Int
    var pomodoroRelaxMinutes: Int
    var enableReviewNotification: Bool
    var reviewNotificationTime: Date

    init(
        pomodoroWorkMinutes: Int = 25,
        pomodoroRelaxMinutes: Int = 5,
        enableReviewNotification: Bool = true,
        reviewNotificationTime: Date = Calendar.current.date(bySettingHour: 18, minute: 15, second: 0, of: Date())!
    ) {
        self.pomodoroWorkMinutes = pomodoroWorkMinutes
        self.pomodoroRelaxMinutes = pomodoroRelaxMinutes
        self.enableReviewNotification = enableReviewNotification
        self.reviewNotificationTime = reviewNotificationTime
    }
}
