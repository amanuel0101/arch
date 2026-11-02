import QtQuick
import Quickshell.Io
import ".."
import "theme"

Rectangle {
    id: root

    anchors.verticalCenter: parent.verticalCenter

    implicitHeight: vol_tune_icon.height
	implicitWidth: vol_tune_icon.width

    radius: Vars.rad

    color: "transparent"

    Text {
        id: vol_tune_icon
        text: "instant_mix"
        
        anchors.centerIn: parent

        color: Colors.foreground

        font {
			family: "Material Symbols Rounded"
			pixelSize: 20
			variableAxes: (
				{
					"opsz": 50,
					"wght": 400
				}
			)
		}
    }

    Process {
        id: proc
    }
    
    MouseArea {
        anchors.fill: parent

        onClicked: {
            proc.command = ["pavucontrol"];
            proc.running = true;
        }
    }
}