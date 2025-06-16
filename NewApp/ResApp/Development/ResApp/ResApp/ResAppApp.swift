import SwiftUI

@main
struct ResAppApp: App {
    @StateObject private var resuscitationManager = ResuscitationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(resuscitationManager)
        }
    }
}
