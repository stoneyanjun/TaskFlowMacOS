import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query var settings: [AppSettings]

    @State private var workMinutes: Int = 25
    @State private var relaxMinutes: Int = 5
    @State private var enableReview: Bool = true
    @State private var reviewTime: Date = Calendar.current.date(
        bySettingHour: 18, minute: 15, second: 0, of: Date()
    )!

    var body: some View {
        Form {
            Section("Pomodoro") {
                Stepper("Work Minutes: \(workMinutes)", value: $workMinutes, in: 1 ... 25)
                Stepper("Relax Minutes: \(relaxMinutes)", value: $relaxMinutes, in: 1 ... 6)
            }
            .padding(.bottom)

            Section("Review Reminder") {
                Toggle("Notification for Review", isOn: $enableReview)
                DatePicker("Notification Time",
                           selection: $reviewTime,
                           displayedComponents: [.hourAndMinute])
            }
        }
        .padding()
        .navigationTitle("Settings")
        .onAppear { loadSettings() }
        // auto-save whenever any field changes
        .onChange(of: workMinutes) { _, _ in saveSettings() }
        .onChange(of: relaxMinutes) { _, _ in saveSettings() }
        .onChange(of: enableReview) { _, _ in saveSettings() }
        .onChange(of: reviewTime) { _, _ in saveSettings() }
        // still save on background
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background { saveSettings() }
        }
    }

    // MARK: - Persistence
    private func loadSettings() {
        guard let current = settings.first else { return }
        workMinutes  = current.pomodoroWorkMinutes
        relaxMinutes = current.pomodoroRelaxMinutes
        enableReview = current.enableReviewNotification
        reviewTime   = current.reviewNotificationTime
    }

    private func saveSettings() {
        let current = settings.first ?? {
            let new = AppSettings(
                pomodoroWorkMinutes: workMinutes,
                pomodoroRelaxMinutes: relaxMinutes,
                enableReviewNotification: enableReview,
                reviewNotificationTime: reviewTime
            )
            context.insert(new)
            return new
        }()
        current.pomodoroWorkMinutes = workMinutes
        current.pomodoroRelaxMinutes = relaxMinutes
        current.enableReviewNotification = enableReview
        current.reviewNotificationTime = reviewTime
        try? context.save() // ensure immediate persistence
    }
}


struct SettingsView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        let container: ModelContainer

        init() {
            container = try! ModelContainer(
                for: AppSettings.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let ctx = container.mainContext
            let defaultTime = Calendar.current.date(
                bySettingHour: 18, minute: 15, second: 0, of: Date()
            )!
            ctx.insert(
                AppSettings(
                    pomodoroWorkMinutes: 20,
                    pomodoroRelaxMinutes: 5,
                    enableReviewNotification: true,
                    reviewNotificationTime: defaultTime
                )
            )
        }
        var body: some View {
            SettingsView()
                .environment(\.modelContext, container.mainContext)
                .frame(width: 420, height: 300)
        }
    }
    static var previews: some View { PreviewWrapper() }
}
