import QtQuick
import Quickshell.Services.Notifications
import Quickshell.Widgets
import Quickshell.Io
import "theme"
import ".."

Item {
    property int max_chars: 60
    ListModel {
        id: popups
    }
    property var curr: null
    
    id: root

    //anchors.centerIn: parent
    anchors.fill: parent

    Process {
        id: sound

        command: ["paplay", "/home/arch/airootfs/root/configs/quickshell/bar/assets/notif.mp3", "--volume=40000"]
    }

    NotificationServer {
        id: notification_server

        keepOnReload: false

        onNotification: (notification) => {
            notification.tracked = true
            sound.running = true
            
            popups.insert(0, {
                appName: notification.appName,
                summary: notification.summary.trim().replace(/\n/g, ""),
                body: notification.body.trim().replace(/\n/g, ""),
                image: notification.image,
                appIcon: notification.appIcon,
                interv: notification.expireTimeout != -1 ? notification.expireTimeout : Vars.auto_dismiss_interval
            })
            print(notification.expireTimeout)
            curr = {
                appName: notification.appName,
                summary: notification.summary.trim().replace(/\n/g, ""),
                body: notification.body.trim().replace(/\n/g, ""),
                image: notification.image,
                appIcon: notification.appIcon
            }
            AppState.notifications.insert(0, {
                appName: notification.appName,
                summary: notification.summary.trim().replace(/\n/g, ""),
                body: notification.body.trim().replace(/\n/g, ""),
                image: notification.image,
                appIcon: notification.appIcon
            })
            print(AppState.notifications.count)
            

            AppState.notif = true
        }
    }

    Repeater {
        model: popups

        delegate: Rectangle {
            required property var appName
            required property var image
            required property var appIcon
            required property var summary
            required property var body
            required property var index
            required property var interv

            // Components.onCompleted: {
            //     print(appName)
            // }

            property var icon: {
                if (image.length > 0)
                    return image;

                if (appIcon.length > 0)
                    return Quickshell.iconPath(appIcon);

                return "file:///home/arch/airootfs/root/configs/quickshell/bar/icons/notification_bell.svg";
            }
            
            id: rec

            height: Vars.notification_height
            width: root.width
            
            z: popups.count - index// === 0 && AppState.notif
            
            color: Colors.background

            radius: Vars.rad

            Component.onCompleted: {
                anchors.rightMargin = 0
            }

            anchors.right: root.right
            anchors.rightMargin: -(rec.width + 30)
            Behavior on anchors.rightMargin {
                SpringAnimation {
                            spring: 4
                            damping: 0.3
                            mass: 1.0
                            epsilon: 0.5
                        }
            }
            NumAnim {
                id: dismiss_animation
                target: rec.anchors
                property: "rightMargin"
                to: -((rec.width * 2) + 30)

                onFinished: {
                    var p = popups.count - 1
                    

                    //dismissing = false
                    popups.remove(index)

                    if (p === 0)
                        AppState.notif = false
                    print(p)
                }
            }

            property real remainingTime: interv
            property double timerStartedAt: 0

            HoverHandler {
                id: rec_hover_handler

                onHoveredChanged: {
                    print("hoajdkl")
                    if (hovered) {
                        if (auto_dismiss_timer.running) {
                            remainingTime = Math.max(
                                0,
                                remainingTime - (Date.now() - timerStartedAt)
                            )

                            auto_dismiss_timer.stop()
                        }
                    } else if (remainingTime > 0) {
                        timerStartedAt = Date.now()
                        auto_dismiss_timer.interval = remainingTime
                        auto_dismiss_timer.start()
                    }
                }
            }

            MouseArea {
                id: rec_mouse_area

                anchors.fill: parent
            }

            Timer {
                id: auto_dismiss_timer

                interval: interv
                running: index === 0 && AppState.notif
                repeat: false

                onRunningChanged: {
                    print(body)
                    if (running)
                        timerStartedAt = Date.now()
                }

                onTriggered: {
                    rec.anchors.rightMargin = -500
                    dismiss_animation.start()
                    remainingTime = 0
                }
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter

                spacing: 8

                ClippingRectangle {
                    id: icon_rec
                    implicitHeight: rec.height / 2
                    implicitWidth: height
                    anchors.verticalCenter: parent.verticalCenter

                    radius: rec.radius

                    color: "transparent"

                    IconImage {
                        anchors.fill: parent
                        source: icon
                    }
                }

                Column {
                    spacing: 3
                    Text {
                        id: app_name_txt
                        text: appName || "!!!notification"

                        color: Qt.alpha(Colors.foreground, 0.6)
                        topPadding: 0

                        font {
                            family: "SF Pro Text"
                            pixelSize: 13
                        }
                    }
                    Text {
                        id: summary_txt
                        text: summary || "!!!summary"

                        color: Qt.alpha(Colors.foreground, 0.8)
                        topPadding: -3

                        font {
                            family: "SF Pro Text"
                            pixelSize: 16
                        }
                    }
                    Rectangle {
                        implicitHeight: 20
                        implicitWidth: rec.width - icon_rec.width - icon_rec.anchors.leftMargin - rec.radius - 5
                        clip: true
                        color: "transparent"
                        radius: Vars.rad

                        Text {
                            text: (body.length > 48 ? body.slice(0, 48) + "..." : body) || "!!!body"
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            lineHeight: 1.4

                            color: Colors.foreground
                            width: parent.width
                            clip: true

                            font {
                                family: "SF Pro Text"
                                pixelSize: 15
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: progress_bar

                property double start_time: 0
                property real progress: 1

                opacity: index === 0

                Behavior on opacity {
                    NumAnim {}
                }

                Timer {
                    id: prog

                    interval: 10
                    running: auto_dismiss_timer.running
                    repeat: true

                    onTriggered: {
                        progress_bar.progress = Math.max(
                            0,
                            remainingTime -
                            (Date.now() - timerStartedAt)
                        ) / interv
                    }
                }

                anchors.top: parent.top
                anchors.topMargin: 2
                anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: 3
                implicitWidth: ((parent.width - (parent.radius * 1.5))) * (index === 0 ? progress : 1)

                radius: parent.radius
                color: Colors.green
            }
        }
    }

    Rectangle {
        id: num

        //opacity: popups.count > 1 && anchors.rightMargin < 10

        Behavior on opacity {
            NumAnim {}
        }

        implicitHeight: 20
        implicitWidth: 20

        opacity: popups.count > 1 ? 1 : 0

        anchors.top: parent.top
        anchors.topMargin: popups.count > 1 ? -5 : 5
        anchors.right: parent.right
        anchors.rightMargin: popups.count > 1 ? 0 : 15

        Behavior on anchors.topMargin {
            SpringAnimation {
                spring: 4
                damping: 0.35
                mass: 1.0
                epsilon: 0.5
            }
        }
        Behavior on anchors.rightMargin {
            SpringAnimation {
                spring: 4
                damping: 0.35
                mass: 1.0
                epsilon: 0.5
            }
        }
        
        radius: Vars.rad

        color: Colors.red

        Text {
            id: label
            anchors.centerIn: parent
            text: popups.count

            color: popups.count > 1 ? Qt.lighter(Colors.foreground, 1.5) : "transparent"

            font {
                pixelSize: 14
                family: "SF Pro Text"
                bold: true
            }
        }
    }
}