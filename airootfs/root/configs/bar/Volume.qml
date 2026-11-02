import Quickshell
import QtQuick
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import "./theme" as Theme

Item {
    id: volume

    anchors.fill: parent
    clip: true

    PwObjectTracker {
        objects: [sink]
    }

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
            return String.fromCodePoint(984449);

        if (muted)
            return String.fromCodePoint(986632);

        if (vol === 0)
            return String.fromCodePoint(984449);

        if (vol < 30)
            return String.fromCodePoint(984447);

        if (vol < 60)
            return String.fromCodePoint(984448);

        return String.fromCodePoint(984446);
    }

    Row {
        anchors.centerIn: parent
        height: parent.height - 1
        spacing: 10
        Text {
            text: icon
            color: muted || !ready ? Theme.Colors.red : Theme.Colors.foreground
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
                implicitWidth: parent.width * (vol / 100)
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

            text: vol + "%"
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