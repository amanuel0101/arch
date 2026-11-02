import Quickshell
import QtQuick
import Quickshell.Widgets
import Quickshell.Io
import "./theme" as Theme


Item {
    id: brightness

    anchors.fill: parent
    clip: true

    Component.onCompleted: {
    brightnessFile.reload()
    maxBrightnessFile.reload()
}


    FileView {
        id: brightnessFile

        path: "/sys/class/backlight/intel_backlight/brightness"
        watchChanges: true

        onFileChanged: reload()
        onTextChanged: updateBrightness()
    }

    FileView {
        id: maxBrightnessFile

        path: "/sys/class/backlight/intel_backlight/max_brightness"
        watchChanges: true

        onTextChanged: updateBrightness()
    }

    function updateBrightness() {
        const value = parseInt(brightnessFile.text())
        const max = parseInt(maxBrightnessFile.text())

        if (!isNaN(value) && !isNaN(max) && max > 0)
            level = Math.round(value / max * 100)
    }

    property int level: 0
    readonly property string icon: {
        return "brightness_7";
    }

    Row {
        anchors.centerIn: parent
        height: parent.height - 1
        spacing: 10
        Text {
            text: icon
            color: Theme.Colors.foreground
            anchors.verticalCenter: parent.verticalCenter
            font {
                family: "Material Symbols Rounded"
                pixelSize: 20
            }
        }

        ClippingRectangle {
            implicitHeight: parent.height / 6
            implicitWidth: (morpher.width - 100)
            anchors.verticalCenter: parent.verticalCenter
            radius: morpher.radius
            color: Qt.lighter(Theme.Colors.background, 1.5)

            Rectangle {
                color: Theme.Colors.green
                anchors.verticalCenter: parent.verticalCenter
                radius: 30
                implicitHeight: parent.height
                implicitWidth: parent.width * (level / 100)
            }
        }

        Text {
            Text {
                id: dummy
                text: "100%"
                visible: false
                color: Theme.Colors.foreground
                anchors.verticalCenter: parent.verticalCenter

                font {
                    family: "SF Mono"
                    pixelSize: 15
                }
            }

            text: level + "%"
            color: Theme.Colors.foreground
            anchors.verticalCenter: parent.verticalCenter
            width: dummy.width

            font {
                family: "SF Mono"
                pixelSize: 15
            }
        }
    }
}