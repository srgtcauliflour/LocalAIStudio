import XCTest
@testable import LocalAIStudio

final class LocalModelTests: XCTestCase {
    func testModelTaskIdentifiersAreStable() {
        XCTAssertEqual(ModelTask.chat.id, "Chat")
        XCTAssertEqual(ModelTask.imageGeneration.id, "Image generation")
        XCTAssertEqual(ModelTask.vision.id, "Vision")
    }

    func testModelFormatRawValuesAreStable() {
        XCTAssertEqual(ModelFormat.gguf.rawValue, "GGUF")
        XCTAssertEqual(ModelFormat.coreML.rawValue, "Core ML")
        XCTAssertEqual(ModelFormat.mlpackage.rawValue, "ML Package")
    }

    func testLocalModelUsesFilenameAsIdentity() {
        let model = LocalModel(
            name: "Example",
            url: URL(fileURLWithPath: "/models/example.gguf"),
            format: .gguf,
            task: .chat,
            fileSize: 1_048_576
        )
        XCTAssertEqual(model.id, "example.gguf")
        XCTAssertEqual(model.name, "Example")
        XCTAssertEqual(model.fileSize, 1_048_576)
    }
}
