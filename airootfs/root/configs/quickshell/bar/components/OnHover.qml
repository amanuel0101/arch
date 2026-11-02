import QtQuick

Rectangle {
    id: root

    anchors.fill: parent

    color: on_hover_handler.hovered ? Qt.lighter(parent.color, 1.25) : parent.color

    Behavior on color {
        ColorAnimation {
            duration: 100
        }
    }

    radius: parent.radius

    HoverHandler {
        id: on_hover_handler
    }
}