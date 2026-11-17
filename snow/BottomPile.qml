import QtQuick
import QtQuick.Shapes

Item {
    id: pile

    property bool active: false
    property real density: 0
    property real cap: 36
    property real growSeconds: 60
    property real avg: 0
    property real fill: 0
    property bool sweeping: false
    property real sweepX: 0
    property real lastPlowX: -1

    signal overflowed()

    readonly property int binW: 6
    readonly property int nb: Math.max(2, Math.ceil(width / binW))
    readonly property real boxH: cap + 6

    property var hs: []
    property var noise: []
    property real prevSum: -1
    property string pathBack: "M0,0"
    property string pathFront: "M0,0"

    height: boxH
    visible: avg > 0.3

    function reset() {
        var n = nb + 1;
        var z = new Array(n);
        var nz = new Array(n);
        for (var i = 0; i < n; i++) {
            z[i] = 0;
            nz[i] = 0.78 + 0.12 * Math.sin(i * 0.21 + 1.7) + 0.10 * Math.sin(i * 0.067 + 0.4);
        }
        hs = z;
        noise = nz;
        avg = 0;
        fill = 0;
        sweeping = false;
        lastPlowX = -1;
        prevSum = -1;
        buildPath();
    }

    function buildPath() {
        var N = nb;
        var H = boxH;
        var w = width;
        var xs = new Array(N + 1);
        for (var i = 0; i <= N; i++) xs[i] = Math.min(w, i * binW);
        xs[N] = w;
        var lo = H - cap * 1.05;
        function cl(v) { return Math.max(lo, Math.min(H, v)); }
        function mk(k) {
            var py = new Array(N + 1);
            for (var q = 0; q <= N; q++) py[q] = H - hs[q] * k;
            var d = "M0," + H.toFixed(1) + " L" + xs[0].toFixed(1) + "," + py[0].toFixed(1);
            for (var m = 0; m < N; m++) {
                var im = Math.max(0, m - 1), ip = Math.min(N, m + 2);
                var c1x = xs[m] + (xs[m + 1] - xs[im]) / 6;
                var c1y = cl(py[m] + (py[m + 1] - py[im]) / 6);
                var c2x = xs[m + 1] - (xs[ip] - xs[m]) / 6;
                var c2y = cl(py[m + 1] - (py[ip] - py[m]) / 6);
                d += " C" + c1x.toFixed(1) + "," + c1y.toFixed(1) + " " + c2x.toFixed(1) + "," + c2y.toFixed(1)
                     + " " + xs[m + 1].toFixed(1) + "," + py[m + 1].toFixed(1);
            }
            return d + " L" + w.toFixed(1) + "," + H.toFixed(1) + " Z";
        }
        pathBack = mk(1.0);
        pathFront = mk(0.88);
    }

    function step() {
        if (hs.length !== nb + 1) reset();
        if (sweeping) return;
        var n = nb + 1;
        if (!sweeping)
            fill = Math.min(1.5, fill + (0.15 + 0.85 * density) / (Math.max(5, growSeconds) * 8) * 0.25);
        var tgt = cap * Math.min(1.0, 0.25 + 0.5 * density + fill);
        var rate = cap * 0.6 / Math.max(5, growSeconds) * 0.25;
        var out = new Array(n);
        for (var i = 0; i < n; i++) {
            var t = tgt * noise[i];
            var h = hs[i];
            out[i] = h < t ? Math.min(t, h + rate) : h;
        }
        var sm = out.slice();
        for (var j = 1; j < n - 1; j++)
            sm[j] = (out[j - 1] + 2 * out[j] + out[j + 1]) / 4;
        var sum = 0;
        for (var k = 0; k < n; k++) sum += sm[k];
        hs = sm;
        avg = sum / n;
        if (Math.abs(sum - prevSum) > 0.05) {
            prevSum = sum;
            buildPath();
        }
        if (!sweeping && avg >= cap * 0.72) {
            sweeping = true;
            overflowed();
        }
    }

    function addDebris(x0, x1, amt) {
        if (!active || sweeping) return;
        if (hs.length !== nb + 1) reset();
        var n = nb + 1;
        var a = Math.max(0, Math.floor(x0 / binW));
        var b = Math.min(n - 1, Math.ceil(x1 / binW));
        var out = hs.slice();
        for (var i = a; i <= b; i++)
            out[i] = Math.min(cap, out[i] + amt * cap * 0.10 * (0.6 + 0.4 * Math.random()));
        hs = out;
        prevSum = -1;
        buildPath();
    }

    // ---- snow_patch15 ----
    // Висота снігу (px над землею) у точці x (координати купи).
    // Повертає 0, якщо купи не видно або трактор уже прибрав сніг у цьому місці.
    function heightAt(x) {
        if (avg <= 0.3 || hs.length !== nb + 1) return 0;
        var f = Math.max(0, Math.min(nb - 0.0001, x / binW));
        var i = Math.floor(f);
        var t = f - i;
        var h = hs[i] * (1 - t) + hs[Math.min(nb, i + 1)] * t;
        return h * 0.88;
    }

    // Забирає сніг між x0 і x1. amt = сила (як у addDebris). Повертає, скільки забрано (сума висот у px).
    function takeSnow(x0, x1, amt) {
        if (sweeping || hs.length !== nb + 1) return 0;
        var n = nb + 1;
        var lo = Math.min(x0, x1);
        var hi = Math.max(x0, x1);
        var a = Math.max(0, Math.floor(lo / binW));
        var b = Math.min(n - 1, Math.ceil(hi / binW));
        if (b < a) return 0;
        var mid = (a + b) / 2;
        var half = Math.max(1, (b - a) / 2);
        var out = hs.slice();
        var taken = 0;
        for (var i = a; i <= b; i++) {
            var w = 1 - 0.5 * Math.abs(i - mid) / half;
            var d = Math.min(out[i], amt * cap * 0.10 * w);
            out[i] -= d;
            taken += d;
        }
        var sum = 0;
        for (var k = 0; k < n; k++) sum += out[k];
        hs = out;
        avg = sum / n;
        prevSum = -1;
        pathTimer.restart();
        return taken;
    }
    // ---- /snow_patch15 ----

    // ---- реалістичне прибирання: відвал знімає сніг стовпчик за стовпчиком ----
    // Викликається, поки техніка їде. bx — позиція леза. Повертає площу знятого снігу (px^2).
    // За лезом лишається тонка плівка снігу, а не ідеально чиста земля.
    function plow(bx) {
        if (hs.length !== nb + 1) return 0;
        var n = nb + 1;
        var from = lastPlowX < 0 ? width + binW : lastPlowX;
        if (bx >= from) return 0;
        var a = Math.max(0, Math.floor(bx / binW));
        var b = Math.min(n - 1, Math.ceil(from / binW));
        var film = Math.min(cap * 0.04, 2.5);
        var out = hs.slice();
        var taken = 0;
        for (var i = a; i <= b; i++) {
            var r = film * noise[i];
            if (out[i] > r) {
                taken += (out[i] - r) * binW;
                out[i] = r;
            }
        }
        var sum = 0;
        for (var k = 0; k < n; k++) sum += out[k];
        lastPlowX = bx;
        hs = out;
        avg = sum / n;
        prevSum = -1;
        buildPath();
        return taken;
    }

    // Техніка проїхала: лишаємо тонку плівку й дозволяємо снігу рости знову.
    function finishSweep() {
        if (hs.length !== nb + 1) { reset(); return; }
        var n = nb + 1;
        var film = Math.min(cap * 0.04, 2.5);
        var out = new Array(n);
        var sum = 0;
        for (var i = 0; i < n; i++) {
            out[i] = Math.min(hs[i], film * noise[i]);
            sum += out[i];
        }
        hs = out;
        avg = sum / n;
        fill = 0;
        sweeping = false;
        lastPlowX = -1;
        prevSum = -1;
        buildPath();
    }
    // ---- /реалістичне прибирання ----

    // відкладена перебудова форми купи після забору снігу (патч 26)
    Timer {
        id: pathTimer
        interval: 50
        onTriggered: pile.buildPath()
    }

    Component.onCompleted: reset()

    Timer {
        interval: 250
        repeat: true
        running: pile.active
        onTriggered: pile.step()
    }

    Item {
        x: 0
        y: 0
        height: pile.height
        width: pile.width
        clip: true

        Shape {
            x: 0
            y: 0
            width: pile.width
            height: pile.height
            layer.enabled: true
            layer.samples: 4

            ShapePath {
                fillColor: "#d6e3f3"
                strokeColor: "transparent"
                strokeWidth: -1
                PathSvg { path: pile.pathBack }
            }
            ShapePath {
                fillColor: "#ffffff"
                strokeColor: "transparent"
                strokeWidth: -1
                PathSvg { path: pile.pathFront }
            }
        }
    }
}
