// snow_patch21: Sleigh.qml
import QtQuick

Item {
    id: tr

    property real layerWidth: 1920
    property real snowAmount: 20
    property real speed: 170
    property real startX: 0
    property bool lite: false

    // локальний x переднього кінця полозів (передній кінець саней, не оленів)
    readonly property real bladeOffset: sled.x + 1
    readonly property real bladeX: x + bladeOffset
    readonly property real load: Math.max(0, Math.min(1, (startX - x) / Math.max(1, layerWidth)))
    readonly property real heapW: 10 + load * 20
    readonly property real heapH: 6 + load * 6
    readonly property bool running: visible

    // хвиля руху: зміщення завжди ВГОРУ від землі
    readonly property real wavelen: 220
    readonly property real amp: 8
    readonly property real basePhase: (startX - x) / wavelen * 6.28318

    property int frame: 0
    property real now: 0
    property int tick: 0
    property int sparkCursor: 0
    property int flights: 0
    property bool boxArmed: false
    property real dropWX: 0
    readonly property var sparkColors: ["#ffd54a", "#fff176", "#ffffff"]

    signal finished()

    width: 300
    height: 100
    visible: false

    function phaseOf(k) { return basePhase + k * 0.55; }
    function tiltOf(k) { return -4 * Math.cos(phaseOf(k)); }
    // halfW компенсує нахил, щоб кут частини ніколи не опускався нижче землі
    function liftOf(k, halfW) {
        return amp * (1 + Math.sin(phaseOf(k))) / 2
            + halfW * Math.abs(Math.sin(tiltOf(k) * Math.PI / 180));
    }

    function start(amount) {
        if (visible) return;
        flights++;
        boxArmed = (flights % 3 === 0);
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
        boxAnim.stop();
        box.visible = false;
        visible = false;
    }

    function dropBox() {
        dropWX = x + 262;
        box.fall = 0;
        box.opacity = 1;
        box.visible = true;
        boxAnim.restart();
    }

    function emitSpark() {
        if (sparks.count === 0) return;
        var s = sparks.itemAt(sparkCursor % sparks.count);
        sparkCursor++;
        if (!s) return;
        s.wx = x + bladeOffset - 4 + Math.random() * 56;
        s.wy = height - 10 - Math.random() * 14;
        s.life = 1000 + Math.random() * 500;
        s.tint = sparkColors[Math.floor(Math.random() * 3)];
        s.born = now;
    }

    onXChanged: {
        if (boxArmed && visible && x < layerWidth * 0.55) {
            boxArmed = false;
            dropBox();
        }
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

    // кадри ніг оленів
    Timer {
        interval: 150
        repeat: true
        running: tr.visible
        onTriggered: tr.frame = 1 - tr.frame
    }

    // шлейф іскор: пул фіксованого розміру, один Timer
    Timer {
        interval: 50
        repeat: true
        running: tr.visible
        onTriggered: {
            tr.now += 50;
            tr.tick++;
            if (!tr.lite || tr.tick % 2 === 0) tr.emitSpark();
        }
    }

    component Deer: Item {
        property int frame: 0
        property bool lead: false
        property bool lite: false
        width: 50
        height: 100

        // хвіст
        Rectangle { x: 39; y: 72; width: 4; height: 4; radius: 2; color: "#ffffff" }
        // задні ноги
        Rectangle { x: 37; y: 83; width: 3; height: 15; color: "#4a2f17"; transformOrigin: Item.Top; rotation: frame === 0 ? -34 : 16 }
        Rectangle { x: 32; y: 83; width: 3; height: 15; color: "#4a2f17"; transformOrigin: Item.Top; rotation: frame === 0 ? -24 : 26 }
        // передні ноги
        Rectangle { x: 19; y: 83; width: 3; height: 15; color: "#4a2f17"; transformOrigin: Item.Top; rotation: frame === 0 ? 34 : -16 }
        Rectangle { x: 14; y: 83; width: 3; height: 15; color: "#4a2f17"; transformOrigin: Item.Top; rotation: frame === 0 ? 24 : -26 }
        // тулуб, шия, голова
        Rectangle { x: 12; y: 72; width: 28; height: 12; radius: 6; color: "#8d5a2b" }
        Rectangle { x: 9; y: 62; width: 7; height: 15; radius: 3; color: "#8d5a2b"; rotation: -22 }
        Rectangle { x: 2; y: 58; width: 12; height: 8; radius: 4; color: "#8d5a2b" }
        Rectangle { x: 9; y: 55; width: 3; height: 5; radius: 1; color: "#6e431d"; rotation: 20 }
        // ріжки
        Rectangle { x: 7; y: 48; width: 2; height: 10; color: "#d8b574"; rotation: -15 }
        Rectangle { x: 12; y: 47; width: 2; height: 11; color: "#d8b574"; rotation: 15 }
        Rectangle { x: 4; y: 51; width: 2; height: 4; color: "#d8b574"; rotation: -50 }
        // ніс (у першого червоний із ореолом)
        Rectangle {
            visible: lead && !lite
            x: -5
            y: 56
            width: 13
            height: 13
            radius: 6.5
            color: "#ff2a2a"
            opacity: 0.35
        }
        Rectangle {
            x: -1
            y: 60
            width: 5
            height: 5
            radius: 2.5
            color: lead ? "#ff2a2a" : "#3b2314"
        }
    }

    component Rein: Rectangle {
        property real x1: 0
        property real y1: 0
        property real x2: 0
        property real y2: 0
        x: x1
        y: y1 - height / 2
        width: Math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
        height: 1.5
        color: "#6b4423"
        transformOrigin: Item.Left
        rotation: Math.atan2(y2 - y1, x2 - x1) * 57.2958
    }

    // іскри (ззаду по порядку малювання)
    Repeater {
        id: sparks
        model: tr.lite ? 12 : 24
        Rectangle {
            required property int index
            property real wx: 0
            property real wy: 0
            property real born: -100000
            property real life: 1200
            property color tint: "#ffd54a"
            readonly property real age: (tr.now - born) / life
            visible: age >= 0 && age < 1
            width: 3
            height: 3
            rotation: 45
            x: wx - tr.x
            y: wy - age * 8
            color: tint
            opacity: 1 - age
        }
    }

    // віжки
    Rein { x1: d1.x + 46; y1: d1.y + 76; x2: d2.x + 10; y2: d2.y + 76 }
    Rein { x1: d2.x + 46; y1: d2.y + 76; x2: d3.x + 10; y2: d3.y + 76 }
    Rein { x1: d3.x + 46; y1: d3.y + 76; x2: sled.x + 26; y2: sled.y + 63 }

    // олені
    Deer { id: d1; lead: true; lite: tr.lite; x: 4; y: -tr.liftOf(3, 25); rotation: tr.tiltOf(3); frame: tr.frame }
    Deer { id: d2; lite: tr.lite; x: 58; y: -tr.liftOf(2, 25); rotation: tr.tiltOf(2); frame: 1 - tr.frame }
    Deer { id: d3; lite: tr.lite; x: 112; y: -tr.liftOf(1, 25); rotation: tr.tiltOf(1); frame: tr.frame }

    // сани
    Item {
        id: sled
        x: 176
        width: 120
        height: 100
        y: -tr.liftOf(0, 60)
        rotation: tr.tiltOf(0)

        // мішок і подарунки
        Rectangle { x: 76; y: 46; width: 22; height: 30; radius: 10; color: "#a0703b" }
        Rectangle { x: 83; y: 44; width: 9; height: 4; radius: 2; color: "#e0b04a" }
        Rectangle { x: 80; y: 34; width: 12; height: 10; color: "#2e9e4f" }
        Rectangle { x: 85; y: 34; width: 2; height: 10; color: "#ffd54a" }
        Rectangle { x: 92; y: 40; width: 11; height: 11; color: "#ffffff" }
        Rectangle { x: 96; y: 40; width: 2; height: 11; color: "#d32f2f" }

        // Санта
        Rectangle { x: 40; y: 56; width: 22; height: 18; radius: 7; color: "#e53935" }
        Rectangle { x: 40; y: 66; width: 22; height: 3; color: "#2b2b2b" }
        Rectangle { x: 28; y: 62; width: 18; height: 4; radius: 2; color: "#e53935" }
        Rectangle { x: 26; y: 62; width: 4; height: 4; radius: 2; color: "#ffffff" }
        Rectangle { x: 45; y: 44; width: 12; height: 12; radius: 6; color: "#f4c9a0" }
        Rectangle { x: 45; y: 50; width: 12; height: 8; radius: 4; color: "#ffffff" }
        Rectangle { x: 44; y: 37; width: 14; height: 9; radius: 4; color: "#e53935" }
        Rectangle { x: 43; y: 44; width: 16; height: 3; radius: 1; color: "#ffffff" }
        Rectangle { x: 54; y: 36; width: 7; height: 4; radius: 2; color: "#e53935" }
        Rectangle { x: 59; y: 34; width: 5; height: 5; radius: 2.5; color: "#ffffff" }

        // корпус саней
        Rectangle { x: 6; y: 70; width: 102; height: 16; radius: 7; color: "#b71c1c" }
        Rectangle { x: 4; y: 62; width: 12; height: 24; radius: 6; color: "#b71c1c" }
        Rectangle { x: 94; y: 60; width: 14; height: 26; radius: 6; color: "#b71c1c" }
        Rectangle { x: 8; y: 82; width: 98; height: 2; color: "#f2c744" }

        // золоті полози із загнутими кінцями
        Rectangle { x: 28; y: 84; width: 3; height: 12; color: "#e6b422" }
        Rectangle { x: 86; y: 84; width: 3; height: 12; color: "#e6b422" }
        Rectangle { x: 4; y: 96; width: 106; height: 4; radius: 2; color: "#e6b422" }
        Rectangle { x: 1; y: 84; width: 4; height: 16; radius: 2; color: "#e6b422" }
        Rectangle { x: 112; y: 84; width: 4; height: 16; radius: 2; color: "#e6b422" }
        Rectangle {
            x: -1
            y: 79
            width: 7
            height: 7
            radius: 3.5
            color: "transparent"
            border.width: 2
            border.color: "#f2c744"
        }
        Rectangle {
            x: 111
            y: 79
            width: 7
            height: 7
            radius: 3.5
            color: "transparent"
            border.width: 2
            border.color: "#f2c744"
        }
    }

    // пасхалка: коробка з бантиком (раз на три проліти)
    Item {
        id: box
        property real fall: 0
        visible: false
        width: 12
        height: 11
        z: 5
        x: tr.dropWX - tr.x - 6
        y: 60 + fall * (tr.height - 60 - 11)
        Rectangle { width: 12; height: 11; color: "#2d7fd3" }
        Rectangle { x: 5; width: 2; height: 11; color: "#ffd54a" }
        Rectangle { y: 4; width: 12; height: 2; color: "#ffd54a" }
        Rectangle { x: 3; y: -3; width: 6; height: 4; radius: 2; color: "#ffd54a" }
    }

    SequentialAnimation {
        id: boxAnim
        NumberAnimation { target: box; property: "fall"; from: 0; to: 1; duration: 600; easing.type: Easing.InQuad }
        PauseAnimation { duration: 1000 }
        NumberAnimation { target: box; property: "opacity"; to: 0; duration: 400 }
        ScriptAction { script: box.visible = false }
    }
}
