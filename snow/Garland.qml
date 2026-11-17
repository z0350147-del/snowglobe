import QtQuick
import QtQuick.Shapes

// Одна гірлянда: дріт + лампочки. Точки задаються в координатах батька.
// kind 0 — лампочки на дроті, kind 1 — "бурульки" (короткі підвіски від горизонтального дроту).
Item {
    id: g

    property var pts: []
    property real spacing: 16
    property int kind: 0
    property bool caps: true
    property real scaleK: 1
    property int offset: 0
    property real clock: 0
    property bool playing: false
    property bool lite: false

    readonly property real bs: 7 * scaleK * SnowConfig.garlandSize
    readonly property var geo: build()

    x: geo.ox
    y: geo.oy
    width: geo.w
    height: geo.h

    function colorAt(i) {
        var p = SnowConfig.garlandColors;
        return p[((i + offset) % p.length + p.length) % p.length];
    }

    function lvl(i) {
        var m = SnowConfig.garlandMode;
        if (m === 0) return 1;
        var t = clock * SnowConfig.garlandSpeed;
        var n = i + offset;
        if (m === 1)
            return 0.35 + 0.65 * (0.5 + 0.5 * Math.sin(t * 2.4 + n * 2.37));
        if (m === 2) {
            var ph = (((n - Math.floor(t * 6)) % 6) + 6) % 6;
            return ph === 0 ? 1 : (ph === 1 ? 0.75 : (ph === 2 ? 0.5 : 0.28));
        }
        if (!playing) return 0.55;
        var p, c;
        if (BeatEngine.active) {
            p = BeatEngine.pulse;
            c = BeatEngine.beatCount;
        } else {
            p = Math.exp(-((t * 2) % 1) * 4);
            c = Math.floor(t * 2);
        }
        var v = (c % 4 === 0 || (n + c) % 2 === 0) ? p : p * 0.3;
        return 0.25 + 0.75 * v;
    }

    function build() {
        var P = pts;
        var empty = { ox: 0, oy: 0, w: 1, h: 1, wire: "", bulbs: [], drops: [], a: [0, 0], b: [0, 0] };
        if (!P || P.length < 2) return empty;
        var minX = 1e9, minY = 1e9, maxX = -1e9, maxY = -1e9;
        var total = 0;
        for (var i = 0; i < P.length; i++) {
            minX = Math.min(minX, P[i][0]);
            minY = Math.min(minY, P[i][1]);
            maxX = Math.max(maxX, P[i][0]);
            maxY = Math.max(maxY, P[i][1]);
            if (i > 0) total += Math.sqrt(Math.pow(P[i][0] - P[i - 1][0], 2) + Math.pow(P[i][1] - P[i - 1][1], 2));
        }
        var sp = Math.max(6, spacing);
        if (total / sp > 300) sp = total / 300;
        var drop = 30 * scaleK * SnowConfig.garlandSize;
        var pad = bs * 2 + 4;
        var ox = minX - pad, oy = minY - pad;
        var w = maxX - minX + pad * 2;
        var h = maxY - minY + pad * 2 + (kind === 1 ? drop : bs * 1.4);
        var wire = "M" + (P[0][0] - ox).toFixed(1) + "," + (P[0][1] - oy).toFixed(1);
        for (var k = 1; k < P.length; k++)
            wire += " L" + (P[k][0] - ox).toFixed(1) + "," + (P[k][1] - oy).toFixed(1);
        var bulbs = [], drops = [];
        var acc = 0, next = sp * 0.5, n = 0;
        for (var s = 0; s < P.length - 1; s++) {
            var dx = P[s + 1][0] - P[s][0], dy = P[s + 1][1] - P[s][1];
            var len = Math.sqrt(dx * dx + dy * dy);
            while (next <= acc + len + 0.001) {
                var t = len > 0 ? (next - acc) / len : 0;
                var bx = P[s][0] + dx * t - ox, by = P[s][1] + dy * t - oy;
                if (kind === 1) {
                    var L = (9 + ((n * 7) % 13)) * scaleK * SnowConfig.garlandSize;
                    drops.push({ x: bx, y: by, len: L });
                    bulbs.push({ x: bx, y: by + L, i: n });
                } else {
                    bulbs.push({ x: bx, y: by, i: n });
                }
                n++;
                next += sp;
            }
            acc += len;
        }
        var last = P[P.length - 1];
        return { ox: ox, oy: oy, w: w, h: h, wire: wire, bulbs: bulbs, drops: drops,
                 a: [P[0][0] - ox, P[0][1] - oy], b: [last[0] - ox, last[1] - oy] };
    }

    Shape {
        x: 0
        y: 0
        width: g.width
        height: g.height
        ShapePath {
            strokeColor: "#4a5058"
            strokeWidth: 1.4 * Math.max(0.8, g.scaleK)
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: g.geo.wire }
        }
    }

    Repeater {
        model: g.geo.drops
        Rectangle {
            required property var modelData
            x: modelData.x - 0.6
            y: modelData.y
            width: 1.2
            height: modelData.len
            color: "#4a5058"
        }
    }

    Rectangle {
        visible: g.caps && g.kind === 0
        x: g.geo.a[0] - 2.2
        y: g.geo.a[1] - 2.2
        width: 4.4
        height: 4.4
        radius: 2.2
        color: "#2b2f33"
    }
    Rectangle {
        visible: g.caps && g.kind === 0
        x: g.geo.b[0] - 2.2
        y: g.geo.b[1] - 2.2
        width: 4.4
        height: 4.4
        radius: 2.2
        color: "#2b2f33"
    }

    Repeater {
        model: g.geo.bulbs
        Item {
            id: b
            required property var modelData
            readonly property color col: g.colorAt(modelData.i)
            readonly property real v: Math.max(0, Math.min(1, g.lvl(modelData.i) * SnowConfig.garlandBright))
            x: modelData.x
            y: modelData.y

            Rectangle {
                visible: !g.lite
                x: -g.bs * 1.15
                y: g.bs * 0.3 + g.bs * 0.58 - g.bs * 1.15
                width: g.bs * 2.3
                height: g.bs * 2.3
                radius: g.bs * 1.15
                color: b.col
                opacity: b.v * 0.24
            }
            Rectangle {
                x: -g.bs * 0.22
                y: -g.bs * 0.1
                width: g.bs * 0.44
                height: g.bs * 0.5
                radius: 1
                color: "#30343a"
            }
            Rectangle {
                x: -g.bs / 2
                y: g.bs * 0.3
                width: g.bs
                height: g.bs * 1.16
                radius: g.bs / 2
                color: Qt.rgba(b.col.r * (0.16 + 0.84 * b.v), b.col.g * (0.16 + 0.84 * b.v), b.col.b * (0.16 + 0.84 * b.v), 1)
            }
        }
    }
}
