import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    var selectedTab: StudioTab = .chat
    var installedModels: [LocalModel] = []
    var isScanningModels = false
    var activeChatModelID: String?
    var isLoadingChatModel = false
    var chatRuntimeMessage: String?
    @ObservationIgnored let modelStore = ModelStore()
    @ObservationIgnored let chatRuntime = LlamaCppChatRuntime()

    init() {
        Task { await refreshModels() }
    }

    func refreshModels() async {
        isScanningModels = true
        defer { isScanningModels = false }
        installedModels = await modelStore.installedModels()
    }

    func activateChatModel(_ model: LocalModel) async {
        guard model.format == .gguf, model.task == .chat else {
            chatRuntimeMessage = "Choose a GGUF chat model."
            return
        }
        if activeChatModelID == model.id { return }

        isLoadingChatModel = true
        chatRuntimeMessage = "Loading \(model.name)…"
        defer { isLoadingChatModel = false }
        do {
            try await chatRuntime.loadModel(at: model.url)
            activeChatModelID = model.id
            chatRuntimeMessage = "Ready • \(model.name)"
        } catch {
            activeChatModelID = nil
            chatRuntimeMessage = error.localizedDescription
        }
    }

    func unloadChatModel() async {
        await chatRuntime.unload()
        activeChatModelID = nil
        chatRuntimeMessage = "Model unloaded"
    }
}

enum StudioTab: Hashable {
    case chat
    case images
    case models
    case settings
}
