# Bible App (Flutter)

Offline AI-powered Bible companion mobile application.

## Modules

- `lib/core`: shared utilities, constants, and common services.
- `lib/data`: models, repositories, and data loaders.
- `lib/features`: feature modules (`bible`, `panic`, `journal`, `home`).
- `lib/ai`: local model integration, prompts, guidance, and emotion detection.

## Assets

- Bible datasets: `assets/bible/`
- Panic dataset: `assets/panic/panic_responses.jsonl`
- Local model folder: `assets/models/`

## Local Model (Not in Git)

Download:

`gemma-270m-it-Q4_K_M.gguf`

Place in:

`assets/models/`

Runtime expects:

`assets/models/gemma-270m.gguf`

Model weights are ignored by `.gitignore`.

## Run

```bash
flutter pub get
flutter run
```
