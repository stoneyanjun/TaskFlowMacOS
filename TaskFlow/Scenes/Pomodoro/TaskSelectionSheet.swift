
import SwiftUI
import SwiftData

struct TaskSelectionSheet: View {
    var tasks: [Task]
    var onSelect: (Task) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTaskID: UUID?

    var body: some View {
        NavigationStack {
            List {
                ForEach(tasks) { task in
                    HStack(spacing: 8) {
                        Image(systemName: task.id == selectedTaskID ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.accentColor)
                        Text(task.name)
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTaskID = task.id
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onSelect(task)
                            dismiss()
                        }
                    }
                }
            }
            .listStyle(.plain) // ✅ Clean, compact layout
            .navigationTitle("Select a Task") // ✅ Works on macOS
        }
        .frame(minWidth: 300, idealWidth: 350, maxWidth: 400,
                minHeight: 400, idealHeight: 450, maxHeight: 500)
    }
}


struct TaskSelectionSheet_Previews: PreviewProvider {

    struct PreviewWrapper: View {
        let container: ModelContainer
        let sampleTasks: [Task]

        init() {
            container = try! ModelContainer(
                for: Task.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )

            let ctx = container.mainContext
            let today = Calendar.current.startOfDay(for: .now)

            ctx.insert(Task(name: "Write Release Notes", date: today))
            ctx.insert(Task(name: "Design App Icon",     date: today))
            ctx.insert(Task(name: "Reply to Emails",     date: today))

            sampleTasks = try! ctx.fetch(FetchDescriptor<Task>())
        }

        var body: some View {
            TaskSelectionSheet(tasks: sampleTasks) { _ in /* no-op */ }
                .environment(\.modelContext, container.mainContext)
                .frame(width: 360, height: 460)
                .previewDisplayName("🎯 Task Selection Sheet")
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
