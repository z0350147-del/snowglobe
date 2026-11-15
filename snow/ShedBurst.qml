import QtQuick
import QtQuick.Particles

Emitter {
    id: em

    property real fallH: 400
    property real amount: 0.5
    property real accel: 480

    signal landed(real x0, real x1, real amt)

    readonly property real fallMs: Math.sqrt(2 * Math.max(40, fallH) / accel) * 1000

    group: "debris"
    enabled: true
    emitRate: 0
    lifeSpan: Math.round(fallMs)
    height: 6
    size: 4
    sizeVariation: 3

    velocity: AngleDirection {
        angle: 90
        angleVariation: 100
        magnitude: 40
        magnitudeVariation: 30
    }
    acceleration: AngleDirection {
        angle: 90
        magnitude: em.accel
    }

    Component.onCompleted: burst(Math.max(4, Math.min(260, Math.round(width * amount * 0.4))))

    Timer {
        interval: em.fallMs + 300
        running: true
        onTriggered: {
            em.landed(em.x, em.x + em.width, em.amount);
            em.destroy();
        }
    }
}
