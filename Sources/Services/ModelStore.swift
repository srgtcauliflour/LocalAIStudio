import Foundation

actor ModelStore {
    private let fileManager = FileManager.default

    private var modelsDirectory: URL {
        get throws {
            let base = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let directory = base.appendingPathComponent("Models", isDirectory: true)
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            return directory
        }
    }

    func installedModels() -> [LocalModel] {
        guard let directory = try? modelsDirectory,
              let urls = try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
              ) else { return [] }

        return urls.compactMap { url in
            let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
            let ext = url.pathExtension.lowercased()
            guard ext != "partial" else { return nil }
            if values?.isDirectory == true && ext != "mlpackage" { return nil }

            let format: ModelFormat
            let task: ModelTask
            switch ext {
            case "gguf":
                format = .gguf
                task = .chat
            case "mlpackage":
                format = .mlpackage
                task = .imageGeneration
            case "safetensors":
                format = .safetensors
                task = .unclassified
            default:
                format = .other
                task = .unclassified
            }

            let size = values?.isDirectory == true ? directorySize(at: url) : Int64(values?.fileSize ?? 0)
            return LocalModel(
                name: url.deletingPathExtension().lastPathComponent,
                url: url,
                format: format,
                task: task,
                fileSize: size
            )
        }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func importModel(from sourceURL: URL) throws -> URL {
        let destination = try modelsDirectory.appendingPathComponent(sourceURL.lastPathComponent)
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: sourceURL, to: destination)
        return destination
    }

    func downloadDestination(repository: String, filename: String) throws -> URL {
        let safeRepository = repository.replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "..", with: "")
        let safeFilename = URL(fileURLWithPath: filename).lastPathComponent
        return try modelsDirectory.appendingPathComponent("\(safeRepository)-\(safeFilename)")
    }

    private func directorySize(at url: URL) -> Int64 {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }
        var total: Int64 = 0
        for case let item as URL in enumerator {
            total += Int64((try? item.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
        return total
    }
}
