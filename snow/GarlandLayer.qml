import QtQuick
import Quickshell.Hyprland

// Усі гірлянди одного монітора: верх екрана, вікна, бурульки, рамка, земля.
// Гірлянди на сніговиках живуть у Snowman.qml, але беруть годинник звідси (clock).
Item {
    id: gl

    property var mon: null
    property real groundY: height
    property bool frozen: false
    property bool playing: false
    property bool lite: false
    property bool refreshHere: true
    property real clock: 0

    property var winRuns: []
    property string winGeo: ""

    readonly property bool on: SnowConfig.garland
    readonly property real k: SnowConfig.garlandSize
    readonly property real topInset: (mon && mon.lastIpcObject && mon.lastIpcObject.reserved && mon.lastIpcObject.reserved.length > 1) ? mon.lastIpcObject.reserved[1] : 0
    readonly property int chainSp: Math.round(15 * k * (lite ? 1.7 : 1))
    readonly property int dropSp: Math.round(26 * k * (lite ? 1.5 : 1))
    readonly property real swagW: Math.max(80, 118 * k)
    readonly property bool wantWins: on && (SnowConfig.garlandWin || SnowConfig.garlandIce)

    Timer {
        id: tclock
        interval: gl.lite ? 140 : 66
        repeat: true
        running: gl.on && !gl.frozen && (SnowConfig.garlandMode === 1 || SnowConfig.garlandMode === 2
                 || (SnowConfig.garlandMode === 3 && gl.playing && !BeatEngine.active))
        onTriggered: gl.clock += tclock.interval / 1000
    }

    function subtractSpan(segs, a, b) {
        var out = [];
        for (var i = 0; i < segs.length; i++) {
            var s0 = segs[i][0], s1 = segs[i][1];
            if (b <= s0 || a >= s1) { out.push([s0, s1]); continue; }
            if (a > s0) out.push([s0, a]);
            if (b < s1) out.push([b, s1]);
        }
        return out;
    }

    function syncWins() {
        var m = mon;
        if (!wantWins || !m || !m.lastIpcObject) {
            if (winRuns.length > 0) { winRuns = []; winGeo = ""; }
            return;
        }
        var mi = m.lastIpcObject;
        var wsId = mi.activeWorkspace ? mi.activeWorkspace.id : -1;
        var list = Hyprland.toplevels.values;
        var rects = [];
        var full = false;
        for (var i = 0; i < list.length; i++) {
            var o = list[i].lastIpcObject;
            if (!o || !o.at || !o.size) continue;
            if (o.monitor !== mi.id) continue;
            if (!o.mapped || o.hidden) continue;
            if (!o.workspace || o.workspace.id !== wsId) continue;
            if (o.fullscreen > 0) { full = true; continue; }
            if (o.size[0] < 80) continue;
            rects.push({ x: o.at[0] - mi.x, y: o.at[1] - mi.y, w: o.size[0], h: o.size[1] });
        }
        var runs = [];
        if (!full) {
            for (var r = 0; r < rects.length; r++) {
                var rc = rects[r];
                if (rc.y - topInset < 10) continue;
                var segs = [[0, rc.w]];
                for (var q = 0; q < rects.length; q++) {
                    if (q === r) continue;
                    var o2 = rects[q];
                    if (o2.y < rc.y && o2.y + o2.h > rc.y - 2)
                        segs = subtractSpan(segs, o2.x - rc.x, o2.x + o2.w - rc.x);
                }
                for (var s = 0; s < segs.length; s++) {
                    var a0 = Math.max(0, segs[s][0]), a1 = Math.min(rc.w, segs[s][1]);
                    if (a1 - a0 >= 40)
                        runs.push({ x0: Math.round(rc.x + a0), x1: Math.round(rc.x + a1), y: Math.round(rc.y) });
                }
            }
        }
        var geo = JSON.stringify(runs);
        if (geo !== winGeo) {
            winGeo = geo;
            winRuns = runs;
        }
    }

    onWantWinsChanged: {
        if (wantWins) {
            Hyprland.refreshToplevels();
            Hyprland.refreshMonitors();
            postT.restart();
        } else {
            syncWins();
        }
    }

    Timer {
        interval: gl.lite ? 700 : 300
        repeat: true
        running: gl.wantWins && !gl.frozen
        onTriggered: {
            if (gl.refreshHere) {
                Hyprland.refreshToplevels();
                Hyprland.refreshMonitors();
            }
            gl.syncWins();
        }
    }

    Timer {
        id: evT
        interval: 30
        onTriggered: {
            Hyprland.refreshToplevels();
            Hyprland.refreshMonitors();
            postT.restart();
        }
    }
    Timer {
        id: postT
        interval: 120
        onTriggered: gl.syncWins()
    }
    Connections {
        target: Hyprland
        enabled: gl.wantWins
        function onRawEvent(event) {
            var n = event.name;
            if (n === "openwindow" || n === "closewindow" || n === "movewindowv2"
                || n === "workspacev2" || n === "fullscreen" || n === "changefloatingmode"
                || n === "focusedmon" || n === "activespecial")
                evT.restart();
        }
    }

    // ---------- геометрія ----------

    function swagPts(i) {
        var x0 = i * swagW;
        var x1 = Math.min(width, x0 + swagW);
        var base = topInset + 3 * k;
        var sag = (18 + (i % 3) * 5) * k;
        var out = [];
        for (var t = 0; t <= 1.0001; t += 0.1)
            out.push([x0 + (x1 - x0) * t, base + sag * Math.sin(Math.PI * Math.min(1, t))]);
        return out;
    }

    function scallopPts(x0, x1, y) {
        var len = x1 - x0;
        if (len < 30) return [];
        var n = Math.max(1, Math.round(len / (80 * k)));
        var sl = len / n;
        var base = y - 7 * k;
        var sag = 8 * k;
        var out = [];
        for (var s = 0; s < len; s += 5) {
            var idx = Math.min(n - 1, Math.floor(s / sl));
            var f = (s - idx * sl) / sl;
            out.push([x0 + s, base + sag * Math.sin(Math.PI * f)]);
        }
        out.push([x1, base]);
        return out;
    }

    function dropRun(x0, x1, y) {
        return [[x0, y + 1], [x1, y + 1]];
    }

    function framePts() {
        var m = 12 * k, r = 18 * k;
        var l = m, rt = width - m, t = topInset + m + 4, b = groundY - m * 0.8;
        if (rt - l < 100 || b - t < 100) return [];
        var out = [];
        function arc(cx, cy, a0, a1) {
            for (var a = a0; a <= a1 + 0.001; a += Math.PI / 12)
                out.push([cx + r * Math.cos(a), cy + r * Math.sin(a)]);
        }
        arc(l + r, t + r, Math.PI, 1.5 * Math.PI);
        arc(rt - r, t + r, 1.5 * Math.PI, 2 * Math.PI);
        arc(rt - r, b - r, 0, 0.5 * Math.PI);
        arc(l + r, b - r, 0.5 * Math.PI, Math.PI);
        out.push(out[0]);
        return out;
    }

    function groundPts() {
        var span = width - 20;
        if (span < 100) return [];
        var n = Math.max(1, Math.round(span / (150 * k)));
        var step = span / n;
        var base = groundY - 12 * k;
        var sag = 9 * k;
        var out = [];
        for (var s = 0; s <= span; s += 6) {
            var idx = Math.min(n - 1, Math.floor(s / step));
            var f = (s - idx * step) / step;
            out.push([10 + s, base + sag * Math.sin(Math.PI * f)]);
        }
        return out;
    }

    // ---------- верх екрана, дугами ----------
    Repeater {
        model: (gl.on && SnowConfig.garlandTop && gl.width > 0) ? Math.ceil(gl.width / gl.swagW) : 0
        Garland {
            required property int index
            pts: gl.swagPts(index)
            spacing: gl.chainSp
            offset: index * 3
            clock: gl.clock
            playing: gl.playing
            lite: gl.lite
        }
    }

    // ---------- верхні краї вікон ----------
    Repeater {
        model: (gl.on && SnowConfig.garlandWin) ? gl.winRuns : []
        Garland {
            required property var modelData
            required property int index
            pts: gl.scallopPts(modelData.x0, modelData.x1, modelData.y)
            spacing: gl.chainSp
            offset: index * 5
            clock: gl.clock
            playing: gl.playing
            lite: gl.lite
        }
    }

    // ---------- бурульки з вікон ----------
    Repeater {
        model: (gl.on && SnowConfig.garlandIce) ? gl.winRuns : []
        Garland {
            required property var modelData
            required property int index
            kind: 1
            caps: false
            pts: gl.dropRun(modelData.x0, modelData.x1, modelData.y)
            spacing: gl.dropSp
            offset: index * 7
            clock: gl.clock
            playing: gl.playing
            lite: gl.lite
        }
    }

    // ---------- рамка екрана ----------
    Garland {
        visible: gl.on && SnowConfig.garlandFrame
        caps: false
        pts: (gl.on && SnowConfig.garlandFrame) ? gl.framePts() : []
        spacing: gl.chainSp
        clock: gl.clock
        playing: gl.playing
        lite: gl.lite
    }

    // ---------- земля, на снігу ----------
    Garland {
        visible: gl.on && SnowConfig.garlandGround
        caps: false
        pts: (gl.on && SnowConfig.garlandGround) ? gl.groundPts() : []
        spacing: gl.chainSp
        offset: 2
        clock: gl.clock
        playing: gl.playing
        lite: gl.lite
    }
}
