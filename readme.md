# Raasi AI Platform Overview

A unified developer-assistant stack composed of three tightly-coupled parts:

1. `main.py` — FastAPI backend orchestrating multi-model chat, autocomplete, and retrieval-augmented generation (RAG).
2. `Fine_tune_Qwen.ipynb` — A reproducible Unsloth fine-tuning pipeline that adapts Qwen2.5-Coder for the Tatkal programming domain.
3. `vscode-extension/` — A VS Code extension (packaged as `raasi-ai-1.0.0.vsix`) that embeds the assistant directly in the IDE.

Together they deliver local-first privacy, cloud flexibility, and IDE-native workflows for developers.

---

## 1. Backend (`main.py`)

**Purpose**  
Runs the FastAPI service consumed by the extension (and any other clients). It routes incoming chat/completion/RAG requests to the appropriate model provider (local Ollama, Google Gemini, or OpenAI) while keeping a unified contract.

**Key Capabilities**
- **Config-driven multi-model routing**: `get_api_config` picks URLs, models, and keys from `app.properties` or env vars. “token” mode aliases to OpenAI for backwards compatibility.
- **Retrieval-Augmented Generation**: `load_documents_from_directory`, `create_embeddings`, and `build_vectorstore_and_chain` chunk project files, embed with `sentence-transformers/all-MiniLM-L6-v2`, persist to FAISS, and expose `/ask` queries via LangChain’s `RetrievalQA`.
- **Unified LangChain LLM wrapper**: `UnifiedLLM` standardizes prompt dispatch, response parsing, and identification metadata.
- **Context-aware prompt builders**: `build_chat_prompt`, `build_chat_messages_for_cloud`, and `build_gemini_messages` inject attached file snippets only into the first user message and tailor formatting per provider.
- **Endpoints**:
  - `POST /chat`: Conversational agent with optional file references.
  - `POST /complete`: Fill-in-the-middle autocomplete endpoint with deterministic defaults.
  - `POST /ask`: Answers backed by the FAISS retriever, returning sources.
  - `POST /reindex`: Rebuilds the FAISS index on demand.
  - `GET /health`, `GET /config`, `GET /`: Diagnostics and metadata.

**Runtime & Deployment Notes**
- Local dev: `./start_local.sh` checks `app.properties`, warns if Ollama is down, and runs `uvicorn main:app --reload --host 0.0.0.0 --port 8000`.
- Container: `Dockerfile` uses a two-stage build, installs curl for the Ollama health probe, copies config defaults, ensures `start_local.sh` is executable, and runs it as the entrypoint.
- Persisting RAG: `faiss_index/` is created if missing; mount it as a volume in Docker to reuse embeddings.

---

## 2. Fine-Tuning Notebook (`Fine_tune_Qwen.ipynb`)

**Purpose**  
Documents the full pipeline for customizing `Qwen/Qwen2.5-Coder-1.5B-Instruct` using Unsloth so we can ship a domain-adapted local model (“Tatkal Assistant”) that mirrors the backend interface.

**Highlights**
- **Two-stage curriculum**:
  - *Stage 1 (“Textbook”)*: 16 cleaned code samples (`project_code.jsonl`) emphasized language + path metadata for better structural reasoning.
  - *Stage 2 (“Workbook”)*: 30 conversational instructions (`chat_dataset.jsonl`) wrapped in `<|im_start|>` chat format with a Tatkal-specific system prompt.
- **Memory-efficient training**:
  - Loads the base model in 4-bit (`load_in_4bit=True`), sequence length 2048.
  - Applies LoRA on key Qwen projection modules (`q_proj`, `k_proj`, etc.) with rank 64.
  - Trainer uses `per_device_train_batch_size=2`, `gradient_accumulation_steps=4`, `adamw_8bit`, and BF16 if available.
- **Exports & Deployment**: Notebook ends by saving adapters and exporting to GGUF for use with Ollama or other local runtimes—aligning with the backend’s “local” mode.

**Critical Hyperparameters & Rationale**
- `max_seq_length=2048`: Matches IDE-sized contexts so completions can consider multi-function files.
- `load_in_4bit=True` + `dtype=bf16/auto`: Keeps VRAM under 24 GB while retaining precision where hardware allows.
- **LoRA setup**: `r=64`, `lora_alpha=16`, `lora_dropout=0`, targeting the full QKV/MLP projection stack (`q_proj`, `k_proj`, `v_proj`, `o_proj`, `gate_proj`, `up_proj`, `down_proj`) so both attention and feed-forward pathways learn Tatkal-specific patterns.
- **Optimizer**: `adamw_8bit` (via bitsandbytes) plus `weight_decay=0.01` balances stability with memory savings.
- **Schedule**: `num_train_epochs=10`, `learning_rate=2e-4`, `warmup_steps=5`, `linear` scheduler—aggressive enough to fit the small curated datasets without catastrophic forgetting.
- **Batching**: `per_device_train_batch_size=2`, `gradient_accumulation_steps=4` → effective batch size 8, which matched the dataset sizes (16 + 30 samples) and kept gradients smooth.
- **Precision**: `bf16` when supported, otherwise `fp16`, ensuring Unsloth’s fused kernels stay stable.
- **Prompt wrapping**: Every Stage 2 example injects `system_prompt="You are a precise Indian Railways Tatkal booking assistant..."` inside `<|im_start|>` tokens, enforcing persona adherence post-tuning.

