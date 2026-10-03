import Quickshell
import QtQuick
import Quickshell.Services.Notifications
import Qt5Compat.GraphicalEffects
import Quickshell.Widgets
import QtQuick.Controls
import QtQuick.Layouts
import "components/theme" as Theme
import "AppState.qml"


Item {
    anchors.fill: parent
    MouseArea {
        anchors.fill: parent
    }

    ClippingRectangle {
        id: notification_panel

        anchors.fill: parent
        color: Theme.Colors.background
        radius: morpher.radius
        Column {
            anchors.fill: parent
            spacing: 5
            Rectangle {
                implicitHeight: 50
                implicitWidth: parent.width - 50
                anchors.horizontalCenter: parent.horizontalCenter
                color: "transparent"

                RowLayout {
                    anchors.fill: parent

                    Text {
                        text: "Notifications"

                        color: Qt.alpha(Theme.Colors.foreground, 0.7)
                        
                        font {
                            family: "SF Pro Display"
                            pixelSize: 18
                        }
                    }

                    Text {
                        text: "•  " + "5"

                        color: Qt.alpha(Theme.Colors.foreground, 0.8)
                        
                        font {
                            family: "SF Pro Display"
                            pixelSize: 15
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "clear"

                        color: Theme.Colors.red
                        
                        font {
                            family: "SF Pro Display"
                            pixelSize: 17
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                AppState.unread_notifications = []
                            }
                        }
                    }
                }
            }
            ClippingRectangle {
                implicitHeight: parent.height - 60
                implicitWidth: parent.width - 1
                anchors.horizontalCenter: parent.horizontalCenter
                color: "transparent"
                radius: morpher.radius

                ScriptModel {
                    id: notification_model
                    values: AppState.unread_notifications
                }


                ListView {
                anchors.fill: parent
                spacing: 10
                clip: true
                model: notification_model
                boundsMovement: Flickable.StopAtBounds
                boundsBehavior: Flickable.DragOverBounds
                opacity: Math.max(0.5, 1.0 - Math.abs(verticalOvershoot) / height)

                delegate: Rectangle {
                    id: rec
                    clip: true
                    required property var modelData
                    required property var index
                    property var icon: {
                        if (modelData.image.length > 0)
                            return modelData.image;

                        if (modelData.appIcon.length > 0)
                            return Quickshell.iconPath(modelData.appIcon);

                        return "file:///home/.config/quickshell/assets/dialog-information.svg";
                    }

                    //visible: opacity === 1
                    height: morpher.bar_height * 2.25
                    implicitWidth: parent.width - 20
                    color: Qt.lighter(Theme.Colors.background, 1.1)
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: morpher.radius * 2

                    Behavior on anchors.topMargin {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }

                    Item {
                        anchors.fill: parent
                        anchors.verticalCenter: parent.verticalCenter
                        ClippingRectangle {
                            id: notification_icon
                            implicitHeight: 40
                            implicitWidth: 40
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            radius: 50
                            color: "transparent"
                            
                            Image {
                                source: icon
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }
                        }
                        Rectangle {
                            //anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 60
                            anchors.top: parent.top
                            clip: true
                            radius: morpher.radius
                            anchors.verticalCenter: parent.verticalCenter
                            color: "transparent"
                            Column {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1

                                Rectangle {
                                    implicitHeight: apptxt.height
                                    implicitWidth: parent.width
                                    clip: true
                                    radius: morpher.radius
                                    color: "transparent"
                                    Text {
                                        id: apptxt
                                        text: modelData.appName + "  •  " + "now"
                                        color: Qt.alpha(Theme.Colors.foreground, 0.5)
                                        font {
                                            family: "SF Pro Display"
                                            pixelSize: 14
                                        }
                                    }
                                }
                                Rectangle {
                                    implicitHeight: summarytxt.height
                                    implicitWidth: parent.width
                                    clip: true
                                    radius: morpher.radius
                                    color: "transparent"
                                    Text {
                                        id: summarytxt
                                        text: modelData.summary
                                        color: Qt.alpha(Theme.Colors.foreground, 0.7)
                                        font {
                                            family: "SF Pro Display"
                                            pixelSize: 15
                                        }
                                    }
                                }
                                Rectangle {
                                    implicitHeight: bodytxt.height
                                    implicitWidth: parent.width
                                    clip: true
                                    radius: morpher.radius
                                    color: "transparent"
                                    Text {
                                        id: bodytxt

                                        text: String(modelData.body).substring(0,55) + (String(modelData.body).length > 55? " .  .  ." : "")

                                        width: parent.width - parent.radius + 2
                                        maximumLineCount: 1
                                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                        textFormat: Text.RichText

                                        color: Theme.Colors.foreground 
                                        font { 
                                            family: "SF Pro Display"
                                            pixelSize: 16 
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                }
            }
        }
    }
}