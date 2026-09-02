# Omarchy Bloom

## Product, Experience, and Technical Specification

| Field | Value |
| --- | --- |
| Product | Omarchy Bloom |
| Tagline | Your workspace, alive. |
| Target | Omarchy 4 / Quattro |
| Plugin ID | `io.github.<publisher>.omarchy-bloom` |
| Specification | 1.0 |
| Status | Implementation-ready |
| License target | MIT; original or permissively licensed visual assets |

---

## 1. Product statement

Omarchy Bloom transforms ordinary workspaces into **living scenes** and active AI coding sessions into a beautiful, navigable **Agent Constellation**.

Bloom should create two reactions in sequence:

1. Within ten seconds: “I have never seen a Linux desktop feel like this.”
2. Within ten minutes: “This helps me understand and move through my work.”

It is not a dashboard placed on top of Omarchy. It is a restrained ambient layer that responds to workspace, project, agents, time, media, and attention state while remaining subordinate to the user’s work.

The product is successful when the desktop feels calm at rest, expressive during transitions, and immediately informative when an agent needs attention.

---

## 2. Why Bloom belongs in Omarchy

Omarchy Quattro consolidates the bar, launcher, menus, notifications, on-screen displays, control panels, lock screen, and related shell behavior in a single Quickshell process. Its plugin contract includes bar widgets, panels, overlays, menus, services, and full replacement bars. Bloom should use those native surfaces and must never launch a second Quickshell process.

Omarchy also has a semantic theme system and an opinionated, keyboard-first interaction model. Bloom therefore extends the active theme instead of creating a competing visual universe. Its motion, colors, typography, spacing, panels, and focus behavior should feel as though they shipped with Omarchy itself.

Reference material:

