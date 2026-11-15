// sp_20261115_1500_truck2: Truck.qml v2 - різдвяна фура 1:1 з референсу (вектор, без бренду)
import QtQuick
import QtQuick.Shapes

Item {
    id: tr

    property real layerWidth: 1920
    property real snowAmount: 20
    property real speed: 130
    property real startX: 0
    property bool lite: false

    // масштаб усієї фури (збільшуй, якщо хочеш ще більшу)
    property real sc: 0.8
    readonly property real dw: 668
    readonly property real dh: 248

    readonly property real bladeX: x + 4 * sc
    readonly property real load: Math.max(0, Math.min(1, (startX - x) / Math.max(1, layerWidth)))
    readonly property real heapW: 8 + load * (snowAmount * 1.8 + 24)
    readonly property real heapH: Math.min(40, 6 + load * (snowAmount * 0.9 + 10))
    readonly property bool running: visible

    // спільні фази анімацій
    property int tick: 0
    property real fx: 0
    property real eb: 0
    property real wv: 0
    property real bx: 0
    property real sw: 0
    readonly property bool winkOn: lite ? (tick % 9 === 0) : (tick % 31 < 3)
    readonly property bool blinkOn: lite ? (tick % 7 === 0) : (tick % 17 < 2)
    readonly property real glowK: 0.75 + 0.25 * Math.sin(tick * 0.3)
    readonly property real wheelTravel: x / sc
    // підстрибування: тягач і причеп трохи не в фазі
    readonly property real bumpA: (Math.sin(x * 0.05) * 0.9 + Math.sin(x * 0.13 + 1.3) * 0.45 + (lite ? 0 : Math.sin(eb * 6.2832) * 0.3)) * 1.2
    readonly property real bumpB: (Math.sin((x + 70) * 0.05) * 0.9 + Math.sin((x + 70) * 0.13 + 1.3) * 0.45) * 1.2

    readonly property var bulbs: buildBulbs()
    readonly property var cabBulbs: bulbs.filter(function (b) { return b.g === 0; })
    readonly property var trlBulbs: bulbs.filter(function (b) { return b.g === 1; })

    signal finished()

    width: dw * sc
    height: dh * sc
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

    // яскравість лампочки i: хвиля-chase + мерехтіння (у lite просто чергування)
    function litOf(i) {
        if (lite) return ((i + tick) % 2 === 0) ? 1.0 : 0.6;
        var d = (((tick * 2 - i) % 14) + 14) % 14;
        var v = 0.38 + 0.62 * Math.max(0, 1 - d / 6);
        if ((i * 7) % 5 === 0 && (tick + i) % 4 === 0) v *= 0.55;
        return v;
    }

    // точки гірлянди (координати малюнка): g=0 кабіна, g=1 причеп
    function buildBulbs() {
        var a = [];
        function line(g, x0, y0, x1, y1, step) {
            var dx = x1 - x0;
            var dy = y1 - y0;
            var n = Math.max(1, Math.round(Math.sqrt(dx * dx + dy * dy) / step));
            for (var i = 0; i < n; i++)
                a.push({ g: g, n: a.length, x: x0 + dx * i / n, y: y0 + dy * i / n });
        }
        function arc(g, cx, cy, r, a0, a1, cnt) {
            for (var i = 0; i < cnt; i++) {
                var th = (a0 + (a1 - a0) * i / Math.max(1, cnt - 1)) * Math.PI / 180;
                a.push({ g: g, n: a.length, x: cx + r * Math.cos(th), y: cy - r * Math.sin(th) });
            }
        }
        // кабіна: дах, стійка, капот, бампер, арки, низ
        line(0, 140, 83, 248, 83, 9);
        line(0, 128, 128, 137, 90, 8);
        line(0, 120, 139, 48, 144, 9);
        line(0, 16, 186, 16, 210, 8);
        arc(0, 73, 224, 27, 20, 160, 6);
        line(0, 101, 210, 148, 210, 10);
        arc(0, 176, 224, 26, 20, 160, 6);
        arc(0, 222, 224, 26, 20, 160, 6);
        // причеп: лівий край, дах, правий край, низ, арки тандема
        line(1, 281, 196, 281, 60, 12);
        line(1, 284, 57, 650, 57, 14);
        line(1, 654, 60, 654, 196, 12);
        line(1, 640, 215, 612, 215, 10);
        arc(1, 587, 226, 24, 12, 168, 6);
        arc(1, 540, 226, 24, 12, 168, 6);
        line(1, 515, 215, 296, 215, 13);
        return a;
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

    // один спільний тік для гірлянди (у lite рідший)
    Timer {
        interval: tr.lite ? 320 : 110
        repeat: true
        running: tr.visible
        onTriggered: tr.tick = (tr.tick + 1) % 7812
    }

    NumberAnimation on fx {
        from: 0
        to: 1
        duration: 1100
        loops: Animation.Infinite
        running: tr.visible
    }

    NumberAnimation on eb {
        from: 0
        to: 3
        duration: 1560
        loops: Animation.Infinite
        running: tr.visible && !tr.lite
    }

    NumberAnimation on wv {
        from: 0
        to: 1
        duration: 1000
        loops: Animation.Infinite
        running: tr.visible
    }

    NumberAnimation on bx {
        from: 0
        to: 1
        duration: 800
        loops: Animation.Infinite
        running: tr.visible && !tr.lite
    }

    // блиск, що пробігає по причепу
    SequentialAnimation on sw {
        loops: Animation.Infinite
        running: tr.visible && !tr.lite
        NumberAnimation { from: 0; to: 1; duration: 1800; easing.type: Easing.InOutSine }
        PauseAnimation { duration: 2600 }
    }

    // ---- малі компоненти (не бачать id зовнішнього файлу) ----

    component Wheel: Item {
        property real travel: 0
        width: 44
        height: 44
        rotation: travel / (width / 2) * 57.2958
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "#15171a"
            border.width: 1
            border.color: "#2a2f36"
        }
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.86
            height: width
            radius: width / 2
            color: "#272b31"
        }
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.62
            height: width
            radius: width / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#ffffff" }
                GradientStop { position: 0.5; color: "#a9b6bf" }
                GradientStop { position: 1.0; color: "#e9eef1" }
            }
        }
        Repeater {
            model: 6
            Rectangle {
                required property int index
                width: Math.max(1.5, parent.width * 0.06)
                height: width
                radius: width / 2
                color: "#6b7780"
                x: parent.width / 2 + Math.cos(index * 1.0472) * parent.width * 0.22 - width / 2
                y: parent.height / 2 + Math.sin(index * 1.0472) * parent.width * 0.22 - height / 2
            }
        }
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.22
            height: width
            radius: width / 2
            color: "#5c6770"
        }
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.5
            height: 1
            color: "#7d8a93"
        }
        Rectangle {
            anchors.centerIn: parent
            width: 1
            height: parent.width * 0.5
            color: "#7d8a93"
        }
    }

    // лампочка гірлянди зі сяйвом (bloom); центр у (0,0)
    component Bulb: Item {
        property real lit: 1
        property real glowK: 1
        property bool soft: true
        property color col: "#ffd75a"
        width: 0
        height: 0
        Rectangle {
            visible: parent.soft
            x: -9
            y: -9
            width: 18
            height: 18
            radius: 9
            color: parent.col
            opacity: 0.32 * parent.lit * parent.glowK
        }
        Rectangle {
            x: -3
            y: -3
            width: 6
            height: 6
            radius: 3
            color: parent.col
            border.width: 1
            border.color: "#fff6cf"
            opacity: 0.4 + 0.6 * parent.lit
        }
    }

    // хромована деталь
    component Chrome: Rectangle {
        id: ch
        property bool hz: false
        gradient: Gradient {
            orientation: ch.hz ? Gradient.Horizontal : Gradient.Vertical
            GradientStop { position: 0.0; color: "#ffffff" }
            GradientStop { position: 0.3; color: "#cfd8dc" }
            GradientStop { position: 0.65; color: "#8fa1ab" }
            GradientStop { position: 1.0; color: "#e8eef2" }
        }
    }

    // плавна фігура з вертикальним градієнтом
    component Panel: Shape {
        id: pn
        property string d: ""
        property real gy1: 0
        property real gy2: 100
        property color c0: "#ee4a43"
        property color c1: "#da2f2f"
        property color c2: "#b82424"
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0
                y1: pn.gy1
                x2: 0
                y2: pn.gy2
                GradientStop { position: 0.0; color: pn.c0 }
                GradientStop { position: 0.4; color: pn.c1 }
                GradientStop { position: 1.0; color: pn.c2 }
            }
            PathSvg { path: pn.d }
        }
    }

    // плавна фігура однієї заливки (з необов'язковим контуром)
    component Flat: Shape {
        id: fl
        property string d: ""
        property color fill: "#ffffff"
        property color edge: "transparent"
        property real edgeW: 0
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: fl.fill
            strokeColor: fl.edge
            strokeWidth: fl.edgeW > 0 ? fl.edgeW : -1
            PathSvg { path: fl.d }
        }
    }

    // лінія-смуга
    component Stroke: Shape {
        id: st
        property string d: ""
        property color col: "#f2b632"
        property real w: 2
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: st.col
            strokeWidth: st.w
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: st.d }
        }
    }

    // ---- купа снігу перед відвалом (у справжніх пікселях) ----
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

    // сніговий пил: 5 сніжинок підлітають і падають
    Repeater {
        model: 5
        Rectangle {
            required property int index
            readonly property real u: (tr.fx + index * 0.21) % 1
            width: 3
            height: 3
            radius: 1.5
            color: "#ffffff"
            x: 6 * tr.sc - tr.heapW * (0.12 + 0.18 * index) - u * 12
            y: tr.height - tr.heapH - 3 - Math.sin(Math.PI * u) * (9 + (index % 2) * 7)
            opacity: 1 - u * u * 0.9
        }
    }

    // ================= уся фура в координатах малюнка =================
    Item {
        id: rig
        width: tr.dw
        height: tr.dh
        scale: tr.sc
        transformOrigin: Item.TopLeft

        // конус світла фар (вліво), гойдається на нерівностях
        Shape {
            visible: !tr.lite
            opacity: 0.8 + 0.2 * Math.sin(tr.fx * 6.2832)
            preferredRendererType: Shape.CurveRenderer
            transform: Rotation {
                origin.x: 30
                origin.y: 184
                angle: tr.bumpA * 1.4
            }
            ShapePath {
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    x1: 30
                    y1: 0
                    x2: -140
                    y2: 0
                    GradientStop { position: 0.0; color: "#99ffe9a0" }
                    GradientStop { position: 1.0; color: "#00ffe9a0" }
                }
                startX: 30
                startY: 180
                PathLine { x: -140; y: 140 }
                PathLine { x: -140; y: 240 }
                PathLine { x: 30; y: 190 }
            }
        }

        // тінь під фурою
        Rectangle { x: 6; y: 243; width: 650; height: 6; radius: 3; color: "#000000"; opacity: 0.22 }

        // шасі
        Rectangle { x: 30; y: 205; width: 620; height: 8; color: "#2b2f36" }

        // паливний бак (хром)
        Chrome { x: 105; y: 207; width: 40; height: 17; radius: 7; border.width: 1; border.color: "#78909c" }

        // ---------------- причеп ----------------
        Item {
            y: tr.bumpB

            Panel {
                d: "M284,54 L650,54 Q657,54 657,62 L657,196 Q657,200 653,200 L278,200 L278,60 Q278,54 284,54 Z"
                gy1: 54
                gy2: 200
            }
            Flat { d: "M284,57 L650,57 L650,64 L284,64 Z"; fill: "#30ffffff" }
            Flat { d: "M278,184 L657,184 L657,198 L278,198 Z"; fill: "#1c000000" }
            Repeater {
                model: [350, 407, 535, 593]
                Item {
                    required property var modelData
                    Rectangle { x: modelData; y: 62; width: 1.5; height: 134; color: "#38000000" }
                    Rectangle { x: modelData + 1.5; y: 62; width: 1; height: 134; color: "#18ffffff" }
                }
            }
            Rectangle { x: 644; y: 60; width: 1; height: 136; color: "#33000000" }
            Rectangle { x: 278; y: 194; width: 379; height: 6; color: "#8e1b1b" }

            // нижня спідниця й ніша під тандем
            Rectangle {
                x: 284
                y: 200
                width: 368
                height: 12
                radius: 2
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#5b636d" }
                    GradientStop { position: 1.0; color: "#2f353c" }
                }
            }
            Rectangle { x: 514; y: 200; width: 98; height: 14; radius: 5; color: "#14171a" }
            Rectangle { x: 296; y: 212; width: 3; height: 14; color: "#455a64" }
            Rectangle { x: 290; y: 225; width: 15; height: 3; color: "#37474f" }

            // задній бампер і ліхтарі (миготять)
            Rectangle { x: 644; y: 203; width: 20; height: 9; radius: 2; color: "#1f2328" }
            Repeater {
                model: 3
                Rectangle {
                    required property int index
                    x: 650
                    y: 150 + index * 15
                    width: 6
                    height: 11
                    radius: 2.5
                    color: "#ff3b3b"
                    opacity: 0.65 + 0.35 * Math.abs(Math.sin(tr.bx * 3.1416 + index * 0.5))
                }
            }

            // зелене коло із Сантою
            Rectangle {
                x: 397
                y: 72
                width: 112
                height: 112
                radius: 56
                color: "#ffffff"
                opacity: tr.lite ? 0 : 0.05 + 0.07 * Math.abs(Math.sin(tr.bx * 3.1416))
            }
            Rectangle {
                x: 405
                y: 80
                width: 96
                height: 96
                radius: 48
                color: "#fafafa"
                border.width: 1
                border.color: "#c5d0d6"
            }
            Rectangle {
                x: 409
                y: 84
                width: 88
                height: 88
                radius: 44
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#43a047" }
                    GradientStop { position: 1.0; color: "#1b5e20" }
                }
            }
            Item {
                x: 429
                y: 104
                width: 48
                height: 48
                scale: 1.8
                transformOrigin: Item.Center

                // шуба
                Flat {
                    d: "M10,31 Q10,28 14,28 L34,28 Q38,28 38,31 L40,38 L36,42.5 L12,42.5 L8,38 Z"
                    fill: "#c62828"
                }
                Rectangle { x: 22.5; y: 30; width: 3; height: 12.5; color: "#ffffff" }

                // рука, що махає
                Item {
                    x: 33
                    y: 25
                    width: 6
                    height: 12
                    transformOrigin: Item.Bottom
                    rotation: 20 + Math.sin(tr.wv * 6.2832) * 22
                    Rectangle { anchors.fill: parent; radius: 3; color: "#c62828" }
                    Rectangle { x: -0.5; y: -3; width: 7; height: 7; radius: 3.5; color: "#ffffff" }
                }

                // голова, борода, обличчя
                Rectangle { x: 17; y: 15; width: 14; height: 14; radius: 7; color: "#f4c9a0" }
                Rectangle { x: 16; y: 22; width: 16; height: 13; radius: 6; color: "#ffffff" }
                Rectangle { x: 22.5; y: 22; width: 3; height: 3; radius: 1.5; color: "#e8a07a" }
                Rectangle { x: 22.5; y: 26.5; width: 3; height: 1.5; radius: 0.75; color: "#c2655a" }
                Rectangle {
                    x: 20.5
                    y: tr.winkOn ? 20.5 : 19.5
                    width: tr.winkOn ? 3 : 2
                    height: tr.winkOn ? 1 : 2
                    radius: 1
                    color: "#37262a"
                }
                Rectangle { x: 26.5; y: 19.5; width: 2; height: 2; radius: 1; color: "#37262a" }

                // шапка
                Flat { d: "M16.5,17 C16.5,11 20,6.5 26,5.5 C30,5 34,8 36,13 L31.5,17 Z"; fill: "#d32f2f" }
                Rectangle { x: 15; y: 15.5; width: 18; height: 4; radius: 2; color: "#ffffff" }
                Rectangle { x: 33.5; y: 10.5; width: 5; height: 5; radius: 2.5; color: "#ffffff" }
            }

            // блиск, що пробігає по причепу
            Item {
                x: 278
                y: 54
                width: 379
                height: 146
                clip: true
                visible: !tr.lite
                Rectangle {
                    x: -80 + tr.sw * 560
                    y: -20
                    width: 34
                    height: 190
                    rotation: 18
                    color: "#26ffffff"
                }
            }
        }

        // колеса тандема причепа
        Wheel { x: 520; y: 206; width: 40; height: 40; travel: tr.wheelTravel }
        Wheel { x: 567; y: 206; width: 40; height: 40; travel: tr.wheelTravel }

        // ---------------- тягач ----------------
        Item {
            y: tr.bumpA

            // кабіна + капот одним силуетом
            Panel {
                d: "M42,206 L42,147 Q42,142 48,142 L120,137 L126,134 L135,86 Q136,80 142,80 L246,80 Q254,80 254,88 L254,206 Z"
                gy1: 80
                gy2: 206
                c2: "#a31d1d"
            }
            Flat { d: "M50,145 L118,140 L118,145 L50,150 Z"; fill: "#38ffffff" }
            Flat { d: "M142,82 L246,82 L246,86 L142,86 Z"; fill: "#40ffffff" }
            Flat { d: "M42,196 L254,196 L254,206 L42,206 Z"; fill: "#20000000" }
            Rectangle { x: 196; y: 92; width: 1.5; height: 112; color: "#8e1b1b" }
            Chrome { x: 186; y: 134; width: 9; height: 3; radius: 1 }
            Rectangle { x: 44; y: 200; width: 208; height: 2; color: "#cfd8dc"; opacity: 0.8 }

            // золоті смуги: по капоту й діагоналлю вгору по кабіні
            Stroke { d: "M46,184 L125,171 L252,140"; col: "#f2b632"; w: 3 }
            Stroke { d: "M46,192 L125,179 L252,148"; col: "#ffd76a"; w: 2 }

            // колісні арки
            Flat { d: "M54.2,206 A26,26 0 0 1 91.8,206 Z"; fill: "#14171a" }
            Flat { d: "M158.65,206 A25,25 0 0 1 193.35,206 Z"; fill: "#14171a" }
            Flat { d: "M204.65,206 A25,25 0 0 1 239.35,206 Z"; fill: "#14171a" }

            // вікно водія
            Panel {
                d: "M129,127 L136,90 Q137,88 140,88 L182,88 L182,127 Z"
                gy1: 88
                gy2: 127
                c0: "#d9f3ff"
                c1: "#9fd4ea"
                c2: "#5f9fc0"
            }
            // водій у червоній шапці киває й кліпає
            Item {
                y: Math.sin(tr.fx * 6.2832) * 1.2
                Rectangle { x: 146; y: 118; width: 26; height: 10; radius: 5; color: "#b3261e" }
                Item {
                    x: 160
                    y: 118
                    rotation: Math.sin(tr.fx * 6.2832 + 0.6) * 5
                    Rectangle { x: -8; y: -17; width: 16; height: 17; radius: 8; color: "#f2c6a0" }
                    Rectangle { x: -9; y: -21; width: 18; height: 10; radius: 5; color: "#d32f2f" }
                    Rectangle { x: -9; y: -13; width: 18; height: 3; radius: 1.5; color: "#ffffff" }
                    Rectangle { x: 6; y: -23; width: 6; height: 6; radius: 3; color: "#ffffff" }
                    Rectangle { x: -5; y: tr.blinkOn ? -8 : -9.5; width: 3; height: tr.blinkOn ? 1 : 3; radius: 1; color: "#37262a" }
                    Rectangle { x: 2; y: tr.blinkOn ? -8 : -9.5; width: 3; height: tr.blinkOn ? 1 : 3; radius: 1; color: "#37262a" }
                    Rectangle { x: -3; y: -3.5; width: 6; height: 1.5; radius: 0.75; color: "#c2655a" }
                }
            }
            Flat { d: "M150,90 L160,90 L146,127 L136,127 Z"; fill: "#33ffffff" }
            Flat { d: "M129,127 L136,90 Q137,88 140,88 L182,88 L182,127 Z"; fill: "transparent"; edge: "#2f3b42"; edgeW: 1.5 }

            // заднє віконце спальника
            Rectangle {
                x: 208
                y: 104
                width: 34
                height: 21
                radius: 3
                border.width: 1.5
                border.color: "#2f3b42"
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#d9f3ff" }
                    GradientStop { position: 1.0; color: "#5f9fc0" }
                }
            }

            // дзеркало
            Rectangle { x: 118; y: 100; width: 12; height: 2; color: "#37474f" }
            Chrome { x: 108; y: 94; width: 9; height: 22; radius: 3; border.width: 1; border.color: "#455a64" }

            // решітка радіатора
            Chrome { x: 24; y: 148; width: 20; height: 42; radius: 4; border.width: 1; border.color: "#78909c" }
            Repeater {
                model: 9
                Rectangle {
                    required property int index
                    x: 27
                    y: 152 + index * 4.4
                    width: 14
                    height: 1.2
                    color: "#5a6b75"
                }
            }

            // фара: світиться і пульсує
            Rectangle {
                visible: !tr.lite
                x: 18
                y: 172
                width: 26
                height: 26
                radius: 13
                color: "#ffe27a"
                opacity: 0.28 + 0.14 * Math.sin(tr.fx * 6.2832)
            }
            Rectangle {
                x: 28
                y: 182
                width: 11
                height: 11
                radius: 5.5
                color: "#fff6c0"
                border.width: 1
                border.color: "#b0bec5"
            }

            // хромований бампер і малий відвал
            Chrome { x: 14; y: 192; width: 32; height: 16; radius: 4; border.width: 1; border.color: "#78909c" }
            Panel {
                d: "M2,190 L15,186 L17,238 L8,246 L0,244 Z"
                gy1: 186
                gy2: 246
                c0: "#b0bec5"
                c1: "#78909c"
                c2: "#546e7a"
            }
            Rectangle { x: 0; y: 242; width: 12; height: 4; radius: 1; color: "#263238" }

            // дві високі хромовані труби за кабіною
            Chrome { hz: true; x: 256; y: 42; width: 8; height: 164 }
            Chrome { hz: true; x: 270; y: 42; width: 8; height: 164 }
            Rectangle { x: 254; y: 38; width: 12; height: 6; radius: 3; color: "#cfd8dc" }
            Rectangle { x: 268; y: 38; width: 12; height: 6; radius: 3; color: "#cfd8dc" }
            Rectangle { x: 254; y: 100; width: 12; height: 4; color: "#90a4ae" }
            Rectangle { x: 268; y: 100; width: 12; height: 4; color: "#90a4ae" }
            Rectangle { x: 254; y: 150; width: 12; height: 4; color: "#90a4ae" }
            Rectangle { x: 268; y: 150; width: 12; height: 4; color: "#90a4ae" }

            // дим із двох труб у ритм двигуна
            Repeater {
                model: 8
                Rectangle {
                    required property int index
                    readonly property int st: index % 2
                    readonly property real u: ((tr.eb / 3) + index / 8) % 1
                    visible: !tr.lite
                    width: 6 + u * 22
                    height: width
                    radius: width / 2
                    x: (st === 0 ? 260 : 274) - width / 2 + u * 80
                    y: 38 - u * 46 - height / 2
                    color: "#e0e6ea"
                    opacity: 0.5 * (1 - u)
                }
            }

            // різдвяний вінок із бантом на решітці
            Item {
                x: 0
                y: 139
                width: 40
                height: 40
                transformOrigin: Item.Top
                rotation: Math.sin(tr.wv * 6.2832) * 2.5
                Rectangle {
                    width: 40
                    height: 40
                    radius: 20
                    color: "transparent"
                    border.width: 8
                    border.color: "#2e7d32"
                }
                Rectangle {
                    x: 3
                    y: 3
                    width: 34
                    height: 34
                    radius: 17
                    color: "transparent"
                    border.width: 2
                    border.color: "#66bb6a"
                    opacity: 0.7
                }
                Repeater {
                    model: 8
                    Rectangle {
                        required property int index
                        width: 4
                        height: 4
                        radius: 2
                        color: (index % 2 === 0) ? "#ff5252" : "#ffd75a"
                        x: 20 + Math.cos(index * 0.7854) * 16 - 2
                        y: 20 + Math.sin(index * 0.7854) * 16 - 2
                        opacity: 0.35 + 0.65 * tr.litOf(index * 3)
                    }
                }
                Item {
                    x: 20
                    y: 1
                    rotation: Math.sin(tr.wv * 6.2832 + 1.0) * 6
                    Rectangle { x: -13; y: -5; width: 13; height: 9; radius: 4.5; color: "#d32f2f"; rotation: -24 }
                    Rectangle { x: 0; y: -5; width: 13; height: 9; radius: 4.5; color: "#d32f2f"; rotation: 24 }
                    Rectangle { x: -3; y: -3; width: 6; height: 6; radius: 3; color: "#b71c1c" }
                    Rectangle { x: -6; y: 1; width: 3; height: 11; radius: 1.5; color: "#d32f2f"; rotation: 14 }
                    Rectangle { x: 3; y: 1; width: 3; height: 11; radius: 1.5; color: "#d32f2f"; rotation: -14 }
                }
            }

            // шапка Санти на даху: гойдається, помпон хитається
            Item {
                y: 5 + Math.sin(tr.fx * 6.2832) * 1.2
                transform: Rotation {
                    origin.x: 165
                    origin.y: 66
                    angle: Math.sin(tr.wv * 6.2832) * 2.5
                }
                Flat {
                    d: "M133,47 C134,22 150,4 172,2 C190,1 200,16 208,32 L198,47 Z"
                    fill: "#d32f2f"
                }
                Flat { d: "M140,30 C146,16 158,8 172,6 C160,14 152,24 148,38 Z"; fill: "#30ffffff" }
                Rectangle {
                    x: 126
                    y: 45
                    width: 76
                    height: 21
                    radius: 10.5
                    color: "#ffffff"
                    border.width: 1
                    border.color: "#cfd8e6"
                }
                Item {
                    transform: Rotation {
                        origin.x: 200
                        origin.y: 38
                        angle: Math.sin(tr.wv * 6.2832 + 0.8) * 12
                    }
                    Rectangle {
                        x: 198
                        y: 24
                        width: 22
                        height: 22
                        radius: 11
                        color: "#ffffff"
                        border.width: 1
                        border.color: "#cfd8e6"
                    }
                }
            }
        }

        // колеса: 1 під капотом і 2 під кабіною
        Wheel { x: 51; y: 202; width: 44; height: 44; travel: tr.wheelTravel }
        Wheel { x: 154; y: 202; width: 44; height: 44; travel: tr.wheelTravel }
        Wheel { x: 200; y: 202; width: 44; height: 44; travel: tr.wheelTravel }

        // гірлянда тягача
        Item {
            y: tr.bumpA
            Repeater {
                model: tr.cabBulbs
                Bulb {
                    required property var modelData
                    x: modelData.x
                    y: modelData.y
                    lit: tr.litOf(modelData.n)
                    glowK: tr.glowK
                    soft: !tr.lite
                    col: (modelData.n % 3 === 0) ? "#ffb830" : "#ffd75a"
                }
            }
        }

        // гірлянда причепа
        Item {
            y: tr.bumpB
            Repeater {
                model: tr.trlBulbs
                Bulb {
                    required property var modelData
                    x: modelData.x
                    y: modelData.y
                    lit: tr.litOf(modelData.n)
                    glowK: tr.glowK
                    soft: !tr.lite
                    col: (modelData.n % 3 === 0) ? "#ffb830" : "#ffd75a"
                }
            }
        }

        // іскри-зірочки, що мерехтять навколо фури
        Repeater {
            model: 6
            Item {
                required property int index
                property var px: [300, 385, 470, 560, 630, 150]
                property var py: [38, 34, 42, 36, 44, 58]
                readonly property real u: (tr.fx + index * 0.19) % 1
                visible: !tr.lite
                x: px[index]
                y: py[index]
                opacity: Math.sin(Math.PI * u)
                scale: 0.4 + 0.9 * Math.sin(Math.PI * u)
                rotation: u * 90
                Rectangle { x: -7; y: -0.75; width: 14; height: 1.5; radius: 0.75; color: "#fff6cf" }
                Rectangle { x: -0.75; y: -7; width: 1.5; height: 14; radius: 0.75; color: "#fff6cf" }
            }
        }

        // сніг із-під задніх коліс
        Repeater {
            model: 8
            Rectangle {
                required property int index
                readonly property real u: (tr.fx * 2 + index / 8) % 1
                visible: !tr.lite
                width: 3
                height: 3
                radius: 1.5
                color: "#f1f5f9"
                x: 612 + u * 44 + (index % 3) * 3
                y: 240 - Math.sin(Math.PI * u) * 10 + u * u * 4
                opacity: 1 - u * 0.7
            }
        }
    }
}
