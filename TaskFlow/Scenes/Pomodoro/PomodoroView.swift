
import SwiftUI
import SwiftData

struct PomodoroView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject var pomodoroModel: PomodoroTimerModel
    @Query var tasks: [Task]
    @Query var settings: [AppSettings]

    @State private var showTaskSelector = false

    private var formattedTime: String {
        let minutes = pomodoroModel.timeRemaining / 60
        let seconds = pomodoroModel.timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var progress: CGFloat {
        let total = pomodoroModel.isRelaxing ? pomodoroModel.relaxMinutes : pomodoroModel.workMinutes
        return 1 - CGFloat(pomodoroModel.timeRemaining) / CGFloat(total * 60)
    }

    var body: some View {
        VStack(spacing: 45) {
            HStack {
                Spacer()
                Button {
                    showTaskSelector = true
                } label: {
                    HStack(spacing: 8) {
                        Text(pomodoroModel.selectedTask?.name ?? (pomodoroModel.isRelaxing ? "Relax Time" : "Focus"))
                            .font(.title2)
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .foregroundStyle(.gray)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(MediumLargeButtonStyle())
                Spacer()
            }

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                    .frame(width: 300, height: 300)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(pomodoroModel.isRelaxing ? .green : .blue, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 300, height: 300)

                VStack {
                    Text(formattedTime)
                        .font(.system(size: 60, weight: .medium))
                    Text(pomodoroModel.statusText)
                        .foregroundColor(.gray)
                        .font(.title3)
                }
            }

            HStack(spacing: 20) {
                if !pomodoroModel.isRunning {
                    Button("Start") { pomodoroModel.startPomodoro() }
                        .buttonStyle(MediumLargeButtonStyle())
                } else if pomodoroModel.isPaused {
                    Button("Continue") { pomodoroModel.resume() }
                        .buttonStyle(MediumLargeButtonStyle())
                } else {
                    Button("Pause") { pomodoroModel.pause() }
                        .buttonStyle(MediumLargeButtonStyle())
                }

                Button("End") {
                    pomodoroModel.end(abandoned: true)
                }
                .buttonStyle(MediumLargeButtonStyle())
            }
            .font(.title2)
            .padding(.horizontal, 30)
        }
        .padding()
        .onAppear {
            pomodoroModel.configure(with: context, settings: settings.first)
            if pomodoroModel.selectedTask == nil {
                pomodoroModel.selectedTask = tasks.first(where: { Calendar.current.isDateInToday($0.date) })
            }
        }
        .sheet(isPresented: $showTaskSelector) {
            TaskSelectionSheet(
                tasks: tasks.filter {
                    Calendar.current.isDateInToday($0.date) && !$0.isFinished
                }
            ) { task in
                pomodoroModel.selectedTask = task
                showTaskSelector = false
            }
        }
        .alert("Pomodoro Finished!", isPresented: $pomodoroModel.showFinishedAlert) {
            Button("Relax") { pomodoroModel.startRelax() }
            Button("Skip") { pomodoroModel.reset() }
        }
        .alert("Relax Finished!", isPresented: $pomodoroModel.showRelaxPrompt) {
            Button("OK") { pomodoroModel.reset() }
        }
    }
}


struct PomodoroView_Previews: PreviewProvider {

    struct PreviewWrapper: View {
        @StateObject private var timerModel = PomodoroTimerModel()

        // 内存容器
        let container: ModelContainer

        init() {
            container = try! ModelContainer(
                for: Task.self, Pomodoro.self, AppSettings.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )

            let ctx = container.mainContext
            let today = Calendar.current.startOfDay(for: .now)

            ctx.insert(
                Task(
                    name: "Write Documentation",
                    date: today,
                    priority: .high,
                    isUrgent: true
                )
            )
            ctx.insert(
                Task(
                    name: "Code Review",
                    date: today
                )
            )

            ctx.insert(
                AppSettings()
            )
        }

        var body: some View {
            PomodoroView()
                .environment(\.modelContext, container.mainContext)
                .environmentObject(timerModel)
                .frame(width: 500, height: 650)
                .previewDisplayName("🍅 Pomodoro Timer")
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
