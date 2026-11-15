import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    property bool open: false
    readonly property var names: ["Off", "Light", "Steady", "Heavy", "Variable"]

    function run(args) {
        Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/snowctl"].concat(args));
    }

    anchors { top: true; right: true }
    margins { top: 52; right: 8 }
    implicitWidth: 190
    implicitHeight: 300
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "snowfall-menu"
    mask: Region { item: panel }

    Rectangle {
        id: panel
        anchors.top: parent.top
        anchors.right: parent.right
        width: win.open ? 190 : 36
        height: win.open ? 36 + 6 + col.implicitHeight + 8 : 36
        radius: 10
        color: "#1a1b26"
        border.color: "#7aa2f7"
        border.width: 1

        Item {
            id: head
            anchors.top: parent.top
            anchors.right: parent.right
            width: 36
            height: 36
            Text {
                anchors.centerIn: parent
                text: "❄"
                font.pixelSize: 18
                color: SnowConfig.level > 0 ? "#7aa2f7" : "#565f89"
            }
            MouseArea {
                anchors.fill: parent
                onClicked: win.open = !win.open
            }
        }

        Column {
            id: col
            visible: win.open
            x: 6
            y: 42
            width: parent.width - 12
            spacing: 2

            Repeater {
                model: win.names
                Rectangle {
                    required property int index
                    required property string modelData
                    width: col.width
                    height: 28
                    radius: 6
                    color: SnowConfig.level === index ? "#33467c" : "transparent"
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 10
                        text: modelData
                        color: "#c0caf5"
                        font.pixelSize: 13
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: win.run(["level", String(index)])
                    }
                }
            }

            Rectangle { width: col.width; height: 1; color: "#3b4261" }

            Repeater {
                model: [
                    { label: "Накопичення", key: "accumulate", on: SnowConfig.accumulate },
                    { label: "Танення", key: "melt", on: SnowConfig.melt }
                ]
                Rectangle {
                    required property var modelData
                    width: col.width
                    height: 28
                    radius: 6
                    color: "transparent"
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 10
                        text: (modelData.on ? "● " : "○ ") + modelData.label
                        color: modelData.on ? "#9ece6a" : "#a9b1d6"
                        font.pixelSize: 13
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: win.run([modelData.key, "toggle"])
                    }
                }
            }
        }
    }
}
