import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Bindable var task: Task
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Basic") {
                TextField("Task Name", text: $task.name)
                Picker("Priority", selection: $task.priority) {
                    ForEach(PlanPriority.allCases) { p in
                        Text(p.displayName).tag(p)
                    }
                }
                Toggle("Is Urgent", isOn: $task.isUrgent)
            }

            Section("Details") {
                TextEditor(text: Binding($task.note, replacingNilWith: ""))
                    .frame(minHeight: 80)
                TextEditor(text: Binding($task.review, replacingNilWith: ""))
                    .frame(minHeight: 80)
                TextField("Tag", text: Binding($task.tag, replacingNilWith: ""))
                TextField("Location", text: Binding($task.location, replacingNilWith: ""))
                DatePicker("Notification", selection: Binding($task.notificationTime, replacingNilWith: Date()), displayedComponents: [.hourAndMinute])
            }

            Section("Related Plan") {
                if let plan = task.plan {
                    Text("Linked to plan: \(plan.name)")
                } else {
                    Text("No plan linked")
                }
            }
            HStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }
            }
            .padding()
        }
        .padding()
        .navigationTitle("Task Detail")
    }
}


struct TaskDetailView_Previews: PreviewProvider {

    struct PreviewWrapper: View {
        let container: ModelContainer
        let sampleTask: Task      // Keep a reference so we can pass it in

        init() {
            container = try! ModelContainer(
                for: Task.self, Plan.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )

            let ctx = container.mainContext
            let plan = Plan(
                name: "Marketing Campaign",
                status: .inProgress,
                priority: .high,
                isUrgent: true,
                startTime: Date()
            )
            ctx.insert(plan)

            let task = Task(
                name: "Draft Email Copy",
                date: Date(),
                note: "Highlight new features and CTA.",
                tag: "marketing",
                priority: .high,
                isUrgent: true,
                location: "Office",
                notificationTime: Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()),
                plan: plan
            )
            ctx.insert(task)
            self.sampleTask = task
        }

        var body: some View {
            TaskDetailView(task: sampleTask)
                .environment(\.modelContext, container.mainContext)
                .frame(width: 480, height: 600)
                .previewDisplayName("🔍 Task Detail")
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
