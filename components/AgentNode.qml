import QtQuick
import qs.Commons
import "../models/AgentStore.js" as AgentStore

Item {
  id: root

  property var agent: ({})
  property color accent: "#91D7C8"
  property bool selected: false
  signal activated()

  implicitWidth: 168
  implicitHeight: 68

  Rectangle {
    anchors.fill: parent
    radius: 16
    color: root.selected ? Qt.rgba(0.10, 0.13, 0.18, 0.97) : Qt.rgba(0.055, 0.07, 0.11, 0.88)
    border.width: root.selected ? 2 : 1
    border.color: root.selected ? root.accent : Qt.rgba(0.72, 0.8, 0.9, 0.14)

    Rectangle {
      id: halo
      anchors.left: parent.left
      anchors.leftMargin: 14
      anchors.verticalCenter: parent.verticalCenter
      width: 34
      height: width
      radius: width / 2
      color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.15)
      border.width: 1
      border.color: root.accent

      Text {
        anchors.centerIn: parent
        text: String(root.agent.providerLabel || "?").slice(0, 1)
        color: root.agent.providerColor || root.accent
        font.family: Style.font.family
        font.pixelSize: 13
        font.bold: true
      }

      Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 8
        height: width
        radius: width / 2
        color: AgentStore.statusColor(root.agent.status, root.accent)
        border.width: 1
        border.color: "#0B0F17"
      }
    }

    Column {
      anchors.left: halo.right
      anchors.leftMargin: 10
      anchors.right: parent.right
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      spacing: 3

      Text {
        text: String(root.agent.providerLabel || "Agent")
        color: "#EFF3F8"
        font.family: Style.font.family
        font.pixelSize: 12
        font.bold: true
        elide: Text.ElideRight
      }

      Text {
        text: String(root.agent.project || "Local session") + "  ·  " + AgentStore.statusLabel(root.agent.status)
        color: AgentStore.statusColor(root.agent.status, "#9AA8BB")
        font.family: Style.font.family
        font.pixelSize: 10
        elide: Text.ElideRight
      }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.activated()
    }
  }
}
