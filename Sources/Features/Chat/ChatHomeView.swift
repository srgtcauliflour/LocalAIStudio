import SwiftUI

struct ChatHomeView: View {
    @Environment(AppState.self) private var appState
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    StudioHeader(title: "AI Chat", subtitle: "Private conversations, processed on your iPhone.")
                    HStack {
                        Label("ON-DEVICE", systemImage: "iphone.gen3").font(.caption.bold()).foregroundStyle(.green)
                        Spacer()
                        Text("\(appState.installedModels.filter { $0.task == .chat }.count) chat models").font(.caption).foregroundStyle(.secondary)
                    }
                    EmptyStateCard(icon: "bubble.left.and.text.bubble.right", title: "Ready for your first model", message: "Install a compatible GGUF chat model in Model Library. The chat runtime will be connected in the next milestone.")
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Try asking").font(.headline)
                        ForEach(["Explain a complex idea simply", "Help me write a Swift function", "Brainstorm a weekend project"], id: \.self) { item in
                            Text(item).font(.subheadline).padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Color.studioPanel, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }.padding()
            }
            .background(Color.studioBackground)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 10) {
                    TextField("Install a chat model to begin…", text: .constant("")).textFieldStyle(.roundedBorder).disabled(true)
                    Image(systemName: "arrow.up.circle.fill").font(.title).foregroundStyle(.tertiary)
                }.padding().background(.ultraThinMaterial)
            }
        }
    }
}
