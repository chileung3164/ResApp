import SwiftUI

struct ContentView: View {
    @EnvironmentObject var resuscitationManager: ResuscitationManager

    var body: some View {
        Group {
            if resuscitationManager.isResuscitationStarted {
                FunctionalButtonView()
            } else {
                StartView()
            }
        }
        .animation(.default, value: resuscitationManager.isResuscitationStarted)
    }
}

struct StartView: View {
    @EnvironmentObject var resuscitationManager: ResuscitationManager
    @State private var isShowingInfo = false

    var body: some View {
        VStack(spacing: 30) {
            Text("ResApp")
                .font(.system(size: 48, weight: .bold, design: .rounded))

            Text("Advanced Resuscitation Assistant for Medical Professionals")
                .font(.title2)
                .multilineTextAlignment(.center)

            Button(action: {
                resuscitationManager.startResuscitation()
            }) {
                Text("Start Resuscitation")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 50)

            Button("More Information") {
                isShowingInfo = true
            }
            .sheet(isPresented: $isShowingInfo) {
                InfoView()
            }
        }
        .padding()
    }
}

struct InfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("About ResApp")
                    .font(.title.bold())

                Text("ResApp is an advanced resuscitation assistant designed for medical professionals. It provides real-time guidance and tracking during critical resuscitation procedures.")

                Text("Key Features:")
                    .font(.title2.bold())

                VStack(alignment: .leading, spacing: 10) {
                    Text("• ECG Rhythm Monitoring")
                    Text("• Defibrillation Protocol")
                    Text("• Medication Tracking")
                    Text("• Resuscitation Timer")
                    Text("• Event Logging")
                    Text("• Guideline-based Assistance")
                }

                Text("Disclaimer: ResApp is a tool to assist trained medical professionals. It does not replace professional medical judgment. Always follow your institution's guidelines and protocols.")
            }
            .padding()
        }
        .navigationBarTitle("Information", displayMode: .inline)
    }
}
