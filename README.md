# Local AI Studio

A native, local-first AI studio for iPhone. Chat and image generation are designed to run on-device; the network is used only when you explicitly search for or download model files.

## Current implementation

- SwiftUI studio with Chat, Images, Models and Settings areas.
- Local model inventory in Application Support.
- Hugging Face model search for public GGUF repositories.
- Repository file browser showing GGUF files, sizes, download counts and licence tags.
- Streaming file downloads with HTTP Range resume support after interruption.
- Model files remain in app storage; prompts and conversations are not sent to Hugging Face.

## Still in development

- llama.cpp runtime integration and real chat generation.
- Conversation persistence, cancellation and generation controls.
- A tested on-device image-generation runtime.
- Device memory/thermal profiling, signed Ad Hoc IPA automation and physical iPhone validation.

The current Images and Chat screens are not yet complete inference clients. Do not treat a model file appearing in the library as proof that it is compatible or runnable.

## Build

1. Install Xcode and XcodeGen.
2. Run `xcodegen generate`.
3. Open `LocalAIStudio.xcodeproj` and build the `LocalAIStudio` scheme.

GitHub Actions performs an unsigned iOS Simulator build on each branch update.

## Privacy

No account is required for public Hugging Face search. Model discovery and downloads require an internet connection. Once downloaded, model files are stored locally. The app does not upload prompts, chat history, images or local files.

## Project

Bundle identifier: `com.srgtcauliflour.LocalAIStudio`
Minimum deployment target: iOS 18.0
Primary device target: iPhone 17 Pro Max

See [Architecture](Documentation/ARCHITECTURE.md), [Model compatibility](Documentation/MODEL-COMPATIBILITY.md) and [Build/signing](Documentation/BUILDING.md).
