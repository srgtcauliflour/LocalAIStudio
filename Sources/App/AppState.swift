import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    var selectedTab: StudioTab = .chat
    var installedModels: [LocalModel] = []
    var isScanningModels = false
    let modelStore = ModelStore()

    init() { Task { await refreshModels() } }

    func refreshModels() async {
        isScanningModels = true
        defer { isScanningModels = false }
        installedModels = await modelStore.installedModels()
    }
}

enum StudioTab: Hashable { case chat, images, models, settings }
