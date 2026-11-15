import QtQuick
import QtQuick.Particles
import Quickshell.Hyprland

Item {
    id: root
    property var screenObj: null

    readonly property int level: SnowConfig.level
    readonly property real rateBase: 55 * width / 1920 * (saving ? 0.4 : 1)
    readonly property bool pileOn: level > 0 && SnowConfig.accumulate && SnowConfig.bottom
    readonly property bool windowsOn: level > 0 && SnowConfig.accumulate && SnowConfig.windowSnow

    property real varT: 0
    property real windT: 0
    readonly property real windTarget: SnowConfig.windStrength + (SnowConfig.windGust ? 0.35 * Math.sin(windT * 0.9) * Math.sin(windT * 0.37 + 1.0) + 0.15 * Math.sin(windT * 2.3) : 0)
    property real windNow: windTarget
    Behavior on windNow { NumberAnimation { duration: 900 } }
    readonly property real pileAvg: pile.avg

    Timer {
        interval: 100
        repeat: true
        running: SnowConfig.windGust && !root.suspended
        onTriggered: root.windT += 0.1
    }
    property real lastDensity: 0
    readonly property real density: densityFor(level, varT)
    property var snows: ({})

    readonly property var mon: {
        if (!screenObj) return null;
        var vs = Hyprland.monitors.values;
        for (var i = 0; i < vs.length; i++)
            if (vs[i].name === screenObj.name) return vs[i];
        return null;
    }

    readonly property real reservedBottom: (SnowConfig.bottomAuto && mon && mon.lastIpcObject && mon.lastIpcObject.reserved) ? mon.lastIpcObject.reserved[3] : 0
    readonly property real groundY: height - SnowConfig.bottomOffset - reservedBottom
    readonly property real killY: pileOn ? Math.max(0, groundY - pile.avg) : height

    function densityFor(lv, t) {
        if (lv <= 0) return 0;
        if (lv === 1) return 0.18;
        if (lv === 2) return 0.45;
        if (lv === 3) return 1.0;
        var v = 0.5 + 0.32 * Math.sin(t * 2 * Math.PI / 75) + 0.18 * Math.sin(t * 2 * Math.PI / 210 + 1.3);
        return Math.max(0.1, Math.min(1.0, v));
    }

    function phaseFor(target) {
        var best = varT, bd = 9;
        for (var t = 0; t < 1050; t += 0.5) {
            var dd = Math.abs(densityFor(4, t) - target);
            if (dd < bd) { bd = dd; best = t; }
        }
        return best;
    }

    function fillBurst(d) {
        if (d <= 0) return;
        fillFar.burst(Math.round(d * rateBase * 0.7 * height / 85));
        fillNear.burst(Math.round(d * rateBase * 0.3 * height / 150));
    }

    function seedFor(key) {
        var h = 0;
        for (var i = 0; i < key.length; i++) h = (h * 31 + key.charCodeAt(i)) | 0;
        return (Math.abs(h) % 1000) / 50;
    }

    function addDebris(x0, x1, amt) {
        if (pileOn) pile.addDebris(x0, x1, amt);
    }

    function shedItem(it) {
        if (!it || it.amount < 0.05) return;
        var top = it.wy - it.maxH * it.amount * 0.8;
        for (var i = 0; i < it.segs.length; i++) {
            var a = it.segs[i][0], b = it.segs[i][1];
            var bo = burstComp.createObject(root, {
                system: sys, x: it.wx + a, y: top, width: b - a,
                fallH: Math.max(40, groundY - top), amount: it.amount * 0.8
            });
            if (bo) bo.landed.connect(root.addDebris);
        }
    }

    function hookWindow(w) {
        w.overflow.connect(function() {
            root.shedPart(w);
            w.slump();
        });
    }

    function shedPart(it) {
        if (!it || it.segs.length === 0) return;
        var sg = it.segs[Math.floor(Math.random() * it.segs.length)];
        var len = sg[1] - sg[0];
        var w = Math.min(len, 60 + Math.random() * 100);
        var a = sg[0] + Math.random() * Math.max(0, len - w);
        var top = it.wy - it.maxH * it.amount * 0.8;
        var bo = burstComp.createObject(root, {
            system: sys, x: it.wx + a, y: top, width: w,
            fallH: Math.max(40, groundY - top), amount: 0.25
        });
        if (bo) bo.landed.connect(root.addDebris);
    }

    property var strips: ({})
    property var stripKeys: []
    property string lastStripGeo: ""
    property real brushAcc: 0
    property var heldBall: null

    function updateStrips() {
        var ns = {};
        var keys = [];
        if (windowsOn && !gameActive) {
            for (var k in snows) {
                var it = snows[k];
                if (!it || it.amount < 0.12 || it.segs.length === 0) continue;
                var a0 = 1e9, a1 = -1e9;
                for (var s = 0; s < it.segs.length; s++) {
                    a0 = Math.min(a0, it.segs[s][0]);
                    a1 = Math.max(a1, it.segs[s][1]);
                }
                if (a1 - a0 < 20) continue;
                ns[k] = { x: Math.round(it.wx + a0), y: Math.round(it.wy - it.maxH), w: Math.round(a1 - a0), h: Math.round(it.maxH) };
                keys.push(k);
            }
        }
        keys.sort();
        var geo = JSON.stringify(ns);
        var changed = keys.join("|") !== stripKeys.join("|");
        if (geo !== lastStripGeo) {
            lastStripGeo = geo;
            strips = ns;
        }
        if (changed) stripKeys = keys;
    }

    function brush(key, gx, gy, big) {
        var it = snows[key];
        if (!it) return 0;
        var rem = it.carve(gx - it.wx, big ? Math.round(SnowConfig.brushSize * 0.65) : SnowConfig.brushSize);
        brushAcc += rem;
        if (!big && brushAcc > 0.9) {
            brushAcc = 0;
            var top = it.wy - it.maxH * it.amount * 0.7;
            var bo = burstComp.createObject(root, {
                system: sys, x: gx - 18, y: top, width: 36,
                fallH: Math.max(40, groundY - top), amount: 0.18
            });
            if (bo) bo.landed.connect(root.addDebris);
        }
        return rem;
    }

    property var balls: []
    property var snowmen: []

    Timer {
        id: snowmanTimer
        interval: 400
        onTriggered: root.checkSnowman()
    }

    function queueSnowmanCheck() {
        snowmanTimer.restart();
    }

    function ballFloor(x) {
        if (!pileOn) return groundY;
        if (x === undefined || typeof pile.heightAt !== "function")
            return groundY - pile.avg * 0.85;
        return groundY - pile.heightAt(x - pile.x);
    }

    function surfaceY(x, fromY) {
        var g = ballFloor(x);
        var best = 1e9;
        for (var k in snows) {
            var it = snows[k];
            if (!it || it.amount < 0.1 || !it.segs) continue;
            for (var s = 0; s < it.segs.length; s++) {
                if (x >= it.wx + it.segs[s][0] && x <= it.wx + it.segs[s][1]) {
                    var hh = (typeof it.heightAt === "function") ? it.heightAt(x - it.wx) : it.maxH * 0.65;
                    var sy = Math.min(it.wy, it.wy + 2 - hh * it.amount);
                    if (sy >= fromY && sy < best) best = sy;
                    break;
                }
            }
        }
        if (best < 1e8 && best < g) return best;
        return g;
    }

    function registerBall(b) {
        var a = balls.slice();
        a.push(b);
        while (a.length > 12) {
            var old = a.shift();
            if (old && !old.held) old.expire();
        }
        balls = a;
    }

    function unregisterBall(b) {
        balls = balls.filter(function(x) { return x !== b; });
    }

    function registerSnowman(s) {
        var a = snowmen.slice();
        a.push(s);
        while (a.length > 6) {
            var old = a.shift();
            if (old) old.melt();
        }
        snowmen = a;
    }

    function unregisterSnowman(s) {
        snowmen = snowmen.filter(function(x) { return x !== s; });
    }

    function stacked(lo, up) {
        var dx = up.cx - lo.cx;
        var dy = up.cy - lo.cy;
        var dist = Math.sqrt(dx * dx + dy * dy);
        return up.cy < lo.cy && Math.abs(dx) < lo.d * 0.4
            && dist < (lo.d + up.d) / 2 + 8 && lo.d >= up.d * 0.7;
    }

    function checkSnowman() {
        if (!SnowConfig.snowmenOn) return;
        for (var i = 0; i < balls.length; i++) {
            var lo = balls[i];
            if (!lo || lo.held || !lo.resting || lo.d < 12) continue;
            for (var j = 0; j < balls.length; j++) {
                if (i === j) continue;
                var up = balls[j];
                if (!up || up.held || !up.resting || up.d < 10) continue;
                if (stacked(lo, up)) {
                    makeSnowman(lo, up);
                    return;
                }
            }
        }
    }

    CfgWriter { id: cfgw }
    property var foundCache: ({})

    function discover(tid) {
        var f = {};
        try { f = JSON.parse(SnowConfig.foundJson) || {}; } catch (e) { f = {}; }
        for (var k in foundCache)
            if ((f[k] || 0) < foundCache[k]) f[k] = foundCache[k];
        f[tid] = (f[tid] || 0) + 1;
        foundCache = f;
        cfgw.set("foundJson", JSON.stringify(f));
    }

    function makeSnowman(b1, b2) {
        var cxs = b1.cx;
        var base = b1.cy + b1.d / 2;
        var d1 = b1.d, d2 = b2.d;
        b1.destroy();
        b2.destroy();
        var tid = SnowTypes.roll(SnowConfig.luck);
        discover(tid);
        snowmanComp.createObject(root, { host: root, cx: cxs, baseY: base, d1: d1, d2: d2, typeId: tid });
    }

    function spawnType(tid) {
        var gx = root.width * (0.15 + Math.random() * 0.7);
        snowmanComp.createObject(root, { host: root, cx: gx, baseY: ballFloor(gx), d1: 42, d2: 28, typeId: tid, summoned: true });
    }

    function meltSnowmen() {
        var sl = snowmen.slice();
        for (var i = 0; i < sl.length; i++)
            if (sl[i]) sl[i].melt();
    }

    function popBalls() {
        var bl = balls.slice();
        for (var i = 0; i < bl.length; i++)
            if (bl[i] && !bl[i].held) bl[i].expire();
    }

    // ---- snow_patch17: трактор зносить або об'їжджає ----
    property var tractorHandled: []
    readonly property int tractorSafeTier: 2

    function checkTractor() {
        if (!veh.visible) return;
        var mode = SnowConfig.tractorMode;
        if (mode === undefined) mode = 1;
        var front = veh.bladeX - veh.heapW * 0.8;
        var lowY = groundY - SnowConfig.bottomMax - 24;
        var done = tractorHandled;
        var sl = snowmen.slice();
        for (var i = 0; i < sl.length; i++) {
            var s = sl[i];
            if (!s || s.melting || s.held || s.preview) continue;
            if (done.indexOf(s) >= 0 || s.baseY < lowY) continue;
            var reach = s.d1 * 0.45;
            var safe = (mode === 2) || (mode === 1 && s.tp.tier >= tractorSafeTier);
            var lead = safe ? reach + 70 : reach;
            if (front > s.cx + lead || front < s.cx - s.d1 * 0.6) continue;
            done.push(s);
            if (safe) s.hopNow();
            else s.melt();
        }
        var bl = balls.slice();
        for (var j = 0; j < bl.length; j++) {
            var b = bl[j];
            if (!b || b.held) continue;
            if (done.indexOf(b) >= 0 || b.cy + b.d / 2 < lowY) continue;
            if (front > b.cx + b.d / 2 || front < b.cx - b.d) continue;
            done.push(b);
            b.expire();
        }
    }

    Timer {
        interval: 40
        repeat: true
        running: root.veh.visible
        onTriggered: root.checkTractor()
        onRunningChanged: { if (!running) root.tractorHandled = []; }
    }
    // ---- /snow_patch17 ----

    function takePile(gx, amt) {
        if (pile && typeof pile.takeSnow === "function")
            pile.takeSnow(gx - 20, gx + 20, amt);
    }

    function feedSnow(gx, gy, dia) {
        if (Math.abs(gy - ballFloor(gx)) < 4)
            addDebris(gx - dia * 0.8, gx + dia * 0.8, 0.4);
    }

    function clearToys(anim) {
        var bl = balls.slice();
        for (var i = 0; i < bl.length; i++) {
            var b = bl[i];
            if (!b) continue;
            if (anim && !b.held) b.expire();
            else b.destroy();
        }
        heldBall = null;
        var sl = snowmen.slice();
        for (var j = 0; j < sl.length; j++) {
            var s = sl[j];
            if (!s) continue;
            if (anim) s.melt();
            else s.destroy();
        }
    }

    function ballStart(gx, gy) {
        if (heldBall) { heldBall.release(); heldBall = null; }
        heldBall = ballComp.createObject(root, { host: root, cx: gx, cy: gy, d: 14 });
        if (heldBall) heldBall.splat.connect(root.onBallSplat);
    }

    function ballMove(gx, gy) {
        if (!heldBall) return;
        var ddx = gx - heldBall.lastX;
        var ddy = gy - heldBall.lastY;
        var dd = Math.sqrt(ddx * ddx + ddy * ddy);
        heldBall.drag(gx, gy);
        heldBall.d = Math.min(SnowConfig.ballMax, heldBall.d + dd * 0.3);
    }

    function ballGrow(v) {
        if (heldBall && v > 0) heldBall.d = Math.min(SnowConfig.ballMax, heldBall.d + v * 10);
    }

    function ballRelease() {
        if (heldBall) {
            heldBall.release();
            heldBall = null;
        }
    }

    function onBallSplat(gx, gy, dia) {
        var w = 30 + dia * 1.6;
        var bo = burstComp.createObject(root, {
            system: sys, x: gx - w / 2, y: gy - 8, width: w,
            fallH: Math.max(40, groundY - gy), amount: Math.min(1, dia / 40)
        });
        if (bo) bo.landed.connect(root.addDebris);
    }

    Timer {
        interval: 250
        repeat: true
        running: true
        onTriggered: root.updateStrips()
    }

    // ---- snow_patch20: пауза, режим ігор, економія, музика ----
    property bool gameActive: false
    readonly property bool saving: SnowConfig.saveMode
    readonly property bool suspended: SnowConfig.paused || gameActive
    readonly property bool musicPlaying: musicLoader.item ? musicLoader.item.playing : false

    Loader {
        id: musicLoader
        active: SnowConfig.dance
        source: Qt.resolvedUrl("MusicWatch.qml")
    }

    function checkGame() {
        if (!SnowConfig.gameMode) {
            if (gameActive) gameActive = false;
            return;
        }
        var m = mon;
        if (!m || !m.lastIpcObject) return;
        var mi = m.lastIpcObject;
        var wsId = mi.activeWorkspace ? mi.activeWorkspace.id : -1;
        var list = Hyprland.toplevels.values;
        var game = false;
        for (var i = 0; i < list.length; i++) {
            var o = list[i].lastIpcObject;
            if (!o || !o.workspace || o.monitor !== mi.id) continue;
            if (!o.mapped || o.hidden || o.workspace.id !== wsId) continue;
            var cls = String(o["class"] || "");
            if (o.fullscreen > 0 || /^(steam_app_|gamescope|lutris|heroic)/i.test(cls)) {
                game = true;
                break;
            }
        }
        if (game !== gameActive) gameActive = game;
    }

    Timer {
        interval: 1500
        repeat: true
        running: SnowConfig.gameMode
        onTriggered: {
            Hyprland.refreshToplevels();
            Hyprland.refreshMonitors();
            root.checkGame();
        }
    }

    Connections {
        target: SnowConfig
        function onGameModeChanged() { root.checkGame(); }
    }
    // ---- /snow_patch20 ----

    // ---- snow_patch24: вибір машини для прибирання ----
    property var veh: tractor

    function pickVehicle() {
        if (veh && veh.visible) return;
        var v = SnowConfig.vehicle;
        if (v === undefined) v = 3;
        if (v === 3) v = 1 + Math.floor(Math.random() * 2);
        veh = (v === 1) ? truckV : ((v === 2) ? sleighV : tractor);
    }

    function abortVehicles() {
        tractor.abort();
        truckV.abort();
        sleighV.abort();
    }
    // ---- /snow_patch24 ----

    function clearWindows() {
        for (var k in snows) snows[k].destroy();
        snows = {};
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

    function sync() {
        if (!windowsOn) return;
        var m = mon;
        if (!m || !m.lastIpcObject) return;
        var mi = m.lastIpcObject;
        var wsId = mi.activeWorkspace ? mi.activeWorkspace.id : -1;
        var topRes = (mi.reserved && mi.reserved.length > 1) ? mi.reserved[1] : 0;
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
            rects.push({ key: String(o.address), x: o.at[0] - mi.x, y: o.at[1] - mi.y, w: o.size[0], h: o.size[1] });
        }
        windowLayer.visible = !full;

        var seen = {};
        for (var r = 0; r < rects.length; r++) {
            var rc = rects[r];
            var room = rc.y - topRes;
            if (room < 4) continue;
            var maxH = Math.min(SnowConfig.windowMax, Math.floor(room));
            var segs = [[0, rc.w]];
            for (var q = 0; q < rects.length; q++) {
                if (q === r) continue;
                var o2 = rects[q];
                if (o2.y < rc.y && o2.y + o2.h > rc.y - 2)
                    segs = subtractSpan(segs, o2.x - rc.x, o2.x + o2.w - rc.x);
            }
            var good = [];
            for (var s = 0; s < segs.length; s++) {
                var a0 = Math.max(0, segs[s][0]), a1 = Math.min(rc.w, segs[s][1]);
                if (a1 - a0 >= 30) good.push([Math.round(a0), Math.round(a1)]);
            }
            if (good.length === 0) continue;
            seen[rc.key] = true;
            var geo = Math.round(rc.x) + "|" + Math.round(rc.y) + "|" + Math.round(rc.w) + "|" + Math.round(rc.h);
            var sk = maxH + ":" + JSON.stringify(good);
            var it = snows[rc.key];
            if (!it) {
                it = snowComp.createObject(windowLayer, {
                    wx: rc.x, wy: rc.y, ww: rc.w, maxH: maxH, segs: good,
                    seed: seedFor(rc.key), growMs: Math.round(SnowConfig.growSeconds * 1000),
                    geo: geo, segKey: sk
                });
                if (it) { snows[rc.key] = it; hookWindow(it); }
            } else if (it.geo !== geo) {
                shedItem(it);
                it.wx = rc.x; it.wy = rc.y; it.ww = rc.w; it.maxH = maxH;
                it.segs = good; it.geo = geo; it.segKey = sk;
                it.restart();
            } else if (it.segKey !== sk) {
                it.maxH = maxH; it.segs = good; it.segKey = sk;
            }
        }
        for (var k in snows) {
            if (!seen[k]) {
                shedItem(snows[k]);
                snows[k].destroy();
                delete snows[k];
            }
        }
    }

    onLevelChanged: {
        if (level === 0) {
            sys.reset();
            lastDensity = 0;
            clearWindows();
            clearToys(false);
            root.abortVehicles();
            pile.reset();
            return;
        }
        if (lastDensity <= 0) {
            initFill.restart();
            return;
        }
        if (level === 4)
            varT = phaseFor(lastDensity);
        var nd = densityFor(level, varT);
        if (nd > lastDensity * 1.25)
            fillBurst(nd - lastDensity);
        lastDensity = nd;
    }

    onPileOnChanged: { if (!pileOn) { abortVehicles(); pile.reset(); } }
    onWindowsOnChanged: { if (!windowsOn) clearWindows(); }

    property bool cmdReady: false

    Timer {
        interval: 2000
        running: true
        onTriggered: root.cmdReady = true
    }

    function clearAllSnow() {
        clearToys(true);
        for (var k in snows) {
            shedItem(snows[k]);
            snows[k].restart();
        }
        if (pileOn && !pile.sweeping && pile.avg > 0.3) {
            pile.sweeping = true;
            pickVehicle();
            veh.start(pile.avg);
        }
    }

    function callTractor() {
        if (!pileOn || pile.sweeping) return;
        pile.sweeping = true;
        pickVehicle();
        veh.start(Math.max(pile.avg, 6));
    }

    Connections {
        target: SnowConfig
        function onClearTickChanged() { if (root.cmdReady) root.clearAllSnow(); }
        function onTractorTickChanged() { if (root.cmdReady) root.callTractor(); }
    }

    Component.onCompleted: {
        Hyprland.refreshToplevels();
        Hyprland.refreshMonitors();
        if (level > 0)
            initFill.restart();
    }

    Component { id: snowComp; WindowSnow {} }
    Component { id: burstComp; ShedBurst {} }
    Component { id: ballComp; Ball {} }
    Component { id: snowmanComp; Snowman {} }

    Timer {
        id: initFill
        interval: 400
        onTriggered: {
            root.lastDensity = root.densityFor(root.level, root.varT);
            root.fillBurst(root.lastDensity);
        }
    }

    Timer {
        interval: 400
        repeat: true
        running: root.level === 4 && !root.suspended
        onTriggered: {
            root.varT += 0.4;
            root.lastDensity = root.densityFor(4, root.varT);
        }
    }

    Timer {
        interval: root.saving ? 600 : 200
        repeat: true
        running: root.windowsOn && !root.suspended
        onTriggered: {
            root.sync();
            Hyprland.refreshToplevels();
            Hyprland.refreshMonitors();
        }
    }

    Timer {
        id: evTimer
        interval: 30
        onTriggered: {
            Hyprland.refreshToplevels();
            Hyprland.refreshMonitors();
            postTimer.restart();
        }
    }

    Timer {
        id: postTimer
        interval: 120
        onTriggered: { root.sync(); root.checkGame(); }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            var n = event.name;
            if (n === "openwindow" || n === "closewindow" || n === "movewindowv2"
                || n === "workspacev2" || n === "fullscreen" || n === "changefloatingmode"
                || n === "focusedmon" || n === "activespecial")
                evTimer.restart();
        }
    }

    ParticleSystem { id: sys; paused: root.suspended }

    ImageParticle {
        system: sys
        groups: ["far", "near", "debris"]
        source: Qt.resolvedUrl("flake.png")
        color: "white"
        alpha: 0
    }

    Gravity {
        system: sys
        groups: ["far", "near"]
        angle: root.windNow >= 0 ? 0 : 180
        magnitude: Math.abs(root.windNow) * 14
    }

    Wander {
        system: sys
        groups: ["far", "near"]
        xVariance: 30
        pace: 100
    }

    Age {
        system: sys
        groups: ["far", "near", "debris"]
        x: 0
        y: root.killY
        width: root.width
        height: 80
        lifeLeft: 80
        advancePosition: false
        once: true
    }

    Emitter {
        system: sys
        group: "far"
        x: 0
        y: -20
        width: root.width
        height: 10
        emitRate: root.density * root.rateBase * 0.7
        lifeSpan: 14000
        size: 5
        sizeVariation: 3
        velocity: AngleDirection { angle: 90; angleVariation: 8; magnitude: 85; magnitudeVariation: 20 }
    }

    Emitter {
        system: sys
        group: "near"
        x: 0
        y: -20
        width: root.width
        height: 10
        emitRate: root.density * root.rateBase * 0.3
        lifeSpan: 8500
        size: 9
        sizeVariation: 4
        velocity: AngleDirection { angle: 90; angleVariation: 8; magnitude: 150; magnitudeVariation: 30 }
    }

    Emitter {
        id: fillFar
        system: sys
        group: "far"
        x: 0
        y: 0
        width: root.width
        height: root.height
        enabled: true
        emitRate: 0
        lifeSpan: 14000
        size: 5
        sizeVariation: 3
        velocity: AngleDirection { angle: 90; angleVariation: 8; magnitude: 85; magnitudeVariation: 20 }
    }

    Emitter {
        id: fillNear
        system: sys
        group: "near"
        x: 0
        y: 0
        width: root.width
        height: root.height
        enabled: true
        emitRate: 0
        lifeSpan: 8500
        size: 9
        sizeVariation: 4
        velocity: AngleDirection { angle: 90; angleVariation: 8; magnitude: 150; magnitudeVariation: 30 }
    }

    BottomPile {
        id: pile
        z: 1
        x: 0
        width: root.width
        y: root.groundY - height
        active: root.pileOn && !root.suspended
        density: root.density
        cap: SnowConfig.bottomMax
        growSeconds: SnowConfig.growSeconds
        sweepX: root.veh.bladeX - root.veh.heapW * 0.6
        onOverflowed: { root.pickVehicle(); root.veh.start(pile.avg); }
    }

    Tractor {
        id: tractor
        z: 3
        y: root.groundY - height
        layerWidth: root.width
        onFinished: pile.reset()
    }

    Truck {
        id: truckV
        z: 3
        y: root.groundY - height
        layerWidth: root.width
        onFinished: pile.reset()
    }

    Sleigh {
        id: sleighV
        z: 3
        y: root.groundY - height
        layerWidth: root.width
        onFinished: pile.reset()
    }

    Item {
        id: windowLayer
        anchors.fill: parent
        z: 1
    }
}
