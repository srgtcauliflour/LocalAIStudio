import XCTest
@testable import LocalAIStudio

final class HuggingFaceHubTests: XCTestCase {
    func testModelSearchPayloadDecodes() throws {
        let json = """
        {
          "id": "community/example-3b-GGUF",
          "downloads": 1200,
          "likes": 42,
          "lastModified": "2026-11-01T00:00:00.000Z",
          "tags": ["gguf", "license:apache-2.0"],
          "pipeline_tag": "text-generation"
        }
        """.data(using: .utf8)!

        let model = try JSONDecoder().decode(HuggingFaceModel.self, from: json)
        XCTAssertEqual(model.id, "community/example-3b-GGUF")
        XCTAssertEqual(model.downloads, 1200)
        XCTAssertEqual(model.license, "apache-2.0")
        XCTAssertEqual(model.pipelineTag, "text-generation")
    }

    func testGGUFFileMetadataDecodes() throws {
        let json = """
        {"path":"model-Q4_K_M.gguf","size":2147483648,"type":"file"}
        """.data(using: .utf8)!

        let file = try JSONDecoder().decode(HuggingFaceFile.self, from: json)
        XCTAssertEqual(file.path, "model-Q4_K_M.gguf")
        XCTAssertEqual(file.size, 2_147_483_648)
        XCTAssertEqual(file.id, file.path)
    }

    func testDownloadURLContainsRepositoryAndFilename() throws {
        let url = try HuggingFaceHub().downloadURL(
            repository: "community/example",
            filename: "model-Q4_K_M.gguf"
        )
        XCTAssertEqual(
            url.absoluteString,
            "https://huggingface.co/community/example/resolve/main/model-Q4_K_M.gguf"
        )
    }
}
