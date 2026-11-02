import QtQuick
import ".."
import "theme"

Rectangle {
    id: root

    anchors.verticalCenter: parent.verticalCenter

    implicitHeight: bluetooth_icon.height
    implicitWidth: bluetooth_icon.width / 1.25

    radius: Vars.rad

    color: "transparent"

    MouseArea {
        anchors.fill: parent
        onClicked: {
            print("blue")
        }
    }

    Text {
        id: bluetooth_icon

        text: ""

        color: Colors.foreground

        font {
            family: "Material Symbols Rounded"
            pixelSize: 20
        }
    }
}