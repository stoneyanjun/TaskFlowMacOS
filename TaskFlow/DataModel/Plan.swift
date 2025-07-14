
import SwiftUI
import SwiftData

@Model
class Plan: Identifiable {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var status: PlanStatus
    var priority: PlanPriority? = PlanPriority.normal
    var isUrgent: Bool = false
    var subPlanID: UUID?
    var createdDate = Date()
    var modifiedDate = Date()
    var startTime: Date
    var estimatedEndTime: Date?
    var endTime: Date?
    var note: String?
    var review: String?

    init(name: String, status: PlanStatus = .notStarted, priority: PlanPriority = .normal, isUrgent: Bool = false, startTime: Date = .now, estimatedEndTime: Date? = nil) {
        self.name = name
        self.status = status
        self.priority = priority
        self.isUrgent = isUrgent
        self.startTime = startTime
        self.estimatedEndTime = estimatedEndTime
    }

    func toggleFinished() {
        if status == .finished {
            status = .inProgress
            endTime = nil
        } else {
            status = .finished
            endTime = Date()
        }
    }
}

extension Plan: Hashable {
    static func == (lhs: Plan, rhs: Plan) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum PlanType: String, Codable, CaseIterable, Identifiable, Equatable {
    case longTerm = "long_term"
    case shortTerm = "short_term"
    case temporary = "temporary"

    var id: Self { self }

    var displayName: String {
        switch self {
        case .longTerm: return "Long Term"
        case .shortTerm: return "Short Term"
        case .temporary: return "Temporary"
        }
    }

    var icon: String {
        switch self {
        case .longTerm: return "calendar"
        case .shortTerm: return "clock"
        case .temporary: return "bolt"
        }
    }
}

enum PlanStatus: String, Codable, CaseIterable, Identifiable, Equatable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case finished = "finished"
    case abandoned = "abandoned"
    case delayed = "delayed"

    var id: Self { self }

    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .finished: return "Finished"
        case .abandoned: return "Abandoned"
        case .delayed: return "Delayed"
        }
    }

    var icon: String {
        switch self {
        case .notStarted: return "circle"
        case .inProgress: return "play.circle"
        case .finished: return "checkmark.circle"
        case .abandoned: return "xmark.circle"
        case .delayed: return "exclamationmark.circle"
        }
    }
}

enum PlanPriority: String, Codable, CaseIterable, Identifiable, Equatable {
    case normal = "normal"
    case high = "high"

    var id: Self { self }

    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .high: return "High"
        }
    }
}
