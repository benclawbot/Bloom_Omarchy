import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "models/AgentStore.js" as AgentStore
import "components"

Item {
  id: root

  // Injected by omarchy-shell.
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null
  property var service: null

  property bool opened: false
  property string currentView: "scenes"
  property string selectedAgentId: ""
  property bool focusPrimed: false
  property bool showWelcome: false
  property double lastSceneClickAt: 0

  readonly property string moduleName: "org.bloom.omarchy"
  readonly property var currentScene: service && service.currentScene
    ? service.currentScene : ({ name: "Forge", accent: "#F3A45D", description: "" })
  readonly property color accent: currentScene.accent || "#F3A45D"
  readonly property var selectedAgent: findAgent(selectedAgentId)

  function isPrimaryScreen(screen) {
    var screens = Quickshell.screens
    return screens.length > 0 && screen && screens[0] && screen.name === screens[0].name
  }

  function parsePayload(payloadJson) {
    var payload = {}
    try { payload = JSON.parse(String(payloadJson || "{}")) } catch (e) { payload = {} }
    return payload
  }

  function open(payloadJson) {
    var payload = parsePayload(payloadJson)
    if (payload.view) currentView = String(payload.view)
    if (payload.demo !== undefined && service) service.setDemoMode(payload.demo)
    showWelcome = service && !service.onboardingComplete
    opened = true
    focusPrimed = false
    Qt.callLater(function() {
      focusPrimed = true
      keyCatcher.forceActiveFocus()
    })
  }

  function close() {
    opened = false
    focusPrimed = false
  }

  function finishWelcome() {
    showWelcome = false
    if (service) service.completeOnboarding()
    keyCatcher.forceActiveFocus()
  }

  function dismiss() {
    root.close()
    if (shell && typeof shell.hide === "function") shell.hide(moduleName)
  }

  function toggle(payloadJson) {
    if (opened) dismiss()
    else open(payloadJson || "{}")
  }

  function setView(view) {
    currentView = String(view || "scenes")
    keyCatcher.forceActiveFocus()
  }

  function selectScene(id) {
    var now = Date.now()
    if (now - root.lastSceneClickAt < 220) return
    root.lastSceneClickAt = now
    if (service) service.setScene(id)
    currentView = "scenes"
    keyCatcher.forceActiveFocus()
  }

  function findAgent(id) {
    if (!service) return null
    for (var i = 0; i < service.agents.length; i++)
      if (String(service.agents[i].id) === String(id)) return service.agents[i]
    return service.agents.length ? service.agents[0] : null
  }

  function selectAgent(id) {
    selectedAgentId = String(id || "")
    currentView = "constellation"
    keyCatcher.forceActiveFocus()
  }

  function nextAgent(delta) {
    if (!service || !service.agents.length) return
    var index = -1
    for (var i = 0; i < service.agents.length; i++)
      if (String(service.agents[i].id) === selectedAgentId) index = i
    index = (index + Number(delta || 1) + service.agents.length) % service.agents.length
    selectedAgentId = String(service.agents[index].id)
  }

  function setDemoFromUi() {
    if (!service) return
    service.setDemoMode(!service.demoMode)
    currentView = "constellation"
  }

  IpcHandler {
    target: root.moduleName
    function open(): void { root.open("{}") }
    function close(): void { root.close() }
    function show(): void { root.open("{}") }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle("{}") }
    function scene(id: string): string { return root.selectScene(id) || id }
    function nextWallpaper(): string {
      if (!root.service) return ""
      return root.service.nextWallpaper()
    }
    function nextScene(): string {
      if (!root.service) return ""
      return root.service.nextScene(1)
    }
  }

  Variants {
    model: root.opened ? Quickshell.screens : []

    delegate: Component {
      PanelWindow {
        id: window
        required property var modelData
        screen: modelData
        visible: root.opened
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "bloom-omarchy"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.isPrimaryScreen(modelData)
          ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }

        Image {
          anchors.fill: parent
          source: root.service ? root.service.currentWallpaperUrl : ""
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          cache: true
          opacity: 0.22
        }

        Rectangle {
          anchors.fill: parent
          color: "#C50A0E16"
        }

        Rectangle {
          anchors.fill: parent
          color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.035)
        }

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.AllButtons
          onClicked: root.dismiss()
        }

        Rectangle {
          id: card
          z: 2
          width: Math.min(parent.width - 72, 1280)
          height: Math.min(parent.height - 92, 790)
          anchors.centerIn: parent
          radius: 26
          color: "#EA0D121B"
          border.width: 1
          border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.28)

          Image {
            anchors.fill: parent
            source: root.service ? root.service.currentWallpaperUrl : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            opacity: 0.11
          }

          Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "#A30B1018"
          }

          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: {}
          }

          Item {
            id: frame
            anchors.fill: parent
            anchors.margins: 28

            Item {
              id: header
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              height: 76

              Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Rectangle {
                  width: 38
                  height: width
                  radius: 13
                  color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
                  border.width: 1
                  border.color: root.accent

                  Text {
                    anchors.centerIn: parent
                    text: "✦"
                    color: root.accent
                    font.family: Style.font.family
                    font.pixelSize: 19
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (service) service.toggleBloomActive()
                  }
                }

                Column {
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 2
                  Text {
                    text: "BLOOM"
                    color: "#F2F5F9"
                    font.family: Style.font.family
                    font.pixelSize: 16
                    font.bold: true
                    font.letterSpacing: 2.3
                  }
                  Text {
                    text: "living workspaces for Omarchy"
                    color: "#8592A5"
                    font.family: Style.font.family
                    font.pixelSize: 10
                  }
                }
              }

              Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Repeater {
                  model: [
                    { id: "scenes", label: "SCENES" },
                    { id: "constellation", label: "CONSTELLATION" },
                    { id: "wallpapers", label: "WALLPAPERS" }
                  ]
                  delegate: Rectangle {
                    required property var modelData
                    width: tabLabel.implicitWidth + 26
                    height: 30
                    radius: 15
                    color: root.currentView === modelData.id
                      ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
                      : "transparent"
                    border.width: root.currentView === modelData.id ? 1 : 0
                    border.color: root.accent

                    Text {
                      id: tabLabel
                      anchors.centerIn: parent
                      text: modelData.label
                      color: root.currentView === modelData.id ? root.accent : "#77869B"
                      font.family: Style.font.family
                      font.pixelSize: 10
                      font.bold: true
                      font.letterSpacing: 1.1
                    }

                    MouseArea {
                      anchors.fill: parent
                      onClicked: root.setView(modelData.id)
                    }
                  }
                }
              }

              Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Rectangle {
                  width: 76
                  height: 30
                  radius: 15
                  color: service && service.demoMode
                    ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
                    : Qt.rgba(0.56, 0.63, 0.72, 0.08)
                  border.width: 1
                  border.color: service && service.demoMode ? root.accent : "#344052"
                  Text {
                    anchors.centerIn: parent
                    text: service && service.demoMode ? "DEMO ON" : "LIVE"
                    color: service && service.demoMode ? root.accent : "#8996A8"
                    font.family: Style.font.family
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1
                  }
                  MouseArea { anchors.fill: parent; onClicked: root.setDemoFromUi() }
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: "ESC"
                  color: "#68768A"
                  font.family: Style.font.family
                  font.pixelSize: 10
                }
              }
            }

            Item {
              id: body
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: header.bottom
              anchors.bottom: footer.top
              anchors.topMargin: 12
              anchors.bottomMargin: 16

              Item {
                id: sceneRail
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 216

                Text {
                  id: railLabel
                  text: "SCENES"
                  color: "#738196"
                  font.family: Style.font.family
                  font.pixelSize: 10
                  font.bold: true
                  font.letterSpacing: 1.5
                }

                Column {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.top: railLabel.bottom
                  anchors.topMargin: 14
                  spacing: 9

                  Repeater {
                    model: service ? service.sceneList : []
                    delegate: SceneCard {
                      required property var modelData
                      width: sceneRail.width
                      height: 84
                      scene: modelData
                      compact: true
                      selected: service && service.currentSceneId === modelData.id
                      onActivated: root.selectScene(modelData.id)
                    }
                  }
                }

                Text {
                  anchors.left: parent.left
                  anchors.bottom: parent.bottom
                  width: parent.width
                  text: "1—5  switch scene\nN    next wallpaper\nA    agent constellation"
                  color: "#66758A"
                  font.family: Style.font.family
                  font.pixelSize: 10
                  lineHeight: 1.45
                }
              }

              Rectangle {
                id: dividerLeft
                anchors.left: sceneRail.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.leftMargin: 22
                width: 1
                color: "#24303F"
              }

              Item {
                id: stage
                anchors.left: dividerLeft.right
                anchors.right: details.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.leftMargin: 26
                anchors.rightMargin: 26

                Item {
                  id: scenesPage
                  anchors.fill: parent
                  visible: root.currentView === "scenes"

                  Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    spacing: 9

                    Text {
                      text: String(root.currentScene.eyebrow || "BUILD")
                      color: root.accent
                      font.family: Style.font.family
                      font.pixelSize: 11
                      font.bold: true
                      font.letterSpacing: 2
                    }
                    Text {
                      text: String(root.currentScene.name || "Forge")
                      color: "#F1F5FA"
                      font.family: Style.font.family
                      font.pixelSize: 38
                      font.bold: true
                    }
                    Text {
                      text: String(root.currentScene.tagline || "Make the hard thing feel possible.")
                      color: "#C5CEDA"
                      font.family: Style.font.family
                      font.pixelSize: 15
                    }
                    Text {
                      width: parent.width
                      text: String(root.currentScene.description || "")
                      color: "#8592A5"
                      font.family: Style.font.family
                      font.pixelSize: 12
                      wrapMode: Text.WordWrap
                    }
                  }

                  Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: Math.min(280, parent.height * 0.42)
                    radius: 20
                    color: "#A70B111A"
                    border.width: 1
                    border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.2)

                    Image {
                      anchors.fill: parent
                      source: service ? service.currentWallpaperUrl : ""
                      fillMode: Image.PreserveAspectCrop
                      asynchronous: true
                      cache: true
                      opacity: 0.48
                    }

                    Rectangle {
                      anchors.fill: parent
                      radius: parent.radius
                      color: "#8D0C121C"
                    }

                    Column {
                      anchors.left: parent.left
                      anchors.bottom: parent.bottom
                      anchors.margins: 22
                      spacing: 5

                      Text {
                        text: "NOW SHAPING THE ROOM"
                        color: root.accent
                        font.family: Style.font.family
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 1.4
                      }
                      Text {
                        text: service ? service.currentWallpaperTitle : "Emberline"
                        color: "#F2F5F9"
                        font.family: Style.font.family
                        font.pixelSize: 20
                        font.bold: true
                      }
                      Text {
                        text: "Right-click the Bloom glyph for the next wallpaper"
                        color: "#9AA7B8"
                        font.family: Style.font.family
                        font.pixelSize: 10
                      }
                    }

                    Rectangle {
                      anchors.right: parent.right
                      anchors.top: parent.top
                      anchors.margins: 18
                      width: 82
                      height: 30
                      radius: 15
                      color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.13)
                      border.width: 1
                      border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.55)
                      Text {
                        anchors.centerIn: parent
                        text: "N  NEXT"
                        color: root.accent
                        font.family: Style.font.family
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 1
                      }
                      MouseArea {
                        anchors.fill: parent
                        onClicked: if (service) service.nextWallpaper()
                      }
                    }
                  }
                }

                Item {
                  id: constellationPage
                  anchors.fill: parent
                  visible: root.currentView === "constellation"

                  Text {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    text: "AGENT CONSTELLATION"
                    color: root.accent
                    font.family: Style.font.family
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 2
                  }
                  Text {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.topMargin: 28
                    text: service && service.agents.length
                      ? String(service.agents.length) + " signals around your workspace"
                      : "Your local agents will appear here"
                    color: "#F1F5FA"
                    font.family: Style.font.family
                    font.pixelSize: 26
                    font.bold: true
                  }
                  Text {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.topMargin: 69
                    text: "Click a node to inspect it. Enter focuses its window."
                    color: "#8290A4"
                    font.family: Style.font.family
                    font.pixelSize: 12
                  }

                  ConstellationCanvas {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: 110
                    anchors.bottomMargin: 4
                    agents: service ? service.agents : []
                    accent: root.accent
                    selectedAgentId: root.selectedAgentId
                    onAgentActivated: root.selectAgent(agentId)
                  }
                }

                Item {
                  id: wallpaperPage
                  anchors.fill: parent
                  visible: root.currentView === "wallpapers"

                  Text {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    text: "WALLPAPER LIBRARY"
                    color: root.accent
                    font.family: Style.font.family
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 2
                  }
                  Text {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.topMargin: 28
                    text: service ? service.currentWallpaperTitle : "A room with a pulse"
                    color: "#F1F5FA"
                    font.family: Style.font.family
                    font.pixelSize: 28
                    font.bold: true
                  }

                  Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: 86
                    radius: 22
                    color: "#930A1018"
                    border.width: 1
                    border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.25)

                    Image {
                      anchors.fill: parent
                      source: service ? service.currentWallpaperUrl : ""
                      fillMode: Image.PreserveAspectCrop
                      asynchronous: true
                      cache: true
                      opacity: 0.78
                    }

                    Rectangle {
                      anchors.fill: parent
                      radius: parent.radius
                      color: "#360B1018"
                    }

                    Row {
                      anchors.left: parent.left
                      anchors.bottom: parent.bottom
                      anchors.margins: 18
                      spacing: 8

                      Rectangle {
                        width: 112
                        height: 32
                        radius: 16
                        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.15)
                        border.width: 1
                        border.color: root.accent
                        Text {
                          anchors.centerIn: parent
                          text: "N  NEXT IMAGE"
                          color: root.accent
                          font.family: Style.font.family
                          font.pixelSize: 9
                          font.bold: true
                          font.letterSpacing: 0.7
                        }
                        MouseArea { anchors.fill: parent; onClicked: if (service) service.nextWallpaper() }
                      }
                    }
                  }
                }
              }

              Rectangle {
                id: dividerRight
                anchors.right: details.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.rightMargin: 22
                width: 1
                color: "#24303F"
              }

              Item {
                id: details
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 236

                Text {
                  id: detailsLabel
                  text: "SIGNAL"
                  color: "#738196"
                  font.family: Style.font.family
                  font.pixelSize: 10
                  font.bold: true
                  font.letterSpacing: 1.5
                }

                Column {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.top: detailsLabel.bottom
                  anchors.topMargin: 16
                  spacing: 12

                  Rectangle {
                    width: parent.width
                    height: 116
                    radius: 18
                    color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.08)
                    border.width: 1
                    border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.27)

                    Column {
                      anchors.left: parent.left
                      anchors.right: parent.right
                      anchors.top: parent.top
                      anchors.margins: 17
                      spacing: 6
                      Text {
                        text: service && service.attentionCount
                          ? service.attentionCount + " NEED YOU"
                          : "ALL QUIET"
                        color: service && service.attentionCount ? "#FF9AAC" : root.accent
                        font.family: Style.font.family
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.2
                      }
                      Text {
                        text: service && service.agents.length
                          ? service.agents.length + " agents in orbit"
                          : "No local agent sessions"
                        color: "#E7EDF5"
                        font.family: Style.font.family
                        font.pixelSize: 14
                        font.bold: true
                      }
                      Text {
                        text: service && service.demoMode
                          ? "Demo signals are on"
                          : service
                            ? "Workspace " + service.currentWorkspaceId + " · " + service.currentScene.name
                            : "Listening for local sessions"
                        color: "#8795A9"
                        font.family: Style.font.family
                        font.pixelSize: 10
                      }
                    }
                  }

                  Rectangle {
                    width: parent.width
                    height: 52
                    radius: 16
                    color: service && service.bloomActive
                      ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.10)
                      : "#121A25"
                    border.width: 1
                    border.color: service && service.bloomActive
                      ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.42)
                      : "#293445"

                    Row {
                      anchors.left: parent.left
                      anchors.verticalCenter: parent.verticalCenter
                      anchors.leftMargin: 16
                      spacing: 8
                      Text {
                        text: service && service.bloomActive ? "BLOOM ACTIVE" : "BLOOM PAUSED"
                        color: service && service.bloomActive ? root.accent : "#A4AFBF"
                        font.family: Style.font.family
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 0.8
                      }
                    }

                    Rectangle {
                      anchors.right: parent.right
                      anchors.verticalCenter: parent.verticalCenter
                      anchors.rightMargin: 12
                      width: 42
                      height: 24
                      radius: 12
                      color: service && service.bloomActive ? root.accent : "#273243"
                      Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: service && service.bloomActive ? parent.width - width - 3 : 3
                        width: 18
                        height: 18
                        radius: 9
                        color: service && service.bloomActive ? "#0C1119" : "#9AA6B6"
                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                      }
                    }

                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: if (service) service.toggleBloomActive()
                    }
                  }

                  Rectangle {
                    visible: false
                    width: parent.width
                    height: 52
                    radius: 16
                    color: service && service.launchAtStartup
                      ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.10)
                      : "#121A25"
                    border.width: 1
                    border.color: service && service.launchAtStartup
                      ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.42)
                      : "#293445"

                    Column {
                      anchors.left: parent.left
                      anchors.verticalCenter: parent.verticalCenter
                      anchors.leftMargin: 16
                      spacing: 2
                      Text {
                        text: "OPEN AT LOGIN"
                        color: "#E7EDF5"
                        font.family: Style.font.family
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 0.8
                      }
                      Text {
                        text: "Show the canvas when Omarchy starts"
                        color: "#718095"
                        font.family: Style.font.family
                        font.pixelSize: 8
                      }
                    }

                    Rectangle {
                      anchors.right: parent.right
                      anchors.verticalCenter: parent.verticalCenter
                      anchors.rightMargin: 12
                      width: 42
                      height: 24
                      radius: 12
                      color: service && service.launchAtStartup ? root.accent : "#273243"
                      Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: service && service.launchAtStartup ? parent.width - width - 3 : 3
                        width: 18
                        height: 18
                        radius: 9
                        color: service && service.launchAtStartup ? "#0C1119" : "#9AA6B6"
                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                      }
                    }

                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: if (service) service.toggleLaunchAtStartup()
                    }
                  }

                  Text {
                    visible: !!root.selectedAgent
                    text: root.selectedAgent ? root.selectedAgent.providerLabel : ""
                    color: root.selectedAgent ? root.selectedAgent.providerColor : root.accent
                    font.family: Style.font.family
                    font.pixelSize: 18
                    font.bold: true
                  }
                  Text {
                    visible: !!root.selectedAgent
                    text: root.selectedAgent ? root.selectedAgent.project : ""
                    color: "#F0F4F8"
                    font.family: Style.font.family
                    font.pixelSize: 13
                    font.bold: true
                  }
                  Text {
                    visible: !!root.selectedAgent
                    width: parent.width
                    text: root.selectedAgent
                      ? String(root.selectedAgent.summary || "") + "\n\n" + String(root.selectedAgent.detail || "")
                      : ""
                    color: "#8997AA"
                    font.family: Style.font.family
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    lineHeight: 1.35
                  }

                  Rectangle {
                    visible: !!root.selectedAgent
                    width: parent.width
                    height: 6
                    radius: 3
                    color: "#202A37"
                    Rectangle {
                      width: parent.width * (root.selectedAgent ? root.selectedAgent.progress : 0)
                      height: parent.height
                      radius: 3
                      color: root.accent
                    }
                  }

                  Rectangle {
                    visible: !!root.selectedAgent
                    width: parent.width
                    height: 34
                    radius: 17
                    color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.13)
                    border.width: 1
                    border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.5)
                    Text {
                      anchors.centerIn: parent
                      text: root.selectedAgent && root.selectedAgent.pid > 0 ? "ENTER  FOCUS WINDOW" : "LIVE SIGNAL"
                      color: root.accent
                      font.family: Style.font.family
                      font.pixelSize: 9
                      font.bold: true
                      font.letterSpacing: 0.8
                    }
                    MouseArea {
                      anchors.fill: parent
                      onClicked: if (root.selectedAgent && service) service.focusAgent(root.selectedAgent.id)
                    }
                  }
                }

                Text {
                  anchors.left: parent.left
                  anchors.bottom: parent.bottom
                  width: parent.width
                  text: "Bloom never uploads agent data.\nEverything stays on this machine."
                  color: "#617084"
                  font.family: Style.font.family
                  font.pixelSize: 10
                  lineHeight: 1.4
                }
              }
            }

            Rectangle {
              id: welcomeCard
              visible: root.showWelcome
              z: 10
              anchors.fill: parent
              radius: 22
              color: "#F20B1018"
              border.width: 1
              border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.42)

              Column {
                anchors.centerIn: parent
                width: Math.min(parent.width - 80, 720)
                spacing: 16

                Text {
                  width: parent.width
                  text: "BLOOM IS ACTIVE"
                  color: root.accent
                  font.family: Style.font.family
                  font.pixelSize: 12
                  font.bold: true
                  font.letterSpacing: 2.2
                  horizontalAlignment: Text.AlignHCenter
                }

                Text {
                  width: parent.width
                  text: "Give every workspace an atmosphere."
                  color: "#F2F5F9"
                  font.family: Style.font.family
                  font.pixelSize: 32
                  font.bold: true
                  horizontalAlignment: Text.AlignHCenter
                  wrapMode: Text.WordWrap
                }

                Text {
                  width: parent.width
                  text: "Bloom is already running in the shell. This canvas is where you shape it; close it anytime and your workspace atmosphere stays in place."
                  color: "#9AA7B8"
                  font.family: Style.font.family
                  font.pixelSize: 13
                  horizontalAlignment: Text.AlignHCenter
                  wrapMode: Text.WordWrap
                  lineHeight: 1.35
                }

                Flow {
                  width: parent.width
                  spacing: 8
                  layoutDirection: Qt.LeftToRight

                  Repeater {
                    model: [
                      { id: "1", name: "FORGE", color: "#F3A45D" },
                      { id: "2", name: "HUSH", color: "#91D7C8" },
                      { id: "3", name: "LIBRARY", color: "#E8C773" },
                      { id: "4", name: "AFTERGLOW", color: "#F28E9A" },
                      { id: "5", name: "ORBIT", color: "#9FBCFF" }
                    ]
                    delegate: Rectangle {
                      required property var modelData
                      width: (parent.width - 32) / 5
                      height: 58
                      radius: 14
                      color: Qt.rgba(1, 1, 1, 0.035)
                      border.width: 1
                      border.color: Qt.rgba(1, 1, 1, 0.09)

                      Column {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                          width: parent.width
                          text: modelData.id
                          color: modelData.color
                          font.family: Style.font.family
                          font.pixelSize: 11
                          font.bold: true
                          horizontalAlignment: Text.AlignHCenter
                        }
                        Text {
                          width: parent.width
                          text: modelData.name
                          color: "#E7EDF5"
                          font.family: Style.font.family
                          font.pixelSize: 9
                          font.bold: true
                          horizontalAlignment: Text.AlignHCenter
                        }
                      }
                    }
                  }
                }

                Text {
                  width: parent.width
                  text: "Switch workspaces 1 → 5 to feel the difference. Use Open at login in the Signal rail if you want Bloom to open with Omarchy."
                  color: "#718095"
                  font.family: Style.font.family
                  font.pixelSize: 11
                  horizontalAlignment: Text.AlignHCenter
                  wrapMode: Text.WordWrap
                }

                Rectangle {
                  anchors.horizontalCenter: parent.horizontalCenter
                  width: 190
                  height: 42
                  radius: 21
                  color: root.accent
                  Text {
                    anchors.centerIn: parent
                    text: "START BLOOM"
                    color: "#0C1119"
                    font.family: Style.font.family
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1.2
                  }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (service) service.setBloomActive(true)
                      root.finishWelcome()
                    }
                  }
                }
              }
            }

            Item {
              id: footer
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              height: 24

              Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: service && service.currentWallpaperUrl
                  ? "Bloom is shaping " + String(root.currentScene.name || "your room")
                  : "Bloom is ready for its first signal"
                color: "#647287"
                font.family: Style.font.family
                font.pixelSize: 10
              }

              Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "← → scenes   ·   ↑ ↓ agents   ·   ENTER focus"
                color: "#647287"
                font.family: Style.font.family
                font.pixelSize: 10
              }
            }

            Item {
              id: keyCatcher
              anchors.fill: parent
              focus: true
              Keys.priority: Keys.BeforeItem
              Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                  root.dismiss()
                  event.accepted = true
                } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_5) {
                  var sceneIndex = event.key - Qt.Key_1
                  if (service && service.sceneList.length > sceneIndex)
                    root.selectScene(service.sceneList[sceneIndex].id)
                  event.accepted = true
                } else if (event.key === Qt.Key_N) {
                  if (service) service.nextWallpaper()
                  event.accepted = true
                } else if (event.key === Qt.Key_A) {
                  root.setView("constellation")
                  event.accepted = true
                } else if (event.key === Qt.Key_W) {
                  root.setView("wallpapers")
                  event.accepted = true
                } else if (event.key === Qt.Key_S) {
                  root.setView("scenes")
                  event.accepted = true
                } else if (event.key === Qt.Key_Tab) {
                  var views = ["scenes", "constellation", "wallpapers"]
                  var current = views.indexOf(root.currentView)
                  root.setView(views[(current + 1) % views.length])
                  event.accepted = true
                } else if (event.key === Qt.Key_Left && service) {
                  service.nextScene(-1)
                  event.accepted = true
                } else if (event.key === Qt.Key_Right && service) {
                  service.nextScene(1)
                  event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                  root.nextAgent(-1)
                  event.accepted = true
                } else if (event.key === Qt.Key_Down) {
                  root.nextAgent(1)
                  event.accepted = true
                } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && root.selectedAgent && service) {
                  service.focusAgent(root.selectedAgent.id)
                  event.accepted = true
                }
              }
            }
          }
        }
      }
    }
  }
}
