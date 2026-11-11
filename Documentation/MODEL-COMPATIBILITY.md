# Model compatibility

The catalogue currently searches public Hugging Face GGUF repositories and can download GGUF files. It does not yet certify that a downloaded file will run.

| Task | Format | Runtime candidate | Status |
|---|---|---|---|
| Chat | GGUF | llama.cpp / Metal | Integration next |
| Chat / vision | GGUF multimodal | llama.cpp MTMD | Research |
| Chat | MLX | MLX Swift | Research |
| Image generation | Core ML packages | Core ML / Apple ml-stable-diffusion | Evaluation |
| Image generation | GGUF diffusion | stable-diffusion.cpp family | Evaluation; check ggml symbol compatibility |

Before recommending a model, inspect its architecture, tensor format, tokenizer assets, model card, licence and pinned repository revision. Search results and licence tags are metadata, not legal advice.

The catalogue should filter by task, architecture, quantisation, size and licence; display the model card and licence; support resumable downloads and integrity checks; and never execute repository-provided scripts automatically.

The primary performance target is iPhone 17 Pro Max. Measure available memory and thermal state at runtime. Do not advertise a model as compatible until it passes load and generation tests on a physical device.
