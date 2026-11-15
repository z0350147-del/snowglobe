import QtQuick

Item {
    id: ball

    property var host: null
    property real cx: 0
    property real cy: 0
    property real d: 8
    property real vx: 0
    property real vy: 0
    property real rot: 0
    property bool held: true
    property bool resting: false
    property bool fed: false
    property bool growing: true
    property real offX: 0
    property real offY: 0
    property int bounces: 0
    property real lastX: 0
    property real lastY: 0
    property real lastT: 0
    property real dvx: 0
    property real dvy: 0

    signal splat(real gx, real gy, real dia)

    x: cx - d / 2
    y: cy - d / 2
    width: d
    height: d
    z: 6

    Behavior on d { NumberAnimation { duration: 90 } }

    onRestingChanged: {
        if (resting && host) host.queueSnowmanCheck();
    }

    function expire() {
        if (held) return;
        phys.stop();
        ball.splat(cx, cy + d / 2, d);
        ball.destroy();
    }

    function drag(gx, gy) {
        var t = Date.now();
        var dt = Math.max(8, t - lastT) / 1000;
        dvx = dvx * 0.5 + ((gx - lastX) / dt) * 0.5;
        dvy = dvy * 0.5 + ((gy - lastY) / dt) * 0.5;
        if (!growing) rot += (gx - lastX) / Math.max(4, d / 2) * 57.2958;
        lastX = gx;
        lastY = gy;
        lastT = t;
        cx = gx + offX;
        cy = gy + offY;
        wd.restart();
    }

    // повторне захоплення лежачої кульки (патч 28)
    function grab(gx, gy) {
        if (held) return;
        phys.stop();
        held = true;
        resting = false;
        vx = 0;
        vy = 0;
        dvx = 0;
        dvy = 0;
        offX = cx - gx;
        offY = cy - gy;
        lastX = gx;
        lastY = gy;
        lastT = Date.now();
        wd.restart();
    }

    function release() {
        if (!held) return;
        held = false;
        growing = false;
        resting = false;
        bounces = 0;
        var stale = (Date.now() - lastT) > 90;
        vx = stale ? 0 : Math.max(-1000, Math.min(1000, dvx));
        vy = stale ? 0 : Math.max(-1000, Math.min(1000, dvy));
        lastT = Date.now();
        phys.start();
    }

    Component.onCompleted: {
        lastX = cx;
        lastY = cy;
        lastT = Date.now();
        if (host) host.registerBall(ball);
    }

    Component.onDestruction: {
        if (host) host.unregisterBall(ball);
    }

    Timer {
        interval: 50
        repeat: true
        running: ball.held && ball.growing
        onTriggered: ball.d = Math.min(SnowConfig.ballMax, ball.d + 0.9 * SnowConfig.ballGrow)
    }

    Timer {
        id: wd
        interval: 4000
        running: ball.held
        onTriggered: ball.release()
    }

    Timer {
        id: life
        interval: 120000
        running: !ball.held
        onTriggered: ball.expire()
    }

    Timer {
        id: phys
        interval: ball.resting ? 90 : 16
        repeat: true
        onTriggered: {
            var L = ball.host;
            var t = Date.now();
            var dt = Math.min(0.033, (t - ball.lastT) / 1000);
            ball.lastT = t;
            if (dt <= 0) return;

            var r = ball.d / 2;
            var pb = ball.cy + r;
            var surf = false;
            var onBall = false;

            if (!ball.resting) {
                ball.vy += 1100 * dt;
                ball.cx += ball.vx * dt;
                ball.cy += ball.vy * dt;
                ball.rot += ball.vx * dt / Math.max(4, r) * 57.2958;
            }

            var sy = L ? L.surfaceY(ball.cx, pb - 1 - ball.d - 30) : 1e9;
            var bottom = ball.cy + r;
            if (bottom >= sy - 0.5 && (ball.resting || ball.vy >= 0)) {
                ball.cy = sy - r;
                if (!ball.resting && ball.vy > 260 && ball.bounces < 2) {
                    ball.vy = -ball.vy * 0.3;
                    ball.vx *= 0.75;
                    ball.bounces += 1;
                } else {
                    ball.vy = 0;
                    surf = true;
                }
            }

            if (L) {
                var bs = L.balls;
                for (var i = 0; i < bs.length; i++) {
                    var o = bs[i];
                    if (!o || o === ball || o.held) continue;
                    var dx = ball.cx - o.cx;
                    var dy = ball.cy - o.cy;
                    var md = r + o.d / 2;
                    var dist2 = dx * dx + dy * dy;
                    if (dist2 < 0.0001 || dist2 >= (md + 1.5) * (md + 1.5)) continue;
                    var dist = Math.sqrt(dist2);
                    var nx = dx / dist;
                    var ny = dy / dist;
                    var pen = md - dist;
                    if (pen > 0) {
                        var w = o.resting ? 1 : 0.5;
                        ball.cx += nx * pen * w;
                        ball.cy += ny * pen * w;
                        if (!o.resting) {
                            o.cx -= nx * pen * 0.5;
                            o.cy -= ny * pen * 0.5;
                        }
                        var vn = (ball.vx - o.vx) * nx + (ball.vy - o.vy) * ny;
                        if (vn < 0) {
                            var j = -1.15 * vn / (o.resting ? 1 : 2);
                            ball.vx += j * nx;
                            ball.vy += j * ny;
                            if (!o.resting) {
                                o.vx -= j * nx;
                                o.vy -= j * ny;
                            } else if (-vn > 140) {
                                o.resting = false;
                            }
                        }
                    }
                    if (ny < -0.9) onBall = true;
                    else if (ny < -0.3) {
                        ball.vx *= 0.995;
                        if (ball.resting) ball.resting = false;
                    }
                }
            }

            if (surf) {
                ball.vx *= Math.pow(0.03, dt);
                if (Math.abs(ball.vx) < 6) ball.vx = 0;
            }

            if (ball.resting) {
                if (!surf && !onBall) ball.resting = false;
            } else if ((surf || onBall) && Math.abs(ball.vx) < 8 && Math.abs(ball.vy) < 40) {
                ball.vx = 0;
                ball.vy = 0;
                ball.resting = true;
                if (surf && !ball.fed && L) {
                    ball.fed = true;
                    L.feedSnow(ball.cx, ball.cy + r, ball.d);
                }
            }

            if (L && (ball.cx < -60 || ball.cx > L.width + 60)) {
                phys.stop();
                ball.destroy();
            }
        }
    }

    Item {
        anchors.fill: parent
        rotation: ball.rot

        SequentialAnimation on scale {
            running: ball.held
            loops: Animation.Infinite
            NumberAnimation { to: 1.06; duration: 260; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.97; duration: 300; easing.type: Easing.InOutSine }
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "#f6faff"
            border.color: "#b8cde6"
            border.width: 1
        }
        Rectangle { x: parent.width * 0.25; y: parent.height * 0.2; width: parent.width * 0.22; height: width; radius: width / 2; color: "#dfeaf7" }
        Rectangle { x: parent.width * 0.58; y: parent.height * 0.55; width: parent.width * 0.18; height: width; radius: width / 2; color: "#dfeaf7" }
    }
}
