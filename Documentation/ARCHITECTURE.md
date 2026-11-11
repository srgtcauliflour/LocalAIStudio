# Architecture

SwiftUI feature screens depend on application state and service abstractions, not concrete inference libraries. Chat and image generation use independent runtime adapters so either engine can be replaced without rewriting the UI.

## Runtime evaluation
- Evaluate llama.cpp with Metal for GGUF chat models; pin a tested upstream revision and preserve licence notices.
- Evaluate MLX Swift only after confirming iOS support and memory/performance on physical hardware.
- Benchmark Mirage and stable-diffusion.cpp for image generation; choose a primary engine only after device testing.
- Runtime adapters own model load, inference, cancellation and unload lifecycle.

## Privacy and networking
Network access is isolated to model discovery, model metadata and explicit downloads. Prompts, conversations, generated images and local files are not uploaded. Verify both inference paths in airplane mode after model installation.

## Memory policy
Do not load chat and diffusion weights concurrently by default. Estimate memory before loading, unload before switching models, respond to memory warnings, and reduce workload under thermal pressure. Compatibility must be measured on-device, not guessed from parameter count.
