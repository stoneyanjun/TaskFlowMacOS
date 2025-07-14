
import SwiftData
import SwiftUI

@Model
class RootData {
    @Attribute(.unique) var id: UUID = UUID()
    var date: Date
    var createdTaskForToday: Bool

    init(date: Date = .now, createdTaskForToday: Bool) {
        self.date = date
        self.createdTaskForToday = createdTaskForToday
    }
}
