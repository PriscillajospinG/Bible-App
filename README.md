# Bible-App

Offline AI-powered Bible companion mobile app built with Flutter.

## Project Layout

Current Flutter app root is `bible_app/`.

```text
Bible-App/
├── bible_app/
│   ├── lib/
│   │   ├── core/
│   │   │   ├── utils/
│   │   │   ├── constants/
│   │   │   └── services/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── repositories/
│   │   │   └── loaders/
│   │   ├── features/
│   │   │   ├── bible/
│   │   │   ├── panic/
│   │   │   ├── journal/
│   │   │   └── home/
│   │   ├── ai/
│   │   └── main.dart
│   ├── assets/
│   │   ├── bible/
│   │   ├── panic/
│   │   └── models/
│   ├── docs/
│   ├── scripts/
│   ├── test/
│   ├── pubspec.yaml
│   └── .gitignore
├── Dataset/
├── LICENSE
├── README.md
└── .gitignore
```

## Local AI Model Setup

Model weights are intentionally excluded from Git.

1. Download model: `gemma-270m-it-Q4_K_M.gguf`.
2. Place it at: `bible_app/assets/models/gemma-270m.gguf`.
3. Never commit `.gguf`, `.bin`, or `.pt` files.

See `bible_app/assets/models/README.md` for details.

## Dataset Policy

- Bible JSON and panic JSONL datasets can stay in repository while small.
- Move large datasets to external download scripts when they grow.

## Clean Git Workflow

```bash
cd /Users/priscillajosping/Downloads/Bible-App

# Initialize if needed
git init

# Ensure large model is not tracked
git rm --cached bible_app/assets/models/gemma-270m.gguf 2>/dev/null || true

# Stage only required development files
git add bible_app/lib/
git add bible_app/assets/bible/
git add bible_app/assets/panic/
git add bible_app/assets/models/README.md
git add bible_app/pubspec.yaml
git add bible_app/README.md
git add README.md
git add .gitignore bible_app/.gitignore
git add bible_app/docs/ bible_app/scripts/

git commit -m "Initial clean project structure"
```

## Push to GitHub

```bash
cd /Users/priscillajosping/Downloads/Bible-App
git remote add origin https://github.com/<your-username>/Bible-App.git
git branch -M main
git push -u origin main
```