import QtQuick

HoverHandler {
    id: root
    //anchors.fill: parent
    onHoveredChanged: {
        if (hovered) {
            parent.scale = 1.2
        }
        else {
            parent.scale = 1
        }
    }
}