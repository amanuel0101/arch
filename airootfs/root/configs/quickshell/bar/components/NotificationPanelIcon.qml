import Quickshell
import QtQuick
import Quickshell.Services.Notifications
import Qt5Compat.GraphicalEffects
import Quickshell.Widgets
import "theme"
import "../AppState.qml"


Rectangle {
    id: notification_panel_icon
    anchors.verticalCenter: parent.verticalCenter
    implicitHeight: 20
    implicitWidth: 20
    color: "transparent"
    radius: morpher.radius

    property bool has_mouse: notification_panel_icon_mouse_handler.hovered

    MouseArea {
        id:  notification_panel_icon_mouse
        anchors.fill: parent

        onClicked: {
            AppState.change_state("notification_panel")
        }
    }

    HoverHandler {
        id: notification_panel_icon_mouse_handler

        onHoveredChanged: {
            if (hovered) {
                tooltip.tooltip("start", notification_panel_icon, "unread: " + AppState.unread_notifications.length)
            }
            else {
                tooltip.tooltip("end")
            }
        }
    }

    Text {
        text: "notifications"

        anchors.centerIn: parent
        
        color: Colors.foreground

        font {
            family: "Material Symbols Rounded"
            pixelSize: 18
        }
    }
}