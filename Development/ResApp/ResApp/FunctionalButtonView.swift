import SwiftUI

struct FunctionalButtonView: View {
    @EnvironmentObject var resuscitationManager: ResuscitationManager
    @StateObject private var guidelineSystem = SmartResuscitationGuidelineSystem()
    @State private var showEndConfirmation = false
    @State private var showPostCareAlert = false
    @State private var isROSCAchieved = false
    @State private var showAttentionEffect = false
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
                            ECGButton(title: "VT/VF", action: { guidelineSystem.recordECGRhythm("VT/VF") })
                            ECGButton(title: "ROSC", action: {
                                guidelineSystem.recordECGRhythm("ROSC")
                                isROSCAchieved = true
                                showPostCareAlert = true
                            }, isSpecial: true)
                            ECGButton(title: "PEA/AS", action: { guidelineSystem.recordECGRhythm("PEA/AS") })
                        }
                        .frame(height: geometry.size.height * 0.18)

                        Spacer().frame(height: 30)

                        // Defibrillation Button
                        Button(action: {
                            resuscitationManager.performDefibrillation()
                            guidelineSystem.recordShock()
                        }) {
                            HStack {
                                Image(systemName: "bolt.heart.fill")
                                Text("Defibrillation")
                            }
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

                if guidelineSystem.showGuideline, let guideline = guidelineSystem.currentGuideline {
                    GuidelineOverlay(guideline: guideline, dismissAction: {
                        guidelineSystem.dismissCurrentGuideline()
                    })
                }
                if showAttentionEffect {
                    Color.red.opacity(0.3)
                         .edgesIgnoringSafeArea(.all)
                         .transition(.opacity)
                         .animation(.easeInOut(duration: 0.5).repeatCount(3), value: showAttentionEffect)
                }
            }
        }
        .onAppear {
                    guidelineSystem.startGuideline()
                }
                .onDisappear {
                    guidelineSystem.stopGuideline()
                }
                .alert(isPresented: $showEndConfirmation) {
                    Alert(
                        title: Text("End Resuscitation?"),
                        message: Text("Are you sure you want to end the resuscitation? This action cannot be undone."),
                        primaryButton: .destructive(Text("End Resuscitation")) {
                            endResuscitation()
                        },
                        secondaryButton: .cancel()
                    )
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

    private func endResuscitation() {
        guidelineSystem.stopGuideline()
        resuscitationManager.endResuscitation()
        DispatchQueue.main.async {
            self.presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func showAttentionSeekingEffect() {
            showAttentionEffect = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showAttentionEffect = false
            }
        }

    // Helper Views
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
                    .onTapGesture {
                        dismissAction()
                    }

                VStack {
                    Text(guideline.message)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: 300)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: guideline.id)
        }
    }
}
