import Foundation
import LlamaSwift

actor LlamaCppChatRuntime: ChatRuntime {
    private var model: OpaquePointer?
    private var context: OpaquePointer?
    private var backendReady = false

    func loadModel(at url: URL) async throws {
        unloadResources()
        guard url.pathExtension.lowercased() == "gguf" else {
            throw RuntimeError.unsupportedModel
        }

        if !backendReady {
            llama_backend_init()
            backendReady = true
        }

        var modelParameters = llama_model_default_params()
        modelParameters.n_gpu_layers = 99
        let loadedModel = url.path.withCString {
            llama_model_load_from_file($0, modelParameters)
        }
        guard let loadedModel else {
            throw RuntimeError.modelLoadFailed
        }

        var contextParameters = llama_context_default_params()
        contextParameters.n_ctx = 4096
        contextParameters.n_batch = 512
        let loadedContext = llama_init_from_model(loadedModel, contextParameters)
        guard let loadedContext else {
            llama_model_free(loadedModel)
            throw RuntimeError.contextCreationFailed
        }

        model = loadedModel
        context = loadedContext
    }

    func generate(
        prompt: String,
        systemPrompt: String,
        settings: GenerationSettings
    ) async -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try self.generateTokens(
                        prompt: prompt,
                        systemPrompt: systemPrompt,
                        settings: settings,
                        continuation: continuation
                    )
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { @Sendable _ in task.cancel() }
        }
    }

    func unload() async {
        unloadResources()
    }

    private func unloadResources() {
        if let context {
            llama_free(context)
            self.context = nil
        }
        if let model {
            llama_model_free(model)
            self.model = nil
        }
    }

    private func generateTokens(
        prompt: String,
        systemPrompt: String,
        settings: GenerationSettings,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) throws {
        guard let model, let context else {
            throw RuntimeError.notConfigured
        }

        llama_memory_clear(llama_get_memory(context), true)
        guard let vocab = llama_model_get_vocab(model) else {
            throw RuntimeError.tokenizationFailed
        }
        let formattedPrompt = makePrompt(
            model: model,
            systemPrompt: systemPrompt,
            userPrompt: prompt
        )
        var promptTokens = try tokenize(formattedPrompt, vocabulary: vocab)
        guard !promptTokens.isEmpty else {
            throw RuntimeError.tokenizationFailed
        }

        let promptBatch = promptTokens.withUnsafeMutableBufferPointer { buffer in
            llama_batch_get_one(buffer.baseAddress!, Int32(buffer.count))
        }
        guard llama_decode(context, promptBatch) == 0 else {
            throw RuntimeError.decodingFailed
        }

        guard let sampler = llama_sampler_chain_init(llama_sampler_chain_default_params()) else {
            throw RuntimeError.samplerCreationFailed
        }
        defer { llama_sampler_free(sampler) }

        llama_sampler_chain_add(sampler, llama_sampler_init_top_p(settings.topP, 1))
        llama_sampler_chain_add(sampler, llama_sampler_init_temp(max(0, settings.temperature)))
        llama_sampler_chain_add(sampler, llama_sampler_init_dist(UInt32.random(in: 0...UInt32.max)))

        for _ in 0..<max(1, settings.maxTokens) {
            if Task.isCancelled { throw CancellationError() }

            let token = llama_sampler_sample(sampler, context, -1)
            if llama_vocab_is_eog(vocab, token) { break }

            let piece = tokenPiece(token, vocabulary: vocab)
            if !piece.isEmpty {
                continuation.yield(piece)
            }

            var nextToken = token
            let nextBatch = withUnsafeMutablePointer(to: &nextToken) {
                llama_batch_get_one($0, 1)
            }
            guard llama_decode(context, nextBatch) == 0 else {
                throw RuntimeError.decodingFailed
            }
        }
    }

    private func tokenize(_ text: String, vocabulary: OpaquePointer) throws -> [llama_token] {
        var capacity = max(128, text.utf8.count + 16)
        for _ in 0..<3 {
            var tokens = [llama_token](repeating: 0, count: capacity)
            let count = text.withCString { textPointer in
                tokens.withUnsafeMutableBufferPointer { buffer in
                    llama_tokenize(
                        vocabulary,
                        textPointer,
                        Int32(text.utf8.count),
                        buffer.baseAddress,
                        Int32(buffer.count),
                        true,
                        true
                    )
                }
            }
            if count >= 0 {
                return Array(tokens.prefix(Int(count)))
            }
            capacity = Int(-count)
        }
        throw RuntimeError.tokenizationFailed
    }

    private func tokenPiece(_ token: llama_token, vocabulary: OpaquePointer) -> String {
        var buffer = [CChar](repeating: 0, count: 256)
        let count = llama_token_to_piece(
            vocabulary,
            token,
            &buffer,
            Int32(buffer.count),
            0,
            false
        )
        guard count > 0 else { return "" }
        let bytes = buffer.prefix(Int(count)).map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    private func makePrompt(
        model: OpaquePointer,
        systemPrompt: String,
        userPrompt: String
    ) -> String {
        guard let template = llama_model_chat_template(model, nil) else {
            return "System: \(systemPrompt)\n\nUser: \(userPrompt)\nAssistant:"
        }

        let capacity = max(4096, (systemPrompt.utf8.count + userPrompt.utf8.count) * 4)
        var output = [CChar](repeating: 0, count: capacity)
        let count = "system".withCString { systemRole in
            "user".withCString { userRole in
                systemPrompt.withCString { systemText in
                    userPrompt.withCString { userText in
                        var messages = [
                            llama_chat_message(role: systemRole, content: systemText),
                            llama_chat_message(role: userRole, content: userText)
                        ]
                        return messages.withUnsafeMutableBufferPointer { messageBuffer in
                            output.withUnsafeMutableBufferPointer { outputBuffer in
                                llama_chat_apply_template(
                                    template,
                                    messageBuffer.baseAddress,
                                    messageBuffer.count,
                                    true,
                                    outputBuffer.baseAddress,
                                    Int32(outputBuffer.count)
                                )
                            }
                        }
                    }
                }
            }
        }

        guard count > 0, count < output.count else {
            return "System: \(systemPrompt)\n\nUser: \(userPrompt)\nAssistant:"
        }
        let bytes = output.prefix(Int(count)).map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }
}
