import Foundation

enum ModelTask: String, Codable, CaseIterable, Identifiable {
    case chat = "Chat"
    case imageGeneration = "Image generation"
    case vision = "Vision"
    case unclassified = "Unclassified"
    var id: String { rawValue }
}

enum ModelFormat: String, Codable, CaseIterable {
    case gguf = "GGUF"
    case coreML = "Core ML"
    case mlpackage = "ML Package"
    case safetensors = "SafeTensors"
    case other = "Other"
}

struct LocalModel: Identifiable, Codable, Hashable {
    var id: String { url.lastPathComponent }
    let name: String
    let url: URL
    let format: ModelFormat
    let task: ModelTask
    let fileSize: Int64
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}
