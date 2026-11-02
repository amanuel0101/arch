import QtQuick
import Quickshell.Services.SystemTray
import Quickshell
import ".."
import "theme"


Item {
    id: root

    anchors.fill: parent

    Row {
        anchors.centerIn: parent
        spacing: 5
        Repeater {
            model: SystemTray.items

            delegate: Rectangle {
                required property var modelData

                id: rec

                implicitHeight: Vars.bar_height
                implicitWidth: height

                color: Colors.background

                radius: Vars.rad
                Image {
                    id: systray_icon

                    anchors.centerIn: parent

                    height: Vars.systray_icon_size
                    width: height

                    source: modelData.icon
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onPressed: (mouse) => {
                    if (mouse.button === Qt.LeftButton)
                    {
                        modelData.activate();
                        return ;
                    }
                    //trayMenu.open();
                }
                }
            }
        }
    }
}