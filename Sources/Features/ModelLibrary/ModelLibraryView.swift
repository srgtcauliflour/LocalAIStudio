import SwiftUI

struct ModelLibraryView: View {
    @Environment(AppState.self) private var appState
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    StudioHeader(title: "Model Library", subtitle: "Your models stay on this device.")
                    HStack { Label("Local storage", systemImage: "internaldrive"); Spacer(); Text("\(appState.installedModels.count) installed").foregroundStyle(.secondary) }.font(.subheadline)
                    Button { Task { await appState.refreshModels() } } label: { Label("Scan local models", systemImage: "arrow.clockwise").frame(maxWidth: .infinity).padding(12) }.buttonStyle(.bordered)
                    if appState.installedModels.isEmpty {
                        EmptyStateCard(icon: "square.stack.3d.up", title: "No models installed", message: "Downloaded GGUF and compatible model packages will appear here.")
                    } else {
                        ForEach(appState.installedModels) { model in
                            HStack(spacing: 12) {
                                Image(systemName: model.task == .chat ? "text.bubble" : "photo").font(.title2).foregroundStyle(.cyan).frame(width: 42, height: 42).background(Color.studioPanel, in: RoundedRectangle(cornerRadius: 12))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(model.name).font(.headline)
                                    Text("\(model.format.rawValue) • \(model.task.rawValue)").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(model.formattedSize).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                            }.padding(12).background(Color.studioPanel, in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    Text("Hugging Face catalogue and resumable downloads are scheduled for the next milestone.").font(.footnote).foregroundStyle(.secondary)
                }.padding()
            }.background(Color.studioBackground)
        }
    }
}
