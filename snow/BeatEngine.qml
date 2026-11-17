pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Визначення ритму музики для гірлянд і сніговиків.
// Слухає басовий канал через cava (якщо він встановлений), знаходить удари
// і темп. Без cava (або в режимі економії) вмикається рівний метроном 120 уд./хв.
// Свій конфіг cava можна покласти в ~/.config/snowfall/cava.conf (потрібен
// вивід raw/ascii, 8 стовпців, розділювач ';', рядки через \n).
Singleton {
    id: root

    property bool playing: false
    property bool cavaOk: true
    property real pulse: 0
    property int beatCount: 0
    property real bpm: 120
    property real avg: 0
    property real prevBass: 0
    property real lastOnset: 0
    property var intervals: []

    readonly property bool wanted: !SnowConfig.paused && !SnowConfig.saveMode
        && (SnowConfig.dance || (SnowConfig.garland && SnowConfig.garlandMode === 3))
    readonly property bool active: wanted && playing
    readonly property int beatMs: Math.round(60000 / Math.max(60, Math.min(190, bpm)))

    readonly property string script:
        "CF=\"${XDG_RUNTIME_DIR:-/tmp}/snowfall_cava.conf\"\n" +
        "if [ -f \"$HOME/.config/snowfall/cava.conf\" ]; then exec cava -p \"$HOME/.config/snowfall/cava.conf\"; fi\n" +
        "cat > \"$CF\" <<'EOF'\n" +
        "[general]\nbars = 8\nframerate = 30\n" +
        "[input]\nmethod = pulse\nsource = auto\n" +
        "[output]\nmethod = raw\nraw_target = /dev/stdout\ndata_format = ascii\n" +
        "ascii_max_range = 100\nbar_delimiter = 59\nframe_delimiter = 10\n" +
        "EOF\n" +
        "exec cava -p \"$CF\"\n"

    onPlayingChanged: { if (playing) cavaOk = true; }
    onActiveChanged: {
        if (!active) {
            pulse = 0;
            lastOnset = 0;
            avg = 0;
            prevBass = 0;
            intervals = [];
        }
    }

    function fire(strength) {
        pulse = Math.max(pulse, strength);
        beatCount = beatCount + 1;
        ghost.restart();
    }

    function onset(now) {
        if (lastOnset > 0) {
            var dt = now - lastOnset;
            if (dt >= 280 && dt <= 1000) {
                var a = intervals.slice();
                a.push(dt);
                if (a.length > 12) a.shift();
                intervals = a;
                var s = a.slice().sort(function (x, y) { return x - y; });
                var med = s[Math.floor(s.length / 2)];
                var b = 60000 / med;
                while (b > 180) b = b / 2;
                while (b < 70) b = b * 2;
                bpm = bpm * 0.75 + b * 0.25;
            }
        }
        lastOnset = now;
        fire(1.0);
    }

    function feed(line) {
        var a = String(line).split(";");
        if (a.length < 4) return;
        var bs = ((Number(a[0]) || 0) + (Number(a[1]) || 0)) / 2;
        var now = Date.now();
        avg = avg * 0.93 + bs * 0.07;
        var rising = bs > prevBass + 3;
        prevBass = bs;
        if (rising && bs > avg * 1.25 + 10 && now - lastOnset > 240)
            onset(now);
    }

    Process {
        id: cava
        running: root.active && root.cavaOk
        command: ["sh", "-c", root.script]
        stdout: SplitParser {
            onRead: function (line) { root.feed(line); }
        }
        onExited: function (code, status) {
            if (root.active && code !== 0) root.cavaOk = false;
        }
    }

    Timer {
        id: ghost
        interval: root.beatMs
        repeat: true
        running: root.active
        onTriggered: {
            if (Date.now() - root.lastOnset > root.beatMs * 1.5)
                root.fire(0.6);
        }
    }

    Timer {
        interval: 33
        repeat: true
        running: root.active && root.pulse > 0.005
        onTriggered: {
            root.pulse = root.pulse * 0.78;
            if (root.pulse < 0.01) root.pulse = 0;
        }
    }
}
