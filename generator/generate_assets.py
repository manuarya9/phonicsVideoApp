#!/usr/bin/env python3
from __future__ import annotations

import argparse
import base64
import json
import mimetypes
import os
import re
import sys
import urllib.request
from pathlib import Path
from typing import Any

from runwayml import RunwayML

ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = ROOT / "generator" / "data"
ASSETS_DIR = ROOT / "assets"
VIDEOS_DIR = ASSETS_DIR / "videos"
METADATA_DIR = ASSETS_DIR / "metadata"

DEFAULT_MODEL = "gen4_turbo"
DEFAULT_RATIO = "1280:720"
DEFAULT_DURATION = 5


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate phonics videos from any JSON file in generator/data using Runway."
    )
    parser.add_argument(
        "--language",
        action="append",
        dest="languages",
        help="Language code(s) to process, for example --language en --language fr.",
    )
    parser.add_argument(
        "--model",
        default=os.getenv("RUNWAY_MODEL", DEFAULT_MODEL),
        help="Runway image-to-video model ID. Defaults to gen4_turbo.",
    )
    parser.add_argument(
        "--ratio",
        default=os.getenv("RUNWAY_RATIO", DEFAULT_RATIO),
        help="Output ratio sent to Runway. Defaults to 1280:720.",
    )
    parser.add_argument(
        "--duration",
        type=int,
        default=int(os.getenv("RUNWAY_DURATION", str(DEFAULT_DURATION))),
        help="Video duration in seconds. Defaults to 5.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Regenerate videos even when the target MP4 already exists.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate inputs and print planned work without contacting Runway.",
    )
    parser.add_argument(
        "--check-balance",
        action="store_true",
        help="Print the current Runway credit balance and exit.",
    )
    return parser.parse_args()


def require_credentials() -> None:
    if os.getenv("RUNWAYML_API_SECRET"):
        return
    raise SystemExit("Missing Runway credentials. Set RUNWAYML_API_SECRET.")


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


def to_plain_data(value: Any) -> Any:
    if value is None or isinstance(value, (str, int, float, bool)):
        return value
    if isinstance(value, Path):
        return str(value)
    if isinstance(value, list):
        return [to_plain_data(item) for item in value]
    if isinstance(value, dict):
        return {key: to_plain_data(item) for key, item in value.items()}
    if hasattr(value, "model_dump"):
        return to_plain_data(value.model_dump())
    if hasattr(value, "to_dict"):
        return to_plain_data(value.to_dict())
    if hasattr(value, "__dict__"):
        return to_plain_data(vars(value))
    return str(value)


def image_reference_to_data_uri(reference: str) -> str:
    if reference.startswith(("https://", "data:", "runway://")):
        return reference

    local_path = ROOT / reference
    if not local_path.exists():
        raise FileNotFoundError(f"Referenced file does not exist: {local_path}")

    mime_type, _ = mimetypes.guess_type(local_path.name)
    if not mime_type:
        raise ValueError(f"Could not infer MIME type for {local_path}")

    encoded = base64.b64encode(local_path.read_bytes()).decode("utf-8")
    return f"data:{mime_type};base64,{encoded}"


def download_file(url: str, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(url) as response:
        destination.write_bytes(response.read())


def extract_video_url(task_data: dict[str, Any]) -> str | None:
    output = task_data.get("output")
    if isinstance(output, list) and output:
        first_item = output[0]
        if isinstance(first_item, str):
            return first_item
        if isinstance(first_item, dict):
            return first_item.get("url") or first_item.get("uri")
    if isinstance(output, dict):
        return output.get("url") or output.get("uri")
    return None


def write_metadata(
    *,
    language: str,
    entry: dict[str, Any],
    model_id: str,
    ratio: str,
    duration: int,
    video_path: Path,
    task_data: dict[str, Any],
) -> None:
    metadata_path = METADATA_DIR / language / f"{slugify(entry['letter'])}.json"
    metadata_path.parent.mkdir(parents=True, exist_ok=True)
    metadata = {
        "provider": "runway",
        "language": language,
        "model_id": model_id,
        "ratio": ratio,
        "duration": duration,
        "letter": entry["letter"],
        "pronunciation": entry["pronunciation"],
        "script": entry["script"],
        "example_words": entry.get("example_words", []),
        "avatar_image": entry["avatar_image"],
        "video_path": str(video_path.relative_to(ROOT)),
        "video_url": extract_video_url(task_data),
        "task_id": task_data.get("id"),
        "status": task_data.get("status"),
    }
    metadata_path.write_text(
        json.dumps(metadata, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def generate_for_entry(
    *,
    client: RunwayML | None,
    language: str,
    entry: dict[str, Any],
    model_id: str,
    ratio: str,
    duration: int,
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
        print(f"[dry-run] Would generate {video_path} from Runway model {model_id}.")
        return

    if client is None:
        raise RuntimeError("Runway client was not initialized.")

    prompt_image = image_reference_to_data_uri(str(entry["avatar_image"]))

    print(f"Submitting {language}:{letter} to Runway model {model_id}...")
    task = (
        client.image_to_video.create(
            model=model_id,
            prompt_image=prompt_image,
            prompt_text=entry["script"],
            ratio=ratio,
            duration=duration,
        )
        .wait_for_task_output()
    )
    task_data = to_plain_data(task)

    video_url = extract_video_url(task_data)
    if not video_url:
        raise RuntimeError(f"No video URL returned for {language}:{letter}: {task_data}")

    download_file(video_url, video_path)
    print(f"Saved video to {video_path}")

    write_metadata(
        language=language,
        entry=entry,
        model_id=model_id,
        ratio=ratio,
        duration=duration,
        video_path=video_path,
        task_data=task_data,
    )


def print_credit_balance(client: RunwayML) -> None:
    details = to_plain_data(client.organization.retrieve())
    balance = details.get("creditBalance")
    tier = details.get("tier", {}).get("name") or details.get("tier")
    print(f"Runway credit balance: {balance}")
    if tier:
        print(f"Runway tier: {tier}")


def main() -> int:
    args = parse_args()

    if args.check_balance:
        require_credentials()
        print_credit_balance(RunwayML())
        return 0

    client: RunwayML | None = None
    if not args.dry_run:
        require_credentials()
        client = RunwayML()

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
                client=client,
                language=language,
                entry=entry,
                model_id=args.model,
                ratio=args.ratio,
                duration=args.duration,
                force=args.force,
                dry_run=args.dry_run,
            )

    return 0


if __name__ == "__main__":
    sys.exit(main())
