# Bible App (Flutter)

Offline AI-powered Bible companion mobile app with:
- Bible reading and search
- Panic support guidance flow
- Journal and prayer support
- Local-only data and local model inference

No cloud backend is required for core app functionality.

## Requirements

- Flutter SDK (stable)
- Dart SDK (comes with Flutter)
- Android Studio and/or Xcode (for device builds)
- Git

Check your setup:

```bash
flutter --version
flutter doctor
```

## Quick Start

1. Clone the repository.
2. Open the project root (`Bible-App/`).
3. Install dependencies.
4. (Optional but recommended) add the local model file.
5. Run the app.

```bash
git clone <your-repo-url>
cd Bible-App
flutter pub get
flutter run
```

## Local Model Setup (Optional)

The app is designed to keep running even if the local model is not available.

If you want local AI generation enabled:

1. Download model: `gemma-270m-it-Q4_K_M.gguf`
2. Place it in: `assets/models/`
3. Rename to: `gemma-270m.gguf`

Final expected path:

`assets/models/gemma-270m.gguf`

Model weights are excluded by `.gitignore` and must not be committed.

## Project Structure

```text
Bible-App/
├── lib/
│   ├── core/
│   ├── data/
│   ├── features/
│   │   ├── bible/
│   │   ├── panic/
│   │   ├── journal/
│   │   └── home/
│   ├── ai/
│   └── main.dart
├── assets/
│   ├── bible/
│   ├── panic/
│   └── models/
├── docs/
├── scripts/
├── test/
├── pubspec.yaml
└── .gitignore
```

## Data Files

- Bible datasets: `assets/bible/`
- Panic dataset: `assets/panic/panic_responses.jsonl`
- Model directory: `assets/models/`

Datasets can remain in-repo while small. If they grow significantly, move them to downloadable assets via scripts.

## Useful Commands

```bash
# Get dependencies
flutter pub get

# Run analyzer
flutter analyze --no-fatal-infos

# Run tests
flutter test

# Build release APK
flutter build apk --release
```

## Troubleshooting

If asset errors appear (for example missing Bible JSON):

```bash
flutter clean
flutter pub get
flutter run
```

If model fails to initialize:
- Confirm file exists at `assets/models/gemma-270m.gguf`
- Confirm filename is exact
- App should still start without model inference

## Contributing

1. Create a branch.
2. Make changes.
3. Run analyze/tests.
4. Open a pull request.

```bash
git checkout -b feat/your-change
flutter analyze --no-fatal-infos
flutter test
git add .
git commit -m "Describe your change"
git push origin feat/your-change
```
