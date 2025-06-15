import SwiftUI
import AVFoundation

struct FunctionalButtonView: View {
    @EnvironmentObject var resuscitationManager: ResuscitationManager
    @StateObject private var guidelineSystem = SmartResuscitationGuidelineSystem()
    @State private var showEndConfirmation = false
    @State private var showPostCareAlert = false
    @State private var isROSCAchieved = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var defibrillationCounter: Int = 0
    @State private var defibrillationTimer: Timer?
    @State private var cprTimer: Timer?
    @State private var cprCounter: Int = 0
    @State private var cprCycleCounter: Int = 0
    @State private var selectedEnergy: Int = 200
    @State private var patientOutcome: PatientOutcome = .none
    @State private var adrenalineDoses: Int = 0
    @State private var amiodaroneDoses: Int = 0
    @Environment(\.presentationMode) var presentationMode

    enum PatientOutcome {
        case none, alive, death
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Main Control Panel (Left Side)
                VStack(spacing: geometry.size.height * 0.008) {
                    // Header with Timer and Patient Outcome
                    headerSection(geometry: geometry)
                        .frame(height: geometry.size.height * 0.14)
                    
                    // Rhythm Section with Icon
                    rhythmSection(geometry: geometry)
                        .frame(height: geometry.size.height * 0.15)
                    
                    // Energy Selection Section with Icon
                    energySection(geometry: geometry)
                        .frame(height: geometry.size.height * 0.13)
                    
                    // CPR Section with Icon - Yellow Theme
                    cprSection(geometry: geometry)
                        .frame(height: geometry.size.height * 0.13)
                    
                    // Medication Section with Icon
                    medicationSection(geometry: geometry)
                        .frame(height: geometry.size.height * 0.15)
                    
                    // Other Events Section with Icon
                    otherEventsSection(geometry: geometry)
                        .frame(height: geometry.size.height * 0.13)
                    
                    Spacer()
                }
                .padding(.horizontal, geometry.size.width * 0.015)
                .padding(.vertical, geometry.size.height * 0.015)
                .frame(width: geometry.size.width * 0.75)
                
