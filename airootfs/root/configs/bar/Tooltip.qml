import Quickshell
import QtQuick
import "./theme" as Theme



Rectangle {
    id: tooltip_container
    opacity: 0
    implicitHeight: tooltip_lable.height + 5
    implicitWidth: tooltip_lable.width + 15
    y: bar.height - 20
    Component.onCompleted: {
        x += 15
    }
    color: morpher.color
    radius: morpher.radius

    border {
        width: 1
        color: Qt.alpha(Theme.Colors.foreground, 0.35)
    }

    // vars
    property int display_duration: 500
    property string text: "..."

    Timer {
        id: tooltip_timer
        interval: display_duration
        repeat: false

        onTriggered: {
            tooltip_container.opacity = 1
            tooltip_container.y = bar.height + 3
        }
    }

    Text {
        id: tooltip_lable
        anchors.centerIn: parent
        text: tooltip_container.text
        color: Theme.Colors.foreground

        font {
            pixelSize: 15
        }
    }

    Behavior on y {
        SpringAnimation {
            spring: 3
            damping: 0.25
            mass: 1
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: 150
        }
    }
    function tooltip(ty="end") {
        if (ty==="end") {
            tooltip_timer.stop()
            tooltip_container.opacity = 0
            tooltip_container.y = bar.height - 20
            return
        }
        tooltip_timer.restart()
    }
}