**Talking Points**
- Demonstrates we own the data pipeline (JSONL datasets, formatting helpers).
- Shows practical fine-tuning skill (Unsloth patches, LoRA configuration, multi-stage training).
- Provides quantitative hooks (e.g., 4.57% of parameters trained, 20 total steps Stage 1).

---

## 3. VS Code Extension (`vscode-extension/`)

**Purpose**  
Delivers the Raasi AI experience directly inside VS Code. Packaged as `raasi-ai-1.0.0.vsix` for easy sideloading during demos or distribution.

**Notable Features**
- **Multi-model UX**: Agent dropdown toggles Local (Ollama), Gemini, or OpenAI modes; chat history auto-resets when switching to avoid cross-context leakage.
- **Context-rich chat**: Attach files or selections; responses offer “create” and “apply” actions to scaffold new files or patch existing ones.
- **Autocomplete**: Inline completions triggered automatically or via `Cmd/Ctrl + L`; respects backend FIM API.
- **VS Code integrations**: Command palette (`Raasi: Open Chat`, `Raasi: Trigger Inline Completion`), right-click “Ask Raasi” and “Fix in Chat”, settings for backend URL / API mode / max file chars.
- **Documentation & Assets**: README, `media/` assets, TypeScript source under `src/`, compiled JS in `dist/`, packaging metadata in `package.json` + `tsconfig.json`.

**Usage Recap (per extension README)**
1. Install backend, set `raasi.backendUrl` to `http://localhost:8000`.
2. Optional: install/pull Ollama models or configure Gemini/OpenAI keys.
3. Install VSIX, open `Raasi: Open Chat`, start coding with chat + autocomplete.

---

## System Flow

1. Developer opens VS Code, installs the extension, and points it to the FastAPI backend.
2. Extension sends chat/completion requests to `/chat` or `/complete`, attaching selected file context, and requests answers from the chosen model mode.
3. Backend uses `UnifiedLLM` to route the prompt to Ollama (fine-tuned Qwen), Gemini, or OpenAI, optionally enriches prompts with FAISS-sourced snippets, and streams responses back to the extension.
4. For knowledge-grounded questions, `/ask` leverages FAISS + LangChain to return answers plus source snippets.
5. Fine-tuned Qwen weights (from the notebook) can replace the default local model by updating `local.model.name` or the Ollama Modelfile, keeping the stack fully local.

---

## Judge Q&A Cheat Sheet

| Question | Data-backed Answer |
| --- | --- |
| **How do you ensure privacy while still offering strong models?** | Local mode uses Ollama endpoints (`local.api.url`), so code never leaves the machine. Cloud modes (Gemini/OpenAI) are opt-in via `app.properties`, and model switching is one dropdown in the extension. |
| **What evidence shows you can customize models?** | `Fine_tune_Qwen.ipynb` fine-tunes Qwen2.5-Coder with Unsloth: 16 project code samples + 30 chat pairs, LoRA rank 64, 4-bit loading, two-stage curriculum, and exports to GGUF for local inference. |
| **How do you ground answers in project code?** | On startup, `load_index_if_exists` pulls a persisted FAISS index (chunks of files under `DOCUMENTS_PATH`). `/ask` returns `sources` with file paths and snippets, so we can cite provenance. |
| **What happens if new files are added?** | Call `POST /reindex` with an optional `path`; backend rebuilds embeddings using `RecursiveCharacterTextSplitter` and overwrites the FAISS index. |
| **How does the extension keep context manageable?** | `build_file_context_block` truncates each attached file to `FILE_CONTEXT_MAX_CHARS / num_files`, wraps snippets in fenced blocks, and only injects them into the first user message to avoid runaway prompts. |
| **Can the system run in containers for demos?** | Yes. The multi-stage `Dockerfile` installs dependencies, copies `app.properties` defaults, checks for Ollama via curl (same logic as `start_local.sh`), exposes port 8000, and sets the entrypoint to the script so logs/showcase messaging remain identical to local runs. |
| **What makes autocomplete reliable?** | `/complete` enforces low temperature (`COMPLETION_TEMPERATURE=0.0` by default), limits max tokens to 128, sends raw prompts (`raw=True` for Ollama), and adds stop tokens (e.g., `"class "`, `"def "`) to keep completions short and compilable. |
| **How quickly can you swap models?** | Update `app.properties` (e.g., `local.model.name=qwen25-coder-tatkal-assistant`), restart the backend, and the extension’s agent dropdown immediately reflects Local/Gemini/OpenAI choices. |

---

## Quick Commands Reference

- **Local run**: `python main.py` or `./start_local.sh`
- **Docker build/run**: `docker build -t raasi-ai . && docker run -p 8000:8000 raasi-ai`
- **VS Code extension install**: `code --install-extension vscode-extension/raasi-ai-1.0.0.vsix`
- **Reindex documents**: `curl -X POST http://localhost:8000/reindex`

Use this README as your rapid refresher before demos or judge Q&A—each section maps directly to the three core assets (`main.py`, `Fine_tune_Qwen.ipynb`, `vscode-extension/`). Good luck at the hackathon!

