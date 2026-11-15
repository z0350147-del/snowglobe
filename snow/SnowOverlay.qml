import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    property bool settingsOpen: false

    IpcHandler {
        target: "snow"
        function settings(): void { root.settingsOpen = !root.settingsOpen; }
        function open(): void { root.settingsOpen = true; }
        function close(): void { root.settingsOpen = false; }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: sc
            required property var modelData
            readonly property bool primary: Quickshell.screens.length > 0 && modelData.name === Quickshell.screens[0].name

            PanelWindow {
                id: win
                screen: sc.modelData

                visible: SnowConfig.level > 0 && !snowLayer.gameActive
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "snowfall"
                anchors { top: true; bottom: true; left: true; right: true }
                mask: Region {}

                SnowLayer {
                    id: snowLayer
                    anchors.fill: parent
                    screenObj: sc.modelData
                }
            }

            // ---- thin strips above the snow on window tops: sweep + make balls ----
            Variants {
                model: snowLayer.stripKeys

                PanelWindow {
                    id: hit
                    required property var modelData
                    readonly property var info: snowLayer.strips[modelData] || ({ x: 0, y: 0, w: 1, h: 1 })

                    screen: sc.modelData
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.namespace: "snowfall-hit"
                    anchors { top: true; left: true }
                    margins { top: hit.info.y; left: hit.info.x }
                    implicitWidth: hit.info.w
                    implicitHeight: hit.info.h

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.RightButton
                        cursorShape: ma.pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                        onPositionChanged: function(m) {
                            var gx = hit.info.x + m.x;
                            var gy = hit.info.y + m.y;
                            if (ma.pressed) {
                                snowLayer.ballMove(gx, gy);
                                if (m.x >= 0 && m.x <= hit.width && m.y >= 0 && m.y <= hit.height)
                                    snowLayer.ballGrow(snowLayer.brush(hit.modelData, gx, gy, true));
                            } else {
                                snowLayer.brush(hit.modelData, gx, gy, false);
                            }
                        }
                        onPressed: function(m) {
                            var gx = hit.info.x + m.x;
                            var gy = hit.info.y + m.y;
                            snowLayer.ballStart(gx, gy);
                            snowLayer.ballGrow(snowLayer.brush(hit.modelData, gx, gy, true));
                        }
                        onReleased: snowLayer.ballRelease()
                        onCanceled: snowLayer.ballRelease()
                    }
                }
            }

            // ---- one grab zone per snowman: drag them around with the left button ----
            Variants {
                model: snowLayer.snowmen

                PanelWindow {
                    id: sh
                    required property var modelData
                    readonly property var man: modelData
                    property bool dragging: false
                    property real fx: 0
                    property real fy: 0

                    screen: sc.modelData
                    visible: !!man && !man.melting && !snowLayer.gameActive
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.namespace: "snowfall-hit"
                    anchors { top: true; left: true }
                    margins {
                        top: sh.dragging ? sh.fy : Math.round(sh.man ? sh.man.hitY : 0)
                        left: sh.dragging ? sh.fx : Math.round(sh.man ? sh.man.hitX : 0)
                    }
                    implicitWidth: Math.max(1, Math.round(sh.man ? sh.man.hitW : 1))
                    implicitHeight: Math.max(1, Math.round(sh.man ? sh.man.hitH : 1))

                    MouseArea {
                        id: sma
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                        cursorShape: sma.pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                        onPressed: function(m) {
                            if (!sh.man) return;
                            sh.fx = Math.round(sh.man.hitX);
                            sh.fy = Math.round(sh.man.hitY);
                            sh.dragging = true;
                            sh.man.grab(sh.fx + m.x, sh.fy + m.y);
                        }
                        onPositionChanged: function(m) {
                            if (sma.pressed && sh.man) sh.man.dragTo(sh.fx + m.x, sh.fy + m.y);
                        }
                        onReleased: {
                            sh.dragging = false;
                            if (sh.man) sh.man.drop();
                        }
                        onCanceled: {
                            sh.dragging = false;
                            if (sh.man) sh.man.drop();
                        }
                    }
                }
            }

            // ---- one grab zone per resting ball: pick it up, roll it and throw it with the left button ----
            Variants {
                model: snowLayer.balls

                PanelWindow {
                    id: bz
                    required property var modelData
                    readonly property var b: modelData
                    property bool dragging: false
                    property real fx: 0
                    property real fy: 0
                    readonly property real zs: b ? Math.max(28, b.d + 12) : 28

                    screen: sc.modelData
                    visible: !!b && (bz.dragging || (b.resting && !b.held)) && !snowLayer.gameActive
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.namespace: "snowfall-hit"
                    anchors { top: true; left: true }
                    margins {
                        top: bz.dragging ? bz.fy : Math.round(bz.b ? bz.b.cy - bz.zs / 2 : 0)
                        left: bz.dragging ? bz.fx : Math.round(bz.b ? bz.b.cx - bz.zs / 2 : 0)
                    }
                    implicitWidth: Math.round(bz.zs)
                    implicitHeight: Math.round(bz.zs)

                    MouseArea {
                        id: bma
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                        cursorShape: bma.pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                        onPressed: function(m) {
                            if (!bz.b) return;
                            bz.fx = Math.round(bz.b.cx - bz.zs / 2);
                            bz.fy = Math.round(bz.b.cy - bz.zs / 2);
                            bz.dragging = true;
                            bz.b.grab(bz.fx + m.x, bz.fy + m.y);
                        }
                        onPositionChanged: function(m) {
                            if (bma.pressed && bz.b) bz.b.drag(bz.fx + m.x, bz.fy + m.y);
                        }
                        onReleased: {
                            bz.dragging = false;
                            if (bz.b) bz.b.release();
                        }
                        onCanceled: {
                            bz.dragging = false;
                            if (bz.b) bz.b.release();
                        }
                    }
                }
            }

            // ---- strip over the snow pile at the bottom: make balls from it ----
            PanelWindow {
                id: pileHit
                readonly property real hhCalc: Math.min(72, Math.max(12, Math.round((snowLayer.pileAvg + 10) / 4) * 4))
                property bool holding: false
                property real holdH: 72
                readonly property real hh: holding ? holdH : hhCalc

                screen: sc.modelData
                visible: ((snowLayer.pileOn && snowLayer.pileAvg > 4) || pileHit.holding) && !snowLayer.gameActive
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "snowfall-hit"
                anchors { top: true; left: true }
                margins { top: Math.round(snowLayer.groundY - pileHit.hh); left: 0 }
                implicitWidth: Math.max(1, Math.round(snowLayer.width))
                implicitHeight: pileHit.hh

                MouseArea {
                    id: pma
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.RightButton
                    cursorShape: pma.pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                    onPressed: function(m) {
                        pileHit.holdH = pileHit.hhCalc;
                        pileHit.holding = true;
                        var gy = Math.round(snowLayer.groundY - pileHit.hh) + m.y;
                        snowLayer.ballStart(m.x, gy);
                    }
                    onPositionChanged: function(m) {
                        if (!pma.pressed) return;
                        var gy = Math.round(snowLayer.groundY - pileHit.hh) + m.y;
                        snowLayer.ballMove(m.x, gy);
                        snowLayer.takePile(m.x, 0.03);
                    }
                    onReleased: { pileHit.holding = false; snowLayer.ballRelease(); }
                    onCanceled: { pileHit.holding = false; snowLayer.ballRelease(); }
                }
            }

            // ---- settings panel (primary screen only) ----
            SnowSettings {
                screen: sc.modelData
                world: snowLayer
                visible: root.settingsOpen && sc.primary
                onCloseRequested: root.settingsOpen = false
            }
        }
    }
}
