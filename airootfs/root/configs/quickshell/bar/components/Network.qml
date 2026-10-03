import QtQuick
import Quickshell.Networking
import "theme"
import  ".."

Rectangle {
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

    id: root

	anchors.verticalCenter: parent.verticalCenter

    implicitHeight: wifi_icon.height
	implicitWidth: wifi_icon.width

    color: "transparent"

    radius: Vars.rad

    MouseArea {
		id: root_mouse
		anchors.fill: parent
        onClicked: {
            print("network clicked.")
        }
	}

    Image {
        id: wifi_icon

        width: 24
        height: 20

        source: "../icons/wifi/" + icon
    }
}