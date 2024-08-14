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
    
    var body: some View {
        VStack {
            Text("Welcome to use Resuscitation Apps!")
                .font(.largeTitle)
            
            Button("Start") {
                resuscitationManager.startResuscitation()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}
