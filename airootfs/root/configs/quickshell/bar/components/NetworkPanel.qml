import QtQuick
import Quickshell.Networking
import Quickshell.Io
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets
import QtQuick.Effects
import "theme"
import  ".."
import "../singletons"

Item {
    id: root

    anchors.fill: parent

    Rectangle {
        id: smth
        anchors.fill: parent

        property string re: ""

        color: "transparent"

        radius: Vars.rad


        Rectangle {
            id: header

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 10
            implicitHeight: 40
            implicitWidth: parent.width - 60

            color: "transparent"

            radius: Vars.rad

            RowLayout {
                anchors.fill: parent

                spacing: 10

                Row {
                    Text {
                        text: "WIFI" + (Networks.wifi_state === "connected" ? " ⋅ " : "")

                        Layout.alignment: Qt.AlignVCenter
                        color: Colors.foreground

                        font {
                            family: "SF Mono"
                            pixelSize: 15
                        }
                    }

                    Text {
                        text: String(Networks.wifi_device?.networks.values.find(n => n.connected)?.name)

                        visible: Networks.wifi_state === "connected"

                        Layout.alignment: Qt.AlignVCenter

                        color: Colors.green

                        font {
                            family: "SF Mono"
                            pixelSize: 15
                        }
                    }

                    Text {
                        text: " connecting..."

                        visible: Networks.wifi_state === "connecting"

                        Layout.alignment: Qt.AlignVCenter

                        color: Colors.green

                        font {
                            family: "SF Mono"
                            pixelSize: 10
                        }
                    }
                    Text {
                        text: " disconnecting..."

                        visible: Networks.wifi_state === "disconnecting"

                        Layout.alignment: Qt.AlignVCenter

                        color: Colors.green

                        font {
                            family: "SF Mono"
                            pixelSize: 10
                        }
                    }
                    Text {
                        text: " failed: " + smth.re

                        visible: smth.re != ""

                        Layout.alignment: Qt.AlignVCenter

                        color: Colors.red

                        font {
                            family: "SF Mono"
                            pixelSize: 10
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    id: scan

                    Layout.alignment: Qt.AlignVCenter

                    implicitHeight: scan_icon.height
                    implicitWidth: scan_icon.width

                    color: "transparent"

                    radius: header.radius

                    Text {
                        id: scan_icon

                        text: "refresh"

                        anchors.centerIn: parent

                        color: Qt.alpha(Colors.green, 1)

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
                        property real rotationAngle: 0
                        transform: Rotation {
                            angle: scan_icon.rotationAngle
                            origin.x: scan_icon.width / 2
                            origin.y: scan_icon.height / 2
                        }

                        Connections {
                            target: Networking

                            function onWifiEnabledChanged() {
                                if (Networking.wifiEnabled)
                                    scan_animation.restart()
                            }
                        }

                        RotationAnimation on rotationAngle {
                            id: scan_animation
                            running: false
                            duration: 6000
                            from: 0
                            to: 3600
                        }
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            Networks.wifi_device.scannerEnabled = false
                            Networks.wifi_device.scannerEnabled = true
                            scan_icon.rotationAngle = 360
                            scan_animation.restart()
                        }
                    }
                }

                Rectangle {
                    id: wifi_switch

                    Layout.alignment: Qt.AlignVCenter

                    implicitHeight: 35
                    implicitWidth: 35

                    color: "transparent"

                    radius: header.radius

                    // Text {
                    //     id: wifi_switch_icon

                    //     text: Networks.wifi_device ? "toggle_on" : "toggle_off"

                    //     anchors.centerIn: parent

                    //     color: Qt.alpha(Colors.green, 1)

                    //     font {
                    //         family: "Material Symbols Rounded"
                    //         pixelSize: 30
                    //         variableAxes: (
                    //             {
                    //                 "opsz": 50,
                    //                 "wght": 400
                    //             }
                    //         )
                    //     }
                    // }
                    IconImage {
                        id: wifi_switch_icon
                        anchors.fill: parent
                        source: Networking.wifiEnabled ? "file:///home/arch/airootfs/root/configs/quickshell/bar/icons/wifi/wifi-toggle-on.svg" : "file:///home/arch/airootfs/root/configs/quickshell/bar/icons/wifi/wifi-toggle-off.svg"
                    }
                    
                    MouseArea{
                        id: wifi_switch_mouse

                        anchors.fill: parent

                        onClicked: {
                            Networking.wifiEnabled = !Networking.wifiEnabled
                        }
                    }
                }
            }
        }

        Rectangle {
            id: separator

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: header.bottom

            implicitHeight: 1
            implicitWidth: header.width

            color: Qt.alpha(Colors.foreground, 0.25)
        }

        ListModel {
            id: networks_list

            Component.onCompleted: {
                Networks.wifi_device?.networks?.values.forEach(n => append(
                    {
                        name: n.name,
                        signal_strength: n.signalStrength,
                        connected: n.connected
                    }
                ))
            }
        }

        ListView {
            id: ssid_list

            model: Networking.wifiEnabled ? [...(Networks.wifi_device?.networks?.values ?? [])].sort((a, b) => {
                if (a.connected !== b.connected)
                    return a.connected ? -1 : 1

                return 0
            }) : []

            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter

            implicitHeight: parent.height - header.height - header.anchors.topMargin - 15
            implicitWidth: parent.width

            spacing: 10

            clip: true

            snapMode: ScrollBar.SnapOnRelease

            footer: Item {
                width: 1
                height: 10
            }

            property var expanded: null

            addDisplaced: Transition {
                NumberAnimation {
                    properties: "x,y"
                    duration: 1000
                    easing.type: Easing.OutCubic
                }
            }

            displaced: Transition {
                NumberAnimation {
                    properties: "x,y"
                    duration: 1000
                    easing.type: Easing.OutCubic
                }
            }


            delegate: Rectangle {
                required property var modelData
                required property int index
                
                implicitHeight: rec.height > rec2.height ? rec.height : rec2.height
                width: ListView.view.width

                color: "transparent"

                Behavior on y {
                    enabled: true
                    NumberAnimation {
                        duration: 1000
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    id: rec

                    implicitHeight: 50
                    implicitWidth: header.width

                    radius: Vars.rad

                    color: modelData.connected ? Qt.lighter(Colors.background, 1.5) : Qt.lighter(Colors.background, 1.2)

                    Text {
                        text: modelData.name

                        anchors.top: parent.top
                        anchors.topMargin: (50 - height) / 2
                        anchors.left: parent.left
                        anchors.leftMargin: 20

                        color: modelData.connected ? Colors.green : Colors.foreground

                        font {
                            family: "SF Mono"
                            pixelSize: 15
                        }
                    }

                    Image {
                        visible: modelData.security !== WifiSecurityType.Open

                        anchors.right: parent.right
                        anchors.rightMargin: wifi_icon.width + 28
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: 2
                        fillMode: Image.PreserveAspectFit

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1
                            colorizationColor: modelData.connected ? Colors.green : Colors.foreground
                            brightness: 1
                        }
                        

                        width: 18
                        height: 18

                        source: "../icons/wifi/wifi-secure.svg"
                    }

                    Image {
                        id: wifi_icon
                        anchors.right: parent.right
                        anchors.rightMargin: 20
                        anchors.verticalCenter: parent.verticalCenter

                        width: 24
                        height: 20

                        property int tier: modelData.signalStrength >= 0.7 ? 4 : modelData.signalStrength >= 0.5 ? 3 : modelData.signalStrength >= 0.25 ? 2 : 1

                        source: "../icons/wifi/" + "wifi-" + tier + ".svg"
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }

                    MouseArea {
                        implicitHeight: 50
                        implicitWidth: parent.width
                        onReleased: {
                            rec.scale = 1
                            if (ssid_list.expanded === modelData){
                                ssid_list.expanded = null
                                return
                            }
                            ssid_list.expanded = modelData
                        }
                        onCanceled: {
                            rec.scale = 1
                        }

                        onPressed: {
                            rec.scale = 0.95
                        }
                    }
                }

                Rectangle {
                    id: rec2
                    anchors.horizontalCenter: parent.horizontalCenter
                    //anchors.centerIn: rec
                    anchors.top: parent.top

                    implicitHeight: AppState.morpher_state === "network" && ssid_list.expanded === modelData ? (modelData.connected || modelData.known ? 110 : 160) : 0
                    Behavior on implicitHeight {
                        SpringAnimation {
                            spring: 4
                            damping: 0.35
                            mass: 1.0
                            epsilon: 0.5
                        }
                    }
                    implicitWidth: header.width - radius

                    z: -1

                    radius: Vars.rad

                    color: Qt.lighter(Colors.background, 1.1)

                    clip: true

                    TextField {
                        id: text_field
                        visible: ssid_list.expanded === modelData && !modelData.connected && !modelData.known
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: rec.height + 10

                        implicitHeight: 35
                        implicitWidth: parent.width * 0.8

                        color: Colors.foreground

                        inputMethodHints: Qt.ImhSensitiveData
                        echoMode: TextInput.Password

                        leftPadding: 10

                        font.pixelSize: 15

                        placeholderText: "Enter Wi-Fi Password"
                        placeholderTextColor: Qt.alpha(Colors.foreground, 0.7)

                        background: Rectangle {
                            id: field_bg
                            color: Qt.lighter(Colors.background, 1.5)
                            radius: Vars.rad
                        }
                        onTextChanged: {
                                    field_bg.color = Qt.lighter(Colors.background, 1.5)
                                }
                    }

                    Rectangle {
                        visible: modelData.connected
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 10

                        implicitHeight: 35
                        implicitWidth: parent.width * 0.5

                        opacity: parent.height > 50 ? 1 : 0

                        color: Colors.red

                        radius: Vars.rad

                        OnHover {}

                        Text {
                            text: "disconnect"
                            
                            anchors.centerIn: parent

                            color: Colors.foreground

                            font {
                                family: "SF Mono"
                                pixelSize: 15
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onReleased: {
                                parent.scale = 1
                                ssid_list.expanded = null
                                if (modelData.connected)
                                    modelData.disconnect()
                                
                            }
                            onCanceled: {
                                parent.scale = 1
                            }

                            onPressed: {
                                parent.scale = 0.9
                            }
                        }
                    }
                    Rectangle {
                        visible: modelData.state === ConnectionState.Disconnected && modelData.known

                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 10

                        implicitHeight: 35
                        implicitWidth: parent.width * 0.5

                        opacity: parent.height > 50 ? 1 : 0

                        color: Colors.green

                        radius: Vars.rad

                        Text {
                            text: "connect"
                            
                            anchors.centerIn: parent

                            color: Colors.foreground

                            font {
                                family: "SF Mono"
                                pixelSize: 15
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onReleased: {
                                parent.scale = 1
                                ssid_list.expanded = null
                                modelData.connect()
                                
                            }
                            onCanceled: {
                                parent.scale = 1
                            }

                            onPressed: {
                                parent.scale = 0.9
                            }
                        }

                        Connections {
                            target: modelData

                            function onConnectionFailed(reason) {
                                console.error("Wi-Fi connection failed:", Networks.conn_fail_reason_to_string(reason))
                                modelData.forget()
                            }
                        }
                    }

                    Rectangle {
                        visible: ssid_list.expanded === modelData && modelData.known
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 30

                        implicitHeight: 35
                        implicitWidth: height

                        opacity: parent.height > 50 ? 1 : 0

                        color: Qt.lighter(Colors.background, 1.5)

                        radius: Vars.rad

                        OnHover {}

                        Text {
                            text: "link_off"

                            anchors.centerIn: parent
                            
                            color: Colors.foreground

                            font {
                                family: "Material Symbols Rounded"
                                pixelSize: 20
                                variableAxes: (
                                    {
                                        "opsz": 50,
                                        "wght": 500
                                    }
                                )
                            }
                        }

                        MouseArea {
                            implicitHeight: 50
                            implicitWidth: parent.width
                            onReleased: {
                                rec.scale = 1
                                modelData.forget()
                            }
                            onCanceled: {
                                rec.scale = 1
                            }

                            onPressed: {
                                rec.scale = 0.95
                            }
                        }
                    }

                    Rectangle {
                        visible: ssid_list.expanded === modelData && !modelData.connected && !modelData.known
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: text_field.bottom
                        anchors.topMargin: 10

                        implicitHeight: 35
                        implicitWidth: parent.width * 0.5

                        color: Colors.green

                        radius: Vars.rad

                        Text {
                            text: "connect"
                            
                            anchors.centerIn: parent

                            color: Colors.foreground

                            font {
                                family: "SF Mono"
                                pixelSize: 15
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onReleased: {
                                parent.scale = 1
                                ssid_list.expanded = null
                                if (!text_field.text) {
                                    field_bg.color = Qt.alpha(Colors.red, 0.5)
                                }
                                modelData.connectWithPsk(text_field.text)
                            }
                            onCanceled: {
                                parent.scale = 1
                            }

                            onPressed: {
                                parent.scale = 0.9
                            }
                        }
                    }
                }
            }
        }
    }
}
