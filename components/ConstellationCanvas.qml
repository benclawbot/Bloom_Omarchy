import QtQuick
import qs.Commons
import "../models/AgentStore.js" as AgentStore

Item {
  id: root

  property var agents: []
  property color accent: "#9FBCFF"
  property string selectedAgentId: ""
  signal agentActivated(string agentId)

  function nodePoint(index) {
    var count = Math.max(1, root.agents.length)
    var angle = (-Math.PI / 2) + (index / count) * Math.PI * 2
    var radius = Math.min(root.width, root.height) * 0.32
    return Qt.point(root.width / 2 + Math.cos(angle) * radius,
                    root.height / 2 + Math.sin(angle) * radius)
  }

  Canvas {
    id: constellation
    anchors.fill: parent
    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      var center = Qt.point(width / 2, height / 2)
      var count = root.agents.length
      for (var i = 0; i < count; i++) {
        var point = root.nodePoint(i)
        ctx.beginPath()
        ctx.moveTo(center.x, center.y)
        ctx.lineTo(point.x, point.y)
        ctx.strokeStyle = Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.18)
        ctx.lineWidth = 1
        ctx.stroke()
        if (i > 0) {
          var previous = root.nodePoint(i - 1)
          ctx.beginPath()
          ctx.moveTo(previous.x, previous.y)
          ctx.lineTo(point.x, point.y)
          ctx.strokeStyle = Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.08)
          ctx.stroke()
        }
      }
    }

    Connections {
      target: root
      function onAgentsChanged() { constellation.requestPaint() }
      function onAccentChanged() { constellation.requestPaint() }
    }
  }

  Rectangle {
    anchors.centerIn: parent
    width: 82
    height: width
    radius: width / 2
    color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.08)
    border.width: 1
    border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.42)

    Rectangle {
      anchors.centerIn: parent
      width: 22
      height: width
      radius: width / 2
      color: root.accent
      opacity: 0.9
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.bottom
      anchors.topMargin: 11
      text: root.agents.length ? "YOUR WORKSPACE" : "AWAITING SIGNAL"
      color: Qt.rgba(0.84, 0.89, 0.96, 0.57)
      font.family: Style.font.family
      font.pixelSize: 9
      font.letterSpacing: 1.4
    }
  }

  Repeater {
    model: root.agents
    delegate: AgentNode {
      required property var modelData
      required property int index
      agent: modelData
      accent: AgentStore.statusColor(modelData.status, root.accent)
      selected: String(modelData.id) === root.selectedAgentId
      x: root.nodePoint(index).x - width / 2
      y: root.nodePoint(index).y - height / 2
      onActivated: root.agentActivated(String(modelData.id))
    }
  }

  Text {
    anchors.centerIn: parent
    anchors.verticalCenterOffset: 76
    visible: root.agents.length === 0
    text: "Start an agent and Bloom will give it a place in the sky."
    color: "#95A2B5"
    font.family: Style.font.family
    font.pixelSize: 12
  }
}
