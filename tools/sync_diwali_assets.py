#!/usr/bin/env python3
"""Copy the web reference's optimised photos into the Flutter asset bundle.

The static reference (festive-ui/) and the Flutter storefront
(lib/diwali/) share one set of local JPEGs so both look the same. Run this
from anywhere after adding or replacing an image in festive-ui/assets/img:

    python3 tools/sync_diwali_assets.py

Only *.jpg files are copied; anything else is left alone. The script also
prints any asset that a Flutter source file refers to but that is missing,
which catches a typo in diwali_data.dart before a build does.
"""

from __future__ import annotations

import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "festive-ui" / "assets" / "img"
TARGET = ROOT / "assets" / "diwali"
DATA = ROOT / "lib" / "diwali" / "diwali_data.dart"


def main() -> int:
    if not SOURCE.is_dir():
        raise SystemExit(f"missing source folder: {SOURCE}")
    TARGET.mkdir(parents=True, exist_ok=True)

    copied = 0
    for image in sorted(SOURCE.glob("*.jpg")):
        destination = TARGET / image.name
        if not destination.exists() or image.stat().st_size != destination.stat().st_size:
            shutil.copy2(image, destination)
            copied += 1
    print(f"assets/diwali: {copied} updated, {len(list(TARGET.glob('*.jpg')))} total")

    if not DATA.is_file():
        return 0
    text = DATA.read_text(encoding="utf-8")
    referenced = set(re.findall(r"Diwali\w+\('([a-z0-9-]+)'", text))
    referenced |= set(re.findall(r"kDiwaliAssetRoot/([a-z0-9-]+)\.jpg", text))
    missing = sorted(name for name in referenced if not (TARGET / f"{name}.jpg").exists())
    if missing:
        print("WARNING: referenced images with no file:")
        for name in missing:
            print(f"  - {name}.jpg")
        return 1
    print(f"all {len(referenced)} referenced images are present")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
