#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.request
from pathlib import Path
from typing import Any

import higgsfield_client

ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = ROOT / "generator" / "data"
ASSETS_DIR = ROOT / "assets"
VIDEOS_DIR = ASSETS_DIR / "videos"
METADATA_DIR = ASSETS_DIR / "metadata"
GENERATED_AUDIO_DIR = ASSETS_DIR / "audio" / "generated"

DEFAULT_MODEL = "higgsfield/lipsync-2"
DEFAULT_RESOLUTION = "1080p"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate phonics videos from any JSON file in generator/data."
    )
    parser.add_argument(
        "--language",
        action="append",
        dest="languages",
        help="Language code(s) to process, for example --language en --language fr.",
    )
    parser.add_argument(
        "--model",
        default=os.getenv("HF_MODEL_ID", DEFAULT_MODEL),
        help=(
            "Higgsfield model ID. Defaults to higgsfield/lipsync-2. "
            "Override with HF_MODEL_ID or this flag if your account uses a different avatar model."
        ),
    )
    parser.add_argument(
        "--resolution",
        default=os.getenv("HF_RESOLUTION", DEFAULT_RESOLUTION),
        help="Video resolution sent to Higgsfield. Defaults to 1080p.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Regenerate videos even when the target MP4 already exists.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate inputs and print planned work without contacting Higgsfield.",
    )
    return parser.parse_args()


def require_credentials() -> None:
    if os.getenv("HF_KEY"):
        return
    if os.getenv("HF_API_KEY") and os.getenv("HF_API_SECRET"):
        return
    raise SystemExit(
        "Missing Higgsfield credentials. Set HF_KEY or both HF_API_KEY and HF_API_SECRET."
    )


def slugify(value: str) -> str:
    slug = re.sub(r"[^\w]+", "_", value.strip(), flags=re.UNICODE)
    slug = slug.strip("_")
    return slug or "item"


def load_language_payloads(languages: list[str] | None) -> list[tuple[str, list[dict[str, Any]]]]:
    files = sorted(DATA_DIR.glob("*.json"))
    if languages:
        requested = {code.lower() for code in languages}
        files = [path for path in files if path.stem.lower() in requested]

    if not files:
        raise SystemExit(f"No JSON files found to process in {DATA_DIR}.")

    payloads: list[tuple[str, list[dict[str, Any]]]] = []
    for path in files:
        data = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(data, list):
            raise SystemExit(f"{path} must contain a top-level array.")
        payloads.append((path.stem, data))
    return payloads


def upload_if_needed(reference: str) -> str:
    if reference.startswith(("http://", "https://")):
        return reference

    local_path = ROOT / reference
    if not local_path.exists():
        raise FileNotFoundError(f"Referenced file does not exist: {local_path}")

    return higgsfield_client.upload_file(str(local_path))


def download_file(url: str, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(url) as response:
        destination.write_bytes(response.read())


def extract_audio_url(result: dict[str, Any]) -> str | None:
    audio = result.get("audio")
    if isinstance(audio, dict):
        return audio.get("url")
    if isinstance(audio, list) and audio:
        first_item = audio[0]
        if isinstance(first_item, dict):
            return first_item.get("url")
    return None


def write_metadata(
    *,
    language: str,
    entry: dict[str, Any],
    model_id: str,
    resolution: str,
    video_path: Path,
    result: dict[str, Any],
    audio_path: Path | None,
) -> None:
    metadata_path = METADATA_DIR / language / f"{slugify(entry['letter'])}.json"
    metadata_path.parent.mkdir(parents=True, exist_ok=True)
    metadata = {
        "language": language,
        "model_id": model_id,
        "resolution": resolution,
        "letter": entry["letter"],
        "pronunciation": entry["pronunciation"],
        "script": entry["script"],
        "example_words": entry.get("example_words", []),
        "avatar_image": entry["avatar_image"],
        "video_path": str(video_path.relative_to(ROOT)),
        "video_url": result.get("video", {}).get("url"),
        "audio_path": str(audio_path.relative_to(ROOT)) if audio_path else None,
        "request_id": result.get("request_id"),
        "status": result.get("status"),
    }
    metadata_path.write_text(
        json.dumps(metadata, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def generate_for_entry(
    *,
    language: str,
    entry: dict[str, Any],
    model_id: str,
    resolution: str,
    force: bool,
    dry_run: bool,
) -> None:
    letter = str(entry["letter"])
    slug = slugify(letter)
    video_path = VIDEOS_DIR / language / f"{slug}.mp4"

    if video_path.exists() and not force:
        print(f"Skipping {language}:{letter} because {video_path} already exists.")
        return

    if dry_run:
        print(f"[dry-run] Would generate {video_path} from model {model_id}.")
        return

    image_url = upload_if_needed(str(entry["avatar_image"]))
    arguments = {
        "prompt": entry["script"],
        "image": image_url,
        "resolution": resolution,
    }

    print(f"Submitting {language}:{letter} to {model_id}...")
    result = higgsfield_client.subscribe(model_id, arguments=arguments)

    video_url = result.get("video", {}).get("url")
    if not video_url:
        raise RuntimeError(f"No video URL returned for {language}:{letter}: {result}")

    download_file(video_url, video_path)
    print(f"Saved video to {video_path}")

    audio_path: Path | None = None
    audio_url = extract_audio_url(result)
    if audio_url:
        audio_path = GENERATED_AUDIO_DIR / language / f"{slug}.mp3"
        download_file(audio_url, audio_path)
        print(f"Saved generated audio to {audio_path}")

    write_metadata(
        language=language,
        entry=entry,
        model_id=model_id,
        resolution=resolution,
        video_path=video_path,
        result=result,
        audio_path=audio_path,
    )


def main() -> int:
    args = parse_args()
    if not args.dry_run:
        require_credentials()
    payloads = load_language_payloads(args.languages)

    for language, entries in payloads:
        print(f"Processing {language} ({len(entries)} letters)")
        for entry in entries:
            required_fields = {"letter", "pronunciation", "script", "example_words", "avatar_image"}
            missing = required_fields.difference(entry)
            if missing:
                raise SystemExit(
                    f"Entry for language {language} is missing required fields: {sorted(missing)}"
                )
            generate_for_entry(
                language=language,
                entry=entry,
                model_id=args.model,
                resolution=args.resolution,
                force=args.force,
                dry_run=args.dry_run,
            )

    return 0


if __name__ == "__main__":
    sys.exit(main())
