import QtQuick
import qs.Commons

Item {
  id: root

  property var scene: ({})
  property bool selected: false
  property bool compact: false
  signal activated()

  implicitWidth: compact ? 154 : 212
  implicitHeight: compact ? 74 : 110

  Rectangle {
    anchors.fill: parent
    radius: Style.cornerRadius
    color: root.selected ? Qt.rgba(0.12, 0.14, 0.19, 0.96) : Qt.rgba(0.06, 0.08, 0.12, 0.75)
    border.width: root.selected ? 2 : 1
    border.color: root.selected ? (root.scene.accent || Color.accent) : Qt.rgba(0.62, 0.68, 0.76, 0.16)

    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: 4
      radius: 2
      color: root.scene.accent || Color.accent
      opacity: root.selected ? 1 : 0.52
    }

    Column {
      anchors.left: parent.left
      anchors.leftMargin: 17
      anchors.verticalCenter: parent.verticalCenter
      spacing: 3

      Text {
        text: String(root.scene.eyebrow || "")
        color: root.scene.accent || Color.accent
        font.family: Style.font.family
        font.pixelSize: 10
        font.letterSpacing: 1.2
        font.bold: true
      }

      Text {
        text: String(root.scene.name || "")
        color: "#F3F6FA"
        font.family: Style.font.family
        font.pixelSize: root.compact ? 17 : 20
        font.bold: true
      }

      Text {
        visible: !root.compact
        text: String(root.scene.tagline || "")
        color: "#A9B4C4"
        font.family: Style.font.family
        font.pixelSize: 11
        elide: Text.ElideRight
        width: root.width - 30
      }
    }

    Text {
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.rightMargin: 14
      anchors.topMargin: 13
      text: String(root.scene.shortcut || "")
      color: Qt.rgba(0.82, 0.87, 0.94, 0.42)
      font.family: Style.font.family
      font.pixelSize: 11
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: root.activated()
      onEntered: parent.opacity = 0.9
      onExited: parent.opacity = 1
    }
  }
}
