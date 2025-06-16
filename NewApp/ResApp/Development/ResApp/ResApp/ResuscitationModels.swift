import SwiftUI

struct ResuscitationEvent: Identifiable {
    let id = UUID()
    enum EventType {
        case ecgRhythm(String)
        case medication(String)
        case defibrillation
        case alert(String)
    }
    
    let type: EventType
    let timestamp: Date
}

class ResuscitationManager: ObservableObject {
    @Published var isResuscitationStarted = false
    @Published var resuscitationStartTime: Date?
    @Published var events: [ResuscitationEvent] = []
    @Published var currentAlert: String?
    @Published var shouldShowAlert = false
    
    private var protocolManager = CPRProtocolManager()
    private var timer: Timer?
    private var currentInterval = 0
    
    var currentECGRhythm: String? {
        events.last {
            if case .ecgRhythm(let rhythm) = $0.type { return true }
            return false
        }.flatMap {
            if case .ecgRhythm(let rhythm) = $0.type { return rhythm }
            return nil
        }
    }
    
    func startResuscitation() {
        isResuscitationStarted = true
        resuscitationStartTime = Date()
        currentInterval = 0
        startProtocolTimer()
    }
    
    func endResuscitation() {
        isResuscitationStarted = false
        timer?.invalidate()
        timer = nil
        events = []
        resuscitationStartTime = nil
        currentAlert = nil
        shouldShowAlert = false
    }
    func performDefibrillation() {
           events.append(ResuscitationEvent(type: .defibrillation, timestamp: Date()))
           currentAlert = "Defibrillation performed"
           shouldShowAlert = true
       }
       
    
    private func startProtocolTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: protocolManager.intervalDuration, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.currentInterval += 1
            if self.currentInterval >= self.protocolManager.totalIntervals {
                self.timer?.invalidate()
                self.timer = nil
                return
            }
            self.checkProtocol()
        }
        checkProtocol() // Check immediately for the first interval
    }
    
    private func checkProtocol() {
        if let alert = protocolManager.getAlertForInterval(currentInterval, currentECGRhythm: currentECGRhythm) {
            currentAlert = alert
            shouldShowAlert = true
            events.append(ResuscitationEvent(type: .alert(alert), timestamp: Date()))
        }
        
        if protocolManager.shouldDefibrillate(ecgRhythm: currentECGRhythm) {
            currentAlert = "Conduct Defibrillation Biphasic 200J"
            shouldShowAlert = true
            events.append(ResuscitationEvent(type: .defibrillation, timestamp: Date()))
        }
    }
}
