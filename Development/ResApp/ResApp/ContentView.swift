import SwiftUI

struct ContentView: View {
    @EnvironmentObject var resuscitationManager: ResuscitationManager
    
    var body: some View {
        if resuscitationManager.isResuscitationStarted {
            FunctionalButtonView()
        } else {
            StartView()
        }
    }
}

struct StartView: View {
    @EnvironmentObject var resuscitationManager: ResuscitationManager
    @State private var isShowingInfo = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    // App Logo
                    Image(systemName: "heart.text.square.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.white)
                        .padding()
                        .background(Circle().fill(Color.red))
                        .shadow(radius: 10)
                    
                    // App Title
                    Text("ResApp")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                    
                    // App Description
                    Text("Advanced Resuscitation Assistant for Medical Professionals")
                        .font(.title2)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Features List
                    VStack(alignment: .leading, spacing: 10) {
                        FeatureRow(icon: "waveform.path.ecg", text: "Real-time ECG Rhythm Monitoring")
                        FeatureRow(icon: "bolt.heart", text: "Guided Defibrillation Protocol")
                        FeatureRow(icon: "pills", text: "Medication Administration Tracking")
                        FeatureRow(icon: "timer", text: "Precise Resuscitation Timer")
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.2)))
                    
                    // Start Button
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
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 50)
                    
                    // Info Button
                    Button(action: {
                        isShowingInfo = true
                    }) {
                        Label("More Information", systemImage: "info.circle")
                            .foregroundColor(.white)
                    }
                    .sheet(isPresented: $isShowingInfo) {
                        InfoView()
                    }
                }
                .frame(width: min(geometry.size.width * 0.8, 600))
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.title2)
            Text(text)
                .foregroundColor(.white)
                .font(.body)
        }
    }
}

struct InfoView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("About ResApp")
                        .font(.title.bold())
                    
                    Text("ResApp is an advanced resuscitation assistant designed for medical professionals. It provides real-time guidance and tracking during critical resuscitation procedures.")
                    
                    Text("Key Features:")
                        .font(.title2.bold())
                    
                    VStack(alignment: .leading, spacing: 10) {
                        BulletPoint(text: "ECG Rhythm Monitoring")
                        BulletPoint(text: "Defibrillation Protocol")
                        BulletPoint(text: "Medication Tracking")
                        BulletPoint(text: "Resuscitation Timer")
                        BulletPoint(text: "Event Logging")
                        BulletPoint(text: "Summary Reports")
                    }
                    
                    Text("Disclaimer:")
                        .font(.title2.bold())
                    
                    Text("ResApp is a tool to assist trained medical professionals. It does not replace professional medical judgment. Always follow your institution's guidelines and protocols.")
                }
                .padding()
            }
            .navigationBarTitle("Information", displayMode: .inline)
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("•")
                .font(.title2)
            Text(text)
        }
    }
}
