import CoreGraphics
import CoreML
import Foundation
import ImageIO
import StableDiffusion
import UniformTypeIdentifiers

actor CoreMLImageGenerationRuntime: ImageGenerationRuntime {
    private var pipeline: StableDiffusionPipeline?

    func loadModel(at url: URL) async throws {
        await unload()
        guard url.hasDirectoryPath else {
            throw RuntimeError.unsupportedModel
        }

        let configuration = MLModelConfiguration()
        configuration.computeUnits = .cpuAndNeuralEngine

        // The user chose no blanket app-level content filter. Do not load an
        // optional model-bundled safety checker as part of this pipeline.
        let loadedPipeline = try StableDiffusionPipeline(
            resourcesAt: url,
            controlNet: [],
            configuration: configuration,
            disableSafety: true,
            reduceMemory: true
        )
        try loadedPipeline.loadResources()
        pipeline = loadedPipeline
    }

    func generate(
        prompt: String,
        negativePrompt: String,
        settings: ImageGenerationSettings
    ) async throws -> URL {
        guard let pipeline else {
            throw RuntimeError.notConfigured
        }

        var configuration = PipelineConfiguration(prompt: prompt)
        configuration.negativePrompt = negativePrompt
        configuration.stepCount = settings.steps
        configuration.guidanceScale = settings.guidanceScale
        configuration.seed = settings.seed ?? UInt32.random(in: 0...UInt32.max)

        let images = try pipeline.generateImages(configuration: configuration)
        guard let image = images.first ?? nil else {
            throw RuntimeError.imageGenerationFailed
        }

        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputDirectory = documents.appendingPathComponent("Generated", isDirectory: true)
        try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let destination = outputDirectory.appendingPathComponent("image-\(UUID().uuidString).png")

        guard let imageDestination = CGImageDestinationCreateWithURL(
            destination as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw RuntimeError.imageGenerationFailed
        }
        CGImageDestinationAddImage(imageDestination, image, nil)
        guard CGImageDestinationFinalize(imageDestination) else {
            throw RuntimeError.imageGenerationFailed
        }
        return destination
    }

    func unload() async {
        pipeline?.unloadResources()
        pipeline = nil
    }
}
