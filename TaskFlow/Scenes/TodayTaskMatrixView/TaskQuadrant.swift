
import SwiftUI
import SwiftData

struct TaskQuadrant: View {
    var title: String
    var tasks: [Task]
    var onEdit: (Task) -> Void
    var onStartPomodoro: (Task) -> Void
    var updateTask: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 4)

            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    if tasks.isEmpty {
                        Text("Drop a task here")
                            .italic()
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(tasks.prefix(10)) { task in
                            TaskCell(task: task, onEdit: onEdit, onStartPomodoro: onStartPomodoro)
                        }
                    }
                }
            }
            .frame(maxHeight: 300)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .border(Color.gray)
        .onDrop(of: [.text], isTargeted: nil) { providers in
            if let first = providers.first {
                _ = first.loadObject(ofClass: NSString.self) { item, _ in
                    if let idString = item as? String,
                       let uuid = UUID(uuidString: idString) {
                        DispatchQueue.main.async {
                            updateTask(uuid)
                        }
                    }
                }
                return true
            }
            return false
        }
    }
}

struct TaskQuadrant_Previews: PreviewProvider {

    struct PreviewWrapper: View {
        let container: ModelContainer
        let sampleTasks: [Task]

        init() {
            container = try! ModelContainer(
                for: Task.self, Plan.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )

            let ctx = container.mainContext
            let plan = Plan(name: "Product Launch",
                            status: .inProgress,
                            startTime: Date())
            ctx.insert(plan)

            ctx.insert(Task(name: "Design Hero Banner",
                            date: Date(),
                            tag: "design",
                            priority: .high,
                            isUrgent: true,
                            plan: plan))

            ctx.insert(Task(name: "Write Blog Post",
                            date: Date(),
                            tag: "content",
                            priority: .normal,
                            isUrgent: false,
                            plan: plan))

            // Fetch back to an array for the quadrant
            sampleTasks = try! ctx.fetch(FetchDescriptor<Task>())
        }

        var body: some View {
            TaskQuadrant(
                title: "Urgent & Important",
                tasks: sampleTasks,
                onEdit: { _ in /* no-op */ },
                onStartPomodoro: { _ in /* no-op */ },
                updateTask: { _ in /* no-op */ }
            )
            .environment(\.modelContext, container.mainContext)
            .frame(width: 360, height: 480)
            .previewDisplayName("🗂️ Task Quadrant")
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
