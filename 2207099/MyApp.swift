import SwiftUI
import FirebaseCore

@main
struct MyApp: App {
    @StateObject private var auth = AuthManager()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isSignedIn {
                    ContentView()
                } else {
                    AuthView()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: auth.isSignedIn)
            .environmentObject(auth)
            .tint(.indigo)
        }
    }
}
