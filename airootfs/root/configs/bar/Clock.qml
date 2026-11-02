import Quickshell
import QtQuick
import "./theme" as Theme


Rectangle {
	id: clock_container
	anchors.centerIn: parent
	implicitHeight: parent.height
	implicitWidth: clock_text.width + 20
	radius: morpher.radius
	color: "transparent"

	

	SystemClock {
		id: clock
		precision: SystemClock.Seconds
	}

	Text {
		id: clock_text
		text: Qt.formatDateTime(clock.date, "hh:mm:ss AP").replace(/ (AM|PM)$/, "")
		anchors.centerIn: parent
		color: Theme.Colors.foreground
		font {
			pixelSize: 15
			letterSpacing: -0.5
			weight: 700
			family: "SF Mono"
		}
	}
}
