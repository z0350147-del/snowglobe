import QtQuick
import Quickshell.Services.Mpris

// Окремий файл: якщо модуль MPRIS недоступний, зламається тільки він, а не весь сніг.
Item {
    readonly property bool playing: {
        var ps = Mpris.players.values;
        for (var i = 0; i < ps.length; i++)
            if (ps[i].isPlaying) return true;
        return false;
    }
}