- [Omarchy releases and Quattro architecture](https://github.com/omacom/omarchy/releases)
- [Omarchy plugin development guide](https://plugins.omarchy.org/develop.html)
- [Omarchy theme documentation](https://github.com/omacom/omarchy/blob/quattro/manual/06-themes.md)

---

## 3. North-star experience

The user opens Bloom from the Omarchy menu or a configurable shortcut. The active display dims into a deep, translucent field. Five large scene cards appear with generous spacing and subtle motion: **Forge**, **Hush**, **Library**, **Afterglow**, and **Orbit**.

The user selects Forge.

- The current wallpaper crossfades into charcoal planes cut by a restrained amber current.
- The bar’s Bloom glyph condenses into a warm ember.
- The workspace receives a faint edge glow using colors derived from the active Omarchy theme.
- Existing windows remain stable; no application is restarted.
- The whole transition completes smoothly and then becomes still.

Later, an agent completes tests and requires approval. Bloom does not interrupt with spectacle. The ember becomes an amber ring with a small attention count. Opening it reveals the Agent Constellation: projects appear as quiet celestial clusters, with one agent breathing gently at the edge of its cluster. The user selects it and is returned directly to the correct window and workspace.

The magic is the combination of atmosphere and orientation: Bloom looks cinematic, but every meaningful visual state corresponds to something the user can act on.

---

## 4. Product principles

### 4.1 Calm by default

Motion appears during transitions, attention changes, and intentional exploration. The settled desktop should be almost completely still.

### 4.2 Theme-native

Every foreground color, surface, border, and focus state should derive from Omarchy’s semantic theme tokens. Scene palettes modulate the theme; they do not hard-code a second desktop theme.

### 4.3 Local first

Bloom requires no account, API key, telemetry endpoint, or cloud service. Agent state and wallpaper indexing remain local. Optional future integrations must be explicit and separately enabled.

### 4.4 Keyboard first, pointer excellent

Every action must be reachable with the keyboard. Pointer interactions should remain discoverable and polished, especially for selecting scenes and agents.

### 4.5 Attention, not activity

Bloom should emphasize agents that require the user. Constant token streaming, log output, and decorative busyness are intentionally absent from the main experience.

### 4.6 Reversible

Disabling the plugin restores the ordinary Omarchy shell immediately. Removing Bloom must never remove user wallpapers or unrelated Omarchy configuration.

### 4.7 Honest state

Bloom must distinguish known, inferred, stale, and unavailable agent states. It should never present a guessed state as authoritative.

---

## 5. Goals and non-goals

### Goals

- Deliver a visually exceptional native Omarchy experience.
- Give each workspace or project a memorable visual identity.
- Make concurrent AI-agent activity understandable at a glance.
- Surface approvals, failures, waiting states, and completions without noise.
- Support original bundled wallpapers and a persistent user wallpaper folder.
- Work across Omarchy themes, bar positions, display scales, and multiple monitors.
- Remain lightweight when idle and graceful on battery power.
- Provide a clean extension contract for scenes, wallpapers, and agent adapters.

### Non-goals for 1.0

- Replacing Omarchy’s launcher, notification daemon, or window manager.
- Becoming a general project-management or issue-tracking application.
- Reading or displaying agent prompt content by default.
- Automatically sending prompts or approving agent actions.
- Terminating agent processes without an explicit, confirmed user action.
- Downloading wallpapers from the internet.
- Supporting executable scene packages or wallpaper metadata.
- Synchronizing configuration across machines.

---

## 6. Core concepts

### Scene

A named visual and behavioral profile associated with a workspace, project, schedule, or manual selection. A scene controls wallpaper selection, ambient treatment, accent modulation, motion intensity, bar glyph, and optional notification posture.

### Scene binding

A rule that selects a scene. Bindings may target a Hyprland workspace, project root, application class, or local schedule. Manual selection has the highest priority.

### Ambient layer

A low-cost visual layer rendered behind Bloom’s interactive surfaces. It may add a color wash, vignette, grain, slow gradient, or sparse particles. It must never obstruct applications or capture input when the overlay is closed.

### Agent

A locally running AI coding session discovered through a provider adapter, an event hook, or a process/window fallback.

### Project cluster

A group of agent nodes associated with the same repository or project root. The cluster is the primary spatial unit in the Agent Constellation.

### Attention state

A normalized state indicating that the user may need to act: approval required, question waiting, failure, conflict, or completed work ready for review.

---

## 7. Information architecture

Bloom has four user-facing surfaces and one headless service.

| Surface | Plugin kind | Purpose |
| --- | --- | --- |
| Bloom glyph | `bar-widget` | Quiet status, attention count, quick access |
| Quick panel | nested panel | Current scene, next wallpaper, attention queue, fast controls |
| Bloom canvas | `overlay` | Scene carousel and full Agent Constellation |
| Omarchy commands | menu extension / IPC | Searchable actions through the standard Omarchy menu |
| Bloom core | `service` | State, adapters, wallpaper index, scene rules, persistence |

The bar widget and overlay are views over one shared state model owned by the service. No surface should run its own polling loop.

---

## 8. Invocation and navigation

Bloom must not silently overwrite existing keybindings.

Required invocation paths:

- Omarchy menu entries: `Bloom: Open`, `Bloom: Scenes`, `Bloom: Agents`, `Bloom: Next Wallpaper`, and `Bloom: Settings`.
- Bar glyph: left click opens the quick panel; a second click closes it.
- IPC: all primary actions are callable through `omarchy-shell shell summon` or a small packaged helper.
- Optional shortcut: the setup panel may suggest `SUPER + SHIFT + B` only when no collision is detected.

Keyboard behavior inside the Bloom canvas:

- `Tab` switches between Scenes and Agents.
- Arrow keys or `H J K L` move selection.
- `Enter` activates the selected scene or focuses the selected agent.
- `Space` opens details without leaving Bloom.
- `/` focuses search.
- `A` toggles the attention-only agent filter.
- `W` advances the current scene’s wallpaper.
- `Esc` closes details first, then closes Bloom.

Pointer behavior:

- Hover produces only a small lift, border brightening, and label reveal.
- Click selects; double click immediately activates.
- Scroll or trackpad gestures move through scene cards and constellation clusters.
- No essential action depends on hover.

---

## 9. First-run experience

The first run should take less than one minute and contain no blocking account setup.

### Step 1: Welcome

Show a full-width preview of the currently active scene and the sentence: **“Give every workspace an atmosphere.”**

Primary action: `Continue`.

For a zero-conf install, the first canvas reveal is scheduled automatically
after the plugin service is ready. This is a one-time discoverability moment,
not a persistent startup preference; the latter remains opt-in under Startup.

### Step 2: Motion

Offer three levels with live previews:

- **Still** — crossfades only.
- **Gentle** — recommended; restrained ambient motion and node transitions.
- **Alive** — richer idle animation while preserving the same layout.

Respect the system’s reduced-motion preference automatically and default to Still when it is enabled.

### Step 3: Agents and wallpapers

- Enable process-only agent discovery by default.
- Offer enhanced provider hooks as an explicit opt-in.
- Create the user wallpaper folder.
- Provide `Open Wallpaper Folder` and `Finish` actions.

The final screen opens Forge and briefly identifies the bar glyph. No tutorial tooltip should appear again unless requested from Settings.

---

## 10. Scene system

### 10.1 Default scenes

Bloom ships with five scenes. They are visual identities, not fixed themes, and must adapt to every supported Omarchy palette.

| Scene | Intent | Visual character | Default behavior |
| --- | --- | --- | --- |
| Forge | Building, coding, shipping | Graphite, ember, precise geometry | Normal notifications; agent activity visible |
| Hush | Deep focus and writing | Obsidian, cool horizon, soft fog | Suppress noncritical Bloom motion |
| Library | Research and reading | Ink, indigo, parchment highlights | Calm, information-dense details panel |
| Afterglow | Evening and decompression | Plum, rose, muted violet | Warmer tint; lower contrast animation |
| Orbit | Multi-agent work | Midnight, cyan, iris, sparse stars | Agent Constellation is the primary view |

### 10.2 Scene selection precedence

The scene resolver applies the first matching source:

1. Temporary manual override.
2. Persistent manual workspace binding.
3. Project-root binding.
4. Application-class binding.
5. Schedule rule.
6. User’s default scene.
7. Forge fallback.

Agent activity must not automatically change the active scene in the default configuration. Users may explicitly enable a rule such as “use Orbit when three or more agents are active.”

### 10.3 Scene transition

A scene transition follows this order:

1. Capture the outgoing visual state.
2. Resolve the new scene and wallpaper.
3. Preload the target wallpaper asynchronously.
4. Crossfade the wallpaper and color wash.
5. Morph the Bloom glyph and ambient accents.
6. Persist the resolved scene.
7. Release the outgoing texture after the transition completes.

The transition must not reload the shell, restart applications, or reapply the global Omarchy theme.

### 10.4 Manual and automatic modes

- **Manual** is the default. A selected scene remains active until changed or until a workspace with an explicit binding is entered.
- **Autopilot** evaluates configured bindings and schedules.
- The quick panel always shows why the current scene was selected: `Manual`, `Workspace 3`, `Project: Medusa`, or `Evening schedule`.
- A one-click `Lock Scene` action creates a temporary manual override.

---

## 11. Agent Constellation

### 11.1 Purpose

Agent Constellation provides a spatial overview of local AI coding sessions. Its primary job is to answer four questions instantly:

1. What is running?
2. Which project does each agent belong to?
3. Which agents need me?
4. How do I return to the correct session?

It should feel like observing a quiet night sky, not monitoring a server farm.

### 11.2 Layout

- Each project is a **cluster core** labeled with the repository or project name.
- Agent sessions appear as smaller nodes arranged around their project core.
- Faint lines indicate membership, not arbitrary dependencies.
- Clusters use deterministic radial packing so their location remains stable between openings.
- A short spring animation may settle new nodes, but physics stops within 600 ms.
- The selected cluster moves slightly toward the visual center; the rest recede through opacity and scale, not blur.
- Attention nodes are raised in z-order and remain visible when other nodes are dimmed.

Density rules:

- 1–12 agents: individual nodes and full labels on selection.
- 13–25 agents: individual nodes with compact project labels.
- 26–50 agents: completed agents collapse into count satellites.
- More than 50 agents: switch to cluster-first mode with an accessible list alongside it.

### 11.3 Normalized states

| State | Meaning | Visual treatment |
| --- | --- | --- |
| `starting` | Session launched, status not yet known | Small ring drawing itself once |
| `thinking` | Model is reasoning or awaiting a tool result | Slow orbital dot |
| `working` | Editing, generating, or executing | Stable core with a restrained traveling edge |
| `testing` | Test, build, lint, or CI-like command running | Segmented ring rotating slowly |
| `waiting` | Waiting for a user answer or input | Amber breathing halo and pause glyph |
| `approval` | Permission or confirmation required | Amber diamond marker and attention count |
| `completed` | Work completed successfully | One soft mint expansion, then a still node |
| `failed` | Command, tool, or session failed | Broken-ring shape with muted coral color |
| `idle` | Session exists but has no current activity | Dim stable point |
| `unknown` | Agent exists but reliable state is unavailable | Hollow neutral ring and `Status unavailable` label |

Color must never be the only status signal. Shape, iconography, text, and motion pattern must reinforce every state.

### 11.4 Attention model

Attention is sorted by severity and age:

1. Approval required.
2. Failed or blocked.
3. Waiting for user input.
4. Completed and ready for review.

The bar glyph displays a count only for these states. Running and thinking agents do not create a badge.

The quick panel shows at most three attention items and a `View all agents` action. Repeated updates from one session must coalesce into one item.

### 11.5 Agent details

Selecting a node opens a right-side details rail containing:

- Provider and session name.
- Project and branch or worktree.
- Normalized state and confidence: `Reported`, `Inferred`, or `Stale`.
- Elapsed time and time of last activity.
- Current activity category such as `Editing`, `Testing`, or `Waiting for approval`.
- Associated workspace and window.
- Optional token or quota information when exposed by the provider.
- Explicit actions.

Actions:

- `Focus Session` — switches to the associated workspace and focuses the exact window.
- `Open Project` — opens the project using the user’s configured terminal or editor behavior.
- `Copy Session ID`.
- `Archive Completed` — removes the node from Bloom, not the provider’s history.
- `Stop Agent…` — available only when a reliable PID is known and always requires confirmation.

Prompt bodies, generated code, environment variables, and raw terminal output are absent by default.

### 11.6 Focusing a session

Bloom stores the strongest available target in this order:

1. Hyprland window address.
2. Process ID plus matching window class.
3. Workspace plus application class.
4. Project root fallback.

If the exact window no longer exists, Bloom must explain that the session ended or moved. It must not focus an unrelated terminal simply because the class matches.

### 11.7 Provider adapters

Bloom uses adapters to normalize provider-specific behavior. Initial support should prioritize the agents offered by Omarchy’s default-agent workflow:

- Codex
- Claude Code
- Gemini
- OpenCode
- Copilot
- Pi / Oh My Pi
- Grok
- Crush

Adapter capability levels:

| Level | Source | Reliability | User consent |
| --- | --- | --- | --- |
| 0 | Process and window discovery | Presence only | Enabled by default |
| 1 | Provider lifecycle hooks | Authoritative state transitions | Explicit setup |
| 2 | Version-gated local session metadata | Richer project/session details | Explicit setup |

An unsupported or changed provider must gracefully fall back to Level 0. Log parsing should never be the only way Bloom remains stable.

### 11.8 Event envelope

Adapters emit a common local event:

```json
{
  "schemaVersion": 1,
  "eventId": "evt_01J...",
  "sessionId": "provider-session-id",
  "provider": "codex",
  "state": "testing",
  "confidence": "reported",
  "requiresAttention": false,
  "project": {
    "name": "medusa",
    "root": "/home/user/Work/medusa",
    "branch": "feature/containment"
  },
  "process": {
    "pid": 4242
  },
  "window": {
    "address": "0x1234abcd",
    "workspaceId": 3,
    "class": "org.omarchy.agent"
  },
  "activity": {
    "kind": "test",
    "label": "Running tests"
  },
  "occurredAt": "2026-09-02T20:30:00Z"
}
```

Validation requirements:

- Unknown fields are ignored.
- Unknown states map to `unknown`.
- Events older than the active session’s latest event are discarded.
- Paths and labels are treated as untrusted text and never interpolated into shell commands.
- Event labels are capped and sanitized before display.

### 11.9 Empty state

When no agents are running, Orbit shows a sparse field and the message:

> No agents in orbit.
>
> Launch your default Omarchy agent or keep this space quiet.

Actions: `Launch Agent` and `Choose Scene`.

---

## 12. Relationship between scenes and agents

Scenes and agents share one visual language but remain independently controllable.

- Agent attention may alter the Bloom bar glyph.
- Agent attention may add a subtle edge marker to the active scene.
- Agent state does not recolor the entire desktop.
- Hush suppresses continuous node animation but preserves approval and failure indicators.
- Orbit opens directly into Agents rather than Scenes.
- Each scene can define constellation accent strength, line opacity, and motion level.
- Autopilot rules may use agent count or attention state only when the user enables those rules.

An approval must remain discoverable in every scene, including Hush and reduced-motion mode.

---

## 13. Visual design system

### 13.1 Art direction

The visual direction is **cinematic minimalism**:

- Deep surfaces with controlled contrast.
- One dominant accent and one supporting accent at a time.
- Hairline geometry, soft luminance, and large areas of quiet space.
- Subtle grain to avoid sterile flatness.
- Crisp typography inherited from Omarchy.
- Almost no permanent cards; surfaces appear when there is content or interaction.
- Soft bloom is reserved for focus and attention, never applied everywhere.

### 13.2 Layer stack

From back to front:

1. Selected wallpaper.
2. Scene color wash.
3. Optional vignette.
4. Static fine grain.
5. Optional ambient shader or sparse particles.
6. Application windows.
7. Bloom panels and canvas.
8. Keyboard focus and attention indicators.

The closed overlay must not intercept pointer or keyboard input.

### 13.3 Semantic color mapping

Bloom consumes Omarchy semantic colors and derives scene-local values:

| Bloom token | Source and treatment |
| --- | --- |
| `canvas` | Theme background mixed with scene tint, maximum 12% tint |
| `surface` | Theme surface with 88–94% opacity |
| `surfaceRaised` | Theme elevated surface plus subtle scene tint |
| `textPrimary` | Theme foreground |
| `textMuted` | Theme muted foreground; maintain required contrast |
| `accent` | Theme primary accent modulated toward scene hue |
| `attention` | Theme warning or accessible amber fallback |
| `success` | Theme success or accessible mint fallback |
| `danger` | Theme danger or muted coral fallback |
| `hairline` | Foreground at 10–18% opacity |

Scene fallback colors are used only when the shell does not expose a required semantic value.

### 13.4 Typography

- Inherit the active Omarchy shell font.
- Use three meaningful levels: display, title, body, plus compact metadata.
- Scene names may use wide tracking; body text must not.
- Numerical counts use tabular figures when available.
- Never rasterize text into wallpapers.

### 13.5 Geometry

- Follow Omarchy’s active corner preference, including sharp-corner configurations.
- Base spacing unit: 4 px after display scaling.
- Primary panel padding: 20–24 px.
- Card gaps: 16–20 px.
- Hairlines: one physical pixel where rendering permits.
- Node sizes: 10–20 px depending on status and selection.
- Selected objects may scale to a maximum of 1.06×.

### 13.6 Motion language

| Motion | Duration | Easing |
| --- | --- | --- |
| Hover/focus response | 110 ms | OutCubic |
| Panel reveal | 180 ms | OutCubic |
| Detail rail | 220 ms | OutCubic |
| Scene card selection | 260 ms | InOutCubic |
| Scene color transition | 420 ms | InOutCubic |
| Wallpaper crossfade | 650 ms | InOutCubic |
| Constellation settle | ≤600 ms | OutCubic, then stop |
| Success expansion | 500 ms once | OutCubic |

No decorative animation may loop faster than six seconds. Failed states never flash. Reduced-motion mode replaces travel and scaling with 120–180 ms opacity changes.

---

## 14. Wallpaper system

### 14.1 Design requirement

Bloom ships with original default wallpapers and also maintains a separate, persistent folder for user-supplied wallpapers. Custom files augment the bundled collection; they do not need to replace it.

Bundled defaults are immutable application assets. User files are outside the installed plugin directory so plugin updates cannot overwrite them or create a dirty Git checkout.

### 14.2 Paths

Bundled wallpapers:

```text
<plugin-root>/assets/wallpapers/default/
├── forge/
├── hush/
├── library/
├── afterglow/
└── orbit/
```

Persistent user folder:

```text
${XDG_CONFIG_HOME}/omarchy-bloom/wallpapers/
├── _shared/
├── forge/
├── hush/
├── library/
├── afterglow/
└── orbit/
```

When `XDG_CONFIG_HOME` is unset, Bloom resolves it using the platform-standard user configuration location. This resolution happens in code; shell commands must not construct paths through unsafe string interpolation.

The folder is created on first run. `Open Wallpaper Folder` is available from the quick panel, settings, and Omarchy menu.

### 14.3 Selection precedence

For a given scene, Bloom resolves wallpaper candidates in this order:

1. A custom wallpaper explicitly pinned to the workspace.
2. A custom wallpaper explicitly pinned to the scene.
3. User files inside the matching scene folder.
4. User files inside `_shared` that are eligible for all scenes.
5. Bundled defaults for the scene.
6. A generated static gradient fallback.

The visual selector can filter by `All`, `Bundled`, `Custom`, and scene name. Custom and bundled wallpapers appear together by default.

### 14.4 Supported files

- `.webp`
- `.png`
- `.jpg`
- `.jpeg`

Guidance:

- Recommended resolution: at least 2560×1440.
- Preferred bundled resolution: 3840×2160.
- Maximum individual file size indexed by default: 30 MiB.
- Recursive scanning depth: two directories below each scene folder.
- Hidden files, unsupported MIME types, sockets, devices, and executables are ignored.
- File contents are validated as images; extension alone is insufficient.

Symlink policy for 1.0:

- Symlinked individual image files may be used after resolving to a readable regular file.
- Symlinked directories are not traversed recursively.
- Bloom never writes through a symlink.

### 14.5 Sidecar metadata

An image may have an optional sidecar named `<image>.bloom.json`:

```json
{
  "schemaVersion": 1,
  "title": "Emberline",
  "scenes": ["forge"],
  "focalPoint": { "x": 0.72, "y": 0.44 },
  "fit": "cover",
  "tintStrength": 0.08,
  "vignetteStrength": 0.12,
  "credit": {
    "name": "Artist name",
    "url": "https://example.com"
  }
}
```

Metadata is declarative. It cannot contain commands, QML, JavaScript, shaders, import paths, or remote asset URLs.

### 14.6 Indexing and caching

- Watch the user wallpaper root and debounce changes for 500 ms.
- Generate thumbnails asynchronously.
- Store derived thumbnails, palette hints, and decode metadata under `${XDG_CACHE_HOME}/omarchy-bloom/wallpapers/`.
- Never alter, rename, optimize, or delete the user’s source image.
- Cache keys include canonical path, modification time, size, and decoder version.
- A corrupted file is skipped and reported once in Settings, not through repeated notifications.
- Scanning must not block the shell’s UI thread.

### 14.7 Rotation

Per-scene options:

- `Pinned`
- `On scene entry`
- `Daily`
- `Hourly`
- `Manual only`

Default: `On scene entry`, avoiding an immediate repeat until all candidates have been visited. Rotation pauses while screen sharing or recording when Omarchy exposes that state.

### 14.8 Multi-monitor behavior

Modes:

- **Mirror** — same wallpaper and treatment on all displays; default.
- **Independent** — each display remembers its own wallpaper for the scene.
- **Span** — one image spans the combined logical display area when supported.

The selector previews the crop for the active display. Focal-point metadata keeps the intended subject away from common window and bar regions.

### 14.9 Uninstall behavior

Uninstalling Bloom removes plugin code and generated cache only. It preserves:

- `${XDG_CONFIG_HOME}/omarchy-bloom/wallpapers/`
- user configuration
- scene bindings

Removal may offer a separate, explicit `Delete Bloom user data…` action with a confirmation showing the exact paths.

---

## 15. Default wallpaper collection

Bloom 1.0 includes ten original 4K wallpapers: two for each scene. Every image must contain generous negative space, remain legible beneath light or dark bar treatments, avoid text and logos, and crop cleanly to 16:10 and ultrawide displays.

| File | Art direction | Primary focal point |
| --- | --- | --- |
| `forge/emberline.webp` | Near-black basalt planes crossed by one hairline amber current; precise and architectural | Right third |
| `forge/monolith.webp` | Layered graphite monoliths with a distant warm horizon and subtle grain | Lower-right |
| `hush/silver-fog.webp` | Blue-black field, soft horizontal silver bloom, barely visible mist | Center-right |
| `hush/eclipsed.webp` | Restrained off-center eclipse with wide obsidian negative space | Upper-right |
| `library/archive.webp` | Deep indigo architectural layers with fine parchment geometry | Right third |
| `library/paperlight.webp` | Desaturated navy planes touched by one warm paper-like glow | Lower-left |
| `afterglow/dusk-field.webp` | Plum and rose vapor fading into black with no hard subject | Center-right |
| `afterglow/last-horizon.webp` | Dark horizon with a muted coral-to-violet atmospheric band | Lower third |
| `orbit/starfield.webp` | Sparse midnight field with cyan and iris stars arranged in quiet clusters | Right half |
| `orbit/lattice.webp` | Delicate constellation lattice with a few luminous nodes and ample void | Center-right |

Asset requirements:

- 3840×2160 WebP, high-quality visually lossless target.
- No baked-in Bloom or Omarchy branding.
- Static images only in 1.0; ambient motion is rendered separately.
- Each file includes sidecar focal-point and attribution metadata.
- Each scene retains one dark-safe and one slightly brighter alternative.
- Source masters are kept outside the distributed package; export settings are documented.
- All imagery is original or licensed for unrestricted redistribution with attribution recorded.

---

## 16. Bar widget and quick panel

### 16.1 Bloom glyph

The glyph is a small scene-aware orb or mark, never a permanent logo lockup.

States:

- Normal: scene accent, still.
- Active agents: one subtle satellite point; no count.
- Attention: amber ring plus numeric count.
- Failure: broken-ring shape; count remains accessible.
- Bloom open: slightly expanded and connected visually to the panel.

The glyph must fit all bar orientations. On left or right bars, labels and counts rotate or reflow appropriately rather than rotating text.

### 16.2 Quick panel

The quick panel contains:

1. Current scene and selection reason.
2. Five compact scene choices.
3. Current wallpaper preview with Previous, Next, and Open Folder.
4. Up to three agent attention items.
5. `Open Constellation`.
6. Motion, Autopilot, and Lock Scene controls.

The default panel should fit within 420×620 logical pixels and adapt when anchored to any screen edge.

---

## 17. Settings

Settings are grouped into five pages:

### Scenes

- Default scene.
- Workspace and project bindings.
- Autopilot rules.
- Per-scene color and motion strength.

### Wallpapers

- Open user wallpaper folder.
- Source filter and rotation mode.
- Multi-monitor mode.
- Reindex and clear derived cache.
- File errors and attributions.

### Agents

- Enable or disable discovery.
- Install or remove enhanced provider hooks.
- Provider capability and health.
- Completed-node retention.
- Privacy controls.

### Appearance

- Motion level.
- Ambient intensity.
- Grain, vignette, and line opacity.
- Reduced-motion override.
- High-contrast mode.

### Startup

- **Open Bloom canvas at login**, off by default.
- **Bloom active**, on by default; when paused, Bloom stops applying scene and
  wallpaper changes to workspaces.
- Persist the preference in Bloom's configuration and apply it when the
  already-loaded Omarchy shell service becomes ready.
- Expose the same on/off/status control in the Signal rail and local IPC.
- Never spawn a second shell process or write compositor autostart entries;
  the setting controls canvas visibility only.

### Advanced

- State and cache locations.
- Export/import configuration.
- Diagnostics bundle with explicit preview.
- Reset Bloom without touching wallpapers.

Every setting should update live where safe. Destructive actions require explicit confirmation.

---

## 18. Configuration model

User configuration lives at:

```text
${XDG_CONFIG_HOME}/omarchy-bloom/config.json
```

Example:

```json
{
  "schemaVersion": 1,
  "defaultScene": "forge",
  "mode": "manual",
  "bloomActive": true,
  "launchAtStartup": false,
  "motion": "gentle",
  "ambientIntensity": 0.65,
  "wallpapers": {
    "root": "${XDG_CONFIG_HOME}/omarchy-bloom/wallpapers",
    "rotation": "on-scene-entry",
    "source": "all",
    "multiMonitor": "mirror"
  },
  "agents": {
    "enabled": true,
    "discovery": "process",
    "completedRetentionMinutes": 10,
    "showPromptContent": false
  },
  "bindings": [
    {
      "type": "workspace",
      "workspace": 2,
      "scene": "hush"
    },
    {
      "type": "project",
      "path": "/home/user/Work/medusa",
      "scene": "forge"
    }
  ]
}
```

Rules:

- Configuration writes are atomic: write temporary, fsync where appropriate, then rename.
- Invalid configuration is backed up and replaced with defaults only after notifying the user.
- Unknown fields survive read/write cycles where practical to support forward compatibility.
- Paths are normalized and never executed.
- Schema migrations are versioned and tested.

---

## 19. Runtime state

State lives separately from configuration:

```text
${XDG_STATE_HOME}/omarchy-bloom/
├── state.json
├── sessions.json
└── migrations/
```

Ephemeral adapter communication uses:

```text
${XDG_RUNTIME_DIR}/omarchy-bloom/agent-events.sock
```

State includes:

- active scene per workspace
- persistent wallpaper per workspace
- last wallpaper and recent rotation history
- project cluster positions
- known session-to-window associations
- completed-node expiry
- onboarding completion

Raw agent output, prompts, secrets, and environment snapshots must never be written into Bloom state.

---

## 20. Proposed repository structure

```text
omarchy-bloom/
├── manifest.json
├── README.md
├── LICENSE
├── CHANGELOG.md
├── BarWidget.qml
├── Panel.qml
├── Overlay.qml
├── Service.qml
├── components/
│   ├── AgentNode.qml
│   ├── AttentionBadge.qml
│   ├── ConstellationCanvas.qml
│   ├── DetailsRail.qml
│   ├── SceneCard.qml
│   ├── SceneCarousel.qml
│   ├── WallpaperLayer.qml
│   └── WallpaperPreview.qml
├── models/
│   ├── AgentStore.js
│   ├── AttentionReducer.js
│   ├── ConfigStore.js
│   ├── SceneResolver.js
│   └── WallpaperIndex.js
├── adapters/
│   ├── AdapterBase.qml
│   ├── ProcessAdapter.qml
│   ├── CodexAdapter.qml
│   ├── ClaudeAdapter.qml
│   ├── GeminiAdapter.qml
│   └── GenericAgentAdapter.qml
├── services/
│   ├── AgentService.qml
│   ├── SceneService.qml
│   ├── WallpaperService.qml
│   └── WindowFocusService.qml
├── assets/
│   ├── icons/
│   ├── shaders/
│   └── wallpapers/
│       └── default/
│           ├── forge/
│           ├── hush/
│           ├── library/
│           ├── afterglow/
│           └── orbit/
├── schemas/
│   ├── agent-event.schema.json
│   ├── config.schema.json
│   ├── scene.schema.json
│   └── wallpaper-metadata.schema.json
├── scenes/
│   ├── forge.scene.json
│   ├── hush.scene.json
│   ├── library.scene.json
│   ├── afterglow.scene.json
│   └── orbit.scene.json
├── scripts/
│   ├── bloomctl
│   ├── install-provider-hook
│   └── uninstall-provider-hook
├── test/
│   ├── fixtures/
│   ├── qml/
│   ├── unit/
│   └── visual/
└── docs/
    ├── DESIGN.md
    ├── PRIVACY.md
    ├── PROVIDER_ADAPTERS.md
    └── WALLPAPERS.md
```

The user wallpaper directory is deliberately absent from this repository tree because it is created under the user’s XDG configuration location.

---

## 21. Manifest contract

Proposed manifest shape:

```json
{
  "schemaVersion": 1,
  "id": "io.github.<publisher>.omarchy-bloom",
  "name": "Omarchy Bloom",
  "version": "1.0.0",
  "author": "<publisher>",
  "license": "MIT",
  "description": "Living workspace scenes and a native constellation for local AI agents.",
  "kinds": ["bar-widget", "overlay", "service"],
  "entryPoints": {
    "barWidget": "BarWidget.qml",
    "overlay": "Overlay.qml",
    "service": "Service.qml"
  },
  "barWidget": {
    "displayName": "Bloom",
    "category": "Productivity",
    "allowMultiple": false,
    "defaultSection": "right"
  }
}
```

The final manifest must be validated against the version of Omarchy targeted for release. If multi-kind lifecycle behavior differs from the current reference, use one service-owned state model and supported nested entry points rather than private shell APIs.

---

## 22. IPC contract

Required commands:

| Command | Payload | Result |
| --- | --- | --- |
| `toggle` | `{}` | Opens or closes Bloom |
| `open` | `{ "view": "scenes" | "agents" }` | Opens requested canvas |
| `close` | `{}` | Closes Bloom |
| `setScene` | `{ "sceneId": "forge", "scope": "temporary" | "workspace" }` | Activates scene |
| `nextWallpaper` | `{ "sceneId": "optional" }` | Advances wallpaper |
| `rescanWallpapers` | `{}` | Reindexes user folder |
| `focusAgent` | `{ "sessionId": "..." }` | Focuses verified session target |
| `archiveAgent` | `{ "sessionId": "..." }` | Hides completed session |
| `setMotion` | `{ "level": "still" | "gentle" | "alive" }` | Updates motion |
| `startup` | `{ "value": "on" | "off" | "status" }` | Controls whether Bloom opens after Omarchy starts |

IPC inputs are schema-validated. Unknown commands fail closed with an actionable diagnostic. Session IDs and scene IDs are data, never command fragments.

---

## 23. Security and privacy

Omarchy plugins run with the user’s permissions inside the long-running shell. Bloom therefore adopts a deliberately narrow trust boundary.

Requirements:

- No `sudo` or privileged helper.
- No network access in the default build.
- No telemetry, crash upload, analytics, or remote fonts.
- No shell command assembled from user or provider strings.
- External processes are invoked with fixed executables and argument arrays.
- Wallpaper and sidecar files are treated as untrusted input.
- Image MIME is verified before decode.
- Adapter events are schema-validated and size-limited.
- The local event socket accepts only the owning user.
- Provider hooks are inspectable scripts installed only after explicit consent.
- Hook installation and removal are idempotent and reversible.
- Diagnostics are previewed before export and redact paths, prompt text, tokens, and environment values by default.
- Stopping an agent requires explicit confirmation and a revalidated PID-to-session association.

Bloom’s privacy page must state exactly what each provider adapter reads and stores.

---

## 24. Performance budgets

These are release gates, measured as incremental Bloom cost over the ordinary Omarchy shell on representative hardware.

| Metric | Budget |
| --- | --- |
| Idle CPU, settled desktop | ≤0.5% average |
| Active transition CPU | ≤3% average during transition |
| Continuous ambient frame rate | 30 fps maximum |
| UI transition frame target | 60 fps where display supports it |
| Added resident memory | ≤100 MiB with one 4K wallpaper and 25 agents |
| Synchronous UI-thread task | <16 ms; no file scan or image analysis on UI thread |
| Agent event-to-visual latency | <250 ms at p95 |
| Scene change initiation | <100 ms after input |
| Wallpaper index: 1,000 files | <2 s in background on reference SSD |
| Settled constellation animation | Stops within 600 ms, except explicit status indicators |

Power behavior:

- Pause ambient animation when displays are off, locked, or the surface is not visible.
- Use Still motion when the system power-saver profile is active.
- Disable particles below a configurable battery threshold, default 20%.
- Decode only the outgoing and incoming full-resolution wallpapers during a transition.
- Release stale textures promptly.

---

## 25. Accessibility

- Full keyboard navigation with visible focus.
- Logical reading order independent of constellation geometry.
- Accessible list equivalent for every agent node.
- Status communicated with shape, text, and motion—not color alone.
- Text contrast target: WCAG AA, 4.5:1 for normal text.
- Reduced-motion support from first launch.
- No flashing or rapid luminance change.
- High-contrast mode removes transparency and strengthens borders.
- Labels expose provider, project, state, attention, and last activity.
- Display scaling tested from 100% through 200%.
- Pointer targets are at least 32 logical pixels even when the visual node is smaller.

---

## 26. Resilience and failure behavior

| Failure | Required behavior |
| --- | --- |
| Missing bundled wallpaper | Use scene gradient fallback and record diagnostic |
| Corrupted custom image | Skip once; show file in Settings errors |
| Invalid sidecar | Ignore metadata; retain valid image |
| Provider adapter breaks | Fall back to process discovery and mark state inferred |
| Agent window disappears | Mark target stale; never focus a guessed window |
| Config parse fails | Preserve bad file, load safe defaults, explain recovery |
| Shell restarts | Restore scene and nonexpired agent state without replaying stale attention |
| User folder unavailable | Continue with bundled defaults; offer Retry/Open Parent |
| Theme changes while Bloom is open | Recompute tokens live without closing the canvas |
| Display removed | Move Bloom canvas to active display and recompute crops |

Critical errors remain accessible in Settings. They must not create notification storms.

---

## 27. Testing strategy

### Static and contract tests

- `omarchy plugin validate` passes.
- `qmllint` passes for every QML entry point and component.
- JSON schemas validate defaults, examples, and migration fixtures.
- No plugin folder symlinks or forbidden IDs.

### Unit tests

- Scene precedence and override expiry.
- Wallpaper filtering, MIME validation, rotation, and sidecar parsing.
- Agent state reducer, stale-event rejection, attention sorting, and coalescing.
- PID/window association and safe focus fallbacks.
- Configuration migration and atomic recovery.

### Integration tests

- Enable, disable, shell restart, re-enable, and remove.
- Scene persistence across workspace changes and restarts.
- Live theme changes.
- Custom wallpaper arrival, deletion, corruption, and 1,000-file scan.
- Simulated event streams for every normalized agent state.
- Provider crash and fallback behavior.
- Exact window focus across multiple workspaces and monitors.

### Visual regression matrix

At minimum:

- Tokyo Night
- Matte Black or Vantablack
- Catppuccin
- Flexoki Light
- Everforest
- A theme with sharp corners
- A theme with rounded corners

For each:

- top, bottom, left, and right bar positions
- opaque and transparent bar
- 100%, 125%, 150%, and 200% scale
- 16:9, 16:10, ultrawide, and two-monitor layouts
- Still and Gentle motion modes
- empty, normal, attention, failed, and high-density constellation states

### Stress tests

- 50 active agents across 15 projects.
- 1,000 custom wallpapers.
- Rapid workspace switching.
- Theme change during wallpaper transition.
- Agent event burst of 100 events per second with coalescing.
- Display hotplug while Bloom is open.

---

## 28. Implementation milestones

### Milestone 0 — Contract and visual prototype

Deliver:

- Valid plugin skeleton.
- Theme token adapter.
- Static Bloom glyph, panel, and canvas.
- Motion prototypes for scene transition and agent node states.
- One representative wallpaper: Forge / Emberline.

Exit criteria:

- Runs inside the existing Omarchy shell.
- Works on one dark and one light theme.
- Visual direction approved before state complexity is added.

### Milestone 1 — Scene engine

Deliver:

- Five scene definitions.
- Manual selection and workspace bindings.
- Scene resolver and persistence.
- Wallpaper crossfade and ambient layer.
- Quick panel and menu actions.

Exit criteria:

- Switching scenes never restarts applications or shell.
- State restores correctly after shell restart.

### Milestone 2 — Wallpaper library

Deliver:

- Ten bundled default wallpapers.
- Persistent user wallpaper folder and watcher.
- Visual selector, rotation, sidecars, thumbnails, and cache.
- Multi-monitor modes.

Exit criteria:

- Adding an image to a user scene folder makes it selectable without restarting.
- Plugin update and removal leave user wallpapers untouched.

### Milestone 3 — Agent Constellation

Deliver:

- Process/window discovery.
- Common event model.
- Codex and Claude enhanced adapters first.
- Deterministic project clusters.
- All normalized visual states.
- Attention queue and exact window focus.

Exit criteria:

- Simulated and real sessions transition reliably.
- Unknown or stale status is represented honestly.
- No prompt content is read or stored by default.

### Milestone 4 — Polish and release

Deliver:

- Remaining priority adapters.
- Accessibility pass.
- Performance and power pass.
- Visual regression suite.
- Documentation, privacy page, previews, and marketplace metadata.

Exit criteria:

- All acceptance criteria below pass.
- Installation, disable, update, and removal paths are verified on a clean Omarchy system.

---

## 29. Acceptance criteria

Bloom 1.0 is complete only when all of the following are true.

### Product

- Five scenes are present and visually distinct across dark and light Omarchy themes.
- Scene selection is understandable without documentation.
- The settled desktop remains calm and readable.
- Agent attention is visible without opening the full canvas.

### Wallpapers

- Ten original bundled wallpapers ship in the defined default folders.
- `${XDG_CONFIG_HOME}/omarchy-bloom/wallpapers/` is created automatically.
- User images placed in `_shared` or a scene folder appear without shell restart.
- Bundled and user wallpapers are presented together and can be filtered.
- Plugin update, disable, or removal does not delete user wallpapers.
- Corrupt and unsupported files cannot crash the shell.

### Agent Constellation

- Agents group deterministically by project.
- Every normalized state has a distinct accessible treatment.
- Approval, failure, waiting, and completion enter the attention queue correctly.
- Selecting `Focus Session` focuses the verified corresponding window.
- Stale associations never focus an unrelated window.
- Unsupported providers fall back without breaking other adapters.
- Prompt content and environment variables are absent from Bloom state by default.

### Quality

- Plugin validation and QML lint pass.
- No second Quickshell process is created.
- Idle and transition performance meet the defined budgets.
- Reduced-motion and keyboard-only flows are complete.
- All visual regression themes and display layouts pass.
- Disabling Bloom restores the ordinary Omarchy experience immediately.

---

## 30. Launch demo

The launch video should be 35–45 seconds and tell one continuous story:

1. Begin on ordinary Forge with two coding windows.
2. Open the Bloom scene carousel.
3. Move through Hush, Library, and Afterglow previews, then select Forge.
4. Show the wallpaper and bar morph settling into silence.
5. Start two agents in separate projects.
6. Open Agent Constellation and reveal both project clusters.
7. One agent changes from Testing to Approval.
8. The amber attention ring appears.
9. Select the node and jump directly to its terminal window.
10. Add a wallpaper file to the user `orbit` folder.
11. Reopen the selector and show the new custom wallpaper beside the bundled defaults.
12. End on the tagline: **“Omarchy Bloom — Your workspace, alive.”**

Avoid narration-heavy feature listing. The product’s visual continuity should make the story self-explanatory.

---

## 31. Definition of beautiful

Bloom is beautiful when:

- screenshots look composed before the user arranges anything;
- animation clarifies a change and then disappears;
- every scene feels related but immediately recognizable;
- the Agent Constellation remains legible with one agent or fifty;
- light themes feel intentionally designed, not inverted;
- custom wallpapers remain the user’s artwork rather than being buried under effects;
- attention is unmistakable without creating anxiety;
- the plugin still feels elegant with all ambient effects disabled.

The final test is simple: Bloom should make Omarchy feel more coherent, more personal, and more alive—while leaving the user’s actual work as the brightest object on the screen.
