import QtQuick
import "theme" as Theme
import ".."
import Quickshell.Widgets

Item {
    id: root

    anchors.fill: parent

    MouseArea {
        id: bar_mouse

        anchors.fill: parent

        onDoubleClicked: {
            AppState.bar_expanded = !AppState.bar_expanded
        }
    }

    Rectangle {
        id: btn
        width: 20
        height: 20
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Vars.bar_edge_space
        radius: 20
        color: "transparent"

        IconImage {
            anchors.fill: parent
            // text: "launch"
            // anchors.centerIn: parent
            // color: Theme.Colors.green
            // font {
            //     pixelSize: 16
            //     family: "Material Symbols Rounded"
            // }

            source: "file:///home/arch/airootfs/root/configs/quickshell/bar/icons/arch.svg"
            mipmap: true
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
        anchors.verticalCenter: parent.verticalCenter

        implicitHeight: Vars.bar_height
        implicitWidth: right_stat_row.width

        color: "transparent"

        radius: morpher.radius

        Row {
            id: right_stat_row

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            spacing: 5

            Row {
                id: right_2
                visible: opacity > 0

                opacity: AppState.bar_expanded ? 1 : 0

                Behavior on opacity {
                    NumAnim {}
                }

                anchors.verticalCenter: parent.verticalCenter

                spacing: 5

                VolTune {
                    id: vol_tune
                }
            }

            // Bluetooth {
            //     id: bluetooth
            // }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter

                implicitHeight: width
                implicitWidth: network.width

                radius: Vars.rad

                color: "transparent"

                Network {
                    id: network
                    anchors.centerIn: parent
                }
            }

            Battery {
                id: battery
            }
        }
    }
}