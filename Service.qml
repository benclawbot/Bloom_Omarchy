import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Commons
import "models/Scenes.js" as Scenes
import "models/AgentStore.js" as AgentStore
import "models/WallpaperIndex.js" as WallpaperIndex

Item {
  id: root

  // These properties are injected by omarchy-shell.
  property var shell: null
  property var manifest: null
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")

  readonly property string moduleName: "org.bloom.omarchy"
  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (home + "/.config")
  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")
  readonly property string runtimeHome: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
  readonly property string bloomConfigDir: configHome + "/omarchy-bloom"
  readonly property string userWallpaperRoot: bloomConfigDir + "/wallpapers"
  readonly property string stateDir: stateHome + "/omarchy-bloom"
  readonly property string eventFile: runtimeHome + "/omarchy-bloom/agent-events.jsonl"
  readonly property string workspaceBgCommand: root.filesystemPath(String(Qt.resolvedUrl("scripts/bloom-workspace-bg")))

  property var sceneList: Scenes.all()
  readonly property var workspaceSceneIds: ["forge", "hush", "library", "afterglow", "orbit"]
  property string currentSceneId: "forge"
  property string currentWorkspaceId: "1"
  property var sceneWallpaper: ({})
  property var workspaceState: ({})
  property string currentWallpaperPath: ""
  property string currentWallpaperTitle: ""
  property var wallpapers: []
  property var processAgents: []
  property var eventAgents: []
  property var agents: []
  property bool demoMode: false
  property bool bloomActive: true
  property bool launchAtStartup: false
  property bool firstRun: false
  property bool onboardingComplete: false
  property bool startupOpenHandled: false
  property bool configLoaded: false
  property bool rescanQueued: false
  property double lastActiveToggleAt: 0
  property bool sceneWriteInProgress: false
  property int revision: 0

  readonly property var currentScene: Scenes.get(currentSceneId)
  readonly property int attentionCount: AgentStore.attentionCount(agents)
  readonly property string currentWallpaperUrl: root.wallpaperUrlFor(currentWallpaperPath)

  function wallpaperUrlFor(path) {
    var value = String(path || "")
    if (!value) return ""
    if (value.indexOf("file://") === 0) return value
    return Util.fileUrl(value)
  }

  function filesystemPath(path) {
    var value = String(path || "")
    if (value.indexOf("file://") !== 0) return value
    try { return decodeURIComponent(value.slice(7)) } catch (e) { return value.slice(7) }
  }

  function bundledWallpapers() {
    var result = []
    var ids = ["forge", "hush", "library", "afterglow", "orbit"]
    var names = [
      ["forge-emberline.webp", "forge-nightshift.webp"],
      ["hush-mistgarden.webp", "hush-slowwater.webp"],
      ["library-quietstacks.webp", "library-goldleaf.webp"],
      ["afterglow-rosehour.webp", "afterglow-latewindow.webp"],
      ["orbit-bluehour.webp", "orbit-constellation.webp"]
    ]
    for (var i = 0; i < ids.length; i++) {
      for (var j = 0; j < names[i].length; j++) {
        var relative = "assets/wallpapers/default/" + ids[i] + "/" + names[i][j]
        var url = String(Qt.resolvedUrl(relative))
        result.push({
          path: url,
          url: url,
          title: WallpaperIndex.titleFor(names[i][j]),
          sceneId: ids[i],
          source: "bundled"
        })
      }
    }
    return result
  }

  function rebuildWallpapers(rawUserPaths) {
    var combined = bundledWallpapers()
    var seen = {}
    for (var i = 0; i < combined.length; i++) seen[combined[i].path] = true

    var custom = WallpaperIndex.fromLines(rawUserPaths)
    for (var j = 0; j < custom.length; j++) {
      if (seen[custom[j].path]) continue
      seen[custom[j].path] = true
      combined.push(custom[j])
    }

    root.wallpapers = combined
    root.syncFocusedWorkspace(true)
    root.revision++
  }

  function refreshWallpapers() {
    if (wallpaperScan.running) {
      root.rescanQueued = true
      return
    }
    wallpaperScan.running = true
  }

  function wallpaperItemForPath(path) {
    var wanted = String(path || "")
    for (var i = 0; i < root.wallpapers.length; i++)
      if (String(root.wallpapers[i].path) === wanted) return root.wallpapers[i]
    return null
  }

  function chooseWallpaper(advance) {
    var options = WallpaperIndex.forScene(root.wallpapers, root.currentSceneId)
    if (!options.length) return

    // Wallpaper ownership is workspace-scoped. A scene's choice on one
    // workspace must never become the implicit choice on another workspace.
    var workspace = root.workspaceState[root.currentWorkspaceId]
    var preferred = workspace && workspace.scene === root.currentSceneId
      ? String(workspace.wallpaper || "") : ""
    var index = -1
    for (var i = 0; i < options.length; i++) {
      if (options[i].path === preferred) {
        index = i
        break
      }
    }
    if (index < 0) index = 0
    if (advance) index = (index + 1) % options.length

    root.currentWallpaperPath = options[index].path
    root.currentWallpaperTitle = options[index].title
    root.applyWallpaperToDesktop(root.currentWallpaperPath)
    root.rememberWorkspaceState()
  }

  function selectWallpaper(path) {
    var item = root.wallpaperItemForPath(path)
    if (!item) return false
    root.currentWallpaperPath = String(item.path)
    root.currentWallpaperTitle = String(item.title || WallpaperIndex.titleFor(item.path))
    root.applyWallpaperToDesktop(root.currentWallpaperPath)
    root.rememberWorkspaceState()
    root.revision++
    return true
  }

  function applyWallpaperToDesktop(path) {
    var value = root.filesystemPath(path)
    if (!value || !root.bloomActive || !root.workspaceBgCommand) return
    // Omarchy's stock setter mutates one global background symlink and
    // restarts swaybg. Bloom deliberately avoids it here: the helper points
    // swaybg directly at the focused workspace's saved image, so changing one
    // workspace does not overwrite the stored choice for any other workspace.
    Quickshell.execDetached([root.workspaceBgCommand, value])
  }

  function setBloomActive(value) {
    var normalized = String(value).toLowerCase()
    root.bloomActive = value === true || normalized === "true" || normalized === "1" || normalized === "on"
    root.scheduleConfigSave()
    root.revision++
    if (root.bloomActive) root.syncFocusedWorkspace(true)
    return root.bloomActive
  }

  function toggleBloomActive() {
    var now = Date.now()
    if (now - root.lastActiveToggleAt < 900) return root.bloomActive
    root.lastActiveToggleAt = now
    return root.setBloomActive(!root.bloomActive)
  }

  function setScene(id) {
    var nextId = String(id || "")
    if (!Scenes.contains(nextId)) return false
    if (root.currentSceneId === nextId) return true
    // The focused workspace is already tracked by the service timer. Do not
    // resync here: a Hyprland notification arriving during a click could
    // restore the previous scene after the user made a selection.
    root.currentSceneId = nextId
    root.sceneWriteInProgress = true
    root.chooseWallpaper(false)
    root.sceneWriteInProgress = false
    root.revision++
    root.scheduleConfigSave()
    return true
  }

  function nextScene(direction) {
    var nextId = Scenes.next(root.currentSceneId, Number(direction || 1))
    root.setScene(nextId)
    return nextId
  }

  function nextWallpaper() {
    root.chooseWallpaper(true)
    root.revision++
    return root.currentWallpaperPath
  }

  function rememberWorkspaceState() {
    var next = ({})
    for (var key in root.workspaceState) next[key] = root.workspaceState[key]
    next[String(root.currentWorkspaceId || "1")] = {
      scene: root.currentSceneId,
      wallpaper: root.currentWallpaperPath
    }
    root.workspaceState = next
    root.scheduleConfigSave()
  }

  function defaultSceneForWorkspace(id) {
    var number = Number(id)
    if (number >= 1 && number <= root.workspaceSceneIds.length)
      return root.workspaceSceneIds[number - 1]
    return "forge"
  }

  function syncFocusedWorkspace(force) {
    if (!root.bloomActive) return
    if (root.sceneWriteInProgress) return
    var focused = Hyprland.focusedWorkspace
    var id = focused && focused.id !== undefined ? String(focused.id) : "1"
    if (!force && id === root.currentWorkspaceId) return
    root.currentWorkspaceId = id

    var saved = root.workspaceState[id]
    if (saved && Scenes.contains(saved.scene)) {
      root.currentSceneId = saved.scene
      var wanted = String(saved.wallpaper || "")
      var item = root.wallpaperItemForPath(wanted)
      if (item) {
        root.currentWallpaperPath = wanted
        root.currentWallpaperTitle = String(item.title || WallpaperIndex.titleFor(wanted))
        root.applyWallpaperToDesktop(wanted)
      } else {
        root.chooseWallpaper(false)
      }
    } else {
      root.currentSceneId = root.defaultSceneForWorkspace(id)
      root.chooseWallpaper(false)
    }
    root.revision++
  }

  function parseConfig(raw) {
    var parsed = null
    try { parsed = JSON.parse(String(raw || "")) } catch (e) { parsed = null }
    if (!parsed || typeof parsed !== "object") {
      root.firstRun = true
      root.bloomActive = true
      root.workspaceState = ({})
      root.configLoaded = true
      root.syncFocusedWorkspace(true)
      return
    }
    if (Scenes.contains(parsed.scene)) root.currentSceneId = parsed.scene
    // Keep reading the old sceneWallpaper field for backwards compatibility,
    // but workspaceState is authoritative from schema v2 onward.
    root.sceneWallpaper = parsed.sceneWallpaper && typeof parsed.sceneWallpaper === "object"
      ? parsed.sceneWallpaper : ({})
    root.workspaceState = parsed.workspaceState && typeof parsed.workspaceState === "object"
      ? parsed.workspaceState : ({})
    root.firstRun = false
    root.bloomActive = parsed.bloomActive !== false
    root.onboardingComplete = parsed.onboardingComplete === true
    root.launchAtStartup = parsed.launchAtStartup === true
    root.configLoaded = true
    root.syncFocusedWorkspace(true)
  }

  function scheduleStartupOpen() {
    if (root.startupOpenHandled) return
    root.startupOpenHandled = true
  }

  function setLaunchAtStartup(value) {
    var normalized = String(value).toLowerCase()
    root.launchAtStartup = value === true || normalized === "true" || normalized === "1" || normalized === "on"
    root.scheduleConfigSave()
    root.revision++
    return root.launchAtStartup
  }

  function toggleLaunchAtStartup() {
    return root.setLaunchAtStartup(!root.launchAtStartup)
  }

  function completeOnboarding() {
    root.onboardingComplete = true
    root.firstRun = false
    root.scheduleConfigSave()
    root.revision++
  }

  function scheduleConfigSave() {
    if (!root.configLoaded) return
    configSaveTimer.restart()
  }

  function saveConfig() {
    if (!root.configLoaded) return
    configFile.setText(JSON.stringify({
      schemaVersion: 2,
      scene: root.currentSceneId,
      bloomActive: root.bloomActive,
      launchAtStartup: root.launchAtStartup,
      onboardingComplete: root.onboardingComplete,
      sceneWallpaper: root.sceneWallpaper,
      workspaceState: root.workspaceState
    }, null, 2) + "\n")
  }

  function applyAgentEvents(raw) {
    var parsed = []
    var lines = String(raw || "").split("\n")
    var start = Math.max(0, lines.length - 200)
    for (var i = start; i < lines.length; i++) {
      var line = lines[i].trim()
      if (!line) continue
      try {
        var item = JSON.parse(line)
        if (item && item.id && item.provider) parsed.push(AgentStore.normalize(item))
      } catch (e) {
        console.warn("Bloom ignored malformed agent event")
      }
    }
    root.eventAgents = AgentStore.sort(parsed)
    root.rebuildAgents()
  }

  function processSnapshot(raw) {
    var found = []
    var lines = String(raw || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var match = lines[i].match(/^\s*(\d+)\s+(\S+)\s*(.*)$/)
      if (!match || !AgentStore.isAgentCommand(match[2])) continue
      found.push(AgentStore.fromProcess(match[1], match[2], match[3]))
    }
    root.processAgents = found
    root.rebuildAgents()
  }

  function demoAgents() {
    var now = Date.now()
    return [
      AgentStore.normalize({ id: "demo-codex", provider: "codex", project: "bloom", branch: "main", status: "working", summary: "Polishing the focus rail", detail: "Refactoring the signal path", progress: 0.72, updatedAt: now - 10000, orbit: 0 }),
      AgentStore.normalize({ id: "demo-claude", provider: "claude", project: "atlas", branch: "experiment/quiet", status: "attention", summary: "One choice needs your eye", detail: "A diff is ready for review", progress: 0.58, attention: true, updatedAt: now - 34000, orbit: 1 }),
      AgentStore.normalize({ id: "demo-gemini", provider: "gemini", project: "lumen", branch: "docs/launch", status: "waiting", summary: "Waiting on a design token", detail: "No action until you switch scenes", progress: 0.31, updatedAt: now - 62000, orbit: 2 }),
      AgentStore.normalize({ id: "demo-opencode", provider: "opencode", project: "signal", branch: "fix/pulse", status: "working", summary: "Running the smoke suite", detail: "42 checks in motion", progress: 0.86, updatedAt: now - 9000, orbit: 3 })
    ]
  }

  function rebuildAgents() {
    var live = AgentStore.merge(root.processAgents, root.eventAgents)
    root.agents = root.demoMode ? AgentStore.merge(demoAgents(), live) : live
    root.revision++
  }

  function setDemoMode(value) {
    root.demoMode = value === true || String(value).toLowerCase() === "true"
    root.rebuildAgents()
  }

  function summon(view) {
    if (root.shell && typeof root.shell.summon === "function")
      return root.shell.summon(root.moduleName, JSON.stringify({ view: view || "scenes", demo: root.demoMode }))
    return false
  }

  function focusAgent(id) {
    for (var i = 0; i < root.agents.length; i++) {
      var agent = root.agents[i]
      if (String(agent.id) !== String(id)) continue
      if (Number(agent.pid) > 0)
        Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "pid:" + Number(agent.pid)])
      return agent.id
    }
    return ""
  }

  Process {
    id: ensureDirs
    command: ["mkdir", "-p", root.bloomConfigDir, root.userWallpaperRoot,
              root.stateDir, root.runtimeHome + "/omarchy-bloom"]
    onExited: {
      root.refreshWallpapers()
      if (!root.configLoaded) configFile.reload()
    }
  }

  FileView {
    id: configFile
    path: root.bloomConfigDir + "/config.json"
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.parseConfig(text())
    onFileChanged: root.parseConfig(configFile.text())
    onLoadFailed: {
      root.firstRun = true
      root.configLoaded = true
      root.scheduleConfigSave()
    }
  }

  FileView {
    id: eventFileView
    path: root.eventFile
    watchChanges: true
    printErrors: false
    onLoaded: root.applyAgentEvents(text())
    onFileChanged: root.applyAgentEvents(eventFileView.text())
  }

  Process {
    id: wallpaperScan
    command: ["find", root.userWallpaperRoot, "-maxdepth", "2", "-type", "f", "-print"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.rebuildWallpapers(text)
    }
    onExited: {
      if (root.rescanQueued) {
        root.rescanQueued = false
        Qt.callLater(root.refreshWallpapers)
      }
    }
  }

  Process {
    id: agentScan
    command: ["ps", "-eo", "pid=,comm=,args="]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.processSnapshot(text)
    }
  }

  Timer {
    id: refreshTimer
    interval: 2500
    repeat: true
    running: true
    onTriggered: {
      if (!agentScan.running) agentScan.running = true
      if (!wallpaperScan.running) root.refreshWallpapers()
    }
  }

  Timer {
    id: configSaveTimer
    interval: 500
    repeat: false
    onTriggered: root.saveConfig()
  }

  Timer {
    id: startupOpenTimer
    interval: 900
    repeat: false
    onTriggered: root.summon("scenes")
  }

  Connections {
    target: Hyprland
    function onFocusedWorkspaceChanged() { root.syncFocusedWorkspace(false) }
  }

  Timer {
    id: workspaceTimer
    interval: 350
    repeat: true
    running: true
    onTriggered: root.syncFocusedWorkspace(false)
  }

  IpcHandler {
    target: "bloom"

    function open(): string { return root.summon("scenes") ? "ok" : "unavailable" }
    function scenes(): string { return root.summon("scenes") ? "ok" : "unavailable" }
    function scene(id: string): string { return root.setScene(id) ? id : "unknown-scene" }
    function nextScene(): string { return root.nextScene(1) }
    function previousScene(): string { return root.nextScene(-1) }
    function nextWallpaper(): string { return root.nextWallpaper() }
    function wallpaper(path: string): string { return root.selectWallpaper(path) ? root.currentWallpaperPath : "unknown-wallpaper" }
    function refresh(): string { root.refreshWallpapers(); if (!agentScan.running) agentScan.running = true; return "ok" }
    function demo(enabled: string): string {
      root.setDemoMode(enabled === "" ? !root.demoMode : enabled === "true" || enabled === "1")
      root.summon("constellation")
      return root.demoMode ? "on" : "off"
    }
    function startup(value: string): string {
      var mode = String(value || "").toLowerCase()
      if (mode === "status") return root.launchAtStartup ? "on" : "off"
      if (mode === "on" || mode === "true" || mode === "1") root.setLaunchAtStartup(true)
      else if (mode === "off" || mode === "false" || mode === "0") root.setLaunchAtStartup(false)
      else root.toggleLaunchAtStartup()
      return root.launchAtStartup ? "on" : "off"
    }
    function active(value: string): string {
      var mode = String(value || "").toLowerCase()
      if (mode === "status") return root.bloomActive ? "on" : "off"
      if (mode === "on" || mode === "true" || mode === "1") root.setBloomActive(true)
      else if (mode === "off" || mode === "false" || mode === "0") root.setBloomActive(false)
      else root.toggleBloomActive()
      return root.bloomActive ? "on" : "off"
    }
    function focus(id: string): string { return root.focusAgent(id) || "unknown-agent" }
  }

  Component.onCompleted: {
    root.bloomActive = true
    ensureDirs.running = true
    root.refreshWallpapers()
    agentScan.running = true
    root.syncFocusedWorkspace(true)
  }
}
