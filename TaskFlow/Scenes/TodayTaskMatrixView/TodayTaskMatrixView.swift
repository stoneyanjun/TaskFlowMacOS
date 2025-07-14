
import SwiftUI
import SwiftData

struct TodayTaskMatrixView: View {
    @Query var tasks: [Task]
    @Query var settings: [AppSettings]
    @Environment(\.modelContext) private var context
    @EnvironmentObject var pomodoroModel: PomodoroTimerModel

    @State private var showingNewTaskSheet = false
    @State private var editingTask: Task?
    @State private var navigateToPomodoro = false

    var groupedTasks: [[Task]] {
        let today = Calendar.current.startOfDay(for: Date())
        let todayTasks = tasks.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
        return [
            todayTasks.filter { $0.isUrgent && $0.priority == .high },     // A
            todayTasks.filter { !$0.isUrgent && $0.priority == .high },    // B
            todayTasks.filter { $0.isUrgent && $0.priority == .normal },   // C
            todayTasks.filter { !$0.isUrgent && $0.priority == .normal }   // D
        ]
    }

    func updateTask(toQuadrant index: Int, id: UUID) {
        guard let task = tasks.first(where: { $0.id == id }) else { return }

        switch index {
        case 0: task.priority = .high;   task.isUrgent = true
        case 1: task.priority = .high;   task.isUrgent = false
        case 2: task.priority = .normal; task.isUrgent = true
        case 3: task.priority = .normal; task.isUrgent = false
        default: break
        }
        task.modifiedDate = Date()
    }

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TaskQuadrant(
                        title: "Urgent & Important",
                        tasks: groupedTasks[0],
                        onEdit: { editingTask = $0 },
                        onStartPomodoro: startPomodoro,
                        updateTask: { updateTask(toQuadrant: 0, id: $0) }
                    )
                    TaskQuadrant(
                        title: "Important, Not Urgent",
                        tasks: groupedTasks[1],
                        onEdit: { editingTask = $0 },
                        onStartPomodoro: startPomodoro,
                        updateTask: { updateTask(toQuadrant: 1, id: $0) }
                    )
                }
                HStack {
                    TaskQuadrant(
                        title: "Urgent, Not Important",
                        tasks: groupedTasks[2],
                        onEdit: { editingTask = $0 },
                        onStartPomodoro: startPomodoro,
                        updateTask: { updateTask(toQuadrant: 2, id: $0) }
                    )
                    TaskQuadrant(
                        title: "Not Urgent & Not Important",
                        tasks: groupedTasks[3],
                        onEdit: { editingTask = $0 },
                        onStartPomodoro: startPomodoro,
                        updateTask: { updateTask(toQuadrant: 3, id: $0) }
                    )
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewTaskSheet = true }) {
                        Label("Add Task", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewTaskSheet) {
                NewTaskView()
            }
            .sheet(item: $editingTask) { task in
                TaskDetailView(task: task)
            }
            .navigationDestination(isPresented: $navigateToPomodoro) {
                PomodoroView()
                    .environmentObject(pomodoroModel)
            }
        }
    }

    private func startPomodoro(for task: Task) {
        pomodoroModel.selectedTask = task
        pomodoroModel.configure(with: context, settings: settings.first)
        pomodoroModel.startPomodoro()
        navigateToPomodoro = true
    }
}


struct TodayTaskMatrixView_Previews: PreviewProvider {

    struct PreviewWrapper: View {
        // Keep the timer model alive during preview refreshes
        @StateObject private var pomodoroModel = PomodoroTimerModel()

        let container: ModelContainer

        init() {
            // 1️⃣ In-memory container so no real data is touched
            container = try! ModelContainer(
                for: Task.self, AppSettings.self, Plan.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )

            let ctx = container.mainContext
            let today = Calendar.current.startOfDay(for: .now)

            // 2️⃣ Sample tasks — one per Eisenhower quadrant
            ctx.insert(Task(name: "Urgent & Important",
                            date: today,
                            priority: .high,
                            isUrgent: true))
            ctx.insert(Task(name: "Important, Not Urgent",
                            date: today,
                            priority: .high,
                            isUrgent: false))
            ctx.insert(Task(name: "Urgent, Not Important",
                            date: today,
                            priority: .normal,
                            isUrgent: true))
            ctx.insert(Task(name: "Not Urgent & Not Important",
                            date: today,
                            priority: .normal,
                            isUrgent: false))

            // 3️⃣ App settings for Pomodoro durations
            ctx.insert(AppSettings())
        }

        var body: some View {
            TodayTaskMatrixView()
                .environment(\.modelContext, container.mainContext)  // inject SwiftData
                .environmentObject(pomodoroModel)                    // inject timer model
                .frame(width: 820, height: 520)
                .previewDisplayName("🗂️ Today Task Matrix")
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
