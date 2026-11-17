// sp_20261115_1800_ui: Snowglobe settings panel v3 (animated, EN/UK)
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: win

    property var world: null
    signal closeRequested()

    property int tab: 0
    property bool adv: false
    property real pop: 0
    property bool resetArmed: false
    readonly property var presets: ({
        cozy: { level: 1, windStrength: 0.1, windGust: false, accumulate: true, bottom: true, windowSnow: true, growSeconds: 120, bottomMax: 28, windowMax: 20 },
        storm: { level: 3, windStrength: 0.7, windGust: true, accumulate: true, bottom: true, windowSnow: true, growSeconds: 25, bottomMax: 80, windowMax: 40 },
        minimal: { level: 1, windStrength: 0, windGust: false, accumulate: false, bottom: false, windowSnow: false, saveMode: true }
    })
    readonly property var defaults: ({
        level: 2, accumulate: true, melt: false, bottom: true, bottomAuto: false, bottomOffset: 0, bottomMax: 36,
        windowSnow: true, windowMax: 26, growSeconds: 60, windStrength: 0, windGust: false, brushSize: 40,
        ballGrow: 1, ballMax: 48, luck: 0, snowmenOn: true, announce: true, tractorMode: 1,
        gameMode: true, saveMode: false, dance: true, vehicle: 3,
        interactive: true, vehicleOpacity: 0.85, vehicleScale: 0.55, snowOpacity: 1, paused: false,
        garland: true, garlandTop: true, garlandWin: true, garlandIce: false, garlandFrame: false,
        garlandGround: false, garlandMan: false, garlandMode: 2, garlandPalette: 0,
        garlandBright: 1, garlandSpeed: 1, garlandSize: 1
    })
    readonly property var found: {
        try { return JSON.parse(SnowConfig.foundJson) || ({}); } catch (e) { return ({}); }
    }
    readonly property int foundCount: {
        var n = 0;
        for (var i = 0; i < SnowTypes.list.length; i++)
            if ((found[i] || 0) > 0) n++;
        return n;
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "snowfall-settings"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    anchors { top: true; right: true }
    margins { top: 56; right: 20 }
    implicitWidth: 380
    implicitHeight: Math.min(700, (win.screen ? win.screen.height : 800) - 90)

    onVisibleChanged: {
        if (visible) {
            pop = 0;
            popAnim.restart();
            revAnim.restart();
        }
    }
    onTabChanged: revAnim.restart()

    NumberAnimation { id: popAnim; target: win; property: "pop"; to: 1; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
    NumberAnimation { id: revAnim; target: SnowConfig; property: "uiReveal"; from: 0; to: 1; duration: 1000; easing.type: Easing.OutCubic }

    CfgWriter { id: cfg }

    // записує кілька ключів у config.json одним разом (пресети, скидання)
    Process { id: batchProc }
    function applyBatch(obj) {
        var py = "import json,os,sys\n"
            + "p=os.path.expanduser('~/.config/snowfall/config.json')\n"
            + "try:\n d=json.load(open(p))\nexcept Exception:\n d={}\n"
            + "d.update(json.loads(sys.argv[1]))\n"
            + "os.makedirs(os.path.dirname(p),exist_ok=True)\n"
            + "json.dump(d,open(p,'w'),indent=2)\n";
        batchProc.command = ["python3", "-c", py, JSON.stringify(obj)];
        batchProc.running = false;
        batchProc.running = true;
    }
    Timer { id: resetTimer; interval: 3000; onTriggered: win.resetArmed = false }

    // ---------------- reusable pieces ----------------

    // м'яке кругле сяйво
    component Glow: Shape {
        id: gl
        property color col: "#7fb4d6"
        property real size: 260
        width: size
        height: size
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: gl.size / 2
                centerY: gl.size / 2
                centerRadius: gl.size / 2
                focalX: gl.size / 2
                focalY: gl.size / 2
                GradientStop { position: 0.0; color: Qt.rgba(gl.col.r, gl.col.g, gl.col.b, 0.30) }
                GradientStop { position: 1.0; color: Qt.rgba(gl.col.r, gl.col.g, gl.col.b, 0.0) }
            }
            PathSvg { path: "M0,0 L" + gl.size + ",0 L" + gl.size + "," + gl.size + " L0," + gl.size + " Z" }
        }
    }

    component SecTitle: Item {
        id: st
        property alias text: lbl.text
        readonly property real rv: Math.max(0, Math.min(1, SnowConfig.uiReveal * 2.4 - (Math.min(Math.max(y, 0), 360) + x * 0.3) / 300))
        width: parent ? parent.width : 300
        height: 28
        opacity: rv
        transform: Translate { y: (1 - st.rv) * 10 }

        Rectangle {
            x: 0
            y: 15
            width: 5
            height: 5
            radius: 2.5
            color: SnowConfig.accent
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: st.visible
                NumberAnimation { to: 0.3; duration: 1100; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 1100; easing.type: Easing.InOutSine }
            }
        }
        Text {
            id: lbl
            x: 14
            y: 10
            color: Qt.lighter(SnowConfig.accent, 1.05)
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 1.4
            font.capitalization: Font.AllUppercase
        }
    }

    component Hint: Text {
        id: ht
        readonly property real rv: Math.max(0, Math.min(1, SnowConfig.uiReveal * 2.4 - (Math.min(Math.max(y, 0), 360) + x * 0.3) / 300))
        width: parent ? parent.width : 300
        wrapMode: Text.WordWrap
        color: "#8d949d"
        font.pixelSize: 11
        lineHeight: 1.2
        opacity: rv
        transform: Translate { y: (1 - ht.rv) * 10 }
    }

    component FToggle: Item {
        id: tg
        property string label: ""
        property string hint: ""
        property bool checked: false
        signal toggled(bool v)
        readonly property real rv: Math.max(0, Math.min(1, SnowConfig.uiReveal * 2.4 - (Math.min(Math.max(y, 0), 360) + x * 0.3) / 300))
        width: parent ? parent.width : 300
        height: hint !== "" ? 46 : 36
        opacity: rv
        transform: Translate { y: (1 - tg.rv) * 10 }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            Text { width: tg.width - 62; text: tg.label; color: "#dfe2e6"; font.pixelSize: 13; elide: Text.ElideRight }
            Text { width: tg.width - 62; visible: tg.hint !== ""; text: tg.hint; color: "#8d949d"; font.pixelSize: 11; elide: Text.ElideRight }
        }

        Rectangle {
            anchors.centerIn: track
            width: track.width + 16
            height: track.height + 16
            radius: height / 2
            color: SnowConfig.accent
            visible: tg.checked
            opacity: 0.1
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: tg.checked && tg.visible
                NumberAnimation { to: 0.3; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.08; duration: 900; easing.type: Easing.InOutSine }
            }
        }

        Rectangle {
            id: track
            width: 44
            height: 24
            radius: 12
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: tg.checked ? SnowConfig.accent : "#3a3f47"
            Behavior on color { ColorAnimation { duration: 200 } }
            Rectangle {
                id: thumb
                width: tma.pressed ? 22 : 18
                height: 18
                radius: 9
                y: 3
                x: tg.checked ? track.width - width - 3 : 3
                color: tg.checked ? "#ffffff" : "#8d949d"
                Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }
                Behavior on width { NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        MouseArea {
            id: tma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tg.toggled(!tg.checked)
        }
    }

    component FSlider: Item {
        id: sl
        property string label: ""
        property real from: 0
        property real to: 1
        property real value: 0
        property real step: 0
        property int decimals: 0
        property string unit: ""
        property real dragV: 0
        property bool dragging: false
        property real pulse: 0
        readonly property real shown: (dragging || hold.running) ? dragV : value
        readonly property real t: Math.max(0, Math.min(1, (shown - from) / (to - from)))
        readonly property real rv: Math.max(0, Math.min(1, SnowConfig.uiReveal * 2.4 - (Math.min(Math.max(y, 0), 360) + x * 0.3) / 300))
        signal moved(real v)
        width: parent ? parent.width : 300
        height: 48
        opacity: rv
        transform: Translate { y: (1 - sl.rv) * 10 }

        onShownChanged: pulseAnim.restart()
        NumberAnimation { id: pulseAnim; target: sl; property: "pulse"; from: 1; to: 0; duration: 320; easing.type: Easing.OutCubic }

        Timer { id: hold; interval: 900 }

        Text { x: 0; y: 0; text: sl.label; color: "#dfe2e6"; font.pixelSize: 13 }
        Text {
            anchors.right: parent.right
            y: 0
            text: (sl.decimals > 0 ? sl.shown.toFixed(sl.decimals) : Math.round(sl.shown)) + sl.unit
            color: Qt.lighter(SnowConfig.accent, 1.25)
            font.pixelSize: 12
            font.weight: Font.DemiBold
            scale: 1 + 0.22 * sl.pulse
            transformOrigin: Item.Right
        }

        Rectangle {
            id: trk
            x: 0
            y: 31
            width: parent.width
            height: 5
            radius: 2.5
            color: "#2a2f37"
            Rectangle {
                width: knob.x + 8
                height: parent.height
                radius: 2.5
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.darker(SnowConfig.accent, 1.5) }
                    GradientStop { position: 1.0; color: Qt.lighter(SnowConfig.accent, 1.2) }
                }
            }
        }

        Rectangle {
            x: knob.x - 6
            y: knob.y - 6
            width: 28
            height: 28
            radius: 14
            color: SnowConfig.accent
            opacity: ma.pressed ? 0.3 : (ma.containsMouse ? 0.16 : 0)
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        Rectangle {
            id: knob
            width: 16
            height: 16
            radius: 8
            y: 25.5
            x: sl.t * (sl.width - 16)
            color: "#ffffff"
            border.width: 3
            border.color: SnowConfig.accent
            scale: ma.pressed ? 1.25 : (ma.containsMouse ? 1.12 : 1)
            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
        }

        MouseArea {
            id: ma
            x: 0
            y: 16
            width: parent.width
            height: 32
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            function upd(mx) {
                var tt = Math.max(0, Math.min(1, mx / width));
                var v = sl.from + tt * (sl.to - sl.from);
                if (sl.step > 0) v = Math.round(v / sl.step) * sl.step;
                sl.dragV = v;
                sl.moved(v);
            }
            onPressed: function(m) { sl.dragging = true; upd(m.x); }
            onPositionChanged: function(m) { if (ma.pressed) upd(m.x); }
            onReleased: { sl.dragging = false; hold.restart(); }
            onCanceled: { sl.dragging = false; hold.restart(); }
        }
    }

    component FPills: Item {
        id: pl
        property var options: []
        property int current: 0
        signal picked(int i)
        readonly property real rv: Math.max(0, Math.min(1, SnowConfig.uiReveal * 2.4 - (Math.min(Math.max(y, 0), 360) + x * 0.3) / 300))
        width: parent ? parent.width : 300
        height: 36
        opacity: rv
        transform: Translate { y: (1 - pl.rv) * 10 }

        Rectangle { anchors.fill: parent; radius: 11; color: "#1c2128"; border.width: 1; border.color: "#2a3038" }
        Rectangle {
            y: 3
            height: parent.height - 6
            radius: 8
            width: (parent.width - 6) / Math.max(1, pl.options.length)
            x: 3 + pl.current * width
            color: Qt.rgba(SnowConfig.accent.r, SnowConfig.accent.g, SnowConfig.accent.b, 0.28)
            border.width: 1
            border.color: SnowConfig.accent
            Behavior on x { NumberAnimation { duration: 340; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }
        }
        Row {
            x: 3
            y: 3
            Repeater {
                model: pl.options
                Item {
                    required property int index
                    required property var modelData
                    width: (pl.width - 6) / Math.max(1, pl.options.length)
                    height: pl.height - 6
                    Text {
                        anchors.fill: parent
                        anchors.margins: 2
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        fontSizeMode: Text.Fit
                        minimumPixelSize: 9
                        font.pixelSize: 12
                        text: modelData
                        color: index === pl.current ? "#ffffff" : (ima.containsMouse ? "#d5dce3" : "#98a0aa")
                        scale: ima.pressed ? 0.94 : 1
                        Behavior on color { ColorAnimation { duration: 160 } }
                        Behavior on scale { NumberAnimation { duration: 100 } }
                    }
                    MouseArea {
                        id: ima
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pl.picked(index)
                    }
                }
            }
        }
    }

    component FButton: Rectangle {
        id: bt
        property string label: ""
        property color tint: SnowConfig.accent
        property real shineX: -60
        property real lift: bma.containsMouse ? -1.5 : 0
        signal clicked()
        readonly property real rv: Math.max(0, Math.min(1, SnowConfig.uiReveal * 2.4 - (Math.min(Math.max(y, 0), 360) + x * 0.3) / 300))
        height: 36
        radius: 10
        clip: true
        color: bma.pressed ? Qt.rgba(tint.r, tint.g, tint.b, 0.38) : (bma.containsMouse ? Qt.rgba(tint.r, tint.g, tint.b, 0.26) : Qt.rgba(tint.r, tint.g, tint.b, 0.14))
        border.color: Qt.rgba(tint.r, tint.g, tint.b, bma.containsMouse ? 0.9 : 0.5)
        border.width: 1
        scale: bma.pressed ? 0.96 : 1
        opacity: rv
        transform: Translate { y: (1 - bt.rv) * 10 + bt.lift }
        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }
        Behavior on lift { NumberAnimation { duration: 130 } }

        Rectangle {
            x: bt.shineX
            y: -bt.height * 0.6
            width: 24
            height: bt.height * 2.2
            rotation: 20
            color: "#26ffffff"
            visible: shineAnim.running
        }
        NumberAnimation { id: shineAnim; target: bt; property: "shineX"; from: -40; to: bt.width + 20; duration: 560; easing.type: Easing.InOutSine }

        Text {
            anchors.fill: parent
            anchors.margins: 4
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            fontSizeMode: Text.Fit
            minimumPixelSize: 9
            font.pixelSize: 12
            font.weight: Font.Medium
            text: bt.label
            color: "#eef3f7"
        }
        MouseArea {
            id: bma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onContainsMouseChanged: { if (containsMouse) shineAnim.restart(); }
            onClicked: bt.clicked()
        }
    }

    component TypeCard: Rectangle {
        id: card
        property int tid: 0
        property int count: 0
        readonly property var tp: SnowTypes.list[tid]
        readonly property color rc: SnowTypes.tiers[tp.tier].color
        readonly property bool known: count > 0
        readonly property string nm: SnowConfig.isUk ? tp.name : SnowConfig.tr("sm_" + tp.key)
        readonly property string tierNm: SnowConfig.isUk ? SnowTypes.tiers[tp.tier].name : SnowConfig.tr("tier" + tp.tier)
        readonly property real rv: Math.max(0, Math.min(1, SnowConfig.uiReveal * 2.4 - (Math.min(Math.max(y, 0), 360) + x * 0.3) / 300))
        property real hv: (cma.containsMouse && known) ? 1 : 0
        property real glow: 0
        signal summon(int tid)
        width: 170
        height: 172
        radius: 14
        opacity: rv
        transform: Translate { y: (1 - card.rv) * 14 - card.hv * 3 }
        color: (cma.containsMouse && known) ? "#242b34" : "#1e242b"
        border.width: 1
        border.color: known ? Qt.rgba(rc.r, rc.g, rc.b, 0.4 + 0.4 * glow) : "#2f353d"
        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on hv { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

        SequentialAnimation on glow {
            loops: Animation.Infinite
            running: card.known && card.visible
            NumberAnimation { to: 1; duration: 1500; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0; duration: 1500; easing.type: Easing.InOutSine }
        }
        SequentialAnimation {
            id: clickAnim
            NumberAnimation { target: card; property: "scale"; to: 0.94; duration: 90 }
            NumberAnimation { target: card; property: "scale"; to: 1; duration: 260; easing.type: Easing.OutBack }
        }

        Rectangle { x: 16; y: 1; width: parent.width - 32; height: 3; radius: 2; color: card.known ? card.rc : "#2f353d" }

        Item {
            id: stage
            x: 1
            y: 8
            width: parent.width - 2
            height: 94
            clip: true
            Snowman {
                preview: true
                typeId: card.tid
                d1: 34
                d2: 22
                cx: stage.width / 2
                baseY: stage.height - 6
            }
        }

        Rectangle {
            x: 1
            y: 8
            width: parent.width - 2
            height: 94
            radius: 12
            color: "#14181d"
            opacity: card.known ? 0 : 0.92
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 300 } }
            Text { anchors.centerIn: parent; text: "?"; color: "#3a4452"; font.pixelSize: 38; font.weight: Font.Bold }
        }

        Column {
            x: 14
            y: 108
            width: parent.width - 28
            spacing: 2
            Text {
                width: parent.width
                text: card.known ? card.nm : "???"
                color: card.known ? "#eef2f6" : "#6a7380"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Row {
                spacing: 8
                Text { text: card.tierNm; color: card.rc; font.pixelSize: 11 }
                Text { text: card.tp.weight + "%"; color: "#98a0aa"; font.pixelSize: 11 }
            }
            Text {
                width: parent.width
                text: card.known ? (SnowConfig.tr("found") + " ×" + card.count) : SnowConfig.tr("notFound")
                color: "#8d949d"
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: cma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: card.known ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (card.known) {
                    clickAnim.restart();
                    card.summon(card.tid);
                }
            }
        }
    }

    // ---------------- panel ----------------

    Rectangle {
        id: panel
        anchors.fill: parent
        radius: 16
        opacity: win.pop
        scale: 0.94 + 0.06 * win.pop
        transformOrigin: Item.TopRight
        border.width: 1
        border.color: Qt.rgba(SnowConfig.accent.r, SnowConfig.accent.g, SnowConfig.accent.b, 0.45)
        clip: true
        focus: true
        Keys.onEscapePressed: win.closeRequested()
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1b2838" }
            GradientStop { position: 0.45; color: "#1b2027" }
            GradientStop { position: 1.0; color: "#16191e" }
        }

        // плаваюче сяйво під кольор теми
        Glow {
            id: glowA
            col: SnowConfig.accent
            size: 300
            x: -90
            y: -110
            SequentialAnimation on x {
                loops: Animation.Infinite
                running: win.visible
                NumberAnimation { to: 140; duration: 9000; easing.type: Easing.InOutSine }
                NumberAnimation { to: -90; duration: 9000; easing.type: Easing.InOutSine }
            }
        }
        Glow {
            id: glowB
            col: SnowConfig.accent
            size: 280
            x: 150
            y: panel.height - 170
            SequentialAnimation on y {
                loops: Animation.Infinite
                running: win.visible
                NumberAnimation { to: panel.height - 260; duration: 7500; easing.type: Easing.InOutSine }
                NumberAnimation { to: panel.height - 120; duration: 7500; easing.type: Easing.InOutSine }
            }
        }

        // сніжинки, що падають усередині панелі
        Repeater {
            model: 16
            Rectangle {
                required property int index
                readonly property real sz: 2 + (index % 3)
                readonly property real baseX: (index * 83 + 17) % 360
                width: sz
                height: sz
                radius: sz / 2
                color: "#ffffff"
                opacity: 0.18 + 0.1 * (index % 3)
                x: baseX + 7 * Math.sin(y * 0.025 + index)
                SequentialAnimation on y {
                    loops: Animation.Infinite
                    running: win.visible
                    PauseAnimation { duration: (index * 397) % 3000 }
                    NumberAnimation { from: -10; to: panel.height + 10; duration: 7000 + (index % 7) * 1300 }
                }
            }
        }

        // header
        Item {
            id: header
            x: 0
            y: 0
            width: parent.width
            height: 50

            Rectangle {
                x: 11
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                height: 34
                radius: 17
                color: SnowConfig.accent
                opacity: 0.18
                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    running: win.visible
                    NumberAnimation { to: 1.25; duration: 1400; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.9; duration: 1400; easing.type: Easing.InOutSine }
                }
            }
            Text {
                id: flakeGlyph
                text: "❄"
                color: SnowConfig.accent
                font.pixelSize: 20
                x: 18
                anchors.verticalCenter: parent.verticalCenter
                RotationAnimation on rotation { from: 0; to: 360; duration: 24000; loops: Animation.Infinite; running: win.visible }
            }
            Column {
                x: 54
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0
                Text { text: "Snowglobe"; color: "#eef2f6"; font.pixelSize: 17; font.weight: Font.DemiBold; font.letterSpacing: 0.4 }
                Text { text: SnowConfig.tr("sub"); color: "#98a0aa"; font.pixelSize: 11 }
            }
            Rectangle {
                id: closeBtn
                width: 28
                height: 28
                radius: 14
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                color: closeMa.containsMouse ? "#3a3f47" : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: closeMa.containsMouse ? "#ffffff" : "#98a0aa"
                    font.pixelSize: 12
                    rotation: closeMa.containsMouse ? 90 : 0
                    Behavior on rotation { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                }
                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.closeRequested()
                }
            }
        }

        // quick actions
        Row {
            id: quick
            x: 14
            y: 54
            width: parent.width - 28
            spacing: 8
            FButton {
                width: (quick.width - 8) / 2
                label: SnowConfig.tr("clear")
                onClicked: cfg.set("clearTick", SnowConfig.clearTick + 1)
            }
            FButton {
                width: (quick.width - 8) / 2
                label: SnowConfig.tr("send")
                onClicked: cfg.set("tractorTick", SnowConfig.tractorTick + 1)
            }
        }

        // tabs
        Item {
            id: tabs
            x: 14
            y: 98
            width: parent.width - 28
            height: 34

            Rectangle { anchors.fill: parent; radius: 11; color: "#1c2128"; border.width: 1; border.color: "#2a3038" }
            Rectangle {
                y: 3
                height: parent.height - 6
                radius: 8
                width: (parent.width - 6) / 2
                x: 3 + win.tab * width
                color: Qt.rgba(SnowConfig.accent.r, SnowConfig.accent.g, SnowConfig.accent.b, 0.28)
                border.width: 1
                border.color: SnowConfig.accent
                Behavior on x { NumberAnimation { duration: 340; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }
            }
            Row {
                x: 3
                y: 3
                Repeater {
                    model: [SnowConfig.tr("tabSettings"), SnowConfig.tr("tabCollection")]
                    Item {
                        required property int index
                        required property var modelData
                        width: (tabs.width - 6) / 2
                        height: tabs.height - 6
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: index === win.tab ? "#ffffff" : (tma2.containsMouse ? "#d5dce3" : "#98a0aa")
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            scale: tma2.pressed ? 0.94 : 1
                            Behavior on color { ColorAnimation { duration: 160 } }
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }
                        MouseArea {
                            id: tma2
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.tab = index
                        }
                    }
                }
            }
        }

        // pages
        Item {
            id: pages
            x: 14
            y: 142
            width: parent.width - 28
            height: parent.height - 142 - 12

            // ===== page 1: settings =====
            Flickable {
                id: f1
                anchors.fill: parent
                visible: opacity > 0.01
                opacity: win.tab === 0 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 220 } }
                transform: Translate {
                    x: win.tab === 0 ? 0 : -26
                    Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                }
                contentWidth: width
                contentHeight: c1.height + 16
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: c1
                    width: f1.width
                    spacing: 6

                    SecTitle { text: SnowConfig.tr("level") }
                    FPills {
                        options: [SnowConfig.tr("lvl0"), SnowConfig.tr("lvl1"), SnowConfig.tr("lvl2"), SnowConfig.tr("lvl3"), SnowConfig.tr("lvl4")]
                        current: SnowConfig.level
                        onPicked: function(i) { cfg.set("level", i); }
                    }
                    FSlider {
                        label: SnowConfig.tr("snowOpacity")
                        from: 0.2
                        to: 1
                        step: 0.05
                        decimals: 2
                        value: SnowConfig.snowOpacity
                        onMoved: function(v) { cfg.set("snowOpacity", v); }
                    }

                    SecTitle { text: SnowConfig.tr("presets") }
                    Row {
                        spacing: 8
                        FButton { width: (c1.width - 16) / 3; label: SnowConfig.tr("pCozy"); onClicked: win.applyBatch(win.presets.cozy) }
                        FButton { width: (c1.width - 16) / 3; label: SnowConfig.tr("pStorm"); onClicked: win.applyBatch(win.presets.storm) }
                        FButton { width: (c1.width - 16) / 3; label: SnowConfig.tr("pMin"); onClicked: win.applyBatch(win.presets.minimal) }
                    }

                    SecTitle { text: SnowConfig.tr("transport") }
                    FPills {
                        options: [SnowConfig.tr("vTruck"), SnowConfig.tr("vSleigh"), SnowConfig.tr("vRandom")]
                        current: SnowConfig.vehicle === 1 ? 0 : (SnowConfig.vehicle === 2 ? 1 : 2)
                        onPicked: function(i) { cfg.set("vehicle", [1, 2, 3][i]); }
                    }
                    FSlider {
                        label: SnowConfig.tr("vehOpacity")
                        from: 0.2
                        to: 1
                        step: 0.05
                        decimals: 2
                        value: SnowConfig.vehicleOpacity
                        onMoved: function(v) { cfg.set("vehicleOpacity", v); }
                    }
                    FSlider {
                        label: SnowConfig.tr("truckSize")
                        from: 0.3
                        to: 1.2
                        step: 0.05
                        decimals: 2
                        value: SnowConfig.vehicleScale
                        onMoved: function(v) { cfg.set("vehicleScale", v); }
                    }

                    SecTitle { text: SnowConfig.tr("garland") }
                    FToggle {
                        label: SnowConfig.tr("garlandOn")
                        hint: SnowConfig.tr("garlandOnHint")
                        checked: SnowConfig.garland
                        onToggled: function(v) { cfg.set("garland", v); }
                    }
                    FToggle {
                        visible: SnowConfig.garland
                        label: SnowConfig.tr("gTop")
                        hint: SnowConfig.tr("gTopHint")
                        checked: SnowConfig.garlandTop
                        onToggled: function(v) { cfg.set("garlandTop", v); }
                    }
                    FToggle {
                        visible: SnowConfig.garland
                        label: SnowConfig.tr("gWin")
                        hint: SnowConfig.tr("gWinHint")
                        checked: SnowConfig.garlandWin
                        onToggled: function(v) { cfg.set("garlandWin", v); }
                    }
                    FToggle {
                        visible: SnowConfig.garland
                        label: SnowConfig.tr("gIce")
                        hint: SnowConfig.tr("gIceHint")
                        checked: SnowConfig.garlandIce
                        onToggled: function(v) { cfg.set("garlandIce", v); }
                    }
                    FToggle {
                        visible: SnowConfig.garland
                        label: SnowConfig.tr("gFrame")
                        hint: SnowConfig.tr("gFrameHint")
                        checked: SnowConfig.garlandFrame
                        onToggled: function(v) { cfg.set("garlandFrame", v); }
                    }
                    FToggle {
                        visible: SnowConfig.garland
                        label: SnowConfig.tr("gGround")
                        hint: SnowConfig.tr("gGroundHint")
                        checked: SnowConfig.garlandGround
                        onToggled: function(v) { cfg.set("garlandGround", v); }
                    }
                    FToggle {
                        visible: SnowConfig.garland
                        label: SnowConfig.tr("gMan")
                        hint: SnowConfig.tr("gManHint")
                        checked: SnowConfig.garlandMan
                        onToggled: function(v) { cfg.set("garlandMan", v); }
                    }
                    Hint { visible: SnowConfig.garland; text: SnowConfig.tr("gMode") }
                    FPills {
                        visible: SnowConfig.garland
                        options: [SnowConfig.tr("gm0"), SnowConfig.tr("gm1"), SnowConfig.tr("gm2"), SnowConfig.tr("gm3")]
                        current: SnowConfig.garlandMode
                        onPicked: function(i) { cfg.set("garlandMode", i); }
                    }
                    Hint { visible: SnowConfig.garland && SnowConfig.garlandMode === 3; text: SnowConfig.tr("gModeHint") }
                    Hint { visible: SnowConfig.garland; text: SnowConfig.tr("gPal") }
                    FPills {
                        visible: SnowConfig.garland
                        options: [SnowConfig.tr("gp0"), SnowConfig.tr("gp1"), SnowConfig.tr("gp2"), SnowConfig.tr("gp3")]
                        current: SnowConfig.garlandPalette
                        onPicked: function(i) { cfg.set("garlandPalette", i); }
                    }
                    FSlider {
                        visible: SnowConfig.garland
                        label: SnowConfig.tr("gBright")
                        from: 0.3
                        to: 1
                        step: 0.05
                        decimals: 2
                        value: SnowConfig.garlandBright
                        onMoved: function(v) { cfg.set("garlandBright", v); }
                    }
                    FSlider {
                        visible: SnowConfig.garland
                        label: SnowConfig.tr("gSpeed")
                        from: 0.4
                        to: 2.5
                        step: 0.05
                        decimals: 2
                        value: SnowConfig.garlandSpeed
                        onMoved: function(v) { cfg.set("garlandSpeed", v); }
                    }
                    FSlider {
                        visible: SnowConfig.garland
                        label: SnowConfig.tr("gSize")
                        from: 0.7
                        to: 1.6
                        step: 0.05
                        decimals: 2
                        value: SnowConfig.garlandSize
                        onMoved: function(v) { cfg.set("garlandSize", v); }
                    }

                    SecTitle { text: SnowConfig.tr("theme") }
                    Row {
                        spacing: 12
                        Repeater {
                            model: SnowConfig.palette
                            Item {
                                required property int index
                                required property var modelData
                                readonly property bool sel: SnowConfig.accentIdx === index
                                readonly property real rv: Math.max(0, Math.min(1, SnowConfig.uiReveal * 2.4 - (Math.min(Math.max(parent.parent.y, 0), 360) + x * 0.5) / 300))
                                width: 34
                                height: 34
                                opacity: rv
                                scale: swma.containsMouse ? 1.15 : 1
                                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 38
                                    height: 38
                                    radius: 19
                                    color: "transparent"
                                    border.width: 2
                                    border.color: "#ffffff"
                                    opacity: parent.sel ? 1 : 0
                                    scale: parent.sel ? 1 : 0.7
                                    Behavior on opacity { NumberAnimation { duration: 180 } }
                                    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
                                }
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: modelData
                                }
                                MouseArea {
                                    id: swma
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: cfg.set("accentIdx", index)
                                }
                            }
                        }
                    }

                    SecTitle { text: SnowConfig.tr("language") }
                    FPills {
                        options: ["Auto", "English", "Українська"]
                        current: SnowConfig.lang === "en" ? 1 : (SnowConfig.lang === "uk" ? 2 : 0)
                        onPicked: function(i) { cfg.set("lang", ["auto", "en", "uk"][i]); }
                    }

                    SecTitle { text: SnowConfig.tr("modes") }
                    FToggle {
                        label: SnowConfig.tr("interactive")
                        hint: SnowConfig.tr("interactiveHint")
                        checked: SnowConfig.interactive
                        onToggled: function(v) { cfg.set("interactive", v); }
                    }
                    FToggle {
                        label: SnowConfig.tr("dance")
                        hint: SnowConfig.tr("danceHint")
                        checked: SnowConfig.dance
                        onToggled: function(v) { cfg.set("dance", v); }
                    }
                    FToggle {
                        label: SnowConfig.tr("game")
                        hint: SnowConfig.tr("gameHint")
                        checked: SnowConfig.gameMode
                        onToggled: function(v) { cfg.set("gameMode", v); }
                    }

                    // розкривний блок "Додатково"
                    Item {
                        width: c1.width
                        height: 36
                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: advMa.containsMouse ? Qt.rgba(SnowConfig.accent.r, SnowConfig.accent.g, SnowConfig.accent.b, 0.2) : "#1f252c"
                            border.color: "#2f353d"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }
                        Text {
                            x: 14
                            anchors.verticalCenter: parent.verticalCenter
                            text: SnowConfig.tr("advanced")
                            color: "#dfe2e6"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            text: "▼"
                            color: SnowConfig.accent
                            font.pixelSize: 10
                            rotation: win.adv ? 180 : 0
                            Behavior on rotation { NumberAnimation { duration: 320; easing.type: Easing.OutBack } }
                        }
                        MouseArea {
                            id: advMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.adv = !win.adv
                        }
                    }
                    Item {
                        id: advWrap
                        width: c1.width
                        height: win.adv ? advCol.implicitHeight : 0
                        clip: true
                        opacity: win.adv ? 1 : 0
                        Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 260 } }

                        Column {
                            id: advCol
                            width: parent.width
                            spacing: 6

                            SecTitle { text: SnowConfig.tr("wind") }
                            FSlider {
                                label: SnowConfig.tr("windDir")
                                from: -1
                                to: 1
                                step: 0.05
                                decimals: 2
                                value: SnowConfig.windStrength
                                onMoved: function(v) { cfg.set("windStrength", v); }
                            }
                            FToggle {
                                label: SnowConfig.tr("gusts")
                                hint: SnowConfig.tr("gustsHint")
                                checked: SnowConfig.windGust
                                onToggled: function(v) { cfg.set("windGust", v); }
                            }

                            SecTitle { text: SnowConfig.tr("accum") }
                            FToggle {
                                label: SnowConfig.tr("accumOn")
                                hint: SnowConfig.tr("accumHint")
                                checked: SnowConfig.accumulate
                                onToggled: function(v) { cfg.set("accumulate", v); }
                            }
                            FToggle {
                                label: SnowConfig.tr("bottom")
                                checked: SnowConfig.bottom
                                onToggled: function(v) { cfg.set("bottom", v); }
                            }
                            FToggle {
                                label: SnowConfig.tr("onWin")
                                checked: SnowConfig.windowSnow
                                onToggled: function(v) { cfg.set("windowSnow", v); }
                            }
                            FSlider {
                                label: SnowConfig.tr("growTime")
                                from: 10
                                to: 180
                                step: 5
                                unit: SnowConfig.tr("secUnit")
                                value: SnowConfig.growSeconds
                                onMoved: function(v) { cfg.set("growSeconds", v); }
                            }
                            FSlider {
                                label: SnowConfig.tr("maxWin")
                                from: 8
                                to: 90
                                step: 1
                                value: SnowConfig.windowMax
                                onMoved: function(v) { cfg.set("windowMax", v); }
                            }
                            FSlider {
                                label: SnowConfig.tr("maxBottom")
                                from: 20
                                to: 400
                                step: 5
                                value: SnowConfig.bottomMax
                                onMoved: function(v) { cfg.set("bottomMax", v); }
                            }

                            SecTitle { text: SnowConfig.tr("snowmen") }
                            FToggle {
                                label: SnowConfig.tr("build")
                                hint: SnowConfig.tr("buildHint")
                                checked: SnowConfig.snowmenOn
                                onToggled: function(v) { cfg.set("snowmenOn", v); }
                            }
                            FToggle {
                                label: SnowConfig.tr("announce")
                                hint: SnowConfig.tr("announceHint")
                                checked: SnowConfig.announce
                                onToggled: function(v) { cfg.set("announce", v); }
                            }

                            SecTitle { text: SnowConfig.tr("balls") }
                            FSlider {
                                label: SnowConfig.tr("ballGrow")
                                from: 0.3
                                to: 3
                                step: 0.1
                                decimals: 1
                                value: SnowConfig.ballGrow
                                onMoved: function(v) { cfg.set("ballGrow", v); }
                            }
                            FSlider {
                                label: SnowConfig.tr("ballMax")
                                from: 24
                                to: 90
                                step: 2
                                unit: " px"
                                value: SnowConfig.ballMax
                                onMoved: function(v) { cfg.set("ballMax", v); }
                            }
                            FSlider {
                                label: SnowConfig.tr("brush")
                                from: 16
                                to: 90
                                step: 2
                                unit: " px"
                                value: SnowConfig.brushSize
                                onMoved: function(v) { cfg.set("brushSize", v); }
                            }

                            SecTitle { text: SnowConfig.tr("react") }
                            FPills {
                                options: [SnowConfig.tr("r0"), SnowConfig.tr("r1"), SnowConfig.tr("r2")]
                                current: SnowConfig.tractorMode
                                onPicked: function(i) { cfg.set("tractorMode", i); }
                            }
                            Hint { text: SnowConfig.tr("reactHint") }

                            SecTitle { text: SnowConfig.tr("perf") }
                            FToggle {
                                label: SnowConfig.tr("save")
                                hint: SnowConfig.tr("saveHint")
                                checked: SnowConfig.saveMode
                                onToggled: function(v) { cfg.set("saveMode", v); }
                            }

                            SecTitle { text: SnowConfig.tr("actions") }
                            Row {
                                spacing: 10
                                FButton {
                                    width: (c1.width - 10) / 2
                                    label: SnowConfig.tr("melt")
                                    onClicked: { if (win.world) win.world.meltSnowmen(); }
                                }
                                FButton {
                                    width: (c1.width - 10) / 2
                                    label: SnowConfig.tr("pop")
                                    onClicked: { if (win.world) win.world.popBalls(); }
                                }
                            }

                            SecTitle { text: SnowConfig.tr("reset") }
                            FButton {
                                width: c1.width
                                label: win.resetArmed ? SnowConfig.tr("resetSure") : SnowConfig.tr("resetBtn")
                                tint: win.resetArmed ? "#e06a6a" : SnowConfig.accent
                                onClicked: {
                                    if (win.resetArmed) {
                                        win.resetArmed = false;
                                        resetTimer.stop();
                                        win.applyBatch(win.defaults);
                                    } else {
                                        win.resetArmed = true;
                                        resetTimer.restart();
                                    }
                                }
                            }
                            Hint { text: SnowConfig.tr("resetHint") }

                            SecTitle { text: SnowConfig.tr("how") }
                            Hint { text: SnowConfig.tr("h1") }
                            Hint { text: SnowConfig.tr("h2") }
                            Hint { text: SnowConfig.tr("h3") }
                            Hint { text: SnowConfig.tr("h4") }
                        }
                    }
                }
            }

            // ===== page 2: collection =====
            Flickable {
                id: f3
                anchors.fill: parent
                visible: opacity > 0.01
                opacity: win.tab === 1 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 220 } }
                transform: Translate {
                    x: win.tab === 1 ? 0 : 26
                    Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                }
                contentWidth: width
                contentHeight: c3.height + 16
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: c3
                    width: f3.width
                    spacing: 12

                    Item {
                        id: collHead
                        width: parent.width
                        height: 50
                        property real shim: 0
                        NumberAnimation on shim {
                            from: 0
                            to: 1
                            duration: 2000
                            loops: Animation.Infinite
                            running: win.visible && win.tab === 1
                        }
                        Text { x: 0; y: 0; text: SnowConfig.tr("collection"); color: "#eef2f6"; font.pixelSize: 15; font.weight: Font.DemiBold }
                        Text {
                            anchors.right: parent.right
                            y: 0
                            text: win.foundCount + " / " + SnowTypes.list.length
                            color: SnowConfig.accent
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }
                        Rectangle {
                            y: 30
                            width: parent.width
                            height: 8
                            radius: 4
                            color: "#2a2f37"
                            Rectangle {
                                id: fillBar
                                width: parent.width * win.foundCount / SnowTypes.list.length
                                height: parent.height
                                radius: 4
                                color: SnowConfig.accent
                                clip: true
                                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                Rectangle {
                                    width: 36
                                    height: parent.height
                                    x: collHead.shim * (fillBar.width + 36) - 36
                                    color: "#55ffffff"
                                }
                            }
                        }
                    }

                    Hint { text: SnowConfig.tr("collHint") }
                    Grid {
                        columns: 2
                        spacing: 12
                        Repeater {
                            model: SnowTypes.list.length
                            TypeCard {
                                tid: index
                                count: win.found[index] || 0
                                onSummon: function(t) { if (win.world) win.world.spawnType(t); }
                            }
                        }
                    }
                }
            }
        }
    }
}
