import QtQuick


NumberAnimation {
    // [ fast | medium | slow ]
    property string dur: "medium"
    // [ default | spring ]
    property string curve: "default"

    readonly property var curveStandard: [0.2, 0, 0, 1, 1, 1]
    readonly property var curveEmphasized: [0.05, 0, 0.133333, 0.06, 0.166667, 0.4, 0.208333, 0.82, 0.25, 1, 1, 1]
    readonly property var curveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
    readonly property var curveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
    readonly property var curveSlowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1]
    readonly property var curveFastEffects: [0.31, 0.94, 0.34, 1, 1, 1]
    readonly property var curveDefaultEffects: [0.34, 0.8, 0.34, 1, 1, 1]
    readonly property var curveSlowEffects: [0.34, 0.88, 0.34, 1, 1, 1]

    duration: {
        if (dur === "medium")
            return 300;
        if (dur === "fast")
            return 150;
        if (dur === "slow")
            return 500;
    }
    easing.type: Easing.Bezier
    easing.bezierCurve: {
        if (curve === "default")
            return curveSlowEffects;
        if (curve === "spring")
            return curveSlowSpatial
    }
}