import SwiftUI

struct FunctionalButtonView: View {
    @EnvironmentObject var resuscitationManager: ResuscitationManager
    @State private var currentTime = Date()
    @State private var timer: Timer?
    @State private var showEndConfirmation = false
    
    var body: some View {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Left side: ECG, Defibrillation, and Medication
                    VStack(spacing: 20) {
                        // Timer and END button
                        HStack {
                            Text("Timer: \(formattedElapsedTime)")
                                .font(.system(size: 28, weight: .bold))
                            Spacer()
                            Button(action: {
                                showEndConfirmation = true  // Show confirmation instead of ending directly
                            }) {
                                HStack {
                                    Image(systemName: "stop.circle.fill")
                                    Text("END")
                                }
                                .padding(.horizontal, 30)
                                .padding(.vertical, 15)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                                .font(.system(size: 24, weight: .bold))
                            }
                        }
                        .padding(.horizontal)
                    
                    // ECG Rhythm (title removed)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ECGButton(title: "AS", icon: "waveform.path.ecg")
                        ECGButton(title: "PEA", icon: "waveform.path.ecg.rectangle")
                        ECGButton(title: "VT", icon: "waveform.path.ecg.rectangle.fill")
                        ECGButton(title: "VF", icon: "waveform.path")
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Defibrillation Button
                    Button(action: {
                        resuscitationManager.performDefibrillation()
                    }) {
                        HStack {
                            Image(systemName: "bolt.heart.fill")
                            Text("Defibrillation")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red) // Changed from orange to red
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .font(.system(size: 28, weight: .bold))
                    }
                    
                    // Medication (title removed)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        MedicationButton(title: "Epinephrine", icon: "syringe.fill")
                        MedicationButton(title: "Amiodarone", icon: "pill.fill")
                        MedicationButton(title: "Lidocaine", icon: "cross.vial.fill")
                        MedicationButton(title: "Magnesium", icon: "atom")
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(width: geometry.size.width * 0.6)
                .padding(.vertical)
                
                // Right side: Resuscitation Summary
                ResuscitationSummaryView()
                    .frame(width: geometry.size.width * 0.4)
                    .background(Color.gray.opacity(0.1))
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .alert(isPresented: $showEndConfirmation) {
                    Alert(
                        title: Text("End Resuscitation?"),
                        message: Text("Are you sure you want to end the resuscitation? This action cannot be undone."),
                        primaryButton: .destructive(Text("End Resuscitation")) {
                            resuscitationManager.endResuscitation()
                        },
                        secondaryButton: .cancel()
                    )
                }
    }
    
    private var formattedElapsedTime: String {
        guard let startTime = resuscitationManager.resuscitationStartTime else { return "00:00" }
        let elapsed = Int(currentTime.timeIntervalSince(startTime))
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            currentTime = Date()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct ECGButton: View {
    let title: String
    let icon: String
    @EnvironmentObject var resuscitationManager: ResuscitationManager
    
    var body: some View {
        Button(action: {
            resuscitationManager.events.append(ResuscitationEvent(type: .ecgRhythm(title), timestamp: Date()))
        }) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 40))
                Text(title)
                    .font(.system(size: 24, weight: .bold))
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(15)
        }
    }
}

struct MedicationButton: View {
    let title: String
    let icon: String
    @EnvironmentObject var resuscitationManager: ResuscitationManager
    
    var body: some View {
        Button(action: {
            resuscitationManager.events.append(ResuscitationEvent(type: .medication(title), timestamp: Date()))
        }) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 40))
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .multilineTextAlignment(.center)
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(15)
        }
    }
}

struct ResuscitationSummaryView: View {
    @EnvironmentObject var resuscitationManager: ResuscitationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Resuscitation Summary")
                .font(.system(size: 28, weight: .bold))
            
            if let startTime = resuscitationManager.resuscitationStartTime {
                Text("Starting Time: \(formatDate(startTime))")
                    .font(.system(size: 20))
            }
            
            Divider()
            
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(resuscitationManager.events.reversed(), id: \.id) { event in
                        HStack {
                            Text(formatDate(event.timestamp))
                                .font(.system(size: 18, design: .monospaced))
                                .foregroundColor(.secondary)
                            eventIcon(for: event)
                            Text(eventDescription(event))
                                .font(.system(size: 18))
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(8)
                    }
                }
                .padding(.trailing, 10)
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
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
