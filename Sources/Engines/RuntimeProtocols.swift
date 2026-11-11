import Foundation

protocol ChatRuntime: Sendable {
    func loadModel(at url: URL) async throws
    func generate(prompt: String, systemPrompt: String, settings: GenerationSettings) -> AsyncThrowingStream<String, Error>
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
    var contextLength: Int = 2048
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
    var errorDescription: String? {
        switch self {
        case .notConfigured: return "The local inference runtime has not been integrated yet."
        case .unsupportedModel: return "This model format is not supported by the selected runtime."
        }
    }
}
