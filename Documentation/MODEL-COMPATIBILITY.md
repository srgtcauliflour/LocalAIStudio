# Model compatibility

Treat Hugging Face repositories as untrusted metadata. Inspect architecture, tensor formats, tokenizer assets, licence and pinned repository revision before offering installation.

| Task | Format | Runtime candidate | Status |
|---|---|---|---|
| Chat | GGUF | llama.cpp / Metal | Planned |
| Chat | MLX | MLX Swift | Research |
| Chat / vision | Core ML | Core ML | Future |
| Image generation | Stable Diffusion family | Mirage or stable-diffusion.cpp | Research |
| Image generation | Core ML packages | Core ML | Future |

The catalogue should filter by task, architecture, quantisation, size and licence; display the model card and licence; support resumable downloads and integrity checks; and never execute repository-provided scripts automatically.

The primary performance target is iPhone 17 Pro Max. Measure available memory and thermal state at runtime. Do not advertise a model as compatible until it passes load and generation tests on a physical device.
