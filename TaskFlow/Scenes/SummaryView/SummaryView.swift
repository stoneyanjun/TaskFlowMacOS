//
//  SummaryView.swift
//  TaskFlow
//
//  Created by You on 2025/07/14.
//

import SwiftUI
import SwiftData

// MARK: - Main View
struct SummaryView: View {
    // ───────── Data ─────────
    @Query var pomodoros: [Pomodoro]
    @Query var tasks:     [Task]
    @Query var plans:     [Plan]
    @Query var reviews:   [Review]

    @State private var selectedTab: SummaryRange = .today

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // ─ Range Picker
            Picker("Summary Range", selection: $selectedTab) {
                ForEach(SummaryRange.allCases, id: \.self) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(.segmented)

            // ─ Metrics Calculation
            let (startDate, endDate) = selectedTab.dateRange(
                tasks: tasks,
                plans: plans,
                reviews: reviews
            )

            let finishedPomodoros = pomodoros.filter {
                $0.status == .finished &&
                ($0.endDate ?? .distantPast) >= startDate &&
                $0.endDate! <= endDate
            }

            let abandonedPomodoros = pomodoros.filter {
                $0.status == .abandoned &&
                ($0.endDate ?? .distantPast) >= startDate &&
                $0.endDate! <= endDate
            }

            let finishedTasks = tasks.filter {
                $0.isFinished && $0.date >= startDate && $0.date <= endDate
            }

            let unfinishedTasksShouldFinish = tasks.filter {
                !$0.isFinished && $0.date >= startDate && $0.date <= endDate
            }

            let finishedPlans = plans.filter {
                $0.status == .finished &&
                ($0.endTime ?? .distantPast) >= startDate &&
                $0.endTime! <= endDate
            }

            let unfinishedPlansShouldFinish = plans.filter {
                $0.status != .finished &&
                ($0.estimatedEndTime ?? .distantFuture) < endDate
            }

            let reviewStats = reviewCount(in: startDate ... endDate)

            // ───────── Summary Card ─────────
            VStack(alignment: .leading, spacing: 18) {

                // Metrics in two aligned columns
                Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 12) {
                    GridRow {
                        Text("🍅 Pomodoros")
                        Text("✅ \(finishedPomodoros.count)   ❌ \(abandonedPomodoros.count)")
                    }
                    GridRow {
                        Text("📋 Tasks")
                        Text("✅ \(finishedTasks.count)   ⚠️ \(unfinishedTasksShouldFinish.count)")
                    }
                    GridRow {
                        Text("📌 Plans")
                        Text("✅ \(finishedPlans.count)   ⚠️ \(unfinishedPlansShouldFinish.count)")
                    }
                    GridRow {
                        Text("✍️ Reviews")
                        Text("✓ \(reviewStats.written)   Ø \(reviewStats.missing)")
                    }
                }
                .font(.body.monospacedDigit().weight(.medium))   // larger, aligned digits
                .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color.gray.opacity(0.06),
                        in: RoundedRectangle(cornerRadius: 12))

            Spacer()
        }
        .padding()
        .navigationTitle("Summary")
    }

    // MARK: - Helpers
    private func reviewCount(in range: ClosedRange<Date>) -> (written: Int, missing: Int) {
        let calendar = Calendar.current
        var date = calendar.startOfDay(for: range.lowerBound)
        let end  = calendar.startOfDay(for: range.upperBound)

        var written = 0
        var total   = 0

        while date <= end {
            let hasTaskOrPlan =
                tasks.contains { calendar.isDate($0.date, inSameDayAs: date) } ||
                plans.contains { calendar.isDate(($0.estimatedEndTime ?? $0.startTime), inSameDayAs: date) }

            if hasTaskOrPlan {
                total += 1
                let hasReview = reviews.contains {
                    calendar.isDate($0.date, inSameDayAs: date) &&
                    !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }
                if hasReview { written += 1 }
            }
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        return (written, total - written)
    }
}

// MARK: - Date Range Enum
enum SummaryRange: CaseIterable {
    case today, thisWeek, thisMonth, thisYear, total

    var title: String {
        switch self {
        case .today:     return "Today"
        case .thisWeek:  return "This Week"
        case .thisMonth: return "This Month"
        case .thisYear:  return "This Year"
        case .total:     return "Total"
        }
    }

    func dateRange(tasks: [Task], plans: [Plan], reviews: [Review]) -> (Date, Date) {
        let calendar = Calendar.current
        let now      = Date()

        switch self {
        case .today:
            return (calendar.startOfDay(for: now), now)

        case .thisWeek:
            let start = calendar.date(
                from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            )!
            return (start, now)

        case .thisMonth:
            let start = calendar.date(
                from: calendar.dateComponents([.year, .month], from: now)
            )!
            return (start, now)

        case .thisYear:
            let start = calendar.date(
                from: calendar.dateComponents([.year], from: now)
            )!
            return (start, now)

        case .total:
            let allDates = (reviews.map { $0.date } +
                            tasks.map   { $0.date } +
                            plans.map   { $0.startTime })
                .map { calendar.startOfDay(for: $0) }

            let earliest = allDates.min() ?? calendar.date(byAdding: .year, value: -1, to: now)!
            return (earliest, now)
        }
    }
}

struct SummaryView_Previews: PreviewProvider {

    struct PreviewWrapper: View {
        let container: ModelContainer

        init() {
            // In-memory SwiftData store for preview
            container = try! ModelContainer(
                for: Pomodoro.self, Task.self, Plan.self, Review.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )

            let ctx = container.mainContext
            let cal = Calendar.current
            let now = Date()
            let today = cal.startOfDay(for: now)
            let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
            let lastWeek  = cal.date(byAdding: .day, value: -5, to: today)!

            // Pomodoros
            let p1 = Pomodoro(task: nil, startDate: yesterday, estimatedMinutes: 25)
            p1.endDate = cal.date(byAdding: .minute, value: 25, to: p1.startDate)
            p1.status  = .finished
            ctx.insert(p1)

            let p2 = Pomodoro(task: nil, startDate: today, estimatedMinutes: 25)
            p2.endDate = cal.date(byAdding: .minute, value: 10, to: p2.startDate)
            p2.status  = .abandoned
            ctx.insert(p2)

            // Tasks
            ctx.insert(Task(name: "Finish UI Mock", date: today, isFinished: true))
            ctx.insert(Task(name: "Write Unit Tests", date: yesterday, isFinished: false))

            // Plans
            let finishedPlan = Plan(name: "Sprint 1", status: .finished,
                                    startTime: lastWeek,
                                    estimatedEndTime: yesterday)
            finishedPlan.endTime = yesterday
            ctx.insert(finishedPlan)

            ctx.insert(Plan(name: "Sprint 2", status: .inProgress, startTime: today))

            // Reviews
            ctx.insert(Review(date: today, content: "Great progress today 🎉", score: 5))
            ctx.insert(Review(date: yesterday, content: "", score: 0))
        }

        var body: some View {
            SummaryView()
                .environment(\.modelContext, container.mainContext)
                .frame(width: 500, height: 600)
        }
    }

    static var previews: some View {
        PreviewWrapper().previewDisplayName("📊 Summary")
    }
}
