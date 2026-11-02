import Quickshell
import QtQuick
import Quickshell.Hyprland
import "./theme" as Theme

Rectangle {
	id: workspaces_container
	anchors.left: parent.left
	anchors.leftMargin: btn.anchors.leftMargin + btn.width + 5
	implicitHeight: parent.height
	implicitWidth: ws_row.width + 20
	color: "transparent"
	radius: morpher.radius

	Row {
		id: ws_row
		spacing: 2
		anchors.verticalCenter: parent.verticalCenter
		Repeater {
			model: 9

			Rectangle {
				id: ws_button
				required property int index
				property var ws: Hyprland.workspaces.values.find(function(w){
					return w.id === index + 1
				})
				property bool is_active: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === (index + 1)

				implicitHeight: ws_lable.implicitHeight + 2
				implicitWidth: ws_lable.implicitWidth + (is_active ? 40 : 15)
				radius: morpher.radius

				color: is_active ? Qt.alpha(Theme.Colors.red, 0.3) : "transparent"

				MouseArea {
					id: ws_button_mouse
					anchors.fill: parent
					onClicked: {
						onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + (parent.index + 1) + " })")
					}
				}

				Behavior on implicitWidth {
					NumberAnimation {
						duration: 80
					}
				}

				Text {
					id: ws_lable
					text: ws_button.index + 1
					color: Theme.Colors.foreground
					anchors.centerIn: parent

					font {
						family: "SF Mono"
						pixelSize: 15
						weight: ws ? 1000 : 1
					}
				}
			}
		}
	}
}

