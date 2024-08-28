import SwiftUI

struct ResuscitationSummaryView: View {
    @EnvironmentObject var resuscitationManager: ResuscitationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Resuscitation Summary")
                .font(.system(size: 28, weight: .bold))
            
            if let startTime = resuscitationManager.events.first?.timestamp {
                Text("Starting Time: \(formatDate(startTime))")
                    .font(.system(size: 20))
            }
            
            Divider()
            
            ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(resuscitationManager.events.reversed()) { event in
                        HStack {
                            Text(formatDate(event.timestamp))
                                .font(.system(size: 18, design: .monospaced))
                                .foregroundColor(.secondary)
                            eventIcon(for: event)
                            Text(eventDescription(event))
                                .font(.system(size: 18))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            
            Divider()
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Medication Counts:")
                    .font(.system(size: 20, weight: .bold))
                ForEach(medicationCounts.sorted(by: { $0.key < $1.key }), id: \.key) { medication, count in
                    Text("\(medication): \(count)")
                        .font(.system(size: 18))
                }
            }
        }
        .padding()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func eventIcon(for event: ResuscitationEvent) -> some View {
        switch event.type {
        case .ecgRhythm:
            return Image(systemName: "waveform.path.ecg")
        case .medication:
            return Image(systemName: "pill.fill")
        case .defibrillation:
            return Image(systemName: "bolt.heart.fill")
        case .alert:
            return Image(systemName: "exclamationmark.triangle.fill")
        }
    }
    
    private func eventDescription(_ event: ResuscitationEvent) -> String {
        switch event.type {
        case .ecgRhythm(let rhythm):
            return "ECG Rhythm: \(rhythm)"
        case .medication(let medication):
            return "Medication: \(medication)"
        case .defibrillation:
            return "Defibrillation performed"
        case .alert(let message):
            return "Alert: \(message)"
        }
    }
    
    private var medicationCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for event in resuscitationManager.events {
            if case .medication(let medication) = event.type {
                counts[medication, default: 0] += 1
            }
        }
        return counts
    }
}
