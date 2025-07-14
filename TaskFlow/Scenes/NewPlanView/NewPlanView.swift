
import SwiftUI
import SwiftData

struct NewPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var priority: PlanPriority = .normal
    @State private var isUrgent: Bool = false
    @State private var startTime = Date()
    @State private var estimatedEndTime: Date? = nil

    @State private var alertMessage = ""
    @State private var showAlert = false

    var body: some View {
        VStack(alignment: .leading) {
            Form {
                TextField("Name", text: $name)

                Picker("Priority", selection: $priority) {
                    ForEach(PlanPriority.allCases) { level in
                        Text(level.displayName).tag(level)
                    }
                }

                Toggle("Urgent", isOn: $isUrgent)

                DatePicker("Start Date", selection: $startTime, in: Date()..., displayedComponents: [.date])

                DatePicker(
                    "End Date",
                    selection: Binding($estimatedEndTime, replacingNilWith: Date()),
                    displayedComponents: [.date]
                )
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    let start = calendar.startOfDay(for: startTime)
                    let end = calendar.startOfDay(for: estimatedEndTime ?? startTime)

                    if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        alertMessage = "Please enter a name for the plan."
                        showAlert = true
                        return
                    }

                    if start < today {
                        alertMessage = "Start date must not be earlier than today."
                        showAlert = true
                        return
                    }

                    if end < start {
                        alertMessage = "End date must not be earlier than start date."
                        showAlert = true
                        return
                    }

                    let newPlan = Plan(
                        name: name,
                        status: .notStarted,
                        priority: priority,
                        isUrgent: isUrgent,
                        startTime: startTime,
                        estimatedEndTime: estimatedEndTime
                    )
                    context.insert(newPlan)

                    if today >= start && today <= end {
                        let newTask = Task(
                            name: newPlan.name,
                            date: today,
                            priority: newPlan.priority ?? .normal,
                            isUrgent: newPlan.isUrgent,
                            plan: newPlan
                        )
                        context.insert(newTask)
                    }

                    dismiss()
                }
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 300)
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        }
    }
}

struct NewPlanView_Previews: PreviewProvider {
    static var previews: some View {
        let container = try! ModelContainer(for: Plan.self, Task.self, configurations: .init(isStoredInMemoryOnly: true))
        NewPlanView()
            .modelContainer(container)
    }
}
