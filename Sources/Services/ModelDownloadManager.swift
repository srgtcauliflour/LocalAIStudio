import Foundation

actor ModelDownloadManager {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Streams a public Hugging Face file to disk. A partial file is retained after
    /// interruption and resumed with an HTTP Range request on the next attempt.
    func download(
        from remoteURL: URL,
        to destination: URL,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let partial = destination.appendingPathExtension("partial")
        let fileManager = FileManager.default
        let existingBytes = (try? fileManager.attributesOfItem(atPath: partial.path)[.size] as? NSNumber)?
            .int64Value ?? 0

        var request = URLRequest(url: remoteURL)
        request.timeoutInterval = 60
        if existingBytes > 0 {
            request.setValue("bytes=\(existingBytes)-", forHTTPHeaderField: "Range")
        }

        let (bytes, response) = try await session.bytes(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw HuggingFaceHubError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw HuggingFaceHubError.httpStatus(http.statusCode)
        }

        let append = existingBytes > 0 && http.statusCode == 206
        if !append {
            try? fileManager.removeItem(at: partial)
            fileManager.createFile(atPath: partial.path, contents: nil)
        } else if !fileManager.fileExists(atPath: partial.path) {
            fileManager.createFile(atPath: partial.path, contents: nil)
        }

        let totalBytes = Self.totalLength(from: http, fallback: http.expectedContentLength)
        let handle = try FileHandle(forWritingTo: partial)
        defer { try? handle.close() }
        try handle.seekToEnd()

        var buffer = Data()
        buffer.reserveCapacity(256 * 1024)
        var received = append ? existingBytes : 0

        do {
            for try await byte in bytes {
                try Task.checkCancellation()
                buffer.append(byte)
                received += 1

                if buffer.count >= 256 * 1024 {
                    try handle.write(contentsOf: buffer)
                    buffer.removeAll(keepingCapacity: true)
                    if totalBytes > 0 {
                        progress(min(1, Double(received) / Double(totalBytes)))
                    }
                }
            }
            if !buffer.isEmpty {
                try handle.write(contentsOf: buffer)
            }
        } catch {
            // Keep the partial file so the next attempt can resume it.
            throw error
        }

        try handle.synchronize()
        try? fileManager.removeItem(at: destination)
        try fileManager.moveItem(at: partial, to: destination)
        progress(1)
        return destination
    }

    private static func totalLength(from response: HTTPURLResponse, fallback: Int64) -> Int64 {
        if let range = response.value(forHTTPHeaderField: "Content-Range"),
           let total = range.split(separator: "/").last,
           let value = Int64(total) {
            return value
        }
        return fallback
    }
}
