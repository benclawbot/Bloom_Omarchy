# Bloom session restore

Bloom can persist the current Hyprland desktop and restore it after a reboot.
The feature is enabled by default and is controlled from the Bloom top bar.

- **SAVE**: Bloom snapshots the desktop and restores the last setup once on the next boot.
- **FRESH**: Bloom skips restoration and leaves the saved snapshot untouched. Switching back to SAVE during the same boot starts saving the current desktop for the next reboot; it does not reopen the old session immediately.

## What is saved

The snapshot lives at `$XDG_STATE_HOME/omarchy-bloom/desktop-session.json` (normally `~/.local/state/omarchy-bloom/desktop-session.json`). It records normal Hyprland windows, workspace number, monitor index, tiling/floating state, geometry, fullscreen state, the active workspace, and a conservative application launch identity.

Bloom does **not** save or replay `/proc/.../cmdline`, shell commands, environment variables, or application arguments. It prefers a validated `.desktop` entry and falls back only to an absolute executable that still exists and is executable.

## Restore behavior

On the first session-manager tick of a boot Bloom takes an exclusive runtime lock and writes a boot marker before launching anything. This prevents duplicate restores when multiple bar instances exist or when the shell reloads the widget. Existing matching windows are reused before Bloom launches another application.

After the one-time restore attempt, SAVE mode writes atomic snapshots periodically. The previous session cannot be replaced by the empty desktop that exists before restoration because snapshotting is gated behind the one-time restore attempt.

FRESH mode is deliberately non-destructive: it marks the boot as handled, performs no launches, and does not overwrite the saved session.

## Limits

Hyprland exposes window geometry and workspace placement through IPC, but it does not expose a complete serializable dwindle tree through the client list. Bloom therefore restores application order, workspaces, floating/fullscreen state and saved dimensions, which normally recreates the prior tiling closely. Layouts may clamp dimensions or choose a different split tree in edge cases, especially when applications create windows in a different order than before.

Applications are responsible for their own internal state such as browser tabs, unsaved documents, terminal shells, and editor buffers. Bloom restores the desktop placement, not arbitrary application-private state.