                // Resuscitation Record (Right Side)
                ResuscitationRecordView()
                    .frame(width: geometry.size.width * 0.25)
                    .background(Color(UIColor.systemGray6))
            }
        }
        .onAppear {
            guidelineSystem.startGuideline()
            setupAudioPlayer()
            startCPRTimer()
        }
        .onDisappear {
            guidelineSystem.stopGuideline()
            stopAllTimers()
            stopSound()
        }
        .alert("End Resuscitation?", isPresented: $showEndConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("End Resuscitation", role: .destructive) {
                endResuscitation()
            }
        } message: {
            Text("Are you sure you want to end the resuscitation? This action cannot be undone.")
        }
    }
    
    private func headerSection(geometry: GeometryProxy) -> some View {
        HStack {
            // Timer - Most Critical Information
            HStack(spacing: geometry.size.width * 0.015) {
                Image(systemName: "stopwatch")
                    .font(.system(size: geometry.size.width * 0.022, weight: .bold))
                    .foregroundColor(.brown)
                Text(formattedElapsedTime)
                    .font(.system(size: geometry.size.width * 0.038, weight: .black, design: .monospaced))
                    .foregroundColor(.brown)
            }
            .padding(.horizontal, geometry.size.width * 0.02)
            .padding(.vertical, geometry.size.height * 0.012)
            .background(Color.brown.opacity(0.15))
            .cornerRadius(geometry.size.width * 0.012)
            
            Spacer()
            
            // Patient Outcome
            VStack(spacing: geometry.size.height * 0.008) {
                Text("Patient Outcome")
                    .font(.system(size: geometry.size.width * 0.016, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: geometry.size.width * 0.012) {
                    Button("ALIVE") {
                        patientOutcome = .alive
                    }
                    .buttonStyle(OutcomeButtonStyle(isSelected: patientOutcome == .alive, color: .green, geometry: geometry))
                    
                    Button("DEATH") {
                        patientOutcome = .death
                    }
                    .buttonStyle(OutcomeButtonStyle(isSelected: patientOutcome == .death, color: .red, geometry: geometry))
                }
            }
        }
        .padding(.horizontal, geometry.size.width * 0.012)
    }
    
    private func rhythmSection(geometry: GeometryProxy) -> some View {
        HStack(spacing: geometry.size.width * 0.018) {
            // ECG Icon
            VStack {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: geometry.size.width * 0.022, weight: .bold))
                    .foregroundColor(.blue)
                    .frame(width: geometry.size.width * 0.04, height: geometry.size.width * 0.04)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(geometry.size.width * 0.01)
            }
            
            // Rhythm Buttons
            HStack(spacing: geometry.size.width * 0.01) {
                RhythmButton(title: "pVT/VF", color: .blue, geometry: geometry) {
                    recordECGRhythm("pVT/VF")
                }
                
                RhythmButton(title: "PEA/AS", color: .blue, geometry: geometry) {
                    recordECGRhythm("PEA/AS")
                }
                
                RhythmButton(title: "ROSC", subtitle: formattedDefibrillationTime, color: Color(red: 0.2, green: 0.3, blue: 0.7), geometry: geometry) {
                    recordECGRhythm("ROSC")
                    isROSCAchieved = true
                    showPostCareAlert = true
                }
            }
        }
        .padding(.horizontal, geometry.size.width * 0.012)
    }
    
    private func energySection(geometry: GeometryProxy) -> some View {
        HStack(spacing: geometry.size.width * 0.018) {
            // Lightning Icon
            VStack {
                Image(systemName: "bolt.fill")
                    .font(.system(size: geometry.size.width * 0.022, weight: .bold))
                    .foregroundColor(.red)
                    .frame(width: geometry.size.width * 0.04, height: geometry.size.width * 0.04)
                    .background(Color.red.opacity(0.15))
                    .cornerRadius(geometry.size.width * 0.01)
            }
            
            // Energy Buttons - Clean professional style
            HStack(spacing: geometry.size.width * 0.008) {
                EnergyButton(energy: 100, type: "Biphasic", isSelected: selectedEnergy == 100, geometry: geometry) {
                    selectedEnergy = 100
                }
                EnergyButton(energy: 150, type: "Biphasic", isSelected: selectedEnergy == 150, geometry: geometry) {
                    selectedEnergy = 150
                }
                EnergyButton(energy: 200, type: "Biphasic", isSelected: selectedEnergy == 200, geometry: geometry) {
                    selectedEnergy = 200
                }
                EnergyButton(energy: 240, type: "Biphasic", isSelected: selectedEnergy == 240, geometry: geometry) {
                    selectedEnergy = 240
                }
                EnergyButton(energy: 360, type: "Monophasic", isSelected: selectedEnergy == 360, geometry: geometry) {
                    selectedEnergy = 360
                }
            }
        }
        .padding(.horizontal, geometry.size.width * 0.012)
    }
    
    private func cprSection(geometry: GeometryProxy) -> some View {
        HStack(spacing: geometry.size.width * 0.018) {
            // CPR Icon - Yellow theme
            VStack {
                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: geometry.size.width * 0.02, weight: .bold))
                    .foregroundColor(.orange)
                    .frame(width: geometry.size.width * 0.04, height: geometry.size.width * 0.04)
                    .background(Color.yellow.opacity(0.15))
                    .cornerRadius(geometry.size.width * 0.01)
            }
            
            // CPR Single Row Layout - Clean yellow background
            HStack(spacing: geometry.size.width * 0.02) {
                Text("CPR")
                    .font(.system(size: geometry.size.width * 0.028, weight: .black))
                    .foregroundColor(.black)
                
                Text(formattedCPRTime)
                    .font(.system(size: geometry.size.width * 0.025, weight: .black, design: .monospaced))
                    .foregroundColor(.black)
                
                Spacer()
                
                HStack(spacing: geometry.size.width * 0.015) {
                    Text("(cycle) now: \(cprCycleCounter)")
                        .font(.system(size: geometry.size.width * 0.016, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text("(cycle) done:")
                        .font(.system(size: geometry.size.width * 0.016, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, geometry.size.width * 0.02)
            .padding(.vertical, geometry.size.height * 0.012)
            .frame(maxWidth: .infinity)
            .background(Color.yellow.opacity(0.9))
            .cornerRadius(geometry.size.width * 0.01)
        }
        .padding(.horizontal, geometry.size.width * 0.012)
    }
    
    private func medicationSection(geometry: GeometryProxy) -> some View {
        HStack(spacing: geometry.size.width * 0.018) {
            // Syringe Icon
            VStack {
                Image(systemName: "syringe")
                    .font(.system(size: geometry.size.width * 0.022, weight: .bold))
                    .foregroundColor(.green)
                    .frame(width: geometry.size.width * 0.04, height: geometry.size.width * 0.04)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(geometry.size.width * 0.01)
            }
            
            // Medication Buttons - Dose counter INSIDE like prototype
            HStack(spacing: geometry.size.width * 0.01) {
                MedicationButtonView(
                    title: "Adrenaline",
                    subtitle: "1mg",
                    doses: adrenalineDoses,
                    color: .green,
                    geometry: geometry
                ) {
                    adrenalineDoses += 1
                    recordMedication("Adrenaline 1mg")
                }
                
                MedicationButtonView(
                    title: "Amiodarone",
                    subtitle: "1st 300mg\n2nd 150mg",
                    doses: amiodaroneDoses,
                    color: .green,
                    geometry: geometry
                ) {
                    amiodaroneDoses += 1
                    let dose = amiodaroneDoses == 1 ? "300mg" : "150mg"
                    recordMedication("Amiodarone \(dose)")
                }
                
                Button("Other\nMedication") {
                    // Handle other medication
                }
                .font(.system(size: geometry.size.width * 0.016, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.green.opacity(0.9))
                .cornerRadius(geometry.size.width * 0.01)
            }
        }
        .padding(.horizontal, geometry.size.width * 0.012)
    }
    
    private func otherEventsSection(geometry: GeometryProxy) -> some View {
        HStack(spacing: geometry.size.width * 0.018) {
            // Other Icon
            VStack {
                Text("Other")
                    .font(.system(size: geometry.size.width * 0.012, weight: .bold))
                    .foregroundColor(.gray)
                    .frame(width: geometry.size.width * 0.04, height: geometry.size.width * 0.04)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(geometry.size.width * 0.01)
            }
            
            // Event Buttons
            HStack(spacing: geometry.size.width * 0.01) {
                Button("Intubation") {
                    recordEvent("Intubation")
                }
                .buttonStyle(EventButtonStyle(geometry: geometry))
                
                Button("Other Events") {
                    recordEvent("Other Event")
                }
                .buttonStyle(EventButtonStyle(geometry: geometry))
            }
        }
        .padding(.horizontal, geometry.size.width * 0.012)
    }
    
    // MARK: - Helper Functions
    
    private var formattedElapsedTime: String {
        let minutes = Int(guidelineSystem.elapsedTime) / 60
        let seconds = Int(guidelineSystem.elapsedTime) % 60
        return String(format: "%02d'%02d\"", minutes, seconds)
    }
    
    private var formattedDefibrillationTime: String {
        let minutes = defibrillationCounter / 60
        let seconds = defibrillationCounter % 60
        return String(format: "%02d'%02d\"", minutes, seconds)
    }
    
    private var formattedCPRTime: String {
        let minutes = cprCounter / 60
        let seconds = cprCounter % 60
        return String(format: "%02d'%02d\"", minutes, seconds)
    }
    
    private func recordECGRhythm(_ rhythm: String) {
        resuscitationManager.events.append(ResuscitationEvent(type: .ecgRhythm(rhythm), timestamp: Date()))
        guidelineSystem.recordECGRhythm(rhythm)
        
        if rhythm == "ROSC" {
            stopAllTimers()
        } else {
            startOrResetDefibrillationTimer()
        }
    }
    
    private func recordMedication(_ medication: String) {
        resuscitationManager.events.append(ResuscitationEvent(type: .medication(medication), timestamp: Date()))
    }
    
    private func recordEvent(_ event: String) {
        resuscitationManager.events.append(ResuscitationEvent(type: .alert(event), timestamp: Date()))
    }
    
    private func startCPRTimer() {
        cprTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            cprCounter += 1
            if cprCounter % 120 == 0 { // 2 minutes cycle
                cprCycleCounter += 1
            }
        }
    }
    
    private func startOrResetDefibrillationTimer() {
        defibrillationTimer?.invalidate()
        defibrillationCounter = 0
        defibrillationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            defibrillationCounter += 1
        }
    }
    
    private func stopAllTimers() {
        cprTimer?.invalidate()
        cprTimer = nil
        defibrillationTimer?.invalidate()
        defibrillationTimer = nil
    }
    
    private func endResuscitation() {
        guidelineSystem.stopGuideline()
        stopAllTimers()
        resuscitationManager.endResuscitation()
        resuscitationManager.isResuscitationStarted = false
    }
    
    private func setupAudioPlayer() {
        guard let soundURL = Bundle.main.url(forResource: "buzzer", withExtension: "wav") else {
            print("Sound file 'buzzer.wav' not found in the app bundle.")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.prepareToPlay()
        } catch {
            print("Error setting up audio player: \(error.localizedDescription)")
        }
    }
    
    private func playLoopingSound() {
        audioPlayer?.play()
    }
    
    private func stopSound() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
    }
}

