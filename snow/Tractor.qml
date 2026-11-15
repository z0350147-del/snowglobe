import QtQuick

Item {
    id: tr

    property real layerWidth: 1920
    property real snowAmount: 20
    property real speed: 140
    property real startX: 0

    readonly property real sc: 0.42
    readonly property real bladeX: x + 8 * sc
    readonly property real load: Math.max(0, Math.min(1, (startX - x) / Math.max(1, layerWidth)))
    readonly property real heapW: 8 + load * (snowAmount * 1.8 + 24)
    readonly property real heapH: Math.min(40, 6 + load * (snowAmount * 0.9 + 10))
    readonly property bool running: visible

    signal finished()

    width: 240 * sc
    height: 148 * sc
    visible: false

    function start(amount) {
        snowAmount = amount;
        startX = layerWidth + 30;
        x = startX;
        visible = true;
        drive.from = startX;
        drive.to = -(width + 120);
        drive.duration = Math.round((drive.from - drive.to) / speed * 1000);
        drive.restart();
    }

    function abort() {
        drive.stop();
        visible = false;
    }

    NumberAnimation {
        id: drive
        target: tr
        property: "x"
        easing.type: Easing.Linear
        onFinished: {
            tr.visible = false;
            tr.finished();
        }
    }

    component Wheel: Image {
        property real travel: 0
        source: Qt.resolvedUrl("tractor_wheel.svg")
        sourceSize.width: width
        sourceSize.height: height
        rotation: travel / (width / 2) * 57.2958
    }

    Rectangle {
        x: 6 * tr.sc - tr.heapW - 2
        y: tr.height - tr.heapH - 1
        width: tr.heapW + 2
        height: tr.heapH + 1
        color: "#d6e3f3"
        topLeftRadius: tr.heapH
        topRightRadius: tr.heapH * 0.45
    }
    Rectangle {
        x: 6 * tr.sc - tr.heapW
        y: tr.height - tr.heapH
        width: tr.heapW
        height: tr.heapH
        color: "#ffffff"
        topLeftRadius: tr.heapH
        topRightRadius: tr.heapH * 0.45
    }

    Image {
        source: Qt.resolvedUrl("tractor_back.svg")
        width: 240 * tr.sc
        height: 150 * tr.sc
        sourceSize.width: width
        sourceSize.height: height
    }

    Rectangle {
        width: 30 * tr.sc
        height: width
        radius: width / 2
        x: 166 * tr.sc - width / 2
        y: 2 * tr.sc - height / 2
        color: "#ffb300"
        opacity: 0
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: tr.visible
            NumberAnimation { to: 0.5; duration: 450 }
            NumberAnimation { to: 0.0; duration: 450 }
        }
    }

    Wheel { x: 132 * tr.sc; y: 68 * tr.sc; width: 80 * tr.sc; height: 80 * tr.sc; travel: tr.x }
    Wheel { x: 34 * tr.sc; y: 96 * tr.sc; width: 52 * tr.sc; height: 52 * tr.sc; travel: tr.x }

    Image {
        source: Qt.resolvedUrl("tractor_front.svg")
        width: 240 * tr.sc
        height: 150 * tr.sc
        sourceSize.width: width
        sourceSize.height: height
    }
}
