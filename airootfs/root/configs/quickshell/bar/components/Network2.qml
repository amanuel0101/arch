import Quickshell
import QtQuick
import Quickshell.Networking
import Qt5Compat.GraphicalEffects
import QtQuick.Shapes
import "./theme" as Theme

Item {
	id: root
	implicitHeight: network_container.height
	implicitWidth: network_container.width
	anchors.verticalCenter: parent.verticalCenter
	property bool has_mouse: network_container_mouse_hover.hovered

	Rectangle {
		id: network_container
		anchors.verticalCenter: parent.verticalCenter
		implicitHeight: network_icon.height - 10
		implicitWidth: network_icon.width
		color: "transparent"
		radius: morpher.radius

		property var wifi_device: Networking.devices.values.find((d) => {
			return d.type === DeviceType.Wifi;
		})
		property var active: wifi_device ? wifi_device.networks.values.find((n) => {
			return n.connected;
		}) : null
		readonly property real signal: active ? active.signalStrength : 0
		readonly property string icon: {
			if (!Networking.wifiEnabled)
				return "wifi-off.svg"

			if (!active)
				return "wifi-off.svg"

			let tier = signal >= 0.7 ? 4 : signal >= 0.5 ? 3 : signal >= 0.25 ? 2 : 1;
			return "wifi-" + tier + ".svg"
		}

		Item {
			id: network_icon
			width: 24
			height: 20
			anchors.centerIn: parent

			Image {
				id: wifi
				anchors.fill: parent
				source: "../icons/wifi/" + network_container.icon
				visible: true
			}

			// ColorOverlay {
			// 	anchors.fill: wifi
			// 	source: wifi
			// 	color: network_container.active ? Theme.Colors.brightCyan : Theme.Colors.red
			// }
		}
				// Text {
		// 	id: network_icon
		// 	text: parent.icon
		// 	anchors.centerIn: parent
		// 	color: parent.signal > 0.25 ? Theme.Colors.green : Theme.Colors.red
		// 	font {
		// 		family: "Material Symbols Rounded"
		// 		pixelSize: 18
		// 		variableAxes: (
		// 			{
		// 				"opsz": 50,
		// 				"wght": 700
		// 			}
		// 		)
		// 	}
		// }

		MouseArea {
			id: network_container_mouse
			anchors.fill: parent
		}
		HoverHandler {
			id: network_container_mouse_hover
			onHoveredChanged: {
				print("ho")
				if (hovered) {
					tooltip.tooltip(
						"start",
						network_container,
						"connected to: " + (parent.active?.name ?? "")
					)
				} else {
					tooltip.tooltip("end")
				}
			}
		}

		
	}
}
