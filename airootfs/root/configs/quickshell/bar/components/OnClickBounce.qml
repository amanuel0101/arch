import QtQuick

MouseArea {
    property var action: null

    anchors.fill: parent

    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onPressed: (mouse) => {
        parent.scale = 0.8

        if (action) {
            action(mouse)
        }
    }

    onReleased: {
        parent.scale = 1
    }
}