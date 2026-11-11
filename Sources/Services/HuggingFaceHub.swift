import Foundation

struct HuggingFaceModel: Decodable, Identifiable, Hashable {
    let id: String
    let downloads: Int?
    let likes: Int?
    let lastModified: String?
    let tags: [String]?
    let pipelineTag: String?

    enum CodingKeys: String, CodingKey {
        case id, downloads, likes, tags
        case lastModified = "lastModified"
        case pipelineTag = "pipeline_tag"
    }

    var license: String {
        tags?.first(where: { $0.hasPrefix("license:") })?
            .replacingOccurrences(of: "license:", with: "") ?? "Not specified"
    }
}

struct HuggingFaceFile: Decodable, Identifiable, Hashable {
    let path: String
    let size: Int64?
    let type: String?

    var id: String { path }
    var formattedSize: String {
        guard let size else { return "Size unavailable" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

enum HuggingFaceHubError: LocalizedError {
    case invalidResponse
    case httpStatus(Int)
    case noGGUFFiles
    case noCoreMLBundle

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Hugging Face returned an unexpected response."
        case .httpStatus(let code): return "Hugging Face request failed (HTTP \(code))."
        case .noGGUFFiles: return "This repository does not contain any GGUF model files."
        case .noCoreMLBundle: return "No supported compiled Core ML Stable Diffusion bundle was found."
        }
    }
}

struct HuggingFaceHub {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func searchGGUFModels(query: String, limit: Int = 20) async throws -> [HuggingFaceModel] {
        try await searchModels(query: query, filter: "gguf", limit: limit)
    }

    func searchCoreMLImageModels(query: String = "coreml-stable-diffusion", limit: Int = 20) async throws -> [HuggingFaceModel] {
        try await searchModels(query: query, filter: nil, limit: limit)
    }

    private func searchModels(query: String, filter: String?, limit: Int) async throws -> [HuggingFaceModel] {
        var components = URLComponents(string: "https://huggingface.co/api/models")!
        var items = [
            URLQueryItem(name: "search", value: query),
            URLQueryItem(name: "sort", value: "downloads"),
            URLQueryItem(name: "direction", value: "-1"),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let filter { items.append(URLQueryItem(name: "filter", value: filter)) }
        components.queryItems = items
        let (data, response) = try await session.data(from: components.url!)
        try validate(response)
        return try JSONDecoder().decode([HuggingFaceModel].self, from: data)
    }

    func files(in repository: String) async throws -> [HuggingFaceFile] {
        try await treeFiles(in: repository)
            .filter { $0.path.lowercased().hasSuffix(".gguf") && $0.type != "directory" }
            .sorted { ($0.size ?? 0) < ($1.size ?? 0) }
    }

    func coreMLBundleFiles(in repository: String, variant: String = "original/compiled") async throws -> [HuggingFaceFile] {
        let prefix = variant.hasSuffix("/") ? variant : variant + "/"
        let allFiles = try await treeFiles(in: repository)
        let files = allFiles.filter {
            $0.type != "directory" && $0.path.hasPrefix(prefix)
        }
        guard files.contains(where: { $0.path.hasSuffix("TextEncoder.mlmodelc/model.mil") || $0.path.contains("TextEncoder.mlmodelc/") }),
              files.contains(where: { $0.path.contains("VAEDecoder.mlmodelc/") }),
              files.contains(where: { $0.path.hasSuffix("/vocab.json") }),
              files.contains(where: { $0.path.hasSuffix("/merges.txt") }),
              files.contains(where: { $0.path.contains("Unet.mlmodelc/") || $0.path.contains("UnetChunk1.mlmodelc/") }) else {
            throw HuggingFaceHubError.noCoreMLBundle
        }
        return files.sorted { $0.path < $1.path }
    }

    private func treeFiles(in repository: String) async throws -> [HuggingFaceFile] {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "huggingface.co"
        components.path = "/api/models/\(repository)/tree/main"
        components.queryItems = [
            URLQueryItem(name: "recursive", value: "true"),
            URLQueryItem(name: "expand", value: "true"),
            URLQueryItem(name: "limit", value: "1000")
        ]
        guard let url = components.url else { throw HuggingFaceHubError.invalidResponse }
        let (data, response) = try await session.data(from: url)
        try validate(response)
        return try JSONDecoder().decode([HuggingFaceFile].self, from: data)
    }

    func downloadURL(repository: String, filename: String) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "huggingface.co"
        components.path = "/\(repository)/resolve/main/\(filename)"
        guard let url = components.url else { throw HuggingFaceHubError.invalidResponse }
        return url
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw HuggingFaceHubError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw HuggingFaceHubError.httpStatus(http.statusCode)
        }
    }
}
