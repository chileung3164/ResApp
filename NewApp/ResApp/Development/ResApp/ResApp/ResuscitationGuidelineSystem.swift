import SwiftUI
import Combine

class SmartResuscitationGuidelineSystem: ObservableObject {
    @Published var currentGuideline: ResuscitationGuideline?
    @Published var showGuideline: Bool = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var isResuscitationEnded: Bool = false

    private var timer: AnyCancellable?
    private var lastAdrenalineTime: Date?
    private var currentECGRhythm: String = ""
    private var lastGuidlineDismissalTime: Date?

    struct ResuscitationGuideline: Identifiable {
        let id = UUID()
        let message: String
    }

    func startGuideline() {
        stopTimer()
        elapsedTime = 0
        isResuscitationEnded = false
        lastAdrenalineTime = Date()
        lastGuidlineDismissalTime = nil
        startTimer()
        print("Guideline system started")
    }

    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.elapsedTime += 1
                self?.checkTimeBasedActions()
            }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private func checkTimeBasedActions() {
        let currentTime = Date()

        if let lastAdrenaline = lastAdrenalineTime,
           currentTime.timeIntervalSince(lastAdrenaline) >= 180,
           currentGuideline == nil,
           (lastGuidlineDismissalTime == nil || currentTime.timeIntervalSince(lastGuidlineDismissalTime!) >= 60) {
            showGuideline(message: "Consider administering Adrenaline")
            print("Showing adrenaline guideline")
        }
    }

    func recordECGRhythm(_ rhythm: String) {
        currentECGRhythm = rhythm
        print("ECG Rhythm recorded: \(rhythm)")
    }

    func recordAdrenaline() {
        lastAdrenalineTime = Date()
        print("Adrenaline recorded")
        dismissCurrentGuideline()
    }

    private func showGuideline(message: String) {
        DispatchQueue.main.async {
            self.currentGuideline = ResuscitationGuideline(message: message)
            self.showGuideline = true
        }
        print("Showing guideline: \(message)")
    }

    func stopGuideline() {
        stopTimer()
        dismissCurrentGuideline()
        isResuscitationEnded = true
        print("Guideline system stopped")
    }

    func resetGuideline() {
        stopTimer()
        elapsedTime = 0
        lastAdrenalineTime = nil
        currentECGRhythm = ""
        lastGuidlineDismissalTime = nil
        dismissCurrentGuideline()
        isResuscitationEnded = false

        startGuideline()
    }

    func dismissCurrentGuideline() {
        DispatchQueue.main.async {
            self.showGuideline = false
            self.currentGuideline = nil
            self.lastGuidlineDismissalTime = Date()
        }
        print("Guideline dismissed")
    }
}
