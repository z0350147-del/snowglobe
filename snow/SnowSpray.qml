import QtQuick

// Бризки снігу від відвала: невеликий пул частинок, які підлітають і падають.
Item {
    id: sp

    property real groundY: 1000
    property bool lite: false

    readonly property int n: 28
    property var st: []
    property int cursor: 0
    property bool busy: false

    function burst(x, y, amount) {
        if (lite) return;
        var k = Math.max(1, Math.min(4, Math.round(amount / 90)));
        for (var j = 0; j < k; j++) {
            var i = cursor;
            cursor = (cursor + 1) % n;
            var it = rep.itemAt(i);
            if (!it) continue;
            it.x = x + (Math.random() - 0.5) * 8;
            it.y = y;
            it.opacity = 1;
            it.visible = true;
            st[i] = { vx: -(10 + Math.random() * 90), vy: -(110 + Math.random() * 190), life: 0 };
        }
        busy = true;
    }

    Component.onCompleted: {
        var a = [];
        for (var i = 0; i < n; i++) a.push(null);
        st = a;
    }

    Timer {
        interval: 33
        repeat: true
        running: sp.busy
        onTriggered: {
            var alive = 0;
            var dt = 0.033;
            for (var i = 0; i < sp.n; i++) {
                var p = sp.st[i];
                var it = rep.itemAt(i);
                if (!p || !it) continue;
                p.vy += 900 * dt;
                it.x += p.vx * dt;
                it.y += p.vy * dt;
                p.life += dt;
                it.opacity = Math.max(0, 1 - p.life / 0.9);
                if (p.life >= 0.9 || it.y > sp.groundY) {
                    it.visible = false;
                    sp.st[i] = null;
                } else {
                    alive++;
                }
            }
            if (alive === 0) sp.busy = false;
        }
    }

    Repeater {
        id: rep
        model: sp.n
        Rectangle {
            required property int index
            visible: false
            width: 2 + (index % 3)
            height: width
            radius: width / 2
            color: index % 2 === 0 ? "#ffffff" : "#d6e3f3"
        }
    }
}
