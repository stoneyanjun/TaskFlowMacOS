
import Foundation
import SwiftData

@Model
class Task: Identifiable {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var date: Date
    var isFinished: Bool = false
    var note: String?
    var review: String?
    var tag: String?
    var priority = PlanPriority.normal
    var isUrgent: Bool = false
    var location: String?
    var notificationTime: Date?
    var createdDate = Date.now
    var modifiedDate = Date.now

    // Relationship
    var plan: Plan?

    init(name: String,
         date: Date,
         isFinished: Bool = false,
         note: String? = nil,
         review: String? = nil,
         tag: String? = nil,
         priority: PlanPriority = .normal,
         isUrgent: Bool = false,
         location: String? = nil,
         notificationTime: Date? = nil,
         plan: Plan? = nil) {
        self.name = name
        self.date = date
        self.isFinished = isFinished
        self.note = note
        self.review = review
        self.tag = tag
        self.priority = priority
        self.isUrgent = isUrgent
        self.location = location
        self.notificationTime = notificationTime
        self.plan = plan
    }

    func toggleFinished() {
        isFinished.toggle()
        modifiedDate = .now
    }
}

extension Task {
    var isValidPlan: Bool {
        plan?.isDelete == false || plan == nil
    }
}
