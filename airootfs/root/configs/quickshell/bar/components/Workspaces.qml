import QtQuick
import Quickshell.Hyprland
import "theme"
import ".."

Rectangle {
    id: root

    anchors.left: parent.left
    anchors.leftMargin: Vars.bar_edge_space

    implicitHeight: parent.height
    implicitWidth: ws_row.width

    color: "transparent"

    radius: Vars.rad
    
    
    // Timer {
    //     id: ti
    //     interval: 1000
    //     onTriggered: {
    //         if (!(AppState.morpher_state === "bar") && AppState.bar_locked)
    //             return
    //         morpher.anchors.topMargin = AppState.bar_locked ? morpher.anchors.topMargin : -(Vars.bar_height)
    //     }
    // }

    // Connections {
    //     target: Hyprland

    //     function onFocusedWorkspaceChanged() {
    //         if (!(morpher.anchors.topMargin < 0) && !(AppState.morpher_state === "bar") && AppState.bar_locked)
    //             return
    //         morpher.anchors.topMargin = 3
    //         ti.restart()
    //     }
    // }

    Row {
        id: ws_row
        spacing: 3
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        
        Repeater {
            model: 9

            Rectangle {
                required property int index
                property var has_window: Hyprland.workspaces.values.find(function(w){
					return w.id === index + 1
				})
                property bool is_focused: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === (index + 1)

                id: ws_button

                implicitHeight: (Vars.bar_height / 2) + 1
                implicitWidth: is_focused ? 40 : 15

                color: is_focused ? Qt.alpha(Colors.red, 0.3) : "transparent"

                radius: Vars.rad

                MouseArea {
					id: ws_button_mouse
					anchors.fill: parent
					onClicked: {
						onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + (parent.index + 1) + " })")
					}
				}

                Behavior on implicitWidth {
					NumAnim {}
				}

                Text {
					id: ws_lable
					text: ws_button.index + 1
					color: Colors.foreground
					anchors.centerIn: parent

					font {
						family: "SF Mono"
						pixelSize: 15
						weight: has_window ? 1000 : 1
					}
				}
            }
        }
    }
}