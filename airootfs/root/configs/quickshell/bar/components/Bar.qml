import QtQuick
import "theme" as Theme
import ".."

Item {
    id: bar

    anchors.fill: parent

    Rectangle {
        id: btn
        width: 22
        height: 22
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Vars.bar_edge_space
        radius: 20
        color: "transparent"
        border {
            width: 1
            color: Theme.Colors.green
        }

        Text {
            text: "launch"
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

    Workspaces {
        id: workspace
        anchors.leftMargin: Vars.bar_edge_space + btn.width+btn.anchors.leftMargin
    }

    Clock {}

    Rectangle {
        id: right_stat

        anchors.right: parent.right
        anchors.rightMargin: Vars.bar_edge_space

        implicitHeight: Vars.bar_height
        implicitWidth: right_stat_row.width

        color: "transparent"

        radius: morpher.radius

        Row {
            id: right_stat_row

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            spacing: 5

            Network {
                id: network
            }

            Battery {
                id: battery
            }
        }
    }
}