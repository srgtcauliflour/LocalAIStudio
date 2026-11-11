import SwiftUI
import UniformTypeIdentifiers

struct ModelLibraryView: View {
    @Environment(AppState.self) private var appState
    @State private var query = ""
    @State private var searchResults: [HuggingFaceModel] = []
    @State private var selectedRepository: String?
    @State private var repositoryFiles: [HuggingFaceFile] = []
    @State private var isSearching = false
    @State private var isLoadingFiles = false
    @State private var downloadingFile: String?
    @State private var downloadProgress = 0.0
    @State private var statusMessage: String?
    @State private var errorMessage: String?
    @State private var showingFileImporter = false

    private let hub = HuggingFaceHub()
    private let downloader = ModelDownloadManager()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    StudioHeader(
                        title: "Model Library",
                        subtitle: "Find open models, download them, and keep inference on your iPhone."
                    )

                    HStack {
                        Label("Local storage", systemImage: "internaldrive")
                        Spacer()
                        Text("\(appState.installedModels.count) installed")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("HUGGING FACE")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        HStack {
                            TextField("Search GGUF chat models", text: $query)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .submitLabel(.search)
                                .onSubmit { Task { await search() } }
                            Button {
                                Task { await search() }
                            } label: {
                                if isSearching {
                                    ProgressView()
                                } else {
                                    Image(systemName: "magnifyingglass")
                                }
                            }
                            .disabled(isSearching || query.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding(12)
                        .background(Color.studioPanel, in: RoundedRectangle(cornerRadius: 12))

                        HStack {
                            Button { showingFileImporter = true } label: { Label("Import from Files", systemImage: "folder.badge.plus") }
                            Spacer()
                        }
                        Text("Search is online; downloaded model files are stored locally. Prompts are never sent to Hugging Face.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.studioPanel.opacity(0.65), in: RoundedRectangle(cornerRadius: 18))

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                    if let statusMessage {
                        Label(statusMessage, systemImage: "checkmark.circle")
                            .font(.footnote)
                            .foregroundStyle(.green)
                    }

                    if !searchResults.isEmpty {
                        Text("SEARCH RESULTS")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        ForEach(searchResults) { model in
                            repositoryCard(model)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("INSTALLED MODELS")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button {
                                Task { await appState.refreshModels() }
                            } label: {
                                Label("Refresh", systemImage: "arrow.clockwise")
                                    .font(.caption)
                            }
                        }

                        if appState.installedModels.isEmpty {
                            EmptyStateCard(
                                icon: "square.stack.3d.up",
                                title: "No models installed",
                                message: "Search Hugging Face above, or import a compatible model file into the app."
                            )
                        } else {
                            ForEach(appState.installedModels) { model in
                                HStack(spacing: 12) {
                                    Image(systemName: model.task == .chat ? "text.bubble" : "shippingbox")
                                        .font(.title2)
                                        .foregroundStyle(.cyan)
                                        .frame(width: 42, height: 42)
                                        .background(Color.studioPanel, in: RoundedRectangle(cornerRadius: 12))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(model.name).font(.headline)
                                        Text("\(model.format.rawValue) • \(model.task.rawValue)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(model.formattedSize)
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                                .padding(12)
                                .background(Color.studioPanel, in: RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.studioBackground)
            .navigationBarTitleDisplayMode(.inline)
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.data, .folder],
                allowsMultipleSelection: true
            ) { result in
                Task { await importFiles(result) }
            }
        }
    }

    @ViewBuilder
    private func repositoryCard(_ model: HuggingFaceModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(model.id).font(.headline).textSelection(.enabled)
            HStack(spacing: 12) {
                Label("\(model.downloads ?? 0)", systemImage: "arrow.down.circle")
                Label("\(model.likes ?? 0)", systemImage: "heart")
                Text("Licence: \(model.license)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Button {
                Task { await loadFiles(for: model) }
            } label: {
                HStack {
                    Text(selectedRepository == model.id ? "Hide model files" : "Choose a GGUF file")
                    Spacer()
                    if isLoadingFiles && selectedRepository == model.id {
                        ProgressView()
                    } else {
                        Image(systemName: "chevron.down")
                    }
                }
                .font(.subheadline.weight(.semibold))
            }
            .disabled(isLoadingFiles)

            if selectedRepository == model.id {
                if repositoryFiles.isEmpty && !isLoadingFiles {
                    Text("No downloadable GGUF files found.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(repositoryFiles) { file in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(file.path)
                                    .font(.caption.weight(.medium))
                                    .textSelection(.enabled)
                                Text(file.formattedSize)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                Task { await download(model: model, file: file) }
                            } label: {
                                Image(systemName: downloadingFile == file.id ? "arrow.down.circle.fill" : "arrow.down.to.line")
                                    .font(.title3)
                            }
                            .disabled(downloadingFile != nil)
                        }
                        if downloadingFile == file.id {
                            ProgressView(value: downloadProgress)
                            Text("\(Int(downloadProgress * 100))% downloaded")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(10)
                    .background(Color.studioBackground, in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(Color.studioPanel, in: RoundedRectangle(cornerRadius: 16))
    }

    @MainActor
    private func search() async {
        isSearching = true
        errorMessage = nil
        statusMessage = nil
        defer { isSearching = false }
        do {
            searchResults = try await hub.searchGGUFModels(query: query)
            if searchResults.isEmpty {
                statusMessage = "No GGUF models matched that search."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func loadFiles(for model: HuggingFaceModel) async {
        if selectedRepository == model.id {
            selectedRepository = nil
            repositoryFiles = []
            return
        }
        selectedRepository = model.id
        repositoryFiles = []
        isLoadingFiles = true
        errorMessage = nil
        defer { isLoadingFiles = false }
        do {
            repositoryFiles = try await hub.files(in: model.id)
            if repositoryFiles.isEmpty {
                errorMessage = "No GGUF files were found in \(model.id)."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func download(model: HuggingFaceModel, file: HuggingFaceFile) async {
        guard downloadingFile == nil else { return }
        downloadingFile = file.id
        downloadProgress = 0
        errorMessage = nil
        statusMessage = nil
        defer { downloadingFile = nil }
        do {
            let remoteURL = try hub.downloadURL(repository: model.id, filename: file.path)
            let destination = try await appState.modelStore.downloadDestination(
                repository: model.id,
                filename: file.path
            )
            _ = try await downloader.download(from: remoteURL, to: destination) { value in
                Task { @MainActor in self.downloadProgress = value }
            }
            await appState.refreshModels()
            statusMessage = "Downloaded \(file.path). It is now stored on this device."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func importFiles(_ result: Result<[URL], Error>) async {
        errorMessage = nil
        do {
            let urls = try result.get()
            for url in urls {
                let hasAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if hasAccess { url.stopAccessingSecurityScopedResource() }
                }
                _ = try await appState.modelStore.importModel(from: url)
            }
            await appState.refreshModels()
            statusMessage = "Imported selected model files into local storage."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
