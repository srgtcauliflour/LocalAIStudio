import SwiftUI

@main
struct LocalAIStudioApp: App {
    @State private var appState = AppState()
    var body: some Scene {
        WindowGroup {
            StudioRootView()
                .environment(appState)
                .preferredColorScheme(.dark)
                .tint(.cyan)
        }
    }
}
