#!/usr/bin/env python3
"""Fast repository checks that do not need a running Quickshell session."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def load_json(path: Path):
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def main() -> int:
    manifest = load_json(ROOT / "manifest.json")
    required = {"schemaVersion", "id", "name", "version", "author", "description", "kinds", "entryPoints"}
    missing = required.difference(manifest)
    if missing:
        raise SystemExit("manifest missing: " + ", ".join(sorted(missing)))
    if manifest["schemaVersion"] != 1:
        raise SystemExit("unsupported manifest schema")
    if manifest["id"] != "org.bloom.omarchy":
        raise SystemExit("unexpected plugin id")
    for kind, entry in manifest["entryPoints"].items():
        if not (ROOT / entry).exists():
            raise SystemExit(f"missing entry point for {kind}: {entry}")

    for path in sorted((ROOT / "scenes").glob("*.json")):
        scene = load_json(path)
        for key in ("id", "name", "accent", "defaultWallpapers"):
            if key not in scene:
                raise SystemExit(f"{path.name} missing {key}")

    for path in sorted((ROOT / "assets/wallpapers/default").glob("*/*")):
        if path.suffix.lower() not in {".webp", ".png", ".jpg", ".jpeg", ".avif"}:
            raise SystemExit(f"unsupported wallpaper asset: {path}")

    qml = "\n".join(path.read_text(encoding="utf-8") for path in ROOT.glob("*.qml"))
    if ".svg" in qml or re.search(r"(?i)\bsvg\b", qml):
        raise SystemExit("QML must not reference SVG assets")
    if not (ROOT / "docs/OMARCHY_BLOOM_SPEC.md").exists():
        raise SystemExit("implementation spec is not stored in the repository")
    service = (ROOT / "Service.qml").read_text(encoding="utf-8")
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    if (
        "launchAtStartup" not in service
        or "bloomActive" not in service
        or "firstRun" not in service
        or "onboardingComplete" not in service
        or "workspaceState" not in service
        or "omarchy-theme-bg-set" not in service
        or "Open at login" not in readme
    ):
        raise SystemExit("startup launch preference is not fully documented")
    print("Bloom repository checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