// MARK: - Custom Button Styles

struct OutcomeButtonStyle: ButtonStyle {
    let isSelected: Bool
    let color: Color
    let geometry: GeometryProxy
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: geometry.size.width * 0.018, weight: .bold))
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, geometry.size.width * 0.025)
            .padding(.vertical, geometry.size.height * 0.01)
            .background(isSelected ? color : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: geometry.size.width * 0.015)
                    .stroke(color, lineWidth: 2.5)
            )
            .cornerRadius(geometry.size.width * 0.015)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct EventButtonStyle: ButtonStyle {
    let geometry: GeometryProxy
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: geometry.size.width * 0.018, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.8))
            .cornerRadius(geometry.size.width * 0.01)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Custom Views

struct RhythmButton: View {
    let title: String
    var subtitle: String = ""
    let color: Color
    let geometry: GeometryProxy
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: geometry.size.height * 0.006) {
                Text(title)
                    .font(.system(size: geometry.size.width * 0.022, weight: .bold))
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: geometry.size.width * 0.016, weight: .medium))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(color)
            .cornerRadius(geometry.size.width * 0.01)
        }
    }
}

struct EnergyButton: View {
    let energy: Int
    let type: String
    let isSelected: Bool
    let geometry: GeometryProxy
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: geometry.size.height * 0.008) {
                Text(type)
                    .font(.system(size: geometry.size.width * 0.016, weight: .semibold))
                Text("\(energy)J")
                    .font(.system(size: geometry.size.width * 0.024, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isSelected ? Color.red : Color.red.opacity(0.9))
            .cornerRadius(geometry.size.width * 0.01)
            .overlay(
                RoundedRectangle(cornerRadius: geometry.size.width * 0.01)
                    .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
            )
        }
    }
}

