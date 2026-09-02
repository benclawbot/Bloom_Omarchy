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
        or "Open at login" not in readme
    ):
        raise SystemExit("startup launch preference is not fully documented")

    wallpaper_helper = ROOT / "scripts/bloom-workspace-bg"
    if not wallpaper_helper.exists():
        raise SystemExit("workspace wallpaper helper is missing")
    wallpaper_source = wallpaper_helper.read_text(encoding="utf-8")
    for required_token in ("swaybg", "realpath", "uwsm-app"):
        if required_token not in wallpaper_source:
            raise SystemExit(f"workspace wallpaper helper missing: {required_token}")
    if "current/background" in wallpaper_source or "omarchy-theme-bg-set" in service:
        raise SystemExit("workspace wallpaper selection must not mutate Omarchy's global background")
    for required_token in (
        "workspaceBgCommand",
        "selectWallpaper",
        "wallpaperItemForPath",
        "workspaceState",
        "schemaVersion: 2",
    ):
        if required_token not in service:
            raise SystemExit(f"workspace wallpaper persistence missing: {required_token}")

    session = ROOT / "scripts/bloom-session"
    if not session.exists():
        raise SystemExit("session manager is missing")
    session_source = session.read_text(encoding="utf-8")
    compile(session_source, str(session), "exec")
    if "shell=True" in session_source or "/proc/{pid}/cmdline" in session_source:
        raise SystemExit("session manager must not replay shell/process command lines")
    for required_token in (
        "desktop-session.json",
        "restoreLastSetup",
        "session-restore.boot",
        "fcntl.flock",
        "os.replace",
        "gtk-launch",
        "movetoworkspacesilent",
    ):
        if required_token not in session_source:
            raise SystemExit(f"session manager missing safety/restore primitive: {required_token}")

    bar = (ROOT / "BarWidget.qml").read_text(encoding="utf-8")
    for required_token in ("SAVE", "FRESH", "bloom-session", "restoreLastSetup"):
        if required_token not in bar:
            raise SystemExit(f"top-bar session control missing: {required_token}")

    print("Bloom repository checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
