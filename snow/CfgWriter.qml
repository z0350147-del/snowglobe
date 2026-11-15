import QtQuick
import Quickshell.Io

Item {
    id: w

    property var pending: ({})

    readonly property string pyCode: "import json,os,sys;p=os.path.expanduser('~/.config/snowfall/config.json');c=json.load(open(p)) if os.path.exists(p) else {};c.update(json.loads(sys.argv[1]));open(p,'w').write(json.dumps(c))"

    function set(key, value) {
        var p = pending;
        p[key] = value;
        pending = p;
        debounce.restart();
    }

    function flush() {
        if (Object.keys(pending).length === 0) return;
        if (proc.running) {
            debounce.restart();
            return;
        }
        var payload = JSON.stringify(pending);
        pending = ({});
        proc.command = ["python3", "-c", pyCode, payload];
        proc.running = true;
    }

    Timer {
        id: debounce
        interval: 90
        onTriggered: w.flush()
    }

    Process { id: proc }
}
