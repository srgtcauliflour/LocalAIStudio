import SwiftUI
import UIKit

struct ImageStudioView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedModelID = ""
    @State private var prompt = ""
    @State private var negativePrompt = ""
    @State private var steps = 20.0
    @State private var guidance = 7.5
    @State private var isGenerating = false
    @State private var outputURL: URL?
    @State private var errorMessage: String?

    private var imageModels: [LocalModel] {
        appState.installedModels.filter { $0.task == .imageGeneration && $0.format == .coreML }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    StudioHeader(
                        title: "Image Studio",
                        subtitle: "Generate with Core ML on your iPhone. No cloud image service."
                    )

                    if imageModels.isEmpty {
                        EmptyStateCard(
                            icon: "photo.badge.plus",
                            title: "Import a Core ML model",
                            message: "Use Model Library → Import from Files to add an Apple Stable Diffusion resource folder containing TextEncoder, UNet, VAE decoder, vocab.json and merges.txt."
                        )
                        Button {
                            appState.selectedTab = .models
                        } label: {
                            Label("Open Model Library", systemImage: "square.stack.3d.up")
                                .frame(maxWidth: .infinity)
                                .padding(12)
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("IMAGE MODEL").font(.caption.bold()).foregroundStyle(.secondary)
                            Picker("Image model", selection: $selectedModelID) {
                                Text("Choose model").tag("")
                                ForEach(imageModels) { model in
                                    Text(model.name).tag(model.id)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: selectedModelID) { _, value in
                                guard let model = imageModels.first(where: { $0.id == value }) else { return }
                                Task { await appState.activateImageModel(model) }
                            }
                            if let status = appState.imageRuntimeMessage {
                                Text(status).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.studioPanel, in: RoundedRectangle(cornerRadius: 16))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("PROMPT").font(.caption.bold()).foregroundStyle(.secondary)
                        TextEditor(text: $prompt)
                            .frame(minHeight: 110)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .background(Color.studioBackground, in: RoundedRectangle(cornerRadius: 12))

                        Text("NEGATIVE PROMPT").font(.caption.bold()).foregroundStyle(.secondary)
                        TextField("Optional", text: $negativePrompt)
                            .textFieldStyle(.roundedBorder)

                        HStack {
                            Text("Steps")
                            Spacer()
                            Text("\(Int(steps))").monospacedDigit().foregroundStyle(.secondary)
                        }
                        Slider(value: $steps, in: 10...40, step: 1)

                        HStack {
                            Text("Guidance")
                            Spacer()
                            Text(String(format: "%.1f", guidance)).monospacedDigit().foregroundStyle(.secondary)
                        }
                        Slider(value: $guidance, in: 1...12, step: 0.5)

                        Text("Output resolution is determined by the selected Core ML model.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button {
                            Task { await generate() }
                        } label: {
                            HStack {
                                if isGenerating { ProgressView().tint(.white) }
                                Label(isGenerating ? "Generating…" : "Generate image", systemImage: "sparkles")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(
                            appState.activeImageModelID == nil ||
                            prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            isGenerating
                        )
                    }
                    .padding()
                    .background(Color.studioPanel, in: RoundedRectangle(cornerRadius: 18))

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }

                    if let outputURL, let image = UIImage(contentsOfFile: outputURL.path) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("LATEST GENERATION").font(.caption.bold()).foregroundStyle(.secondary)
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            ShareLink(item: outputURL) {
                                Label("Share image", systemImage: "square.and.arrow.up")
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.studioBackground)
            .onAppear {
                if selectedModelID.isEmpty, let active = appState.activeImageModelID {
                    selectedModelID = active
                }
            }
        }
    }

    @MainActor
    private func generate() async {
        guard appState.activeImageModelID != nil, !isGenerating else { return }
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }
        do {
            outputURL = try await appState.imageRuntime.generate(
                prompt: prompt,
                negativePrompt: negativePrompt,
                settings: ImageGenerationSettings(
                    steps: Int(steps),
                    guidanceScale: Float(guidance),
                    width: 512,
                    height: 512,
                    seed: nil
                )
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
