
import SwiftData
import SwiftUI

struct NewTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var priority: PlanPriority = .normal
    @State private var isUrgent = false
    @State private var tag = ""
    @State private var note = ""
    @State private var location = ""
    @State private var enableNotification = false
    @State private var notificationTimeValue = Date()

    var body: some View {
        VStack {
            Form {
                TextField("Task Name", text: $name)

                Picker("Priority", selection: $priority) {
                    ForEach(PlanPriority.allCases) { level in
                        Text(level.displayName).tag(level)
                    }
                }

                Toggle("Urgent", isOn: $isUrgent)
                TextField("Tag", text: $tag)
                TextField("Location", text: $location)

                Toggle("Enable Notification", isOn: $enableNotification)
                if enableNotification {
                    DatePicker("Notification Time", selection: $notificationTimeValue, displayedComponents: [.hourAndMinute])
                }

                TextEditor(text: $note).frame(height: 80)
            }
            .padding()

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    let newTask = Task(
                        name: name,
                        date: Date(), // Today
                        note: note,
                        tag: tag.isEmpty ? nil : tag,
                        priority: priority,
                        isUrgent: isUrgent,
                        location: location.isEmpty ? nil : location,
                        notificationTime: enableNotification ? notificationTimeValue : nil
                    )
                    context.insert(newTask)
                    dismiss()
                }
            }
            .padding()
            Spacer()
        }
        .frame(minWidth: 400, minHeight: 380)
    }
}

struct NewTaskView_Previews: PreviewProvider {

    struct PreviewWrapper: View {
        let container: ModelContainer

        init() {
            // 1️⃣ In-memory store to isolate preview data
            container = try! ModelContainer(
                for: Task.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }

        var body: some View {
            NewTaskView()
                .environment(\.modelContext, container.mainContext)
                .frame(width: 420, height: 420)
                .previewDisplayName("➕ New Task Form")
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
