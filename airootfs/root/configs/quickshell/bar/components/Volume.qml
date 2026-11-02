import QtQuick
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import "theme" as Theme

Item {
    property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: {
        return sink && sink.ready;
    }
    readonly property bool muted: {
        return ready && sink.audio.muted;
    }
    readonly property int vol: {
        return (ready ? Math.round(sink.audio.volume * 100) : 0);
    }
    readonly property string icon: {
        if (!ready)
            return "volume_0.svg";

        if (muted)
            return "volume_0.svg";

        if (vol === 0)
            return "volume_0.svg";

        if (vol < 30)
            return "volume_1.svg";

        if (vol < 80)
            return "volume_2.svg";

        return "volume_3.svg";
    }

    id: root

    anchors.fill: parent
    clip: true

    // keep tracking
    PwObjectTracker {
        objects: [sink]
    }

    Row {
        anchors.centerIn: parent

        spacing: 10

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            
            implicitHeight: 22
            implicitWidth: 22

            color: "transparent"

            Image {
                id: vol_icon
                anchors.fill: parent
                source: "../icons/sound/" + icon
                sourceSize.width: 40
                sourceSize.height: 40
            }

            // Text {
            //     id: icon_dummy

            //     text: String.fromCodePoint(984446)

            //     visible: false

            //     font {
            //         family: "Material Symbols Rounded"
            //         pixelSize: 20
            //     }
            // }
            // Text {
            //     id: vol_icon

            //     text: icon

            //     anchors.left: parent.left

            //     color: muted || !ready ? Theme.Colors.red : Theme.Colors.foreground

            //     font {
            //         family: "Material Symbols Rounded"
            //         pixelSize: 20
            //     }
            // }
        }

        ClippingRectangle {
            implicitHeight: parent.height / 5
            implicitWidth: (root.width - 100)
            anchors.verticalCenter: parent.verticalCenter
            radius: morpher.radius
            color: Qt.lighter(Theme.Colors.background, 1.5)

            Rectangle {
                color: Theme.Colors.green
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: parent.height
                implicitWidth: parent.width * (vol / 100)
            }
        }

        Text {
            id: lvl_dummy
            text: "100%"
            visible: false

            font {
                family: "SF Mono"
                pixelSize: 15
            }
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter

            implicitHeight: lvl_dummy.height
            implicitWidth: lvl_dummy.width

            color: "transparent"

            Text {
                text: vol + "%"

                anchors.right: parent.right

                color: Theme.Colors.foreground

                font {
                    family: "SF Mono"
                    pixelSize: 15
                }
            }
        }
    }
}
