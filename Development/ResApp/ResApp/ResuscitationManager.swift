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
    @Published var events: [ResuscitationEvent] = []
    @Published var resuscitationStartTime: Date?
    @Published var shouldShowAttentionEffect = false

    func startResuscitation() {
        isResuscitationStarted = true
        resuscitationStartTime = Date()
        events = []
    }

    func endResuscitation() {
        isResuscitationStarted = false
        events = []
        resuscitationStartTime = nil
    }

    func performDefibrillation() {
        events.append(ResuscitationEvent(type: .defibrillation, timestamp: Date()))
        triggerAttentionEffect()
    }

    func recordECGRhythm(_ rhythm: String) {
        events.append(ResuscitationEvent(type: .ecgRhythm(rhythm), timestamp: Date()))
        if rhythm == "VF" || rhythm == "VT" {
            triggerAttentionEffect()
        }
    }

    func administarMedication(_ medication: String) {
        events.append(ResuscitationEvent(type: .medication(medication), timestamp: Date()))
        if medication == "Epinephrine" {
            triggerAttentionEffect()
        }
    }

    private func triggerAttentionEffect() {
        shouldShowAttentionEffect = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.shouldShowAttentionEffect = false
        }
    }
}
