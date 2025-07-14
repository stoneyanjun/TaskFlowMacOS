import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase)   private var scenePhase
    @Query var settings: [AppSettings]

    @State private var workMinutes: Int = 25
    @State private var relaxMinutes: Int = 5
    @State private var enableReview: Bool = true
    @State private var reviewTime: Date = Calendar.current.date(
        bySettingHour: 18, minute: 15, second: 0, of: Date()
    )!

    // ───────── UI ─────────
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
        .onDisappear { saveSettings() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background { saveSettings() }
        }
        Spacer()
    }

    // ───────── Persistence ─────────
    private func loadSettings() {
        guard let current = settings.first else { return }
        workMinutes  = current.pomodoroWorkMinutes
        relaxMinutes = current.pomodoroRelaxMinutes
        enableReview = current.enableReviewNotification
        reviewTime   = current.reviewNotificationTime
    }

    private func saveSettings() {
        if let existing = settings.first {
            existing.pomodoroWorkMinutes    = workMinutes
            existing.pomodoroRelaxMinutes   = relaxMinutes
            existing.enableReviewNotification = enableReview
            existing.reviewNotificationTime = reviewTime
        } else {
            context.insert(
                AppSettings(
                    pomodoroWorkMinutes:  workMinutes,
                    pomodoroRelaxMinutes: relaxMinutes,
                    enableReviewNotification: enableReview,
                    reviewNotificationTime:  reviewTime
                )
            )
        }
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
