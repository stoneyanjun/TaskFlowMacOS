import SwiftUI
import SwiftData
import UserNotifications

enum MainSidebarItem: Hashable {
    case plans
    case todayTasks
    case pomodoro
    case todayReview
    case summary
    case settings
}

struct RootView: View {
    @StateObject private var pomodoroModel = PomodoroTimerModel()
    
    @Environment(\.modelContext) private var context
    @Query var rootDataRecords: [RootData]
    @Query var plans: [Plan]
    @Query var settings: [AppSettings]

    @State private var selectedItem: MainSidebarItem? = .plans

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedItem) {
                NavigationLink(value: MainSidebarItem.plans) {
                    Label("Plans", systemImage: "list.bullet.rectangle")
                }
                NavigationLink(value: MainSidebarItem.todayTasks) {
                    Label("Today Tasks", systemImage: "calendar")
                }
                NavigationLink(value: MainSidebarItem.pomodoro) {
                    Label("Pomodoro", systemImage: "timer")
                }
                NavigationLink(value: MainSidebarItem.todayReview) {
                    Label("Review Today", systemImage: "square.and.pencil")
                }
                NavigationLink(value: MainSidebarItem.summary) {
                    Label("Summary", systemImage: "chart.bar.fill")
                }
                NavigationLink(value: MainSidebarItem.settings) {
                    Label("Settings", systemImage: "gear")
                }
            }
            .navigationTitle("TaskFlow")
        } detail: {
            switch selectedItem {
            case .plans:
                PlanListView()
            case .todayTasks:
                TodayTaskMatrixView()
                    .environmentObject(pomodoroModel)
            case .pomodoro:
                PomodoroView()
                    .environmentObject(pomodoroModel)
            case .todayReview:
                TodayReviewView()
            case .summary:
                SummaryView()
            case .settings:
                SettingsView()
            case .none:
                ContentUnavailableView("Select a section", systemImage: "sidebar.left", description: Text("Choose a view from the sidebar"))
            }
        }
        .onAppear {
            createTodayTasksIfNeeded()
            scheduleReviewNotificationIfNeeded()
        }
    }

    // MARK: - Create Today's Tasks

    private func createTodayTasksIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        if rootDataRecords.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: today) && $0.createdTaskForToday }) {
            return
        }

        for plan in plans where plan.status != .finished && plan.status != .abandoned {
            let task = Task(
                name: plan.name,
                date: today,
                priority: plan.priority ?? .normal,
                isUrgent: plan.isUrgent,
                plan: plan
            )
            context.insert(task)
        }

        context.insert(RootData(date: today, createdTaskForToday: true))
    }

    // MARK: - Review Notification

    private func scheduleReviewNotificationIfNeeded() {
        guard let config = settings.first, config.enableReviewNotification else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["reviewNotification"])
            return
        }

        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let alreadyScheduled = requests.contains { $0.identifier == "reviewNotification" }
            guard !alreadyScheduled else { return }

            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
                guard granted else { return }

                let content = UNMutableNotificationContent()
                content.title = "Daily Review"
                content.body = "Don’t forget to reflect on your day ✍️"
                content.sound = .default

                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: config.reviewNotificationTime)

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

                let request = UNNotificationRequest(
                    identifier: "reviewNotification",
                    content: content,
                    trigger: trigger
                )

                UNUserNotificationCenter.current().add(request)
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {

    struct PreviewWrapper: View {
        let container: ModelContainer

        init() {
            container = try! ModelContainer(
                for: 
                    Plan.self,
                Task.self,
                RootData.self,
                AppSettings.self,
                Pomodoro.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )

            let ctx = container.mainContext
            let today = Calendar.current.startOfDay(for: .now)

            ctx.insert(
                Plan(
                    name: "Launch TaskFlow MVP",
                    status: .inProgress,
                    priority: .high,
                    isUrgent: true,
                    startTime: today,
                    estimatedEndTime: Calendar.current.date(byAdding: .day, value: 10, to: today)
                )
            )
            ctx.insert(
                Plan(
                    name: "Write Documentation",
                    status: .notStarted,
                    startTime: today
                )
            )

            ctx.insert(
                AppSettings()
            )
        }

        var body: some View {
            RootView()
                .environment(\.modelContext, container.mainContext)
                .frame(minWidth: 950, minHeight: 620)
                .previewDisplayName("🏠 Root View")
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
