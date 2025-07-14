import SwiftUI
import SwiftData

struct TodayReviewView: View {
    @Environment(\.modelContext) private var context
    @Query var reviews: [Review]
    @Query var pomodoros: [Pomodoro]
    @Query var tasks: [Task]
    @Query var plans: [Plan]
    
    @State private var content: String = ""
    @State private var score: Int = 5
    @State private var loaded = false
    
    private let todayStart = Calendar.current.startOfDay(for: Date())
    private let todayEnd = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!
    
    init() {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        
        _reviews = Query(filter: #Predicate<Review> {
            $0.date >= start && $0.date < end
        })
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Summary Section
                summarySection()
                
                // MARK: - Review Form
                Form {
                    Section(header: Text("How was your day?")) {
                        TextEditor(text: $content)
                            .frame(minHeight: 200)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                    }
                    
                    Section(header: Text("Self-Rating")) {
                        Stepper("Score: \(score)", value: $score, in: 0...10)
                    }
                }
                
                // MARK: - Save Button
                HStack {
                    Spacer()
                    Button("Save Review") {
                        saveReview()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            
            Spacer()
        }
        .onAppear {
            loadReviewIfNeeded()
        }
    }
    
    // MARK: – Top Summary View
    @ViewBuilder
    private func summarySection() -> some View {
        // ––––– Metrics –––––
        let finishedPomodoros = pomodoros.filter {
            $0.status == .finished &&
            ($0.endDate ?? .distantPast) >= todayStart &&
            $0.endDate! < todayEnd
        }.count

        let abandonedPomodoros = pomodoros.filter {
            $0.status == .abandoned &&
            ($0.endDate ?? .distantPast) >= todayStart &&
            $0.endDate! < todayEnd
        }.count

        let finishedTasks = tasks.filter {
            $0.isFinished && $0.date >= todayStart && $0.date < todayEnd
        }.count

        let unfinishedTasks = tasks.filter {
            !$0.isFinished && $0.date >= todayStart && $0.date < todayEnd
        }.count

        let finishedPlans = plans.filter {
            $0.status == .finished &&
            ($0.endTime ?? .distantPast) >= todayStart &&
            $0.endTime! < todayEnd
        }.count

        let shouldBeFinishedPlans = plans.filter {
            $0.status != .finished &&
            ($0.estimatedEndTime ?? .distantFuture) < todayEnd
        }.count

        // ––––– UI –––––
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("Summary of Today")
                    .font(.title3.weight(.semibold))
            } icon: {
                Image(systemName: "chart.bar.fill")
            }
            
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    Text("🍅 Pomodoros")
                    Text("✅ \(finishedPomodoros)   ❌ \(abandonedPomodoros)")
                }
                GridRow {
                    Text("📋 Tasks")
                    Text("✅ \(finishedTasks)   ⚠️ \(unfinishedTasks)")
                }
                GridRow {
                    Text("📌 Plans")
                    Text("✅ \(finishedPlans)   ⚠️ \(shouldBeFinishedPlans)")
                }
            }
            .font(.body.monospacedDigit())          // bigger & aligned digits
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Load existing review
    private func loadReviewIfNeeded() {
        guard !loaded else { return }
        if let today = reviews.first {
            content = today.content
            score = today.score
        }
        loaded = true
    }
    
    // MARK: - Save or update
    private func saveReview() {
        if let existing = reviews.first {
            existing.content = content
            existing.score = score
        } else {
            let review = Review(
                date: Calendar.current.startOfDay(for: Date()),
                content: content,
                score: score
            )
            context.insert(review)
        }
    }
}

struct TodayReviewView_Previews: PreviewProvider {
    
    struct PreviewWrapper: View {
        let container: ModelContainer
        
        init() {
            container = try! ModelContainer(
                for:
                    Review.self,
                Pomodoro.self,
                Task.self,
                Plan.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            
            let ctx = container.mainContext
            let cal = Calendar.current
            let today      = cal.startOfDay(for: .now)
            let tenAM      = cal.date(bySettingHour: 10, minute: 0, second: 0, of: today)!
            let elevenAM   = cal.date(bySettingHour: 11, minute: 0, second: 0, of: today)!
            let twoPM      = cal.date(bySettingHour: 14, minute: 0, second: 0, of: today)!
            
            let p1 = Pomodoro(task: nil, startDate: tenAM, estimatedMinutes: 25)
            p1.endDate = cal.date(byAdding: .minute, value: 25, to: p1.startDate)
            p1.status  = .finished
            ctx.insert(p1)
            
            let p2 = Pomodoro(task: nil, startDate: elevenAM, estimatedMinutes: 25)
            p2.endDate = cal.date(byAdding: .minute, value: 5, to: p2.startDate)
            p2.status  = .abandoned
            ctx.insert(p2)
            
            ctx.insert(Task(name: "Finish UI Prototype", date: today, isFinished: true))
            ctx.insert(Task(name: "Refactor ViewModel",   date: today, isFinished: false))
            
            let finishedPlan = Plan(name: "MVP Phase 1", status: .finished, startTime: today)
            finishedPlan.endTime = twoPM
            ctx.insert(finishedPlan)
            ctx.insert(Plan(name: "MVP Phase 2", status: .inProgress, startTime: today))
            
            ctx.insert(Review(date: today, content: "Solid progress, but need better focus.", score: 7))
        }
        
        var body: some View {
            TodayReviewView()
                .environment(\.modelContext, container.mainContext)
                .frame(width: 580, height: 800)
                .previewDisplayName("📝 Today Review")
        }
    }
    
    static var previews: some View {
        PreviewWrapper()
    }
}
