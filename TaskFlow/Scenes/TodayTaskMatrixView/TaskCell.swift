
import SwiftUI
import SwiftData

struct TaskCell: View {
    @Bindable var task: Task
    var onEdit: (Task) -> Void
    var onStartPomodoro: (Task) -> Void

    var body: some View {
        HStack {
            Button(action: { task.toggleFinished() }) {
                Image(systemName: task.isFinished ? "checkmark.circle.fill" : "circle")
            }

            VStack(alignment: .leading) {
                Text(task.name)
                    .font(task.isFinished ? .body : .body.weight(.bold))
                    .foregroundColor(task.isFinished ? .gray : (task.isUrgent ? .red : .primary))

                if let planName = task.plan?.name {
                    Text("Plan: \(planName)")
                        .font(.caption)
                        .foregroundColor(task.isFinished ? .gray : .secondary)
                }

                if let tag = task.tag {
                    Text("#\(tag)")
                        .font(.caption2)
                        .foregroundColor(task.isFinished ? .gray : .blue)
                }
            }

            Spacer()
            
            if !task.isFinished {
                Button(action: {
                    onStartPomodoro(task)
                }) {
                    Image(systemName: "play.circle")
                        .foregroundColor(.blue) // ✅ Blue color
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            
            if !task.isFinished {
                Button("Edit") {
                    onEdit(task)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .onDrag {
            NSItemProvider(object: NSString(string: task.id.uuidString))
        }
    }
}

struct TaskCell_Previews: PreviewProvider {

    struct PreviewWrapper: View {
        let container: ModelContainer
        let sampleTask: Task

        init() {
            container = try! ModelContainer(
                for: Task.self, Plan.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )

            let ctx = container.mainContext
            let plan = Plan(name: "Website Redesign",
                            status: .inProgress,
                            priority: .high,
                            isUrgent: true,
                            startTime: Date())
            ctx.insert(plan)

            let task = Task(name: "Build Landing Page",
                            date: Date(),
                            tag: "frontend",
                            priority: .high,
                            isUrgent: true,
                            plan: plan)
            ctx.insert(task)
            sampleTask = task
        }

        var body: some View {
            TaskCell(
                task: sampleTask,
                onEdit: { _ in /* no-op */ },
                onStartPomodoro: { _ in /* no-op */ }
            )
            .environment(\.modelContext, container.mainContext)
            .frame(width: 420)
            .previewDisplayName("📝 Task Cell")
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
