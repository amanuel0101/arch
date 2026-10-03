import Quickshell
import QtQuick
import Quickshell.Services.Notifications
import Qt5Compat.GraphicalEffects
import Quickshell.Widgets
import "components/theme"
import "AppState.qml"

Item {
    id: notification_
    anchors.left: parent.left
    anchors.right: parent.right
    property var max_chars: 210
    property var nots: []
    property var pops: []
    property var seenNotifications: []

    NotificationServer {
        id: notification_server

        imageSupported: true
        actionIconsSupported: true
        bodyImagesSupported: true
        inlineReplySupported: true
        persistenceSupported: false
        actionsSupported: true

        onNotification: (notification) => {
            if (seenNotifications.includes(notification.id))
                return;

            seenNotifications = [...seenNotifications, notification.id]
            notification.tracked = true;
            AppState.unread_notifications = [...AppState.unread_notifications, notification]
            pops = [...pops, notification]
            AppState.visible_notifications++
            print(notification.body)
            AppState.change_state("notification")
        }
    }
    Timer {
        id: smth
        interval: 1000

        onTriggered: {
            pops = []
            AppState.visible_notifications--
        }
    }

    function auto_dismiss(notification) {
        if (pops.length === 1) {
            AppState.change_state("bar")
            smth.restart()
            return
        }
        pops = pops.filter(n => n !== notification)
        AppState.visible_notifications--
    }

    Repeater{
        model: pops
        delegate: Rectangle {
            id: rec
            clip: true
            required property var modelData
            required property var index
            property var root: notification_
            property var icon: {
                if (modelData.image.length > 0)
                    return modelData.image;

                if (modelData.appIcon.length > 0)
                    return Quickshell.iconPath(modelData.appIcon);

                return "file:///home/.config/quickshell/assets/dialog-information.svg";
            }

            //visible: opacity === 1
            anchors.left: parent.left
            anchors.right: parent.right
            height: morpher.bar_height * 2.7
            color: Theme.Colors.background
            radius: morpher.radius * 2
            anchors.top: parent.top
            anchors.topMargin: (index) * 6

            Behavior on anchors.topMargin {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }
            z: index
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: -2
                radius: 10
                samples: 100
                color: '#1e000000'
            }

            Timer {
                id: auto_dis

                interval: 400
                running: false

                onTriggered: {
                    if (!AppState.is_notification)
                        return
                    auto_dismiss(modelData)
                }
            }

            Timer {
                id: auto_dis_anim

                interval: modelData.expireTimeout > 0 ? modelData.expireTimeout : 1000
                running: AppState.is_notification && modelData === pops[pops.length - 1]

                onTriggered: {
                    if (pops.length === 1){
                        auto_dis.restart()
                        return
                    }
                    parent.opacity = 0
                    parent.anchors.topMargin = -(parent.height/2)
                    
                    auto_dis.restart()
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }

            Behavior on y {
                NumberAnimation {
                    duration: 500
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onPressed: function(mouse) {
                    if (mouse.button === Qt.LeftButton) {
                        if (modelData.actions.values.length == 0) {
                            auto_dismiss(modelData)
                            return ;
                        }
                        modelData.actions[0].invoke();
                        return ;
                    }
                    auto_dismiss(modelData)
                }
            }



            Item {
                anchors.fill: parent
                anchors.verticalCenter: parent.verticalCenter
                ClippingRectangle {
                    id: notification_icon
                    implicitHeight: 50
                    implicitWidth: 50
                    anchors.left: parent.left
                    anchors.leftMargin: 15
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
                   // anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 75
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
                                    pixelSize: 16
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
                                    pixelSize: 15 
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
