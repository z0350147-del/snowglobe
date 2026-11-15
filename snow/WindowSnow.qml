import QtQuick
import QtQuick.Shapes

Item {
    id: ws

    property real wx: 0
    property real wy: 0
    property real ww: 100
    property real maxH: 24
    property var segs: []
    property real seed: 1

    property real amount: 0
    property real targetAmount: 1
    property int growMs: 90000
    property int settleMs: 1200
    property string geo: ""
    property string segKey: ""
    property int curMs: growMs
    property real slumpFrac: 0.3
    signal overflow()
    property var holes: []
    property var hsArr: []
    property bool holesDirty: false

    property string pathBack: "M0,0"
    property string pathFront: "M0,0"

    x: wx
    y: wy - maxH
    width: ww
    height: maxH + 2
    visible: amount > 0.01

    function restart() {
        grow.stop();
        slumpAnim.stop();
        holdTimer.stop();
        curMs = growMs;
        holes = [];
        amount = 0;
        settle.restart();
    }

    function nBins() {
        return Math.max(2, Math.ceil(ww / 6));
    }

    function carve(cx, r) {
        var inSeg = false;
        for (var s = 0; s < segs.length; s++)
            if (cx >= segs[s][0] && cx <= segs[s][1]) inSeg = true;
        if (!inSeg) return 0;
        var n = nBins();
        var h = holes.slice();
        if (h.length !== n + 1) {
            h = new Array(n + 1);
            for (var z = 0; z <= n; z++) h[z] = 1;
        }
        var removed = 0;
        for (var i = 0; i <= n; i++) {
            var d = Math.abs(Math.min(ww, i * 6) - cx);
            if (d >= r) continue;
            var f = d / r;
            var nv = 0.6 * f * f;
            if (nv < h[i]) {
                removed += (h[i] - nv);
                h[i] = nv;
            }
        }
        if (removed > 0) {
            holes = h;
            holesDirty = true;
        }
        return removed * amount * 0.25;
    }

    function slump() {
        grow.stop();
        slumpAnim.to = ws.amount * (1 - ws.slumpFrac);
        slumpAnim.restart();
    }

    // ---- snow_patch27 ----
    // Висота снігу (px над верхом вікна) у точці lx (координата всередині вікна, до масштабу amount).
    // Беремо 0.94 від висоти заднього шару: кулька трохи занурюється в сніг, а не лежить на самому краї.
    function heightAt(lx) {
        var a = hsArr;
        if (!a || a.length < 2) return 0;
        var f = Math.max(0, Math.min(a.length - 1.0001, lx / 6));
        var i = Math.floor(f);
        var t = f - i;
        return (a[i] * (1 - t) + a[i + 1] * t) * 0.94;
    }
    // ---- /snow_patch27 ----

    function rebuild() {
        var H = ws.height;
        var maxH = ws.maxH;
        var step = 6;
        var n = Math.max(2, Math.ceil(ww / step));
        var taper = Math.max(12, Math.min(48, ww * 0.12));
        var hs = new Array(n + 1);
        var xs = new Array(n + 1);
        for (var i = 0; i <= n; i++) {
            var x = Math.min(ww, i * step);
            xs[i] = x;
            var t = 0;
            for (var s = 0; s < segs.length; s++) {
                var a0 = segs[s][0], a1 = segs[s][1];
                if (x >= a0 && x <= a1) {
                    var d = Math.min(x - a0, a1 - x);
                    t = Math.max(t, Math.min(1, d / taper));
                }
            }
            t = t * t * (3 - 2 * t);
            var p = 0.68 + 0.18 * Math.sin(x * 0.021 + seed) + 0.10 * Math.sin(x * 0.057 + seed * 2.3);
            hs[i] = maxH * p * t * ((ws.holes.length === n + 1) ? ws.holes[i] : 1);
        }
        for (var pass = 0; pass < 3; pass++) {
            var tmp = hs.slice();
            for (var j = 1; j < n; j++)
                tmp[j] = (hs[j - 1] + 2 * hs[j] + hs[j + 1]) / 4;
            hs = tmp;
        }
        ws.hsArr = hs;
        var lo = H - maxH * 1.05;
        function cl(v) { return Math.max(lo, Math.min(H, v)); }
        function mk(k) {
            var py = new Array(n + 1);
            for (var q = 0; q <= n; q++) py[q] = H - hs[q] * k;
            var d = "M0," + H.toFixed(1) + " L" + xs[0].toFixed(1) + "," + py[0].toFixed(1);
            for (var m = 0; m < n; m++) {
                var im = Math.max(0, m - 1), ip = Math.min(n, m + 2);
                var c1x = xs[m] + (xs[m + 1] - xs[im]) / 6;
                var c1y = cl(py[m] + (py[m + 1] - py[im]) / 6);
                var c2x = xs[m + 1] - (xs[ip] - xs[m]) / 6;
                var c2y = cl(py[m + 1] - (py[ip] - py[m]) / 6);
                d += " C" + c1x.toFixed(1) + "," + c1y.toFixed(1) + " " + c2x.toFixed(1) + "," + c2y.toFixed(1)
                     + " " + xs[m + 1].toFixed(1) + "," + py[m + 1].toFixed(1);
            }
            return d + " L" + ww.toFixed(1) + "," + H.toFixed(1) + " Z";
        }
        pathBack = mk(1.0);
        pathFront = mk(0.88);
    }

    onWwChanged: Qt.callLater(rebuild)
    onMaxHChanged: Qt.callLater(rebuild)
    onSegsChanged: Qt.callLater(rebuild)
    onSeedChanged: Qt.callLater(rebuild)
    Component.onCompleted: rebuild()

    onTargetAmountChanged: {
        if (!settle.running)
            grow.restart();
    }

    Timer {
        id: settle
        interval: ws.settleMs
        running: true
        onTriggered: grow.restart()
    }

    NumberAnimation {
        id: grow
        target: ws
        property: "amount"
        to: ws.targetAmount
        duration: ws.curMs
        easing.type: Easing.InOutSine
        onFinished: holdTimer.restart()
    }

    NumberAnimation {
        id: slumpAnim
        target: ws
        property: "amount"
        duration: 800
        easing.type: Easing.InOutQuad
        onFinished: {
            ws.curMs = Math.max(3000, Math.round(ws.growMs * ws.slumpFrac));
            grow.restart();
        }
    }

    Timer {
        id: holdTimer
        interval: 6000 + Math.round(Math.random() * 9000)
        onTriggered: {
            ws.overflow();
            interval = 6000 + Math.round(Math.random() * 9000);
        }
    }

    Timer {
        interval: 33
        running: ws.holesDirty
        onTriggered: {
            ws.holesDirty = false;
            ws.rebuild();
        }
    }

    Timer {
        interval: 400
        repeat: true
        running: ws.holes.length > 0 && ws.visible
        onTriggered: {
            var h = ws.holes.slice();
            var any = false;
            for (var i = 0; i < h.length; i++) {
                if (h[i] < 1) {
                    h[i] = Math.min(1, h[i] + 0.012);
                    if (h[i] < 1) any = true;
                }
            }
            ws.holes = any ? h : [];
            ws.rebuild();
        }
    }

    Shape {
        id: shape
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4
        transform: Scale {
            origin.x: 0
            origin.y: shape.height
            yScale: ws.amount
        }

        ShapePath {
            fillColor: "#d6e3f3"
            strokeColor: "transparent"
            strokeWidth: -1
            PathSvg { path: ws.pathBack }
        }
        ShapePath {
            fillColor: "#ffffff"
            strokeColor: "transparent"
            strokeWidth: -1
            PathSvg { path: ws.pathFront }
        }
    }
}
