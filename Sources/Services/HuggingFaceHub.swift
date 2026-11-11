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

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Hugging Face returned an unexpected response."
        case .httpStatus(let code): return "Hugging Face request failed (HTTP \(code))."
        case .noGGUFFiles: return "This repository does not contain any GGUF model files."
        }
    }
}

struct HuggingFaceHub {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func searchGGUFModels(query: String, limit: Int = 20) async throws -> [HuggingFaceModel] {
        var components = URLComponents(string: "https://huggingface.co/api/models")!
        components.queryItems = [
            URLQueryItem(name: "search", value: query),
            URLQueryItem(name: "filter", value: "gguf"),
            URLQueryItem(name: "sort", value: "downloads"),
            URLQueryItem(name: "direction", value: "-1"),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        let (data, response) = try await session.data(from: components.url!)
        try validate(response)
        return try JSONDecoder().decode([HuggingFaceModel].self, from: data)
    }

    func files(in repository: String) async throws -> [HuggingFaceFile] {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "huggingface.co"
        components.path = "/api/models/\(repository)/tree/main"
        components.queryItems = [
            URLQueryItem(name: "recursive", value: "true"),
            URLQueryItem(name: "expand", value: "true")
        ]
        guard let url = components.url else { throw HuggingFaceHubError.invalidResponse }
        let (data, response) = try await session.data(from: url)
        try validate(response)
        let files = try JSONDecoder().decode([HuggingFaceFile].self, from: data)
        return files.filter { $0.path.lowercased().hasSuffix(".gguf") && $0.type != "directory" }
            .sorted { ($0.size ?? 0) < ($1.size ?? 0) }
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
