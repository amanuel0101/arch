import QtQuick
import Quickshell
import QtQuick.Controls
import Quickshell.Widgets
//import "file:/home/arch/airootfs/root/configs/quickshell/bar/roundedclip/build"
import ".."
import "theme"

ClippingRectangle {
    property int item_height: 60
    property int item_spacing: 5
    property var a_st: AppLauncherState
    property int in_view: a_st.apps.length > 6 ? 6 : a_st.apps.length
    property bool bg: true

    id: root

    anchors.top: parent.top

    implicitHeight: in_view * item_height + (item_spacing * (in_view - 1)) + 16
    implicitWidth: parent.width

    color: bg ? Colors.background : "transparent"

    radius: Vars.rad

    Flickable {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.left: parent.left
        
        contentHeight: items.implicitHeight + 16
        contentWidth: width

        clip: true

        Column {
            id: items

            anchors.top: parent.top
            anchors.topMargin: 8
            // anchors.bottom: parent.bottom
            // anchors.bottomMargin: 16

            width: parent.width

            spacing: item_spacing

            Repeater {
                model: a_st.apps

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    
                    anchors.horizontalCenter: parent.horizontalCenter

                    implicitHeight: item_height
                    implicitWidth: parent.width - 20

                    color: bg ? (item_hover_handler.hovered ? Qt.alpha(Colors.green, 0.5) : "transparent") : Colors.background

                    radius: Vars.rad

                    HoverHandler {
                        id: item_hover_handler
                    }
                    MouseArea {
                        anchors.fill: parent

                        onDoubleClicked: {
                            modelData.execute()
                            AppState.change_state("bar")
                        }
                    }

                    ClippingRectangle {
                        id: icon_container

                        anchors.left: parent.left
                        anchors.leftMargin: parent.radius / 2 
                        anchors.verticalCenter: parent.verticalCenter

                        implicitHeight: parent.height - 30
                        implicitWidth: height

                        radius: Vars.rad

                        color: "transparent"

                        IconImage {
                            anchors.fill: parent
                            source: Quickshell.iconPath(modelData.icon)
                        }
                    }

                    Column {
                        anchors.left: icon_container.right
                        anchors.leftMargin: icon_container.anchors.leftMargin

                        Text {
                            text: modelData.name

                            topPadding: icon_container.y

                            color: Colors.foreground

                            font {
                                family: "SF Mono"
                                pixelSize: 15
                            }
                        }
                        Text {
                            text: modelData.genericName.slice(0,60) || modelData.comment.slice(0,60)

                            topPadding: 5

                            color: Qt.alpha(Colors.foreground, 0.5)

                            font {
                                family: "SF Mono"
                                pixelSize: 12
                            }
                        }
                    }
                }
            }
        }
    }
    Behavior on implicitHeight {
        SpringAnimation {
            spring: 4
            damping: 0.35
            mass: 1.0
            epsilon: 0.5
        }
    }

    Behavior on implicitWidth {
        SpringAnimation {
            spring: 4
            damping: 0.35
            mass: 1.0
            epsilon: 0.5
        }
    }
}