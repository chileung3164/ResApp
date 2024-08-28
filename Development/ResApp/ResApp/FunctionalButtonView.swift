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
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                HStack(spacing: 0) {
                    // Left side: Timer, ECG, Defibrillation, and Medication
                    VStack {
                        HStack {
                            Text("Timer: \(formattedElapsedTime)")
                                .font(.system(size: 44, weight: .bold))
                            Spacer()
                            Button(action: {
                                showEndConfirmation = true
                            }) {
                                Text("END")
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 15)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(25)
                                    .font(.system(size: 24, weight: .bold))
                            }
                        }
                        .padding(.bottom, 20)

                        // ECG Rhythm buttons
                        HStack(spacing: 10) {
                            ECGButton(title: "VT/VF", action: {
                                guidelineSystem.recordECGRhythm("VT/VF")
                            })
                            ECGButton(title: "ROSC", action: {
                                guidelineSystem.recordECGRhythm("ROSC")
                                isROSCAchieved = true
                                showPostCareAlert = true
                            }, isSpecial: true)
                            ECGButton(title: "PEA/AS", action: {
                                guidelineSystem.recordECGRhythm("PEA/AS")
                            })
                        }
                        .frame(height: geometry.size.height * 0.18)

                        Spacer().frame(height: 30)

                        // Defibrillation Button
                        Button(action: {
                            resuscitationManager.performDefibrillation()
                            startOrResetDefibrillationCounter()
                        }) {
                            HStack {
                                Text(formattedDefibrillationTime)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text("Defibrillation")
                                Spacer()
                                Image(systemName: "bolt.heart.fill")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .frame(height: geometry.size.height * 0.18)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .font(.system(size: 36, weight: .bold))
                        }
                        .disabled(isROSCAchieved)

                        Spacer().frame(height: 30)

                        // Medication buttons
                        VStack(spacing: 15) {
                            HStack(spacing: 10) {
                                MedicationButton(title: "Adrenaline", action: {
                                    guidelineSystem.recordAdrenaline()
                                }, isSpecial: true)
                                MedicationButton(title: "Amiodarone", action: {
                                    // Add specific action for Amiodarone if needed
                                }, isSpecial: true)
                            }
                            .frame(height: geometry.size.height * 0.14)
                            HStack(spacing: 10) {
                                MedicationButton(title: "Lidocaine", action: {
                                    // Add specific action for Lidocaine if needed
                                })
                                MedicationButton(title: "Magnesium", action: {
                                    // Add specific action for Magnesium if needed
                                })
                                MedicationButton(title: "Atropine", action: {
                                    // Add specific action for Atropine if needed
                                })
                            }
                            .frame(height: geometry.size.height * 0.14)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                    .frame(width: geometry.size.width * 0.65)

                    // Right side: Resuscitation Summary
                    ResuscitationSummaryView()
                        .frame(width: geometry.size.width * 0.35)
                        .background(Color(UIColor.systemGray6))
                }

                // Guideline Overlay
                if guidelineSystem.showGuideline, let guideline = guidelineSystem.currentGuideline {
                    GuidelineOverlay(guideline: guideline) {
                        guidelineSystem.dismissCurrentGuideline()
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: guideline.id)
                    .onAppear {
                        playSound()
                    }
                }
            }
        }
        .onAppear {
            guidelineSystem.startGuideline()
            setupAudioPlayer()
            print("FunctionalButtonView appeared")
        }
        .onDisappear {
            guidelineSystem.stopGuideline()
            stopDefibrillationCounter()
            print("FunctionalButtonView disappeared")
        }
        .alert("End Resuscitation?", isPresented: $showEndConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("End Resuscitation", role: .destructive) {
                endResuscitation()
            }
        } message: {
            Text("Are you sure you want to end the resuscitation? This action cannot be undone.")
        }
        .alert(isPresented: $showPostCareAlert) {
            Alert(
                title: Text("ROSC Achieved"),
                message: Text("Proceed to post-cardiac arrest care. You can continue recording events."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var formattedElapsedTime: String {
        let minutes = Int(guidelineSystem.elapsedTime) / 60
        let seconds = Int(guidelineSystem.elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var formattedDefibrillationTime: String {
        let minutes = defibrillationCounter / 60
        let seconds = defibrillationCounter % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func endResuscitation() {
        guidelineSystem.stopGuideline()
        stopDefibrillationCounter()
        resuscitationManager.endResuscitation()
        resuscitationManager.isResuscitationStarted = false
    }

    private func setupAudioPlayer() {
        guard let soundURL = Bundle.main.url(forResource: "level-up-191997", withExtension: "mp3") else {
            print("Sound file 'level-up-191997.mp3' not found in the app bundle.")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            print("Audio player set up successfully.")
        } catch {
            print("Error setting up audio player: \(error.localizedDescription)")
        }
    }

    private func playSound() {
        audioPlayer?.play()
    }

    private func startOrResetDefibrillationCounter() {
        if defibrillationTimer == nil {
            // Start the timer if it's not running
            defibrillationCounter = 0
            defibrillationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                defibrillationCounter += 1
            }
        } else {
            // Reset the counter if the timer is already running
            defibrillationCounter = 0
        }
    }

    private func stopDefibrillationCounter() {
        defibrillationTimer?.invalidate()
        defibrillationTimer = nil
    }
}

struct ECGButton: View {
    let title: String
    let action: () -> Void
    var isSpecial: Bool = false
    @EnvironmentObject var resuscitationManager: ResuscitationManager

    var body: some View {
        Button(action: {
            resuscitationManager.events.append(ResuscitationEvent(type: .ecgRhythm(title), timestamp: Date()))
            action()
        }) {
            Text(title)
                .font(.system(size: isSpecial ? 36 : 32, weight: isSpecial ? .bold : .semibold))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isSpecial ? Color.blue.opacity(0.8) : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(15)
        }
    }
}

struct MedicationButton: View {
    let title: String
    let action: () -> Void
    var isSpecial: Bool = false
    @EnvironmentObject var resuscitationManager: ResuscitationManager

    var body: some View {
        Button(action: {
            resuscitationManager.events.append(ResuscitationEvent(type: .medication(title), timestamp: Date()))
            action()
        }) {
            Text(title)
                .font(.system(size: isSpecial ? 32 : 28, weight: isSpecial ? .bold : .semibold))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isSpecial ? Color.green.opacity(0.8) : Color.green)
                .foregroundColor(.white)
                .cornerRadius(15)
        }
    }
}

struct GuidelineOverlay: View {
    let guideline: SmartResuscitationGuidelineSystem.ResuscitationGuideline
    let dismissAction: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Text(guideline.message)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(30)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 15)
                    .onTapGesture {
                        dismissAction()
                    }
            }
            .frame(maxWidth: 500)
        }
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
