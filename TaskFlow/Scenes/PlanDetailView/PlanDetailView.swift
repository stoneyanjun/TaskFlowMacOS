
import SwiftUI
import SwiftData

struct PlanDetailView: View {

    @State private var showDeleteConfirmation = false
    
    @Bindable var plan: Plan
    @Binding var startTime: Date
    @Binding var endTime: Date
    
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allTasks: [Task]
    
    private var tasksForThisPlan: [Task] {
        allTasks.filter { $0.plan == plan }
    }
    private var hasTaskForToday: Bool {
        tasksForThisPlan.contains {
            Calendar.current.isDateInToday($0.date)
        }
    }

    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        Form {
            Section(header: Text("Plan Info")) {
                TextField("Name", text: $plan.name)

                Picker("Priority", selection: $plan.priority) {
                    ForEach(PlanPriority.allCases) { level in
                        Text(level.displayName).tag(level)
                    }
                }

                Toggle("Urgent", isOn: $plan.isUrgent)

                DatePicker("Start Date", selection: $startTime, displayedComponents: [.date])
                    .onChange(of: startTime) { newValue in
                        validateDates(start: newValue, end: endTime)
                    }

                DatePicker("End Date", selection: $endTime, displayedComponents: [.date])
                    .onChange(of: endTime) { newValue in
                        validateDates(start: startTime, end: newValue)
                    }
            }

            Section(header: Text("Note")) {
                TextEditor(text: Binding($plan.note, replacingNilWith: ""))
                    .frame(minHeight: 120)
            }

            Section(header: Text("Review")) {
                TextEditor(text: Binding($plan.review, replacingNilWith: ""))
                    .frame(minHeight: 120)
            }

            Section(header: Text("Actions")) {
                HStack(spacing: 16) {
                    Button("Finish") {
                        plan.status = .finished
                        plan.endTime = Date()
                    }
                    Button("Abandon") {
                        plan.status = .abandoned
                    }
                    Button("🗑️ Delete Plan") {
                        showDeleteConfirmation = true
                    }
                    .foregroundColor(.red)

                    Button("➕ Add Today’s Task") {
                        addTodayTaskIfNeeded()
                    }
                    .disabled(hasTaskForToday)
                }
            }
        }
        .padding()
        .navigationTitle("Plan Details")
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        }
        .alert("Delete this plan?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                plan.isDelete = true
                plan.modifiedDate = Date()
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private func validateDates(start: Date, end: Date) {
        if end < start {
            alertMessage = "End date cannot be earlier than start date."
            showAlert = true
        }
    }
    
    private func addTodayTaskIfNeeded() {
        guard !hasTaskForToday else { return }

        let task = Task(
            name: plan.name + " Task",
            date: Calendar.current.startOfDay(for: Date()),
            priority: plan.priority ?? .normal,
            isUrgent: plan.isUrgent,
            plan: plan
        )
        context.insert(task)
    }
}

struct PlanDetailView_Previews: PreviewProvider {

    struct PreviewWrapper: View {
        @State private var startDate = Date()
        @State private var endDate   = Calendar.current.date(byAdding: .day, value: 7, to: Date())!

        let container: ModelContainer
        let plan: Plan

        init() {
            container = try! ModelContainer(
                for: Plan.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )

            plan = Plan(
                name: "Learn SwiftData",
                status: .inProgress,
                priority: .high,
                isUrgent: true,
                startTime: Date(),
                estimatedEndTime: Calendar.current.date(byAdding: .day, value: 7, to: Date())
            )
            container.mainContext.insert(plan)
        }

        var body: some View {
            PlanDetailView(
                plan: plan,
                startTime: $startDate,
                endTime: $endDate
            )
            .environment(\.modelContext, container.mainContext)
            .frame(width: 460, height: 640)
            .previewDisplayName("📅 Plan Detail")
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
