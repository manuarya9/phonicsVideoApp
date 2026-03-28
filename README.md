# Multi-Language Phonics App

This repository contains two connected pieces:

- `generator/`: a language-agnostic asset pipeline that reads JSON lesson data and generates image-to-video clips with the official `runwayml` Python SDK.
- `PhonicsVideoApp.xcodeproj`: a SwiftUI iPhone/iPad app that bundles the same JSON files and any generated media from `assets/`.

## Repository Layout

```text
App/                      SwiftUI source files and asset catalog
PhonicsVideoApp.xcodeproj Xcode project
assets/                   Generated videos, metadata, images, and audio
generator/
  data/                   Language JSON files shared with the app
  generate_assets.py      Higgsfield automation script
  requirements.txt        Python dependencies
.github/workflows/        GitHub Action for automated generation
```

## 1. Install Dependencies

Python 3.10+ is recommended.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r generator/requirements.txt
```

## 2. Configure Runway Credentials

Runway's official SDK expects the API key in `RUNWAYML_API_SECRET`:

```bash
export RUNWAYML_API_SECRET="your-runway-api-key"
```

Optional overrides:

```bash
export RUNWAY_MODEL="gen4_turbo"
export RUNWAY_RATIO="1280:720"
export RUNWAY_DURATION="5"
```

The current generator uses Runway's `image_to_video.create(...).wait_for_task_output()` flow. Local avatar images are encoded as data URIs before the request, matching Runway's documented image-input flow.

## 3. Prepare Lesson Data

Each file in `generator/data/` is a language pack. The filename becomes the language code in the app and output folders.

Example shape:

```json
{
  "letter": "A",
  "pronunciation": "[ay]",
  "script": "[calm tone] Hi kids! Let's learn the letter A... A is for apple...",
  "example_words": [
    {
      "word": "apple",
      "image": "assets/images/en/apple.png",
      "audio": "assets/audio/en/apple.mp3"
    }
  ],
  "avatar_image": "assets/images/avatars/en_teacher.jpg"
}
```

Starter packs are included for:

- English: `generator/data/en.json`
- Hindi: `generator/data/hi.json`
- Arabic: `generator/data/ar.json`
- French: `generator/data/fr.json`

Before a real generation run, replace the placeholder asset references with actual avatar images and example-word media inside `assets/images/` and `assets/audio/`.

## 4. Generate Videos

Validate the data without calling the API:

```bash
python generator/generate_assets.py --dry-run
```

Generate all languages:

```bash
python generator/generate_assets.py
```

Generate selected languages only:

```bash
python generator/generate_assets.py --language en --language fr
```

Check your current credit balance:

```bash
python generator/generate_assets.py --check-balance
```

Override the default model explicitly if needed:

```bash
python generator/generate_assets.py --language en --model "gen4_turbo"
```

Force regeneration even if videos already exist:

```bash
python generator/generate_assets.py --force
```

Outputs:

- `assets/videos/<language>/<letter>.mp4`
- `assets/metadata/<language>/<letter>.json`
- Runway currently returns video output only in this generator path; example-word audio remains a separate asset you manage under `assets/audio/`

## 5. Build the iOS/iPadOS App

1. Open [PhonicsVideoApp.xcodeproj](/Users/manuarya/Documents/Projects/mobileapp-1/PhonicsVideoApp.xcodeproj).
2. Select an iPhone or iPad simulator.
3. Build and run.

The app:

- loads every JSON file bundled from `generator/data/`
- lets the learner switch languages with a picker
- shows letter tiles in source order or scrambled order
- opens a detail lesson that autoplays the pre-generated video when present
- displays a mouth-animation cue
- plays example-word audio on tap
- uses large typography and VoiceOver-friendly controls

Because `assets/` is bundled as a folder resource, newly generated videos and supporting media become available in the app without changing Swift code.

## 6. Add a New Language

1. Create a new JSON file in `generator/data/`, for example `es.json`.
2. Add avatar/example assets under `assets/images/` and `assets/audio/`.
3. Run `python generator/generate_assets.py --language es`.
4. Add any new generated files to version control.
5. Rebuild the app and choose the new language from the picker.

## 7. GitHub Automation

The workflow at `.github/workflows/generate-assets.yml`:

- triggers on pushes that modify `generator/data/**` or `assets/images/**`
- installs the Python dependencies
- runs the generator with `RUNWAYML_API_SECRET` from GitHub Secrets
- creates a pull request containing updated generated assets

Required GitHub configuration:

- Repository secret: `RUNWAYML_API_SECRET`
- Optional repository variable: `RUNWAY_MODEL`

## Educational Notes

- Keep each video short, direct, and repetition-friendly.
- Prefer clear, front-facing avatar photos for lip sync quality.
- Use multiple concrete example words per letter.
- For each new language, preserve culturally relevant vocabulary and imagery.
- Consider adding mini-games later for blending, segmentation, and grapheme recognition practice.

## References

The generator implementation aligns with the official Runway SDK and API docs:

- [Runway API Getting Started](https://docs.dev.runwayml.com/guides/using-the-api/)
- [Runway Python SDK on PyPI](https://pypi.org/project/runwayml/)
- [Runway API Reference](https://docs.dev.runwayml.com/api/)
