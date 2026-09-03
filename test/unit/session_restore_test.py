#!/usr/bin/env python3
"""Focused checks for Bloom's workspace-first session restore."""

from __future__ import annotations

import importlib.machinery
import importlib.util
import json
from pathlib import Path
import tempfile
from unittest import mock


ROOT = Path(__file__).resolve().parents[2]
LOADER = importlib.machinery.SourceFileLoader(
    "bloom_session", str(ROOT / "scripts/bloom-session")
)
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
assert SPEC is not None
SESSION = importlib.util.module_from_spec(SPEC)
LOADER.exec_module(SESSION)


def test_active_workspace_first() -> None:
    windows = [{"workspace": 5}, {"workspace": 2}, {"workspace": 3}]
    assert SESSION.workspace_order(windows, 3) == [3, 2, 5]


def test_saved_geometry_is_normalized() -> None:
    assert SESSION.normalize_pair(["40", 120]) == [40, 120]
    assert SESSION.normalize_pair(["bad", 120]) == [0, 0]


def test_snapshot_replaces_closed_apps_with_current_window_set() -> None:
    first = {"class": "first", "workspace": 1}
    closed = {"class": "closed", "workspace": 2}
    with tempfile.TemporaryDirectory() as directory:
        session_file = Path(directory) / "desktop-session.json"
        snapshot_time = Path(directory) / "snapshot.time"
        with (
            mock.patch.object(SESSION, "SESSION_FILE", session_file),
            mock.patch.object(SESSION, "LAST_SNAPSHOT", snapshot_time),
            mock.patch.object(
                SESSION, "snapshot_clients", side_effect=[[first, closed], [first]]
            ),
            mock.patch.object(SESSION, "hypr_json", return_value={"id": 1}),
        ):
            assert SESSION.snapshot()
            assert SESSION.snapshot()
        saved = json.loads(session_file.read_text(encoding="utf-8"))
    assert saved["windows"] == [first]


def test_restore_finishes_first_workspace_before_next() -> None:
    payload = {
        "schemaVersion": SESSION.SCHEMA_VERSION,
        "activeWorkspace": 3,
        "windows": [
            {"order": 2, "workspace": 5, "class": "later"},
            {"order": 1, "workspace": 3, "class": "first"},
        ],
    }
    restored: list[int] = []
    with (
        mock.patch.object(SESSION, "read_json", return_value=payload),
        mock.patch.object(SESSION, "dispatch", return_value=True),
        mock.patch.object(
            SESSION,
            "restore_workspace",
            side_effect=lambda targets, claimed: restored.append(targets[0]["workspace"]),
        ),
    ):
        assert SESSION.restore()
    assert restored == [3, 5]


def test_launch_targets_saved_workspace_silently() -> None:
    target = {
        "workspace": 4,
        "launch": {"desktopId": "org.example.Editor", "executable": ""},
    }
    with (
        mock.patch.dict(SESSION.core, {"valid_desktop_id": lambda value: True}),
        mock.patch.object(SESSION.subprocess, "run") as run,
    ):
        assert SESSION.launch_target(target)
    run.assert_called_once()
    assert run.call_args.args[0] == [
        "hyprctl",
        "dispatch",
        "exec",
        "[workspace 4 silent] gtk-launch org.example.Editor",
    ]


def test_unavailable_ipc_preserves_snapshot() -> None:
    with (
        mock.patch.object(SESSION, "restore_enabled", return_value=True),
        mock.patch.object(SESSION, "already_restored_this_boot", return_value=False),
        mock.patch.object(SESSION, "hypr_json", return_value=None),
        mock.patch.object(SESSION, "restore") as restore,
        mock.patch.object(SESSION, "snapshot") as snapshot,
        mock.patch.object(SESSION, "mark_restored_this_boot") as mark,
    ):
        SESSION.auto()
    restore.assert_not_called()
    snapshot.assert_not_called()
    mark.assert_not_called()


if __name__ == "__main__":
    test_active_workspace_first()
    test_saved_geometry_is_normalized()
    test_snapshot_replaces_closed_apps_with_current_window_set()
    test_restore_finishes_first_workspace_before_next()
    test_launch_targets_saved_workspace_silently()
    test_unavailable_ipc_preserves_snapshot()
    print("Bloom session restore checks passed")
