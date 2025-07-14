
import Foundation
import SwiftData

@Model
class Review {
    @Attribute(.unique) var id: UUID = UUID()
    var date: Date
    var content: String
    var score: Int

    init(date: Date = .now, content: String = "", score: Int = 0) {
        self.date = date
        self.content = content
        self.score = score
    }
}
