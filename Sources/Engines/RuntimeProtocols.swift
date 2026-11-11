import Foundation

protocol ChatRuntime: Sendable {
    func loadModel(at url: URL) async throws
    func generate(prompt: String, systemPrompt: String, settings: GenerationSettings) async -> AsyncThrowingStream<String, Error>
    func unload() async
}

protocol ImageGenerationRuntime: Sendable {
    func loadModel(at url: URL) async throws
    func generate(prompt: String, negativePrompt: String, settings: ImageGenerationSettings) async throws -> URL
    func unload() async
}

struct GenerationSettings: Sendable {
    var temperature: Float = 0.7
    var topP: Float = 0.9
    var maxTokens: Int = 512
    var contextLength: Int = 4096
}

struct ImageGenerationSettings: Sendable {
    var steps: Int = 20
    var guidanceScale: Float = 7
    var width: Int = 512
    var height: Int = 512
    var seed: UInt32?
}

enum RuntimeError: LocalizedError {
    case notConfigured
    case unsupportedModel
    case modelLoadFailed
    case contextCreationFailed
    case tokenizationFailed
    case decodingFailed
    case samplerCreationFailed

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Load a local model before starting a conversation."
        case .unsupportedModel: return "This model format is not supported by the selected runtime."
        case .modelLoadFailed: return "The GGUF model could not be loaded. Check that the file is complete and compatible."
        case .contextCreationFailed: return "The inference context could not be created. The model may exceed available memory."
        case .tokenizationFailed: return "The prompt could not be tokenized by this model."
        case .decodingFailed: return "The local model failed while generating a response."
        case .samplerCreationFailed: return "The text-generation sampler could not be initialized."
        }
    }
}
