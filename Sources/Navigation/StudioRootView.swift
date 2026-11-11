import SwiftUI

struct StudioRootView: View {
    @Environment(AppState.self) private var appState
    var body: some View {
        TabView(selection: Binding(get: { appState.selectedTab }, set: { appState.selectedTab = $0 })) {
            ChatHomeView().tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right") }.tag(StudioTab.chat)
            ImageStudioView().tabItem { Label("Images", systemImage: "sparkles.rectangle.stack") }.tag(StudioTab.images)
            ModelLibraryView().tabItem { Label("Models", systemImage: "square.stack.3d.up") }.tag(StudioTab.models)
            SettingsHomeView().tabItem { Label("Settings", systemImage: "slider.horizontal.3") }.tag(StudioTab.settings)
        }
        .background(Color.studioBackground)
    }
}
extension Color {
    static let studioBackground = Color(red: 0.035, green: 0.045, blue: 0.065)
    static let studioPanel = Color(red: 0.075, green: 0.09, blue: 0.12)
}
struct StudioHeader: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.largeTitle.bold())
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 34)).foregroundStyle(.cyan)
            Text(title).font(.headline)
            Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity).padding(24).background(Color.studioPanel, in: RoundedRectangle(cornerRadius: 20))
    }
}
