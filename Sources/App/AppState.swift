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

    var activeImageModelID: String?
    var isLoadingImageModel = false
    var imageRuntimeMessage: String?

    @ObservationIgnored let modelStore = ModelStore()
    @ObservationIgnored let chatRuntime = LlamaCppChatRuntime()
    @ObservationIgnored let imageRuntime = CoreMLImageGenerationRuntime()

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
        await imageRuntime.unload()
        activeImageModelID = nil
        imageRuntimeMessage = "Image model unloaded to free memory for chat."
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

    func activateImageModel(_ model: LocalModel) async {
        guard model.task == .imageGeneration, model.format == .coreML else {
            imageRuntimeMessage = "Choose an imported Core ML Stable Diffusion resource folder."
            return
        }
        if activeImageModelID == model.id { return }

        isLoadingImageModel = true
        await chatRuntime.unload()
        activeChatModelID = nil
        chatRuntimeMessage = "Chat model unloaded to free memory for image generation."
        imageRuntimeMessage = "Loading \(model.name)…"
        defer { isLoadingImageModel = false }
        do {
            try await imageRuntime.loadModel(at: model.url)
            activeImageModelID = model.id
            imageRuntimeMessage = "Ready • \(model.name)"
        } catch {
            activeImageModelID = nil
            imageRuntimeMessage = error.localizedDescription
        }
    }

    func unloadImageModel() async {
        await imageRuntime.unload()
        activeImageModelID = nil
        imageRuntimeMessage = "Image model unloaded"
    }
}

enum StudioTab: Hashable {
    case chat
    case images
    case models
    case settings
}
