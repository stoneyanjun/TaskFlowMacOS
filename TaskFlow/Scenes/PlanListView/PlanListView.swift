
import SwiftUI
import SwiftData

struct PlanListView: View {
    @Query(
        filter: #Predicate<Plan> { plan in
            plan.isDelete == false
        },
        sort: [SortDescriptor(\Plan.startTime)]
    )
    var plans: [Plan]
    
    @Environment(\.modelContext) private var context

    @State private var showingNewPlanSheet = false
    @State private var selectedPlan: Plan?
    @State private var cachedStartTime: Date = .now
    @State private var cachedEndTime: Date = .now

    var body: some View {
        NavigationSplitView {
            List(selection: Binding(
                get: { selectedPlan },
                set: { switchToPlan($0) }
            )) {
                ForEach(plans) { plan in
                    HStack {
                        Button(action: {
                            plan.toggleFinished()
                        }) {
                            Image(systemName: plan.status == .finished ? "checkmark.circle.fill" : "circle")
                        }
                        VStack(alignment: .leading) {
                            Text(plan.name)
                                .font(plan.isUrgent && plan.priority == .high ? .footnote : .headline)
                                .foregroundColor(plan.status == .finished || plan.status == .abandoned ? .gray :
                                                 plan.isUrgent ? .red : .primary)

                            HStack {
                                Image(systemName: plan.status.icon)
                                Text(plan.startTime.formatted(.dateTime.year().month().day()))
                            }
                            .font(.caption)
                            .foregroundColor(plan.status == .finished || plan.status == .abandoned ? .gray : .secondary)
                        }
                        Spacer()
                    }
                    .frame(minWidth: 300)
                    .tag(plan)
                }
            }
            .navigationTitle("Plans")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewPlanSheet = true }) {
                        Label("Add Plan", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewPlanSheet) {
                NewPlanView()
            }
        } detail: {
            if let selected = selectedPlan {
                PlanDetailView(plan: selected, startTime: $cachedStartTime, endTime: $cachedEndTime)
            } else {
                Text("Select a plan to view details")
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }

    private func switchToPlan(_ newPlan: Plan?) {
        if let previous = selectedPlan {
            previous.startTime = cachedStartTime
            previous.estimatedEndTime = cachedEndTime
            previous.modifiedDate = Date()
        }

        if let new = newPlan {
            cachedStartTime = Calendar.current.startOfDay(for: new.startTime)
            cachedEndTime = Calendar.current.startOfDay(for: new.estimatedEndTime ?? new.startTime)
        }

        selectedPlan = newPlan
    }
}


struct PlanListView_Previews: PreviewProvider {

    struct PreviewWrapper: View {
        let container: ModelContainer

        init() {
            container = try! ModelContainer(
                for: Plan.self, Task.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )

            let ctx = container.mainContext
            let cal = Calendar.current
            let today = cal.startOfDay(for: .now)

            ctx.insert(
                Plan(
                    name: "Project Alpha",
                    status: .inProgress,
                    priority: .high,
                    isUrgent: true,
                    startTime: today,
                    estimatedEndTime: cal.date(byAdding: .day, value: 14, to: today)
                )
            )
            ctx.insert(
                Plan(
                    name: "Learn SwiftData",
                    status: .notStarted,
                    priority: .normal,
                    startTime: cal.date(byAdding: .day, value: 3, to: today)!
                )
            )
            let finished = Plan(
                name: "Yearly Review",
                status: .finished,
                priority: .normal,
                startTime: cal.date(byAdding: .day, value: -30, to: today)!,
                estimatedEndTime: cal.date(byAdding: .day, value: -2, to: today)
            )
            finished.endTime = cal.date(byAdding: .day, value: -1, to: today)
            ctx.insert(finished)
        }

        var body: some View {
            PlanListView()
                .environment(\.modelContext, container.mainContext)
                .frame(minWidth: 760, minHeight: 480)
                .previewDisplayName("📋 Plan List")
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
