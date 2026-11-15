// snow_patch21: Truck.qml
import QtQuick
import QtQuick.Shapes

Item {
    id: tr

    property real layerWidth: 1920
    property real snowAmount: 20
    property real speed: 130
    property real startX: 0
    property bool lite: false

    readonly property real bladeX: x + 3
    readonly property real load: Math.max(0, Math.min(1, (startX - x) / Math.max(1, layerWidth)))
    readonly property real heapW: 8 + load * (snowAmount * 1.8 + 24)
    readonly property real heapH: Math.min(40, 6 + load * (snowAmount * 0.9 + 10))
    readonly property bool running: visible

    // мерехтіння гірлянди (один спільний Timer) і спільні фази анімацій
    property int phase: 0
    property real fx: 0
    property real sx: 0
    readonly property var palette: ["#ffcf4a", "#ffffff", "#ff4b4b", "#44d36a"]

    // 22 лампочки: верх причепа, задній і передній край причепа, дах кабіни, решітка
    readonly property var bulbPts: {
        var a = [];
        var i;
        for (i = 0; i < 9; i++) a.push({ x: 93 + i * 12, y: 12 });
        for (i = 0; i < 3; i++) a.push({ x: 196, y: 26 + i * 13 });
        for (i = 0; i < 3; i++) a.push({ x: 90, y: 26 + i * 13 });
        for (i = 0; i < 4; i++) a.push({ x: 55 + i * 9, y: 11 });
        for (i = 0; i < 3; i++) a.push({ x: 10, y: 44 + i * 7 });
        return a;
    }

    signal finished()

    width: 200
    height: 76
    visible: false

    function start(amount) {
        if (visible) return;
        snowAmount = amount;
        startX = layerWidth + 30;
        x = startX;
        visible = true;
        drive.from = startX;
        drive.to = -(width + 160);
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

    Timer {
        interval: 320
        repeat: true
        running: tr.visible
        onTriggered: tr.phase = (tr.phase + 1) % 4
    }

    NumberAnimation on fx {
        from: 0
        to: 1
        duration: 1100
        loops: Animation.Infinite
        running: tr.visible
    }

    NumberAnimation on sx {
        from: 0
        to: 1
        duration: 1800
        loops: Animation.Infinite
        running: tr.visible && !tr.lite
    }

    component Wheel: Item {
        property real travel: 0
        width: 22
        height: 22
        rotation: travel / (width / 2) * 57.2958
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "#15171a"
        }
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.56
            height: width
            radius: width / 2
            color: "#f4f6f8"
        }
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.5
            height: 2
            color: "#8a919a"
        }
    }

    // конус світла фар (вліво), вимикається в lite
    Shape {
        visible: !tr.lite
        ShapePath {
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 3
                y1: 0
                x2: -90
                y2: 0
                GradientStop { position: 0.0; color: "#99ffe9a0" }
                GradientStop { position: 1.0; color: "#00ffe9a0" }
            }
            startX: 3
            startY: 46
            PathLine { x: -90; y: 30 }
            PathLine { x: -90; y: 74 }
            PathLine { x: 3; y: 51 }
        }
    }

    // купа снігу перед відвалом
    Rectangle {
        x: 6 - tr.heapW - 2
        y: tr.height - tr.heapH - 1
        width: tr.heapW + 2
        height: tr.heapH + 1
        color: "#d6e3f3"
        topLeftRadius: tr.heapH
        topRightRadius: tr.heapH * 0.45
    }
    Rectangle {
        x: 6 - tr.heapW
        y: tr.height - tr.heapH
        width: tr.heapW
        height: tr.heapH
        color: "#ffffff"
        topLeftRadius: tr.heapH
        topRightRadius: tr.heapH * 0.45
    }

    // сніговий пил: 4 сніжинки підлітають і падають
    Repeater {
        model: 4
        Rectangle {
            required property int index
            readonly property real u: (tr.fx + index * 0.27) % 1
            width: 3
            height: 3
            radius: 1.5
            color: "#ffffff"
            x: 6 - tr.heapW * (0.15 + 0.2 * index) - u * 10
            y: tr.height - tr.heapH - 3 - Math.sin(Math.PI * u) * (9 + (index % 2) * 6)
            opacity: 1 - u * u * 0.9
        }
    }

    // шасі
    Rectangle { x: 8; y: 60; width: 188; height: 6; color: "#2b2f36" }

    // причеп
    Rectangle { x: 88; y: 14; width: 110; height: 46; radius: 3; color: "#d32f2f" }
    Rectangle { x: 88; y: 14; width: 110; height: 3; radius: 1; color: "#ef5350" }
    Rectangle { x: 88; y: 56; width: 110; height: 4; color: "#8e1b1b" }
    Rectangle { x: 84; y: 52; width: 6; height: 8; color: "#222222" }

    // біла хвиляста смуга
    Repeater {
        model: 16
        Rectangle {
            required property int index
            x: 89 + index * 6.6
            y: 46 + Math.round(Math.sin(index * 0.9) * 3)
            width: 7
            height: 4
            color: "#ffffff"
        }
    }

    // Санта на боці причепа
    Rectangle { x: 107; y: 18; width: 12; height: 8; radius: 4; color: "#7f1313" }
    Rectangle { x: 106; y: 25; width: 14; height: 3; radius: 1; color: "#ffffff" }
    Rectangle { x: 108; y: 27; width: 10; height: 9; radius: 4; color: "#f4c9a0" }
    Rectangle { x: 108; y: 31; width: 10; height: 8; radius: 4; color: "#ffffff" }
    Rectangle { x: 117; y: 15; width: 4; height: 4; radius: 2; color: "#ffffff" }
    Text {
        x: 134
        y: 20
        text: "2027"
        color: "#ffffff"
        font.bold: true
        font.pixelSize: 14
    }

    // капот
    Rectangle { x: 8; y: 40; width: 44; height: 20; radius: 3; color: "#d32f2f" }
    Rectangle { x: 10; y: 42; width: 40; height: 2; color: "#ef5350" }
    Rectangle { x: 6; y: 42; width: 5; height: 18; radius: 1; color: "#b8c2c9" }

    // вихлопна труба
    Rectangle { x: 49; y: 12; width: 4; height: 30; color: "#cfd8dc" }
    Rectangle { x: 48; y: 9; width: 6; height: 3; color: "#9fb0b8" }

    // кабіна
    Rectangle { x: 52; y: 17; width: 32; height: 43; radius: 3; color: "#d32f2f" }
    Rectangle { x: 51; y: 14; width: 34; height: 4; radius: 2; color: "#a31d1d" }
    Rectangle {
        x: 57
        y: 21
        width: 20
        height: 17
        radius: 2
        color: "#bfe6f7"
        border.width: 1
        border.color: "#7aa9bd"
    }
    Rectangle { x: 80; y: 20; width: 1; height: 38; color: "#a31d1d" }
    Rectangle { x: 74; y: 44; width: 4; height: 2; color: "#e0e0e0" }

    // легкий дим з труби (вимикається в lite)
    Repeater {
        model: 3
        Rectangle {
            required property int index
            visible: !tr.lite
            readonly property real u: (tr.sx + index / 3) % 1
            width: 4 + u * 7
            height: width
            radius: width / 2
            x: 51 - width / 2 + u * 22
            y: 6 - u * 16 - height / 2
            color: "#cfd8dc"
            opacity: 0.5 * (1 - u)
        }
    }

    // відвал-бампер, червоно-білий
    Repeater {
        model: 4
        Rectangle {
            required property int index
            x: 0
            y: 50 + index * 6
            width: 9
            height: 6
            color: index % 2 === 0 ? "#d32f2f" : "#ffffff"
        }
    }
    Rectangle { x: -1; y: 50; width: 2; height: 24; radius: 1; color: "#8e1b1b" }

    // колеса
    Wheel { x: 17; y: 54; travel: tr.x }
    Wheel { x: 53; y: 54; travel: tr.x }
    Wheel { x: 71; y: 54; travel: tr.x }
    Wheel { x: 145; y: 54; travel: tr.x }
    Wheel { x: 167; y: 54; travel: tr.x }

    // фара
    Rectangle {
        visible: !tr.lite
        x: -3
        y: 41
        width: 12
        height: 12
        radius: 6
        color: "#ffe27a"
        opacity: 0.35
    }
    Rectangle { x: 1; y: 44; width: 5; height: 6; radius: 2; color: "#fff6c0" }

    // гірлянда
    Repeater {
        model: tr.bulbPts
        Rectangle {
            required property int index
            required property var modelData
            x: modelData.x - 2
            y: modelData.y - 2
            width: 4
            height: 4
            radius: 2
            color: tr.palette[(index + tr.phase) % 4]
            Rectangle {
                visible: !tr.lite
                z: -1
                x: -3
                y: -3
                width: 10
                height: 10
                radius: 5
                color: parent.color
                opacity: 0.28
            }
        }
    }
}
