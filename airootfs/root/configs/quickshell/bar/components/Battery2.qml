import Quickshell
import QtQuick
import Quickshell.Services.UPower
import "theme"
import ".."

Rectangle {
	id: root
	
	implicitHeight: battery_icon.height - 8
	implicitWidth: battery_icon.width
	anchors.verticalCenter: parent.verticalCenter
	color: "transparent"
	radius: morpher.radius
	property bool has_mouse: root_mouse_handler.hovered

	property var battery: UPower.displayDevice
    property bool charging: battery.state === UPowerDeviceState.Charging
	property int level: Math.round(battery.percentage * 100)
	readonly property string icon: {
		if (charging)
			return "battery_android_frame_bolt"
		
		if (level >= 90)
			return "battery_android_full"
		
		if (level >= 80)
			return "battery_android_6"

		if (level >= 60)
			return "battery_android_5"

		if (level >= 50)
			return "battery_android_4"
		
		if (level >= 40)
			return "battery_android_3"
		
		if (level >= 30)
			return "battery_android_2"

		if (level >= 15)
			return "battery_android_1"
		
		if (level >= 5)
			return "battery_android_0"

		return "battery_android_0"
	}


	Text {
		id: battery_icon
		text: icon
		color: level > 40 ? Colors.cyan : (level < 25 ? Colors.red : Colors.yellow)
		anchors.centerIn: parent

		font {
			family: "Material Symbols Rounded"
			pixelSize: 25
			variableAxes: (
				{
					"opsz": 50,
					"wght": 200
				}
			)
		}
		Text {
			id: battery_lable
			text: level
			color: "transparent"
			anchors.right: parent.right
			anchors.verticalCenter: parent.verticalCenter
			anchors.rightMargin: (parent.width - width) / (level < 10 ? 1.8 : (level===100 ? 1.6 : 1.7))

			font {
				family: "SF Mono"
				pixelSize: 11
				weight: 500
			}
		}
	}

	MouseArea {
		id: root_mouse
		anchors.fill: parent
		hoverEnabled: true
		onEntered: {
			tooltip.tooltip("start", root, charging ? "charging: " + level + "%" : level + "%")
		}

		onExited: {
			tooltip.tooltip("end")
		}
	}

	HoverHandler {
		id: root_mouse_handler

		onHoveredChanged: {
			if (hovered) {
				tooltip.tooltip("start", root, charging ? "charging: " + level + "%" : level + "%")
			}
			else {
				tooltip.tooltip("end")
			}
		}
	}
}