struct MedicationButtonView: View {
    let title: String
    let subtitle: String
    let doses: Int
    let color: Color
    let geometry: GeometryProxy
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: geometry.size.height * 0.008) {
                HStack {
                    VStack(alignment: .leading, spacing: geometry.size.height * 0.004) {
                        Text(title)
                            .font(.system(size: geometry.size.width * 0.018, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(subtitle)
                            .font(.system(size: geometry.size.width * 0.014, weight: .medium))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Spacer()
                    
                    // Dose counter INSIDE button - like prototype
                    VStack(spacing: geometry.size.height * 0.002) {
                        Text("dose")
                            .font(.system(size: geometry.size.width * 0.01, weight: .medium))
                        Text("\(doses)")
                            .font(.system(size: geometry.size.width * 0.016, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, geometry.size.width * 0.01)
                    .padding(.vertical, geometry.size.height * 0.006)
                    .background(Color.white.opacity(0.25))
                    .cornerRadius(geometry.size.width * 0.008)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, geometry.size.width * 0.015)
            .padding(.vertical, geometry.size.height * 0.01)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(color.opacity(0.9))
            .cornerRadius(geometry.size.width * 0.01)
        }
    }
}

struct ResuscitationRecordView: View {
    @EnvironmentObject var resuscitationManager: ResuscitationManager
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                Text("RESUSCITATION RECORD")
                    .font(.system(size: geometry.size.width * 0.065, weight: .bold))
                    .padding(.horizontal, geometry.size.width * 0.06)
                    .padding(.vertical, geometry.size.height * 0.018)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.2))
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: geometry.size.height * 0.01) {
                        ForEach(resuscitationManager.events.reversed()) { event in
                            EventRowView(event: event, geometry: geometry)
                        }
                    }
                    .padding(.horizontal, geometry.size.width * 0.05)
                    .padding(.top, geometry.size.height * 0.015)
                }
            }
        }
        .background(Color.white)
    }
}

struct EventRowView: View {
    let event: ResuscitationEvent
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(alignment: .leading, spacing: geometry.size.height * 0.006) {
            HStack {
                Text(eventTitle)
                    .font(.system(size: geometry.size.width * 0.055, weight: .semibold))
                Spacer()
                Text(timeFormatter.string(from: event.timestamp))
                    .font(.system(size: geometry.size.width * 0.045, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            if let subtitle = eventSubtitle {
                Text(subtitle)
                    .font(.system(size: geometry.size.width * 0.045, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, geometry.size.height * 0.01)
        .padding(.horizontal, geometry.size.width * 0.04)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(geometry.size.width * 0.025)
    }
    
    private var eventTitle: String {
        switch event.type {
        case .ecgRhythm(let rhythm):
            return "ECG: \(rhythm)"
        case .medication(let med):
            return "Med: \(med)"
        case .defibrillation:
            return "Defibrillation"
        case .alert(let alert):
            return alert
        }
    }
    
    private var eventSubtitle: String? {
        switch event.type {
        case .defibrillation:
            return "Energy delivered"
        default:
            return nil
        }
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}
