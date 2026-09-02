import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root

  moduleName: "org.bloom.omarchy"
  property var bloom: bar && bar.shell && typeof bar.shell.serviceFor === "function"
    ? bar.shell.serviceFor(moduleName) : null
  property bool restoreLastSetup: true
  readonly property color pulseColor: bloom && bloom.attentionCount > 0
    ? "#FF8DA1" : (bloom && bloom.currentScene ? bloom.currentScene.accent : Color.accent)
  readonly property string sessionCommand: {
    var value = String(Qt.resolvedUrl("scripts/bloom-session"))
    if (value.indexOf("file://") === 0) {
      try { return decodeURIComponent(value.slice(7)) } catch (e) { return value.slice(7) }
    }
    return value
  }

  implicitWidth: controls.implicitWidth
  implicitHeight: controls.implicitHeight

  function open(view) {
    if (bar && bar.shell) bar.shell.summon(moduleName, JSON.stringify({ view: view || "scenes" }))
  }

  function close() {
    if (bar && bar.shell) bar.shell.hide(moduleName)
  }

  function toggle() {
    if (bar && bar.shell) bar.shell.toggle(moduleName, JSON.stringify({ view: "scenes" }))
  }

  function setSessionMode(restore) {
    root.restoreLastSetup = !!restore
    Quickshell.execDetached(["python3", root.sessionCommand, "set", restore ? "restore" : "fresh"])
    sessionRefresh.restart()
  }

  Row {
    id: controls
    spacing: Style.space(2)

    BarIconButton {
      id: button
      bar: root.bar
      text: root.setting("glyph", "✦")
      active: !!root.bloom && root.bloom.attentionCount > 0
      tooltipText: root.bloom && root.bloom.attentionCount > 0
        ? "Bloom · " + root.bloom.attentionCount + " agent needs you"
        : "Bloom · open controls · " + (root.bloom && root.bloom.currentScene ? root.bloom.currentScene.name : "Forge")
      onPressed: function(buttonCode) {
        if (buttonCode === Qt.RightButton && root.bloom)
          root.bloom.nextWallpaper()
        else if (buttonCode === Qt.MiddleButton && root.bloom)
          root.bloom.nextScene(1)
        else
          root.toggle()
      }

      Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        width: root.bloom && root.bloom.attentionCount > 0 ? Style.space(6) : 0
        height: width
        radius: width / 2
        color: "#FF8DA1"
        visible: width > 0
        border.width: 1
        border.color: Qt.rgba(0.08, 0.1, 0.14, 0.85)
      }
    }

    BarIconButton {
      id: activeToggle
      bar: root.bar
      text: root.bloom && root.bloom.bloomActive ? "ON" : "OFF"
      active: !!root.bloom && root.bloom.bloomActive
      tooltipText: root.bloom && root.bloom.bloomActive
        ? "Bloom is active · click to pause"
        : "Bloom is paused · click to activate"
      onPressed: function() {
        if (root.bloom) root.bloom.toggleBloomActive()
      }
    }

    BarIconButton {
      id: sessionToggle
      bar: root.bar
      text: root.restoreLastSetup ? "SAVE" : "FRESH"
      active: root.restoreLastSetup
      tooltipText: root.restoreLastSetup
        ? "Session restore is on · Bloom saves this setup and restores it after reboot · click to start fresh next time"
        : "Start fresh is on · no apps will be restored after reboot · click to resume saving this setup"
      onPressed: function() {
        root.setSessionMode(!root.restoreLastSetup)
      }
    }
  }

  Process {
    id: sessionRefresh
    command: ["python3", root.sessionCommand, "auto"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.restoreLastSetup = String(text || "").trim() !== "fresh"
    }
  }

  Timer {
    interval: 5000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: {
      if (!sessionRefresh.running) sessionRefresh.running = true
    }
  }
}
