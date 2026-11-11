# Architecture

SwiftUI feature screens depend on application state and service abstractions, not concrete inference libraries. Chat and image generation use independent runtime adapters so either engine can be replaced without rewriting the UI.

## Model discovery and storage

- Search public Hugging Face model metadata through the Hub API.
- Filter catalogue results to GGUF repositories for the first supported chat-model workflow.
- Fetch repository file metadata before offering a download.
- Stream selected model files into Application Support/Models.
- Preserve interrupted partial downloads and resume with HTTP Range when the Hub responds with a partial-content response.
- Do not execute repository scripts, model-card code or downloaded files during installation.
- Treat repository metadata and licence labels as untrusted data; users remain responsible for checking model terms.

Public models are supported by the current browser. Gated/private repositories and authenticated downloads are not yet implemented.

## Runtime evaluation

- Chat: integrate llama.cpp with Metal for GGUF models; pin a tested upstream revision.
- Image generation: evaluate Core ML or a separately namespaced diffusion runtime. Avoid linking two incompatible ggml builds into one process without resolving symbol and Metal-resource collisions.
- Runtime adapters own model load, inference, cancellation and unload lifecycle.

A file being downloadable does not mean it is compatible. Only expose models as runnable after format, architecture and on-device tests pass.

## Privacy and networking

Network access is isolated to model discovery, metadata and explicit downloads. Prompts, conversations, generated images and local files are not uploaded. Verify both inference paths in airplane mode after model installation.

## Memory policy

Do not load chat and diffusion weights concurrently by default. Estimate memory before loading, unload before switching models, respond to memory warnings, and reduce workload under thermal pressure. Compatibility must be measured on-device, not guessed from parameter count.
