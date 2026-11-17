import QtQuick

Item {
    id: sm

    property var host: null
    property bool preview: false
    property bool summoned: false
    property int typeId: 0
    property real cx: 0
    property real baseY: 0
    property real d1: 40
    property real d2: 26
    property real vy: 0
    property bool falling: false
    property bool melting: false
    property bool hopping: false
    property bool held: false
    property real offX: 0
    property real offY: 0

    property real blink: 1
    property real winkR: 1
    property real look: 0
    property real breath: 1
    property real jump: 0
    property real shake: 0
    property real headTilt: 0
    property real cheekOp: 0.6
    property real waveL: 0
    property real waveR: 0
    property real armUp: held ? 1 : 0
    property real lift: 0
    property real hue: 0
    property real burst: 0
    property real flash: 0
    property real bannerOp: 0
    property real shuriken: 0
    property real tip: 0
    // ---- snow_patch20: танці ----
    readonly property bool lite: host ? host.saving : false
    readonly property bool dancing: !!host && !preview && SnowConfig.dance && host.musicPlaying && !host.suspended && !melting && !held && !falling
    readonly property int beat: kind === "king" ? 700 : 500
    readonly property real danceH: floaty ? d1 * 0.07 : d1 * 0.16
    property int phase: Math.floor(Math.random() * 500)
    // ---- /snow_patch20 ----

    readonly property var tp: SnowTypes.list[typeId] || SnowTypes.list[0]
    readonly property string kind: tp.key
    readonly property bool floaty: kind === "astro" || kind === "frost"
    readonly property color rcol: SnowTypes.tiers[tp.tier].color
    readonly property color bodyCol: kind === "frost" ? Qt.hsla(hue, 0.45, 0.9, 1) : tp.body
    readonly property color edgeCol: kind === "frost" ? Qt.hsla(hue, 0.6, 0.7, 1) : tp.edge
    readonly property real eyeK: 1 + 0.35 * armUp
    readonly property real hatH: d2 * tp.hatK
    readonly property real bodyH: d1 + d2 * 0.82
    readonly property real bodyTop: hatH + d2 * 0.82
    readonly property real midX: width / 2
    readonly property real neckY: hatH + d2 * 0.92
    readonly property real hitW: d1 * 1.7
    readonly property real hitX: cx - hitW / 2
    readonly property real hitY: baseY - height
    readonly property real hitH: height
    readonly property int confettiN: (preview || lite) ? 0 : (tp.tier >= 5 ? 30 : (tp.tier >= 4 ? 22 : (tp.tier >= 2 ? 12 : 0)))
    readonly property int sparkN: lite ? 0 : tp.tier >= 5 ? 8 : (tp.tier >= 3 ? 5 : 3)

    width: d1 * 2.4
    height: hatH + bodyH
    x: cx - width / 2
    y: baseY - height + jump - lift
    z: 5
    scale: 0.2
    transformOrigin: Item.Bottom
    transform: [
        Scale {
            origin.x: sm.midX
            origin.y: sm.height
            xScale: (2 - sm.breath) * (1 + 0.08 * sm.armUp)
            yScale: sm.breath * (1 + 0.08 * sm.armUp)
        },
        Rotation {
            origin.x: sm.midX
            origin.y: sm.height
            angle: sm.shake
        }
    ]

    Behavior on baseY {
        enabled: !sm.falling && !sm.held
        NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
    }
    Behavior on look { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }
    Behavior on armUp { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

    onHeldChanged: { if (!held) shake = 0; }
    onFallingChanged: { if (!falling && !preview) landAnim.restart(); }
    onDancingChanged: {
        if (dancing) {
            if (!hopping) danceStart.restart();
        } else {
            danceStart.stop();
            danceAnim.stop();
            hopL.stop();
            hopR.stop();
            resetAnim.restart();
        }
    }
    onHoppingChanged: {
        if (hopping) {
            danceStart.stop();
            danceAnim.stop();
            hopL.stop();
            hopR.stop();
            waveL = 0;
            waveR = 0;
            shake = 0;
        } else if (dancing) {
            danceStart.restart();
        }
    }

    // ---- snow_patch17 ----
    function hopNow() {
        if (falling || hopping || held || melting || preview) return;
        hop.restart();
    }
    // ---- /snow_patch17 ----

    function melt() {
        if (melting) return;
        melting = true;
        appear.stop();
        if (host) host.onBallSplat(cx, baseY, d1 * 1.2);
        meltAnim.start();
    }

    function grab(gx, gy) {
        held = true;
        falling = false;
        vy = 0;
        offX = cx - gx;
        offY = baseY - gy;
    }

    function dragTo(gx, gy) {
        if (!held) return;
        var hw = host ? host.width : 100000;
        cx = Math.max(12, Math.min(hw - 12, gx + offX));
        baseY = gy + offY;
    }

    function drop() {
        held = false;
    }

    Component.onCompleted: {
        appear.start();
        if (host) host.registerSnowman(sm);
        if (dancing) danceStart.restart();
        if (!preview) {
            if (SnowConfig.announce && tp.tier >= 1) bannerAnim.start();
            if (confettiN > 0) burstAnim.start();
            if (tp.tier >= 4) flashAnim.start();
        }
    }

    Component.onDestruction: {
        if (host) host.unregisterSnowman(sm);
    }

    // ================= animations =================

    NumberAnimation {
        id: appear
        target: sm
        property: "scale"
        from: 0.2
        to: 1
        duration: 650
        easing.type: Easing.OutBack
    }

    ParallelAnimation {
        id: meltAnim
        NumberAnimation { target: sm; property: "scale"; to: 0.1; duration: 500; easing.type: Easing.InQuad }
        NumberAnimation { target: sm; property: "opacity"; to: 0; duration: 500 }
        onFinished: sm.destroy()
    }

    SequentialAnimation on rotation {
        loops: Animation.Infinite
        running: !sm.melting && !sm.falling && !sm.held
        NumberAnimation { to: 1.6; duration: 2200; easing.type: Easing.InOutSine }
        NumberAnimation { to: -1.6; duration: 2200; easing.type: Easing.InOutSine }
    }

    SequentialAnimation {
        id: breathAnim
        loops: Animation.Infinite
        running: !sm.melting && !sm.hopping && !sm.dancing
        NumberAnimation { target: sm; property: "breath"; to: 1.025; duration: 1300; easing.type: Easing.InOutSine }
        NumberAnimation { target: sm; property: "breath"; to: 1; duration: 1300; easing.type: Easing.InOutSine }
    }

    SequentialAnimation on headTilt {
        loops: Animation.Infinite
        running: !sm.melting
        NumberAnimation { to: 3.5; duration: 1700; easing.type: Easing.InOutSine }
        NumberAnimation { to: -2.5; duration: 2100; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0; duration: 900; easing.type: Easing.InOutSine }
        PauseAnimation { duration: 1500 }
    }

    SequentialAnimation on cheekOp {
        loops: Animation.Infinite
        running: !sm.melting
        NumberAnimation { to: 0.95; duration: 1400; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.55; duration: 1400; easing.type: Easing.InOutSine }
    }

    SequentialAnimation on lift {
        loops: Animation.Infinite
        running: sm.floaty && !sm.melting && !sm.held
        NumberAnimation { to: sm.d1 * 0.16; duration: 1500; easing.type: Easing.InOutSine }
        NumberAnimation { to: sm.d1 * 0.03; duration: 1500; easing.type: Easing.InOutSine }
    }

    NumberAnimation on hue {
        from: 0
        to: 1
        duration: 9000
        loops: Animation.Infinite
        running: sm.kind === "frost"
    }

    SequentialAnimation {
        running: sm.held
        loops: Animation.Infinite
        NumberAnimation { target: sm; property: "shake"; to: 5; duration: 130 }
        NumberAnimation { target: sm; property: "shake"; to: -5; duration: 130 }
    }

    SequentialAnimation {
        id: hop
        ScriptAction { script: sm.hopping = true }
        NumberAnimation { target: sm; property: "breath"; to: 0.88; duration: 160; easing.type: Easing.OutQuad }
        ParallelAnimation {
            NumberAnimation { target: sm; property: "jump"; to: -sm.d1 * 0.4; duration: 260; easing.type: Easing.OutQuad }
            NumberAnimation { target: sm; property: "breath"; to: 1.08; duration: 260 }
        }
        ParallelAnimation {
            NumberAnimation { target: sm; property: "jump"; to: 0; duration: 260; easing.type: Easing.InQuad }
            NumberAnimation { target: sm; property: "breath"; to: 1; duration: 260 }
        }
        NumberAnimation { target: sm; property: "breath"; to: 0.9; duration: 90 }
        NumberAnimation { target: sm; property: "breath"; to: 1; duration: 220; easing.type: Easing.OutBack }
        ScriptAction { script: sm.hopping = false }
    }

    SequentialAnimation {
        id: landAnim
        ScriptAction { script: sm.hopping = true }
        NumberAnimation { target: sm; property: "breath"; to: 0.86; duration: 90 }
        NumberAnimation { target: sm; property: "breath"; to: 1; duration: 280; easing.type: Easing.OutBack }
        ScriptAction { script: sm.hopping = false }
    }

    SequentialAnimation {
        id: blinkAnim
        NumberAnimation { target: sm; property: "blink"; to: 0.1; duration: 70 }
        NumberAnimation { target: sm; property: "blink"; to: 1; duration: 100 }
    }

    SequentialAnimation {
        id: winkAnim
        NumberAnimation { target: sm; property: "winkR"; to: 0.1; duration: 90 }
        PauseAnimation { duration: 260 }
        NumberAnimation { target: sm; property: "winkR"; to: 1; duration: 120 }
    }

    SequentialAnimation {
        id: waveRAnim
        NumberAnimation { target: sm; property: "waveR"; to: 47; duration: 200 }
        NumberAnimation { target: sm; property: "waveR"; to: -3; duration: 200 }
        NumberAnimation { target: sm; property: "waveR"; to: 47; duration: 200 }
        NumberAnimation { target: sm; property: "waveR"; to: -3; duration: 200 }
        NumberAnimation { target: sm; property: "waveR"; to: 0; duration: 220 }
    }

    SequentialAnimation {
        id: waveLAnim
        NumberAnimation { target: sm; property: "waveL"; to: 47; duration: 200 }
        NumberAnimation { target: sm; property: "waveL"; to: -3; duration: 200 }
        NumberAnimation { target: sm; property: "waveL"; to: 47; duration: 200 }
        NumberAnimation { target: sm; property: "waveL"; to: -3; duration: 200 }
        NumberAnimation { target: sm; property: "waveL"; to: 0; duration: 220 }
    }

    SequentialAnimation {
        id: tipAnim
        NumberAnimation { target: sm; property: "tip"; to: 1; duration: 260; easing.type: Easing.OutQuad }
        PauseAnimation { duration: 650 }
        NumberAnimation { target: sm; property: "tip"; to: 0; duration: 300; easing.type: Easing.InOutQuad }
    }

    NumberAnimation {
        id: shurAnim
        target: sm
        property: "shuriken"
        from: 0
        to: 1
        duration: 750
    }

    SequentialAnimation {
        id: bannerAnim
        PauseAnimation { duration: 500 }
        NumberAnimation { target: sm; property: "bannerOp"; to: 1; duration: 320; easing.type: Easing.OutBack }
        PauseAnimation { duration: 3200 }
        NumberAnimation { target: sm; property: "bannerOp"; to: 0; duration: 700 }
    }

    SequentialAnimation {
        id: burstAnim
        PauseAnimation { duration: 350 }
        NumberAnimation { target: sm; property: "burst"; from: 0; to: 1; duration: 1500; easing.type: Easing.OutCubic }
    }

    SequentialAnimation {
        id: flashAnim
        PauseAnimation { duration: 300 }
        NumberAnimation { target: sm; property: "flash"; from: 0; to: 1; duration: 900; easing.type: Easing.OutQuad }
    }

    // ---- snow_patch20: анімація танцю ----
    Timer {
        id: danceStart
        interval: sm.phase
        onTriggered: { if (sm.dancing && !sm.hopping && !sm.beatDriven) danceAnim.restart(); }
    }

    SequentialAnimation {
        id: danceAnim
        loops: Animation.Infinite
        ParallelAnimation {
            NumberAnimation { target: sm; property: "jump"; to: -sm.danceH; duration: sm.beat / 2; easing.type: Easing.OutQuad }
            NumberAnimation { target: sm; property: "breath"; to: 1.05; duration: sm.beat / 2 }
            NumberAnimation { target: sm; property: "waveL"; to: 40; duration: sm.beat / 2 }
            NumberAnimation { target: sm; property: "waveR"; to: 0; duration: sm.beat / 2 }
            NumberAnimation { target: sm; property: "shake"; to: 4; duration: sm.beat / 2 }
        }
        ParallelAnimation {
            NumberAnimation { target: sm; property: "jump"; to: 0; duration: sm.beat / 2; easing.type: Easing.InQuad }
            NumberAnimation { target: sm; property: "breath"; to: 0.95; duration: sm.beat / 2 }
            NumberAnimation { target: sm; property: "shake"; to: 1.5; duration: sm.beat / 2 }
        }
        ParallelAnimation {
            NumberAnimation { target: sm; property: "jump"; to: -sm.danceH; duration: sm.beat / 2; easing.type: Easing.OutQuad }
            NumberAnimation { target: sm; property: "breath"; to: 1.05; duration: sm.beat / 2 }
            NumberAnimation { target: sm; property: "waveL"; to: 0; duration: sm.beat / 2 }
            NumberAnimation { target: sm; property: "waveR"; to: 40; duration: sm.beat / 2 }
            NumberAnimation { target: sm; property: "shake"; to: -4; duration: sm.beat / 2 }
        }
        ParallelAnimation {
            NumberAnimation { target: sm; property: "jump"; to: 0; duration: sm.beat / 2; easing.type: Easing.InQuad }
            NumberAnimation { target: sm; property: "breath"; to: 0.95; duration: sm.beat / 2 }
            NumberAnimation { target: sm; property: "shake"; to: -1.5; duration: sm.beat / 2 }
        }
    }

    ParallelAnimation {
        id: resetAnim
        NumberAnimation { target: sm; property: "jump"; to: 0; duration: 220; easing.type: Easing.OutQuad }
        NumberAnimation { target: sm; property: "breath"; to: 1; duration: 220 }
        NumberAnimation { target: sm; property: "waveL"; to: 0; duration: 220 }
        NumberAnimation { target: sm; property: "waveR"; to: 0; duration: 220 }
        NumberAnimation { target: sm; property: "shake"; to: 0; duration: 220 }
    }

    Timer {
        interval: 3500
        repeat: true
        running: sm.dancing && sm.kind === "ninja"
        onTriggered: shurAnim.restart()
    }

    // ---- ритм: стрибок на кожен удар музики ----
    readonly property bool beatDriven: BeatEngine.active
    readonly property int hopMs: Math.max(300, Math.min(900, BeatEngine.beatMs))
    property int beatIdx: 0
    property real hopK: 1

    onBeatDrivenChanged: {
        if (beatDriven) danceAnim.stop();
        else if (dancing && !hopping) danceStart.restart();
    }

    function beatKick(strength) {
        if (!dancing || hopping || !beatDriven) return;
        beatIdx++;
        if (kind === "king" && beatIdx % 2 === 1) return;
        hopK = 0.65 + 0.35 * Math.max(0, Math.min(1, strength));
        if (beatIdx % 2 === 0) {
            hopR.stop();
            hopL.restart();
        } else {
            hopL.stop();
            hopR.restart();
        }
    }

    Connections {
        target: BeatEngine
        enabled: sm.dancing && sm.beatDriven
        function onBeatCountChanged() { sm.beatKick(BeatEngine.pulse); }
    }

    SequentialAnimation {
        id: hopL
        ParallelAnimation {
            NumberAnimation { target: sm; property: "jump"; to: -sm.danceH * sm.hopK; duration: sm.hopMs * 0.42; easing.type: Easing.OutQuad }
            NumberAnimation { target: sm; property: "breath"; to: 1.05; duration: sm.hopMs * 0.42 }
            NumberAnimation { target: sm; property: "waveL"; to: 40; duration: sm.hopMs * 0.3 }
            NumberAnimation { target: sm; property: "waveR"; to: 0; duration: sm.hopMs * 0.3 }
            NumberAnimation { target: sm; property: "shake"; to: 4; duration: sm.hopMs * 0.42 }
        }
        ParallelAnimation {
            NumberAnimation { target: sm; property: "jump"; to: 0; duration: sm.hopMs * 0.48; easing.type: Easing.InQuad }
            NumberAnimation { target: sm; property: "breath"; to: 0.95; duration: sm.hopMs * 0.48 }
            NumberAnimation { target: sm; property: "shake"; to: 1.5; duration: sm.hopMs * 0.48 }
        }
    }

    SequentialAnimation {
        id: hopR
        ParallelAnimation {
            NumberAnimation { target: sm; property: "jump"; to: -sm.danceH * sm.hopK; duration: sm.hopMs * 0.42; easing.type: Easing.OutQuad }
            NumberAnimation { target: sm; property: "breath"; to: 1.05; duration: sm.hopMs * 0.42 }
            NumberAnimation { target: sm; property: "waveL"; to: 0; duration: sm.hopMs * 0.3 }
            NumberAnimation { target: sm; property: "waveR"; to: 40; duration: sm.hopMs * 0.3 }
            NumberAnimation { target: sm; property: "shake"; to: -4; duration: sm.hopMs * 0.42 }
        }
        ParallelAnimation {
            NumberAnimation { target: sm; property: "jump"; to: 0; duration: sm.hopMs * 0.48; easing.type: Easing.InQuad }
            NumberAnimation { target: sm; property: "breath"; to: 0.95; duration: sm.hopMs * 0.48 }
            NumberAnimation { target: sm; property: "shake"; to: -1.5; duration: sm.hopMs * 0.48 }
        }
    }

    // ---- /snow_patch20 ----

    // ================= timers =================

    Timer {
        interval: 250
        repeat: true
        running: !sm.melting && !sm.held && !sm.preview
        onTriggered: {
            if (!sm.host || sm.held) return;
            var sy = sm.host.surfaceY(sm.cx, sm.baseY - 30);
            if (!sm.falling && sy - sm.baseY > 3) {
                sm.falling = true;
                sm.vy = 0;
            } else if (!sm.falling) {
                sm.baseY = sy;
            }
        }
    }

    Timer {
        id: fall
        property real lastT: 0
        interval: 16
        repeat: true
        running: sm.falling && !sm.held
        onRunningChanged: { if (running) lastT = Date.now(); }
        onTriggered: {
            var t = Date.now();
            var dt = Math.min(0.033, (t - lastT) / 1000);
            lastT = t;
            sm.vy += 1100 * dt;
            var nb = sm.baseY + sm.vy * dt;
            var sy = sm.host ? sm.host.surfaceY(sm.cx, sm.baseY - 8) : 1e9;
            if (nb >= sy) {
                sm.baseY = sy;
                sm.vy = 0;
                sm.falling = false;
            } else {
                sm.baseY = nb;
            }
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: !sm.melting
        onTriggered: {
            if (Math.random() < 0.2) winkAnim.restart();
            else blinkAnim.restart();
            interval = 2200 + Math.random() * 3500;
        }
    }

    Timer {
        interval: 2500
        repeat: true
        running: !sm.melting
        onTriggered: {
            var opts = [-1, 0, 1, 0];
            sm.look = opts[Math.floor(Math.random() * 4)];
            interval = 1800 + Math.random() * 2600;
        }
    }

    Timer {
        interval: 6500
        repeat: true
        running: !sm.melting && !sm.held && !sm.dancing
        onTriggered: {
            if (Math.random() < 0.5) waveRAnim.restart();
            else waveLAnim.restart();
            interval = 6000 + Math.random() * 5000;
        }
    }

    Timer {
        interval: 9000
        repeat: true
        running: !sm.melting
        onTriggered: {
            if (!sm.falling && !sm.hopping && !sm.held && !sm.dancing) hop.restart();
            interval = 8000 + Math.random() * 8000;
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: sm.kind === "gent" && !sm.melting
        onTriggered: {
            tipAnim.restart();
            interval = 5000 + Math.random() * 4000;
        }
    }

    Timer {
        interval: 6000
        repeat: true
        running: sm.kind === "ninja" && !sm.melting && !sm.held
        onTriggered: {
            shurAnim.restart();
            waveRAnim.restart();
            interval = 6000 + Math.random() * 5000;
        }
    }

    // ================= behind the body =================

    Loader {
        anchors.fill: parent
        sourceComponent: sm.kind === "king" ? capeComp : (sm.kind === "frost" ? auraComp : (sm.kind === "astro" ? shadowComp : null))
    }

    // ================= body =================

    Rectangle {
        x: (sm.width - sm.d1) / 2
        y: sm.bodyTop
        width: sm.d1
        height: sm.d1
        radius: width / 2
        color: sm.bodyCol
        border.color: sm.edgeCol
        border.width: 1
    }
    Rectangle {
        x: sm.midX - sm.d1 * 0.28
        y: sm.bodyTop + sm.d1 * 0.62
        width: sm.d1 * 0.16
        height: width
        radius: width / 2
        color: Qt.rgba(0.75, 0.85, 0.96, 0.45)
    }
    Rectangle {
        x: sm.midX + sm.d1 * 0.14
        y: sm.bodyTop + sm.d1 * 0.76
        width: sm.d1 * 0.12
        height: width
        radius: width / 2
        color: Qt.rgba(0.75, 0.85, 0.96, 0.45)
    }

    Repeater {
        model: sm.tp.buttons
        Rectangle {
            width: Math.max(2.4, sm.d1 * 0.07)
            height: width
            radius: width / 2
            color: modelData
            x: sm.midX - width / 2
            y: sm.bodyTop + sm.d1 * (0.3 + index * 0.17)
        }
    }

    Loader {
        anchors.fill: parent
        sourceComponent: sm.kind === "santa" ? beltComp : (sm.kind === "cowboy" ? starComp : (sm.kind === "cozy" ? mugComp : null))
    }

    // arms
    Rectangle {
        id: armL
        width: sm.d1 * 0.55
        height: Math.max(1.8, sm.d1 * 0.06)
        radius: height / 2
        color: sm.tp.arm
        x: sm.midX - sm.d1 / 2 + sm.d1 * 0.1 - width
        y: sm.bodyTop + sm.d1 * 0.34
        transformOrigin: Item.Right
        rotation: 28 + sm.waveL + sm.armUp * 45
        Repeater {
            model: 2
            Rectangle {
                width: parent.width * 0.3
                height: parent.height * 0.9
                radius: height / 2
                color: sm.tp.arm
                x: 0
                y: 0
                transformOrigin: Item.Right
                rotation: index === 0 ? 38 : -38
            }
        }
    }
    Rectangle {
        id: armR
        width: sm.d1 * 0.55
        height: Math.max(1.8, sm.d1 * 0.06)
        radius: height / 2
        color: sm.tp.arm
        x: sm.midX + sm.d1 / 2 - sm.d1 * 0.1
        y: sm.bodyTop + sm.d1 * 0.34
        transformOrigin: Item.Left
        rotation: -(28 + sm.waveR + sm.armUp * 45)
        Repeater {
            model: 2
            Rectangle {
                width: parent.width * 0.3
                height: parent.height * 0.9
                radius: height / 2
                color: sm.tp.arm
                x: parent.width * 0.7
                y: 0
                transformOrigin: Item.Left
                rotation: index === 0 ? 38 : -38
            }
        }
    }

    // ================= head =================

    Item {
        id: headG
        width: sm.width
        height: sm.height
        transform: Rotation {
            origin.x: sm.midX
            origin.y: sm.neckY
            angle: sm.headTilt
        }

        Rectangle {
            x: (sm.width - sm.d2) / 2
            y: sm.hatH
            width: sm.d2
            height: sm.d2
            radius: width / 2
            color: sm.bodyCol
            border.color: sm.edgeCol
            border.width: 1
        }

        Loader {
            anchors.fill: parent
            sourceComponent: {
                switch (sm.kind) {
                case "classic":
                case "cozy": return hatBeanie;
                case "gent": return hatTop;
                case "pirate": return hatPirate;
                case "ninja": return hatNinja;
                case "cowboy": return hatCowboy;
                case "king": return hatKing;
                case "santa": return hatSanta;
                case "frost": return hatFrost;
                default: return null;
                }
            }
        }

        // eyes
        Repeater {
            model: 2
            Rectangle {
                property real e: Math.max(2.6, sm.d2 * 0.15) * sm.eyeK
                property real f: index === 0 ? sm.blink : Math.min(sm.blink, sm.winkR)
                property real sq: sm.kind === "ninja" ? 0.75 : 1
                width: e
                height: e * 1.15 * f * sq
                radius: width / 2
                color: "#232733"
                x: sm.midX + (index === 0 ? -1 : 1) * sm.d2 * 0.22 - e / 2 + sm.look * sm.d2 * 0.03
                y: sm.hatH + sm.d2 * 0.4 + e * 1.15 * sq * (1 - f) / 2
                Rectangle {
                    visible: parent.f > 0.5
                    width: parent.e * 0.38
                    height: width
                    radius: width / 2
                    color: "white"
                    x: parent.e * 0.42
                    y: parent.e * 0.14
                }
            }
        }

        // cheeks
        Repeater {
            model: 2
            Rectangle {
                width: sm.d2 * 0.17
                height: sm.d2 * 0.11
                radius: height / 2
                color: sm.tp.cheek
                opacity: sm.cheekOp
                x: sm.midX + (index === 0 ? -1 : 1) * sm.d2 * 0.31 - width / 2
                y: sm.hatH + sm.d2 * 0.57
            }
        }

        // nose
        Rectangle {
            width: sm.d2 * 0.15
            height: sm.d2 * 0.17
            radius: width / 2
            color: "#ff8a1f"
            x: sm.midX - width / 2
            y: sm.hatH + sm.d2 * 0.5
        }

        // smile
        Item {
            id: mouth
            visible: !sm.held
            width: sm.d2 * 0.34
            height: sm.d2 * 0.16
            x: sm.midX - width / 2
            y: sm.hatH + sm.d2 * 0.7
            clip: true
            transformOrigin: Item.Top

            SequentialAnimation on scale {
                loops: Animation.Infinite
                running: !sm.melting
                PauseAnimation { duration: 2600 }
                NumberAnimation { to: 1.25; duration: 260; easing.type: Easing.OutQuad }
                NumberAnimation { to: 1; duration: 340; easing.type: Easing.InOutQuad }
            }

            Rectangle {
                y: -mouth.height
                width: mouth.width
                height: mouth.height * 2
                radius: mouth.height
                color: "#3a2230"
            }
            Rectangle {
                width: mouth.width * 0.5
                height: mouth.height * 0.5
                radius: height / 2
                color: "#ff7f9a"
                x: (mouth.width - width) / 2
                y: mouth.height * 0.6
            }
        }

        // surprised "O" while being dragged
        Rectangle {
            visible: sm.held
            width: sm.d2 * 0.15
            height: sm.d2 * 0.19
            radius: width / 2
            color: "#3a2230"
            x: sm.midX - width / 2
            y: sm.hatH + sm.d2 * 0.68
        }

        Loader {
            anchors.fill: parent
            sourceComponent: {
                switch (sm.kind) {
                case "gent": return fgMonocle;
                case "pirate": return fgPatch;
                case "ninja": return fgBrows;
                case "santa": return fgMustache;
                case "astro": return fgHelmet;
                default: return null;
                }
            }
        }

        Loader {
            anchors.fill: parent
            sourceComponent: {
                switch (sm.kind) {
                case "gent": return neckBow;
                case "king": return neckCollar;
                case "astro": return neckRing;
                case "santa":
                case "pirate": return null;
                default: return neckScarf;
                }
            }
        }
    }

    // ================= orbiting / sparkles / effects =================

    Loader {
        anchors.fill: parent
        sourceComponent: (sm.kind === "frost" || sm.kind === "astro") ? orbitComp : null
    }

    Repeater {
        model: sm.sparkN
        Rectangle {
            property var px: [-0.62, 0.66, 0.5, -0.7, 0.1, 0.8, -0.4, 0.3]
            property var py: [0.22, 0.05, 0.62, 0.7, 0.0, 0.4, 0.15, 0.85]
            width: Math.max(3, sm.d2 * 0.14)
            height: width
            rotation: 45
            color: sm.tp.tier >= 3 ? sm.rcol : "white"
            opacity: 0
            x: sm.midX + px[index] * sm.d1 * 1.1 - width / 2
            y: sm.height * py[index]

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: !sm.melting
                PauseAnimation { duration: 600 + index * 700 }
                NumberAnimation { to: 0.95; duration: 220 }
                NumberAnimation { to: 0; duration: 520 }
                PauseAnimation { duration: 1800 }
            }
            SequentialAnimation on scale {
                loops: Animation.Infinite
                running: !sm.melting
                PauseAnimation { duration: 600 + index * 700 }
                NumberAnimation { from: 0.4; to: 1.3; duration: 740 }
                PauseAnimation { duration: 1800 }
            }
        }
    }

    Rectangle {
        visible: sm.flash > 0 && sm.flash < 1
        width: sm.d1 * (1 + sm.flash * 5)
        height: width
        radius: width / 2
        x: sm.midX - width / 2
        y: sm.height * 0.55 - height / 2
        color: "transparent"
        border.width: 3
        border.color: sm.rcol
        opacity: 1 - sm.flash
    }

    Item {
        id: shurikenItem
        visible: sm.shuriken > 0 && sm.shuriken < 1
        x: sm.midX + sm.d1 * 0.4 + sm.shuriken * sm.d1 * 3.4
        y: sm.bodyTop + sm.d1 * 0.15 - sm.shuriken * sm.d1 * 0.5
        rotation: sm.shuriken * 1080
        opacity: 1 - sm.shuriken * sm.shuriken * sm.shuriken
        Rectangle { x: -sm.d1 * 0.1; y: -sm.d1 * 0.03; width: sm.d1 * 0.2; height: sm.d1 * 0.06; radius: 1; color: "#c3ccd8" }
        Rectangle { x: -sm.d1 * 0.03; y: -sm.d1 * 0.1; width: sm.d1 * 0.06; height: sm.d1 * 0.2; radius: 1; color: "#c3ccd8" }
    }

    Repeater {
        model: sm.confettiN
        Rectangle {
            readonly property real ang: index * 2.399963
            readonly property real rad: sm.d1 * (1.0 + (index % 5) * 0.32)
            width: 4 + (index % 3) * 1.5
            height: width * 1.6
            radius: 1
            color: index % 3 === 0 ? sm.rcol : (index % 3 === 1 ? "#ffffff" : "#ffd96a")
            x: sm.midX + Math.cos(ang) * rad * sm.burst - width / 2
            y: sm.height * 0.35 + Math.sin(ang) * rad * 0.8 * sm.burst + sm.d1 * 1.2 * sm.burst * sm.burst
            rotation: sm.burst * 540 * (index % 2 === 0 ? 1 : -1)
            opacity: sm.burst > 0 ? Math.max(0, 1 - sm.burst * sm.burst) : 0
        }
    }

    Repeater {
        model: (sm.dancing && !sm.lite) ? 3 : 0
        Text {
            id: note
            text: index % 2 === 0 ? "♪" : "♫"
            color: sm.tp.tier >= 3 ? sm.rcol : "#e6eaee"
            font.pixelSize: Math.max(11, sm.d2 * 0.5)
            x: sm.midX + (index - 1) * sm.d1 * 0.6 - width / 2
            y: sm.hatH
            opacity: 0
            SequentialAnimation {
                running: true
                loops: Animation.Infinite
                PauseAnimation { duration: index * 500 }
                ParallelAnimation {
                    NumberAnimation { target: note; property: "y"; from: sm.hatH; to: -sm.d1 * 0.5; duration: 1800; easing.type: Easing.OutQuad }
                    SequentialAnimation {
                        NumberAnimation { target: note; property: "opacity"; to: 0.9; duration: 250 }
                        NumberAnimation { target: note; property: "opacity"; to: 0; duration: 1550 }
                    }
                }
            }
        }
    }

    Rectangle {
        id: banner
        visible: sm.bannerOp > 0.01
        opacity: sm.bannerOp
        width: Math.max(bnName.implicitWidth, bnTier.implicitWidth) + 26
        height: 46
        radius: 12
        x: sm.midX - width / 2
        y: -height - 10 + (1 - sm.bannerOp) * 10
        z: 20
        color: Qt.rgba(0.05, 0.08, 0.12, 0.92)
        border.width: 1
        border.color: sm.rcol

        Column {
            anchors.centerIn: parent
            spacing: 2
            Text {
                id: bnName
                anchors.horizontalCenter: parent.horizontalCenter
                text: (sm.tp.tier >= 5 ? "✦ " : "") + sm.tp.name + (sm.tp.tier >= 5 ? " ✦" : "")
                color: "#f4f9ff"
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
            Text {
                id: bnTier
                anchors.horizontalCenter: parent.horizontalCenter
                text: SnowTypes.tiers[sm.tp.tier].name.toUpperCase() + " · " + sm.tp.weight + "%"
                color: sm.rcol
                font.pixelSize: 9
                font.letterSpacing: 1.2
            }
        }
    }

    // ================= components: behind =================

    Component {
        id: capeComp
        Item {
            Rectangle {
                id: cape
                x: sm.midX - sm.d1 * 0.62
                y: sm.bodyTop + sm.d1 * 0.1
                width: sm.d1 * 1.24
                height: sm.d1 * 0.98
                radius: sm.d1 * 0.5
                color: "#b3202a"
                border.color: "#8c1620"
                border.width: 1
                transformOrigin: Item.Top
                SequentialAnimation on rotation {
                    loops: Animation.Infinite
                    running: !sm.melting
                    NumberAnimation { to: 1.6; duration: 1800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -1.6; duration: 1800; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    Component {
        id: shadowComp
        Item {
            Rectangle {
                width: Math.max(4, sm.d1 * 0.95 - sm.lift * 1.3)
                height: 6
                radius: 3
                color: Qt.rgba(0, 0, 0, 0.25)
                x: sm.midX - width / 2
                y: sm.height + sm.lift - 3
            }
        }
    }

    Component {
        id: auraComp
        Item {
            Rectangle {
                width: Math.max(4, sm.d1 * 0.95 - sm.lift * 1.3)
                height: 6
                radius: 3
                color: Qt.rgba(0, 0, 0, 0.25)
                x: sm.midX - width / 2
                y: sm.height + sm.lift - 3
            }
            Repeater {
                model: 3
                Rectangle {
                    width: sm.d1 * (1.5 + index * 0.55)
                    height: width
                    radius: width / 2
                    x: sm.midX - width / 2
                    y: sm.height * 0.58 - height / 2
                    color: Qt.hsla(sm.hue, 0.6, 0.8, 0.12 - index * 0.03)
                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        running: !sm.melting
                        PauseAnimation { duration: index * 350 }
                        NumberAnimation { to: 1.08; duration: 1500; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.92; duration: 1500; easing.type: Easing.InOutSine }
                    }
                }
            }
        }
    }

    // ================= components: body fx =================

    Component {
        id: beltComp
        Item {
            Rectangle {
                x: sm.midX - sm.d1 * 0.46
                y: sm.bodyTop + sm.d1 * 0.6
                width: sm.d1 * 0.92
                height: sm.d1 * 0.13
                color: "#1f2229"
            }
            Rectangle {
                x: sm.midX - sm.d1 * 0.08
                y: sm.bodyTop + sm.d1 * 0.585
                width: sm.d1 * 0.16
                height: sm.d1 * 0.16
                radius: 2
                color: "#f2c230"
                border.color: "#b8860b"
                border.width: 1
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: !sm.melting
                    NumberAnimation { to: 0.7; duration: 700; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    Component {
        id: starComp
        Item {
            Item {
                x: sm.midX
                y: sm.bodyTop + sm.d1 * 0.38
                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    running: !sm.melting
                    NumberAnimation { to: 1.18; duration: 650; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.95; duration: 650; easing.type: Easing.InOutSine }
                }
                Rectangle { x: -sm.d1 * 0.11; y: -sm.d1 * 0.11; width: sm.d1 * 0.22; height: width; color: "#f5c518"; border.color: "#c99a14"; border.width: 1 }
                Rectangle { x: -sm.d1 * 0.11; y: -sm.d1 * 0.11; width: sm.d1 * 0.22; height: width; color: "#f5c518"; border.color: "#c99a14"; border.width: 1; rotation: 45 }
                Rectangle { x: -sm.d1 * 0.04; y: -sm.d1 * 0.04; width: sm.d1 * 0.08; height: width; radius: width / 2; color: "#fff3b0" }
            }
        }
    }

    Component {
        id: mugComp
        Item {
            id: mugRoot
            readonly property real mx: sm.midX + sm.d1 * 0.74
            readonly property real my: sm.bodyTop - sm.d1 * 0.02
            Rectangle {
                x: mugRoot.mx
                y: mugRoot.my
                width: sm.d1 * 0.2
                height: sm.d1 * 0.24
                radius: 4
                color: "#f2e6d8"
                border.color: "#c9b8a2"
                border.width: 1
                Rectangle { x: 0; y: parent.height * 0.4; width: parent.width; height: parent.height * 0.16; color: "#d9433f" }
                Rectangle { x: 0; y: 0; width: parent.width; height: 3; radius: 1; color: "#5a3524" }
            }
            Rectangle {
                x: mugRoot.mx + sm.d1 * 0.17
                y: mugRoot.my + sm.d1 * 0.05
                width: sm.d1 * 0.1
                height: sm.d1 * 0.14
                radius: 5
                color: "transparent"
                border.color: "#c9b8a2"
                border.width: 2
            }
            Repeater {
                model: 3
                Rectangle {
                    id: puff
                    width: sm.d1 * 0.07
                    height: width
                    radius: width / 2
                    color: Qt.rgba(1, 1, 1, 0.75)
                    x: mugRoot.mx + sm.d1 * 0.1 + (index - 1) * sm.d1 * 0.07 - width / 2
                    ParallelAnimation {
                        loops: Animation.Infinite
                        running: !sm.melting
                        PauseAnimation { duration: index * 500 }
                        NumberAnimation { target: puff; property: "y"; from: mugRoot.my; to: mugRoot.my - sm.d1 * 0.55; duration: 1500 }
                        NumberAnimation { target: puff; property: "opacity"; from: 0.75; to: 0; duration: 1500 }
                    }
                }
            }
        }
    }

    // ================= components: hats / head =================

    Component {
        id: hatBeanie
        Item {
            Rectangle {
                x: sm.midX - sm.d2 * 0.43
                y: sm.hatH - sm.d2 * 0.3
                width: sm.d2 * 0.86
                height: sm.d2 * 0.5
                radius: sm.d2 * 0.25
                color: sm.tp.hat
            }
            Rectangle {
                x: sm.midX - sm.d2 * 0.47
                y: sm.hatH + sm.d2 * 0.1
                width: sm.d2 * 0.94
                height: Math.max(3, sm.d2 * 0.15)
                radius: height / 2
                color: "#f6faff"
                border.color: "#b8cde6"
                border.width: 1
            }
            Rectangle {
                width: sm.d2 * 0.22
                height: width
                radius: width / 2
                x: sm.midX - width / 2
                y: sm.hatH - sm.d2 * 0.43
                color: sm.tp.pom
                border.color: "#b8cde6"
                border.width: 1
                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    running: !sm.melting
                    NumberAnimation { to: 1.14; duration: 700; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.94; duration: 800; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    Component {
        id: hatTop
        Item {
            y: -sm.tip * sm.d2 * 0.12
            transform: Rotation {
                origin.x: sm.midX + sm.d2 * 0.42
                origin.y: sm.hatH + sm.d2 * 0.1
                angle: -sm.tip * 24
            }
            Rectangle { x: sm.midX - sm.d2 * 0.27; y: sm.hatH - sm.d2 * 0.4; width: sm.d2 * 0.54; height: sm.d2 * 0.52; radius: 3; color: "#20242d" }
            Rectangle { x: sm.midX - sm.d2 * 0.27; y: sm.hatH - sm.d2 * 0.04; width: sm.d2 * 0.54; height: sm.d2 * 0.1; color: "#d9433f" }
            Rectangle { x: sm.midX - sm.d2 * 0.44; y: sm.hatH + sm.d2 * 0.08; width: sm.d2 * 0.88; height: sm.d2 * 0.1; radius: height / 2; color: "#20242d" }
        }
    }

    Component {
        id: hatPirate
        Item {
            Rectangle { x: sm.midX - sm.d2 * 0.46; y: sm.hatH - sm.d2 * 0.1; width: sm.d2 * 0.92; height: sm.d2 * 0.36; radius: sm.d2 * 0.22; color: "#b3202a" }
            Rectangle { x: sm.midX - sm.d2 * 0.47; y: sm.hatH + sm.d2 * 0.14; width: sm.d2 * 0.94; height: sm.d2 * 0.1; radius: height / 2; color: "#8c1d1d" }
            Repeater {
                model: 3
                Rectangle {
                    width: sm.d2 * 0.07
                    height: width
                    radius: width / 2
                    color: "white"
                    x: sm.midX + (index - 1) * sm.d2 * 0.24 - width / 2
                    y: sm.hatH + sm.d2 * 0.03
                }
            }
            Repeater {
                model: 2
                Rectangle {
                    width: sm.d2 * 0.18
                    height: sm.d2 * 0.07
                    radius: height / 2
                    color: "#b3202a"
                    x: sm.midX + sm.d2 * 0.42
                    y: sm.hatH + sm.d2 * 0.14 + index * sm.d2 * 0.07
                    transformOrigin: Item.Left
                    SequentialAnimation on rotation {
                        loops: Animation.Infinite
                        running: !sm.melting
                        NumberAnimation { to: index === 0 ? 25 : 50; duration: 500 + index * 130; easing.type: Easing.InOutSine }
                        NumberAnimation { to: index === 0 ? 5 : 25; duration: 500 + index * 130; easing.type: Easing.InOutSine }
                    }
                }
            }
        }
    }

    Component {
        id: hatNinja
        Item {
            Rectangle { x: sm.midX - sm.d2 * 0.5; y: sm.hatH + sm.d2 * 0.14; width: sm.d2; height: sm.d2 * 0.2; radius: height / 2; color: "#1b1f27" }
            Rectangle { x: sm.midX - sm.d2 * 0.13; y: sm.hatH + sm.d2 * 0.17; width: sm.d2 * 0.26; height: sm.d2 * 0.14; radius: 2; color: "#c3ccd8" }
            Repeater {
                model: 2
                Rectangle {
                    width: sm.d2 * 0.36
                    height: sm.d2 * 0.07
                    radius: height / 2
                    color: "#1b1f27"
                    x: sm.midX + sm.d2 * 0.46
                    y: sm.hatH + sm.d2 * 0.2 + index * sm.d2 * 0.06
                    transformOrigin: Item.Left
                    SequentialAnimation on rotation {
                        loops: Animation.Infinite
                        running: !sm.melting
                        NumberAnimation { to: index === 0 ? 30 : 55; duration: 380 + index * 110; easing.type: Easing.InOutSine }
                        NumberAnimation { to: index === 0 ? -5 : 15; duration: 380 + index * 110; easing.type: Easing.InOutSine }
                    }
                }
            }
        }
    }

    Component {
        id: hatCowboy
        Item {
            Rectangle { x: sm.midX - sm.d2 * 0.62; y: sm.hatH + sm.d2 * 0.04; width: sm.d2 * 1.24; height: sm.d2 * 0.14; radius: height / 2; color: "#7a4b26" }
            Rectangle { x: sm.midX - sm.d2 * 0.66; y: sm.hatH + sm.d2 * 0.0; width: sm.d2 * 0.22; height: sm.d2 * 0.1; radius: height / 2; color: "#7a4b26"; rotation: -22 }
            Rectangle { x: sm.midX + sm.d2 * 0.44; y: sm.hatH + sm.d2 * 0.0; width: sm.d2 * 0.22; height: sm.d2 * 0.1; radius: height / 2; color: "#7a4b26"; rotation: 22 }
            Rectangle { x: sm.midX - sm.d2 * 0.27; y: sm.hatH - sm.d2 * 0.26; width: sm.d2 * 0.54; height: sm.d2 * 0.34; radius: sm.d2 * 0.12; color: "#8b5a2b" }
            Rectangle { x: sm.midX - sm.d2 * 0.27; y: sm.hatH - sm.d2 * 0.02; width: sm.d2 * 0.54; height: sm.d2 * 0.07; color: "#3a2616" }
            Rectangle { x: sm.midX - sm.d2 * 0.08; y: sm.hatH - sm.d2 * 0.26; width: sm.d2 * 0.16; height: sm.d2 * 0.06; radius: height / 2; color: "#6b431f" }
        }
    }

    Component {
        id: hatKing
        Item {
            Rectangle { x: sm.midX - sm.d2 * 0.4; y: sm.hatH - sm.d2 * 0.02; width: sm.d2 * 0.8; height: sm.d2 * 0.18; radius: 2; color: "#f2c230"; border.color: "#c99a14"; border.width: 1 }
            Repeater {
                model: 3
                Rectangle {
                    width: sm.d2 * 0.2
                    height: width
                    rotation: 45
                    color: "#f2c230"
                    border.color: "#c99a14"
                    border.width: 1
                    x: sm.midX + (index - 1) * sm.d2 * 0.3 - width / 2
                    y: sm.hatH - sm.d2 * 0.2
                }
            }
            Repeater {
                model: ["#ef4444", "#38bdf8", "#4ade80"]
                Rectangle {
                    width: sm.d2 * 0.09
                    height: width
                    radius: width / 2
                    color: modelData
                    x: sm.midX + (index - 1) * sm.d2 * 0.25 - width / 2
                    y: sm.hatH + sm.d2 * 0.025
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: !sm.melting
                        PauseAnimation { duration: index * 400 }
                        NumberAnimation { to: 0.35; duration: 500 }
                        NumberAnimation { to: 1; duration: 500 }
                        PauseAnimation { duration: 800 }
                    }
                }
            }
        }
    }

    Component {
        id: hatSanta
        Item {
            Rectangle { x: sm.midX - sm.d2 * 0.44; y: sm.hatH - sm.d2 * 0.34; width: sm.d2 * 0.88; height: sm.d2 * 0.56; radius: sm.d2 * 0.3; color: "#d62828" }
            Rectangle { x: sm.midX - sm.d2 * 0.5; y: sm.hatH + sm.d2 * 0.1; width: sm.d2; height: Math.max(3, sm.d2 * 0.16); radius: height / 2; color: "white"; border.color: "#d3dcef"; border.width: 1 }
            Rectangle {
                id: santaPom
                width: sm.d2 * 0.2
                height: width
                radius: width / 2
                color: "white"
                border.color: "#d3dcef"
                border.width: 1
                x: sm.midX + sm.d2 * 0.3
                SequentialAnimation on y {
                    loops: Animation.Infinite
                    running: !sm.melting
                    NumberAnimation { from: sm.hatH - sm.d2 * 0.42; to: sm.hatH - sm.d2 * 0.34; duration: 700; easing.type: Easing.InOutSine }
                    NumberAnimation { from: sm.hatH - sm.d2 * 0.34; to: sm.hatH - sm.d2 * 0.42; duration: 700; easing.type: Easing.InOutSine }
                }
            }
            Rectangle { x: sm.midX - sm.d2 * 0.42; y: sm.hatH + sm.d2 * 0.58; width: sm.d2 * 0.84; height: sm.d2 * 0.46; radius: sm.d2 * 0.3; color: "white"; border.color: "#d3dcef"; border.width: 1 }
        }
    }

    Component {
        id: hatFrost
        Item {
            Repeater {
                model: 5
                Rectangle {
                    width: sm.d2 * 0.11
                    height: sm.d2 * (index % 2 === 0 ? 0.42 : 0.3)
                    radius: width / 2
                    color: Qt.rgba(0.75, 0.93, 1, 0.85)
                    border.color: "white"
                    border.width: 1
                    transformOrigin: Item.Bottom
                    rotation: (index - 2) * 16
                    x: sm.midX + (index - 2) * sm.d2 * 0.19 - width / 2
                    y: sm.hatH - height + sm.d2 * 0.14
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: !sm.melting
                        PauseAnimation { duration: index * 260 }
                        NumberAnimation { to: 0.55; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutSine }
                    }
                }
            }
        }
    }

    // ================= components: in front of the face =================

    Component {
        id: fgMonocle
        Item {
            Rectangle {
                id: ring
                width: sm.d2 * 0.26
                height: width
                radius: width / 2
                color: "transparent"
                border.color: "#d4a937"
                border.width: 2
                x: sm.midX + sm.d2 * 0.22 - width / 2
                y: sm.hatH + sm.d2 * 0.4 + sm.d2 * 0.086 - height / 2
            }
            Rectangle {
                width: 1.5
                height: sm.d2 * 0.5
                color: "#d4a937"
                rotation: 8
                x: ring.x + ring.width * 0.55
                y: ring.y + ring.height
            }
            Rectangle {
                width: sm.d2 * 0.05
                height: width
                radius: width / 2
                color: "white"
                x: ring.x + ring.width * 0.2
                y: ring.y + ring.height * 0.18
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: !sm.melting
                    PauseAnimation { duration: 1500 }
                    NumberAnimation { to: 0.1; duration: 300 }
                    NumberAnimation { to: 1; duration: 300 }
                }
            }
        }
    }

    Component {
        id: fgPatch
        Item {
            Rectangle {
                width: sm.d2 * 0.26
                height: width
                radius: width / 2
                color: "#15171d"
                x: sm.midX - sm.d2 * 0.22 - width / 2 + sm.look * sm.d2 * 0.03
                y: sm.hatH + sm.d2 * 0.4 + sm.d2 * 0.086 - height / 2
            }
            Rectangle {
                width: sm.d2 * 1.0
                height: Math.max(1.4, sm.d2 * 0.04)
                color: "#15171d"
                rotation: -18
                x: sm.midX - sm.d2 * 0.5
                y: sm.hatH + sm.d2 * 0.3
            }
        }
    }

    Component {
        id: fgBrows
        Item {
            Repeater {
                model: 2
                Rectangle {
                    width: sm.d2 * 0.2
                    height: Math.max(1.6, sm.d2 * 0.05)
                    radius: height / 2
                    color: "#232733"
                    rotation: index === 0 ? 14 : -14
                    x: sm.midX + (index === 0 ? -1 : 1) * sm.d2 * 0.22 - width / 2
                    y: sm.hatH + sm.d2 * 0.33
                }
            }
        }
    }

    Component {
        id: fgMustache
        Item {
            Repeater {
                model: 2
                Rectangle {
                    width: sm.d2 * 0.26
                    height: sm.d2 * 0.14
                    radius: height / 2
                    color: "white"
                    border.color: "#d3dcef"
                    border.width: 1
                    rotation: index === 0 ? -12 : 12
                    x: sm.midX + (index === 0 ? -1 : 1) * sm.d2 * 0.12 - width / 2
                    y: sm.hatH + sm.d2 * 0.6
                }
            }
        }
    }

    Component {
        id: fgHelmet
        Item {
            Rectangle {
                x: sm.midX - sm.d2 * 0.6
                y: sm.hatH - sm.d2 * 0.1
                width: sm.d2 * 1.2
                height: width
                radius: width / 2
                color: Qt.rgba(0.55, 0.8, 1, 0.13)
                border.color: Qt.rgba(0.85, 0.95, 1, 0.8)
                border.width: 2
            }
            Rectangle {
                width: sm.d2 * 0.34
                height: sm.d2 * 0.07
                radius: height / 2
                color: Qt.rgba(1, 1, 1, 0.55)
                rotation: -40
                x: sm.midX - sm.d2 * 0.42
                y: sm.hatH + sm.d2 * 0.12
            }
            Rectangle {
                width: Math.max(1.6, sm.d2 * 0.05)
                height: sm.d2 * 0.34
                color: "#9aa7b8"
                x: sm.midX + sm.d2 * 0.28
                y: sm.hatH - sm.d2 * 0.42
            }
            Rectangle {
                width: sm.d2 * 0.12
                height: width
                radius: width / 2
                color: "#ef4444"
                x: sm.midX + sm.d2 * 0.28 - width / 2 + 0.8
                y: sm.hatH - sm.d2 * 0.5
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: !sm.melting
                    NumberAnimation { to: 0.2; duration: 500 }
                    NumberAnimation { to: 1; duration: 500 }
                }
            }
        }
    }

    // ================= components: neckwear =================

    Component {
        id: neckScarf
        Item {
            Rectangle {
                width: sm.d2 * 1.0
                height: Math.max(3, sm.d2 * 0.17)
                radius: height / 2
                color: sm.tp.scarf
                x: sm.midX - width / 2
                y: sm.neckY - height / 2
            }
            Rectangle {
                width: Math.max(2.6, sm.d2 * 0.16)
                height: sm.d2 * 0.45
                radius: width / 2
                color: sm.tp.scarf
                x: sm.midX + sm.d2 * 0.22
                y: sm.neckY
                transformOrigin: Item.Top
                SequentialAnimation on rotation {
                    loops: Animation.Infinite
                    running: !sm.melting
                    NumberAnimation { to: 8; duration: 850; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -8; duration: 850; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    Component {
        id: neckBow
        Item {
            Rectangle { width: sm.d2 * 0.24; height: sm.d2 * 0.16; radius: 3; color: "#d9433f"; rotation: -18; x: sm.midX - sm.d2 * 0.25; y: sm.neckY - height / 2 }
            Rectangle { width: sm.d2 * 0.24; height: sm.d2 * 0.16; radius: 3; color: "#d9433f"; rotation: 18; x: sm.midX + sm.d2 * 0.01; y: sm.neckY - height / 2 }
            Rectangle { width: sm.d2 * 0.1; height: width; radius: width / 2; color: "#a82b2b"; x: sm.midX - width / 2; y: sm.neckY - height / 2 }
        }
    }

    Component {
        id: neckCollar
        Item {
            Rectangle { width: sm.d2 * 1.0; height: Math.max(4, sm.d2 * 0.2); radius: height / 2; color: "#ffffff"; border.color: "#c9d3ee"; border.width: 1; x: sm.midX - width / 2; y: sm.neckY - height / 2 }
            Repeater {
                model: 4
                Rectangle {
                    width: Math.max(1.6, sm.d2 * 0.05)
                    height: width
                    radius: width / 2
                    color: "#2b2f3a"
                    x: sm.midX + (index - 1.5) * sm.d2 * 0.22 - width / 2
                    y: sm.neckY - height / 2
                }
            }
        }
    }

    Component {
        id: neckRing
        Item {
            Rectangle { width: sm.d2 * 1.0; height: Math.max(4, sm.d2 * 0.22); radius: height / 2; color: "#9aa7b8"; border.color: "#d4dce8"; border.width: 1; x: sm.midX - width / 2; y: sm.neckY - height / 2 }
        }
    }

    // ================= component: orbit =================

    Component {
        id: orbitComp
        Item {
            Repeater {
                model: sm.kind === "frost" ? 4 : 1
                Rectangle {
                    id: orb
                    readonly property real baseAng: index * 2 * Math.PI / (sm.kind === "frost" ? 4 : 1)
                    property real ang: baseAng
                    width: sm.kind === "frost" ? Math.max(4, sm.d2 * 0.18) : Math.max(5, sm.d2 * 0.2)
                    height: width
                    radius: sm.kind === "frost" ? 1 : width / 2
                    rotation: sm.kind === "frost" ? 45 : 0
                    color: sm.kind === "frost" ? Qt.hsla(sm.hue, 0.7, 0.85, 1) : "#fb923c"
                    x: sm.midX + Math.cos(ang) * sm.d1 * 1.0 - width / 2
                    y: sm.height * 0.45 + Math.sin(ang) * sm.d1 * 0.35 - height / 2
                    opacity: 0.55 + 0.45 * Math.sin(ang)
                    NumberAnimation on ang {
                        from: orb.baseAng
                        to: orb.baseAng + 2 * Math.PI
                        duration: sm.kind === "frost" ? 5200 : 7500
                        loops: Animation.Infinite
                        running: !sm.melting
                    }
                }
            }
        }
    }

    // ---- гірлянда на сніговику ----
    Garland {
        z: 7
        visible: SnowConfig.garland && SnowConfig.garlandMan && !sm.preview && !sm.melting
        caps: false
        pts: {
            var r = sm.d1 / 2;
            var cy = sm.height - r;
            var out = [];
            for (var t = 0; t <= 1.0001; t += 0.1)
                out.push([sm.midX - r * 0.9 + 1.8 * r * Math.min(1, t), cy - r * 0.25 + r * 0.4 * Math.sin(Math.PI * Math.min(1, t))]);
            return out;
        }
        spacing: Math.max(8, Math.round(sm.d1 * 0.21 * SnowConfig.garlandSize))
        scaleK: Math.max(0.65, Math.min(1.2, sm.d1 / 48))
        offset: sm.typeId * 3
        clock: sm.host ? sm.host.garlandClock : 0
        playing: sm.host ? sm.host.musicPlaying : false
        lite: sm.host ? sm.host.saving : false
    }
}
