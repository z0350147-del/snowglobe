// snow_patch21: VehiclePreview.qml
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    anchors {
        left: true
        right: true
        bottom: true
    }
    implicitHeight: 190
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "vehicle-preview"

    property var sources: ["Truck.qml", "Sleigh.qml"]
    property var names: ["Truck", "Sleigh"]
    property int idx: -1
    property bool lite: false

    function next() {
        idx = (idx + 1) % sources.length;
        ld.source = Qt.resolvedUrl(sources[idx]);
    }

    Timer {
        id: gap
        interval: 900
        running: true
        onTriggered: win.next()
    }

    Rectangle {
        id: scene
        anchors.fill: parent
        color: "#0e1424"

        Rectangle {
            x: 0
            y: scene.height - 28
            width: scene.width
            height: 28
            color: "#dfe9f5"
        }

        Loader {
            id: ld
            onLoaded: {
                var it = ld.item;
                it.layerWidth = scene.width > 0 ? scene.width : 1920;
                it.lite = win.lite;
                it.y = scene.height - 28 - it.height;
                it.z = 3;
                it.finished.connect(function () { gap.restart(); });
                it.start(20);
            }
        }

        Text {
            x: 12
            y: 8
            color: "#9fb3c8"
            font.pixelSize: 13
            text: (win.idx >= 0 ? win.names[win.idx] : "...") + (win.lite ? "  [lite]" : "") + "   (клік: lite on/off)"
                + (ld.item ? "   " + Math.round(ld.item.width) + "x" + Math.round(ld.item.height) + "  y=" + Math.round(ld.item.y) : "")
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                win.lite = !win.lite;
                if (ld.item) ld.item.lite = win.lite;
            }
        }
    }
}
