import Quickshell
import QtQuick
import "./theme" as Theme

// bar
Item {
    id: bar
    anchors.fill: parent
    clip: true

    property bool bar_locked: true
    readonly property bool has_mouse: bar_mouse.containsMouse

    MouseArea {
        id: bar_mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton){
                bar.bar_locked = !bar.bar_locked
            }
        }
    }
    Rectangle {
        id: btn
        width: 22
        height: 22
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 6
        radius: 20
        color: "transparent" //Theme.Colors.green
        border {
            width: 1
            color: Theme.Colors.green
        }

        Text {
            text: "blur_on"
            anchors.centerIn: parent
            color: Theme.Colors.green
            font {
                pixelSize: 16
                family: "Material Symbols Rounded"
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                panel.change_state("launcher")
            }
        }
    }

    Workspaces {}
    Clock {}

    Rectangle {
        implicitHeight: rr.height
        implicitWidth: rr.width + 10
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 7
        radius: morpher.radius
        color: "transparent"
        Row {
            id: rr
            anchors.centerIn: parent
            spacing: 5
            Network {
                id: network
            }
            Battery {}
        }
    }

    // animations
    Behavior on opacity {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

} // bar