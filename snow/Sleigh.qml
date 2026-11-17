// snow_patch30: Sleigh.qml — Санта 2.0: олені, сани й Санта з анімаціями
import QtQuick
import QtQuick.Shapes

Item {
    id: tr

    property real layerWidth: 1920
    property real snowAmount: 20
    property real speed: 170
    property real startX: 0
    property bool lite: false

    readonly property real sledX: 192
    readonly property real sledY: 88
    // локальний x переднього кінця полозів (передній кінець саней, не оленів)
    readonly property real bladeOffset: sledX - 4
    readonly property real bladeX: x + bladeOffset
    readonly property real load: Math.max(0, Math.min(1, (startX - x) / Math.max(1, layerWidth)))
    property real heapFill: 0
    readonly property real heapW: 10 + heapFill * 34
    readonly property real heapH: 6 + heapFill * 14
    readonly property bool running: visible

    // хвиля руху: зміщення завжди ВГОРУ від землі
    readonly property real wavelen: 220
    readonly property real amp: 8
    readonly property real basePhase: (startX - x) / wavelen * 6.28318
    // фаза галопу прив'язана до пройденого шляху: копита не ковзають по землі
    readonly property real gait: (startX - x) / 70 * 6.28318
    // секунди для дрібних рухів (хвіст, вуха, дзвіночки, борода)
    property real tm: 0

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
        dropWX = x + sledX + 88;
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
        s.wx = x + sledX + 104 + Math.random() * 10;
        s.wy = height - 6 - Math.random() * 12;
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

    FrameAnimation {
        running: tr.visible
        onTriggered: tr.tm += frameTime
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

    // ---------- допоміжні елементи ----------
    // Shape із зсувом +70: шляхи з від'ємними координатами малюються надійно
    component Flat: Item {
        id: fl
        property string d: ""
        property color fill: "#ffffff"
        property color edge: "transparent"
        property real edgeW: 0
        function shifted(s) {
            return s.replace(/(-?[0-9.]+),(-?[0-9.]+)/g, function (m, a, b) {
                return (parseFloat(a) + 70) + "," + (parseFloat(b) + 70);
            });
        }
        Shape {
            x: -70
            y: -70
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: fl.fill
                strokeColor: fl.edge
                strokeWidth: fl.edgeW > 0 ? fl.edgeW : -1
                PathSvg { path: fl.shifted(fl.d) }
            }
        }
    }

    component Stroke: Item {
        id: st
        property string d: ""
        property color col: "#f2b632"
        property real w: 2
        function shifted(s) {
            return s.replace(/(-?[0-9.]+),(-?[0-9.]+)/g, function (m, a, b) {
                return (parseFloat(a) + 70) + "," + (parseFloat(b) + 70);
            });
        }
        Shape {
            x: -70
            y: -70
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: st.col
                strokeWidth: st.w
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                PathSvg { path: st.shifted(st.d) }
            }
        }
    }

    // нога з двох суглобів: стегно й гомілка
    component Leg: Item {
        id: lg
        property real ph: 0
        property color tone: "#4a2f17"
        Rectangle {
            x: -1.3
            y: 0
            width: 2.6
            height: 8
            radius: 1.3
            color: lg.tone
            transformOrigin: Item.Top
            rotation: -0.7 * Math.sin(lg.ph) * 57.2958
            Rectangle {
                x: 0
                y: 7
                width: 2.6
                height: 8.6
                radius: 1.3
                color: lg.tone
                transformOrigin: Item.Top
                rotation: -1.15 * Math.max(0, -Math.cos(lg.ph)) * 57.2958
            }
        }
    }

    component Gift: Item {
        id: gf
        property real bw: 10
        property real bh: 9
        property real baseY: 0
        property real seed: 0
        property real tm: 0
        property color boxCol: "#2e9e4f"
        property color ribCol: "#ffd54a"
        readonly property real k: Math.sin(tm * 5.5 + seed * 1.7)
        y: baseY - Math.abs(k) * 2.4
        rotation: 4 * k
        Rectangle { x: -gf.bw / 2; y: -gf.bh / 2; width: gf.bw; height: gf.bh; color: gf.boxCol }
        Rectangle { x: -0.9; y: -gf.bh / 2; width: 1.8; height: gf.bh; color: gf.ribCol }
        Rectangle { x: -gf.bw / 2; y: -0.9; width: gf.bw; height: 1.8; color: gf.ribCol }
    }

    component Deer: Item {
        id: dr
        property bool lead: false
        property bool lite: false
        property real ph: 0
        property real seed: 0
        property real tm: 0
        readonly property real cyc: (tm * 0.37 + seed * 0.31) % 1
        readonly property real eyeH: (cyc > 0.93 && cyc < 0.97) ? 0.2 : 2
        width: 0
        height: 0

        Leg { x: 11; y: 4; ph: dr.ph + 3.4558; tone: "#5a3a1e" }
        Leg { x: -8; y: 4; ph: dr.ph + 0.754; tone: "#5a3a1e" }

        Rectangle {
            x: 13.4
            y: -6.4
            width: 5.2
            height: 6.8
            radius: 2.6
            color: "#ffffff"
            transform: Rotation {
                origin.x: 0.6
                origin.y: 4.4
                angle: 14 * Math.sin(dr.tm * 7 + dr.seed)
            }
        }

        Rectangle { x: -15; y: -7; width: 30; height: 14; radius: 7; color: "#8d5a2b" }
        Rectangle { x: -11; y: 0.5; width: 22; height: 6.2; radius: 3.1; color: "#c9a06a" }

        Leg { x: 14; y: 4; ph: dr.ph + 3.1416; tone: "#4a2f17" }
        Leg { x: -5; y: 4; ph: dr.ph; tone: "#4a2f17" }

        Stroke { d: "M-9.5,-5.5 L-6.5,6.5 M-2,-6.8 L-1,7"; col: "#c62828"; w: 1.7 }
        Flat { d: "M-8,-5 L-13.5,-2 L-22,-14.5 L-16.5,-18 Z"; fill: "#8d5a2b" }

        // дзвіночки на збруї
        Repeater {
            model: [[-8.5, -1.5], [-4.1, 0.5], [-1.4, 3.5]]
            Rectangle {
                required property var modelData
                required property int index
                readonly property real sw: dr.lite ? 0 : 1.4 * Math.sin(dr.tm * 11 + index + dr.seed)
                x: modelData[0] - 1.7 + sw
                y: modelData[1] - 1.7 + Math.abs(sw) * 0.4
                width: 3.4
                height: 3.4
                radius: 1.7
                color: "#f2c744"
                border.width: 0.4
                border.color: "#b8860b"
            }
        }
        Rectangle {
            x: -15.9 + (dr.lite ? 0 : 1.2 * Math.sin(dr.tm * 10 + dr.seed))
            y: -9.1
            width: 3.8
            height: 3.8
            radius: 1.9
            color: "#f2c744"
            border.width: 0.4
            border.color: "#b8860b"
        }

        // пара з ніздрів
        Repeater {
            model: dr.lite ? 0 : 4
            Rectangle {
                required property int index
                readonly property real age: ((dr.tm + index * 0.225 + dr.seed * 0.13) % 0.9) / 0.9
                readonly property real r: 1 + age * 2.6
                x: -32 + age * 34 - r
                y: -15 - age * 8 - r
                width: 2 * r
                height: 2 * r
                radius: r
                color: "#ffffff"
                opacity: 0.7 * (1 - age)
            }
        }

        // голова
        Item {
            width: 0
            height: 0
            transform: Rotation {
                origin.x: -12
                origin.y: -10
                angle: 4 * Math.sin(dr.ph - 0.8)
            }
            Stroke { d: "M-21,-21 L-19,-31 M-19.4,-27 L-24,-30.5 M-19,-31 L-15,-35.5 M-20,-24.5 L-15.5,-27.5"; col: "#e2c78d"; w: 1.7 }
            Item {
                width: 0
                height: 0
                transform: Rotation {
                    origin.x: -19.5
                    origin.y: -19
                    angle: 11 * Math.sin(dr.tm * 5.5 + dr.seed * 2)
                }
                Rectangle { x: -21.3; y: -25.1; width: 3.6; height: 7.2; radius: 1.8; color: "#6e431d"; rotation: -20 }
            }
            Rectangle { x: -30.5; y: -21; width: 13; height: 8; radius: 4; color: "#8d5a2b"; rotation: -22 }
            Rectangle { x: -33.1; y: -17.9; width: 7.2; height: 5.4; radius: 2.7; color: "#a8723a" }
            Rectangle {
                visible: dr.lead && !dr.lite
                readonly property real hr: 4.8 + 0.9 * Math.sin(dr.tm * 6)
                x: -32.2 - hr
                y: -15.2 - hr
                width: 2 * hr
                height: 2 * hr
                radius: hr
                color: "#ff2a2a"
                opacity: 0.3 + 0.2 * Math.sin(dr.tm * 6)
            }
            Rectangle { x: -34.1; y: -17.1; width: 3.8; height: 3.8; radius: 1.9; color: dr.lead ? "#ff2a2a" : "#3b2314" }
            Rectangle { x: -24; y: -18.4 - dr.eyeH / 2; width: 2; height: dr.eyeH; radius: Math.min(1, dr.eyeH / 2); color: "#1b1209" }
        }
    }

    // віжки: провисають і погойдуються
    component ReinCurve: Shape {
        id: rc
        property real x1: 0
        property real y1: 0
        property real x2: 0
        property real y2: 0
        property real sway: 0
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: "#6b4423"
            strokeWidth: 1.1
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg {
                path: "M" + rc.x1 + "," + rc.y1 + " Q" + (rc.x1 + rc.x2) / 2 + ","
                      + (Math.max(rc.y1, rc.y2) + 2.5 + rc.sway) + " " + rc.x2 + "," + rc.y2
            }
        }
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

    // сани з Сантою
    Item {
        id: sled
        x: tr.sledX
        y: tr.sledY - tr.liftOf(0, 60)
        width: 110
        height: 1
        transformOrigin: Item.Top
        rotation: tr.tiltOf(0)

        // мішок і подарунки
        Flat { d: "M80,-8 C76,-22 80,-32 88,-32 C96,-32 100,-22 98,-8 Z"; fill: "#a0703b" }
        Rectangle { x: 83; y: -33; width: 10; height: 3.5; radius: 1.5; color: "#e0b04a" }
        Gift { x: 85; baseY: -37.5; bw: 10; bh: 9; seed: 0; tm: tr.tm; boxCol: "#2e9e4f"; ribCol: "#ffd54a" }
        Gift { x: 94.5; baseY: -36; bw: 9; bh: 8; seed: 1; tm: tr.tm; boxCol: "#ffffff"; ribCol: "#d32f2f" }
        Gift { x: 89; baseY: -44.5; bw: 8; bh: 7; seed: 2; tm: tr.tm; boxCol: "#2d7fd3"; ribCol: "#ffd54a" }

        // далека рука махає
        Item {
            x: 64
            y: -27
            width: 0
            height: 0
            rotation: (-1.0 + 0.15 * Math.sin(tr.tm * 6)) * 57.2958
            Rectangle { x: -2; y: -2; width: 12; height: 4; radius: 2; color: "#c62828" }
            Item {
                x: 8
                y: 0
                width: 0
                height: 0
                rotation: (-0.5 + 0.75 * Math.sin(tr.tm * 6 + 0.8)) * 57.2958
                Rectangle { x: -2; y: -2; width: 11; height: 4; radius: 2; color: "#c62828" }
                Rectangle { x: 4.6; y: -2.4; width: 4.8; height: 4.8; radius: 2.4; color: "#ffffff" }
            }
        }

        // тулуб
        Flat { d: "M44,-8 C44,-24 50,-32 58,-32 C66,-32 72,-24 72,-8 Z"; fill: "#e53935" }
        Rectangle { x: 44; y: -17; width: 28; height: 3; color: "#2b2b2b" }
        Rectangle { x: 56; y: -17.6; width: 4; height: 4.2; radius: 0.8; color: "#f2c744" }
        Rectangle { x: 44; y: -10; width: 28; height: 3; color: "#ffffff" }

        // голова: киває, борода гойдається, очі моргають
        Item {
            id: santaHead
            readonly property real bs: 1.6 * Math.sin(tr.tm * 4.2)
            readonly property real c2: (tr.tm * 0.29) % 1
            readonly property real bl: (c2 > 0.94 && c2 < 0.985) ? 0.12 : 1
            readonly property real pa: 0.55 * Math.sin(tr.tm * 4.2 - 0.9)
            y: 0.7 * Math.sin(tr.tm * 6.8)
            width: 0
            height: 0

            Rectangle { x: 51.8; y: -46.2; width: 12.4; height: 12.4; radius: 6.2; color: "#f4c9a0" }
            Rectangle { x: 53; y: -39.4; width: 2.4; height: 2.4; radius: 1.2; color: "#f19a98"; opacity: 0.8 }
            Rectangle { x: 60.6; y: -39.4; width: 2.4; height: 2.4; radius: 1.2; color: "#f19a98"; opacity: 0.8 }
            Flat {
                x: santaHead.bs * 0.5
                d: "M52.2,-40 C51,-34 54,-28 58," + (-26 + 0.4 * santaHead.bs) + " C62,-28 65,-34 63.8,-40 C62,-36 54,-36 52.2,-40 Z"
                fill: "#ffffff"
                edge: "#e2e8f0"
                edgeW: 0.3
            }
            Rectangle { x: 53.2; y: -38.7; width: 4.8; height: 2.2; radius: 1.1; color: "#ffffff"; rotation: 12 }
            Rectangle { x: 58; y: -38.7; width: 4.8; height: 2.2; radius: 1.1; color: "#ffffff"; rotation: -12 }
            Rectangle { x: 56.8; y: -40.8; width: 2.4; height: 2.4; radius: 1.2; color: "#f19a98" }
            Rectangle { x: 54.5; y: -41.8 - 0.9 * santaHead.bl; width: 1.8; height: 1.8 * santaHead.bl; radius: 0.9 * santaHead.bl; color: "#1b1209" }
            Rectangle { x: 59.7; y: -41.8 - 0.9 * santaHead.bl; width: 1.8; height: 1.8 * santaHead.bl; radius: 0.9 * santaHead.bl; color: "#1b1209" }

            Flat { d: "M51.5,-44.5 C52,-53 59,-57 67,-52 C63,-52 61,-48 64.5,-44.5 Z"; fill: "#e53935" }
            Rectangle { x: 50; y: -46.2; width: 16.5; height: 3.8; radius: 1.9; color: "#ffffff" }
            Rectangle {
                x: 67 + 6 * Math.sin(santaHead.pa) - 2.6
                y: -53 + 5 * Math.cos(santaHead.pa) - 2.6
                width: 5.2
                height: 5.2
                radius: 2.6
                color: "#ffffff"
            }
        }

        // ближня рука тримає віжки
        Stroke { d: "M52,-26 L46,-20 L37,-17"; col: "#c62828"; w: 4.2 }
        Rectangle { x: 34.1; y: -19.4; width: 4.8; height: 4.8; radius: 2.4; color: "#ffffff" }

        // корпус саней
        Flat { d: "M6,-16 C6,-6 10,0 20,2 L90,2 C100,2 106,-6 108,-22 L103,-24 C101,-12 97,-8 90,-8 L24,-8 C17,-8 13,-11 11,-18 Z"; fill: "#b71c1c" }
        Stroke { d: "M11,-18 C13,-11 17,-8 24,-8 L90,-8 C97,-8 101,-12 103,-24"; col: "#f2c744"; w: 1.6 }
        Stroke { d: "M14,-1 L98,-1"; col: "#f2c744"; w: 1.2 }

        // золоті полози із загнутими кінцями
        Stroke { d: "M2,12 C-4,12 -6,4 -1,1 M2,12 L104,12 C110,12 112,6 108,3"; col: "#e6b422"; w: 3 }
        Stroke { d: "M30,2 L30,12 M84,2 L84,12"; col: "#e6b422"; w: 2.4 }
    }

    // олені
    Deer { id: d1; lead: true; seed: 0; tm: tr.tm; lite: tr.lite; ph: tr.gait; x: 32; y: 80 - tr.liftOf(3, 25); rotation: tr.tiltOf(3) }
    Deer { id: d2; seed: 1; tm: tr.tm; lite: tr.lite; ph: tr.gait + 0.9; x: 88; y: 80 - tr.liftOf(2, 25); rotation: tr.tiltOf(2) }
    Deer { id: d3; seed: 2; tm: tr.tm; lite: tr.lite; ph: tr.gait + 1.8; x: 144; y: 80 - tr.liftOf(1, 25); rotation: tr.tiltOf(1) }

    // віжки
    ReinCurve { x1: d1.x + 15; y1: d1.y - 2; x2: d2.x - 9; y2: d2.y - 4; sway: 1.2 * Math.sin(tr.tm * 6) }
    ReinCurve { x1: d2.x + 15; y1: d2.y - 2; x2: d3.x - 9; y2: d3.y - 4; sway: 1.2 * Math.sin(tr.tm * 6 + 1) }
    ReinCurve { x1: d3.x + 15; y1: d3.y - 2; x2: sled.x + 36.5; y2: sled.y - 17; sway: 1.2 * Math.sin(tr.tm * 6 + 2) }

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
