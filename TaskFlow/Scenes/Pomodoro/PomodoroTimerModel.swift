
import AppKit
import AVFoundation
import SwiftData
import Combine

class PomodoroTimerModel: ObservableObject {
    @Published var selectedTask: Task?
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var isRelaxing = false
    @Published var timeRemaining: Int = 25 * 60
    @Published var statusText: String = "Idle"
    @Published var showFinishedAlert = false
    @Published var showRelaxPrompt = false

    var workMinutes: Int = 25
    var relaxMinutes: Int = 3

    private var timer: Timer?
    private var startDate: Date?
    private var context: ModelContext?
    private var audioPlayer: AVAudioPlayer?  // 🔊 Add audio player

    init(context: ModelContext? = nil) {
        self.context = context
    }

    func configure(with context: ModelContext, settings: AppSettings?) {
        self.context = context
        self.workMinutes = settings?.pomodoroWorkMinutes ?? 25
        self.relaxMinutes = settings?.pomodoroRelaxMinutes ?? 3

        if !isRunning {
            self.timeRemaining = workMinutes * 60
        }
    }

    func startPomodoro() {
        guard !isRunning else { return }
        isRelaxing = false
        timeRemaining = workMinutes * 60
        isRunning = true
        isPaused = false
        startDate = Date()
        updateStatusText()
        startTimer()
    }

    func startRelax() {
        isRelaxing = true
        timeRemaining = relaxMinutes * 60
        isRunning = true
        isPaused = false
        startDate = nil
        updateStatusText()
        startTimer()
    }

    func pause() {
        isPaused = true
        timer?.invalidate()
        updateStatusText()
    }

    func resume() {
        isPaused = false
        startTimer()
        updateStatusText()
    }

    func end(abandoned: Bool) {
        timer?.invalidate()
        isRunning = false
        isPaused = false

        if !isRelaxing, let start = startDate, let context = context {
            let finishDate = Date()
            let duration = Int(finishDate.timeIntervalSince(start)) / 60
            let record = Pomodoro(task: selectedTask, startDate: start, estimatedMinutes: workMinutes)
            record.endDate = finishDate
            record.status = abandoned ? .abandoned : .finished
            record.finishedMinutes = duration
            context.insert(record)
        }

        reset()
    }

    func reset() {
        isRunning = false
        isPaused = false
        isRelaxing = false
        startDate = nil
        timeRemaining = workMinutes * 60
        updateStatusText()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.timer?.invalidate()
                    self.end(abandoned: false)
                    self.playAlertSound()
                    if self.isRelaxing {
                        self.showRelaxPrompt = true
                    } else {
                        self.showFinishedAlert = true
                    }
                    self.updateStatusText()
                }
            }
        }
    }

    private func updateStatusText() {
        if !isRunning {
            statusText = "Idle"
        } else if isPaused {
            statusText = "Paused"
        } else {
            statusText = isRelaxing ? "Relaxing" : "Working"
        }
    }

    /// 🔊 Play custom `alert.wav` from app bundle
    private func playAlertSound() {
        guard let url = Bundle.main.url(forResource: "alert", withExtension: "wav") else {
            print("⚠️ alert.wav not found in bundle")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("⚠️ Error playing alert sound: \(error)")
        }
    }
}
