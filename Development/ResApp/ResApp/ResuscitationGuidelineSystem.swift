import SwiftUI
import Combine

class SmartResuscitationGuidelineSystem: ObservableObject {
    @Published var currentGuideline: ResuscitationGuideline?
    @Published var showGuideline: Bool = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var isResuscitationEnded: Bool = false
    
    private var timer: AnyCancellable?
    private var currentStep = 1
    private var lastShockTime: Date?
    private var lastAdrenalineTime: Date?
    private var isShockableRhythm = false
    
    struct ResuscitationGuideline: Identifiable {
        let id = UUID()
        let message: String
        let duration: TimeInterval
    }
    
    func startGuideline() {
        currentStep = 1
        elapsedTime = 0
        isResuscitationEnded = false
        showGuideline(message: "Start CPR\n• Give oxygen\n• Attach monitor/defibrillator", duration: 5)
        startTimer()
    }
    
    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.elapsedTime += 1
                self?.checkTimeBasedActions()
            }
    }
    
    private func checkTimeBasedActions() {
        let twoMinuteInterval = 120.0
        
        if Int(elapsedTime) % Int(twoMinuteInterval) == 0 {
            checkRhythm()
        }
        
        if let lastAdrenaline = lastAdrenalineTime, Date().timeIntervalSince(lastAdrenaline) >= 180 {
            showGuideline(message: "Consider administering Adrenaline 1mg", duration: 5)
        }
    }
    
    func checkRhythm() {
        showGuideline(message: "Check rhythm\nIs rhythm shockable?", duration: 5)
    }
    
    func recordECGRhythm(_ rhythm: String) {
        if rhythm == "ROSC" {
            showGuideline(message: "ROSC achieved. Proceed to post-cardiac arrest care.", duration: 5)
            isResuscitationEnded = true
            stopGuideline()
        } else {
            isShockableRhythm = (rhythm == "VT/VF")
            if isShockableRhythm {
                showGuideline(message: "Shock advised", duration: 5)
            } else {
                showGuideline(message: "Continue CPR for 2 minutes", duration: 5)
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.showGuideline(message: "Give Adrenaline 1mg", duration: 5)
                }
            }
        }
    }
    
    func recordShock() {
        lastShockTime = Date()
        showGuideline(message: "Shock delivered. Resume CPR immediately for 2 minutes", duration: 5)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.showGuideline(message: "Give Adrenaline 1mg", duration: 5)
        }
    }
    
    func recordAdrenaline() {
        lastAdrenalineTime = Date()
        showGuideline(message: "Adrenaline administered. Continue CPR", duration: 5)
    }
    
    private func showGuideline(message: String, duration: TimeInterval) {
        currentGuideline = ResuscitationGuideline(message: message, duration: duration)
        showGuideline = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.showGuideline = false
        }
    }
    
    func stopGuideline() {
        timer?.cancel()
        timer = nil
        currentGuideline = nil
        showGuideline = false
    }
    
    func dismissCurrentGuideline() {
        showGuideline = false
    }
}
