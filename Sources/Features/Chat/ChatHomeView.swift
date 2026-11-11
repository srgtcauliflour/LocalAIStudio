import SwiftUI

private struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String
    var content: String
}

struct ChatHomeView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedModelID = ""
    @State private var messages: [ChatMessage] = []
    @State private var draft = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?

    private var chatModels: [LocalModel] {
        appState.installedModels.filter { $0.task == .chat && $0.format == .gguf }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    StudioHeader(
                        title: "AI Chat",
                        subtitle: "Your prompts stay on your iPhone. No cloud inference."
                    )

                    if chatModels.isEmpty {
                        EmptyStateCard(
                            icon: "cpu",
                            title: "Install a GGUF model",
                            message: "Open Model Library to search Hugging Face and download a local chat model."
                        )
                        Button {
                            appState.selectedTab = .models
                        } label: {
                            Label("Browse Model Library", systemImage: "square.stack.3d.up")
                                .frame(maxWidth: .infinity)
                                .padding(12)
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        HStack {
                            Label("ON-DEVICE", systemImage: "iphone.gen3")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                            Spacer()
                            Picker("Model", selection: $selectedModelID) {
                                Text("Choose model").tag("")
                                ForEach(chatModels) { model in
                                    Text(model.name).tag(model.id)
                                }
                            }
                            .labelsHidden()
                            .tint(.cyan)
                            .onChange(of: selectedModelID) { _, newValue in
                                guard let model = chatModels.first(where: { $0.id == newValue }) else { return }
                                Task { await appState.activateChatModel(model) }
                            }
                        }
                    }

                    if let status = appState.chatRuntimeMessage {
                        Text(status)
                            .font(.caption)
                            .foregroundStyle(appState.activeChatModelID == nil ? Color.secondary : Color.green)
                    }
                }
                .padding()

                Divider().overlay(Color.white.opacity(0.08))

                if messages.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 42))
                            .foregroundStyle(.cyan)
                        Text("A private AI conversation")
                            .font(.headline)
                        Text("Load a model, type a message, and generate a response locally.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(30)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(messages) { message in
                                messageBubble(message)
                            }
                        }
                        .padding()
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .padding(.horizontal)
                }
            }
            .background(Color.studioBackground)
            .safeAreaInset(edge: .bottom) {
                composer
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        messages.removeAll()
                        errorMessage = nil
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .disabled(messages.isEmpty || isGenerating)
                }
            }
            .onAppear {
                if selectedModelID.isEmpty, let active = appState.activeChatModelID {
                    selectedModelID = active
                }
            }
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Message your local model…", text: $draft, axis: .vertical)
                .lineLimit(1...5)
                .textFieldStyle(.roundedBorder)
                .disabled(appState.activeChatModelID == nil || isGenerating)

            Button {
                Task { await sendMessage() }
            } label: {
                if isGenerating {
                    ProgressView()
                        .frame(width: 42, height: 42)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(.cyan)
                }
            }
            .disabled(appState.activeChatModelID == nil || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private func messageBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.role == "assistant" { Spacer(minLength: 36) }
            VStack(alignment: .leading, spacing: 5) {
                Text(message.role == "assistant" ? "LOCAL AI" : "YOU")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                Text(message.content.isEmpty && message.role == "assistant" ? "Thinking…" : message.content)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(13)
            .background(message.role == "assistant" ? Color.studioPanel : Color.cyan.opacity(0.14), in: RoundedRectangle(cornerRadius: 16))
            if message.role == "user" { Spacer(minLength: 36) }
        }
    }

    @MainActor
    private func sendMessage() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, appState.activeChatModelID != nil, !isGenerating else { return }

        draft = ""
        errorMessage = nil
        let conversation = messages.map { "\($0.role): \($0.content)" }
            .joined(separator: "\n") + "\nuser: \(text)"
        messages.append(ChatMessage(role: "user", content: text))
        let response = ChatMessage(role: "assistant", content: "")
        messages.append(response)
        let responseID = response.id
        isGenerating = true
        defer { isGenerating = false }

        do {
            let stream = await appState.chatRuntime.generate(
                prompt: conversation,
                systemPrompt: "You are a helpful assistant. Answer clearly and directly.",
                settings: GenerationSettings()
            )
            for try await piece in stream {
                guard let index = messages.firstIndex(where: { $0.id == responseID }) else { continue }
                messages[index].content += piece
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
