import Quickshell
import QtQuick
import QtQuick.Controls
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import QtQuick.Effects
import "components"
import "components/theme"
import "."


ShellRoot {
    property bool kb_bounce: false
    property string st: AppState.morpher_state

    id: root

    Timer {
        id: kb_bounce_timer

        interval: 90

        onTriggered: {
            kb_bounce = false
        }
    }
    PanelWindow {
        id: kb_bounce_panel

        visible: kb_bounce

        implicitHeight: 1
        implicitWidth: 1

        color: "transparent"

        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.layer: WlrLayer.Overlay

        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        anchors {
            top: true
            left: true
        }
    }

    Scope {
        IpcHandler {
            target: "launcher"

            function launch() {
                AppState.change_state("launcher")
            }
        }
        IpcHandler {
            target: "osd-volume"

            function display_vol() {
                AppState.change_state("osd-volume")
            }
        }
        IpcHandler {
          target: "osd-brightness"

          function display_brightness() {
            AppState.change_state("osd-brightness")
          }
        }
        IpcHandler {
            target: "wallpaper-switcher"

            function switch_wallpaper() {
                AppState.change_state("wallpaper")
            }
        }

        Connections {
            target: AppState

            function onMorpher_stateChanged() {
                // if switching from launcher, release keyboard focus
                if (AppState. past_morpher_state === "launcher") {
                    Qt.callLater(() => {
                        kb_bounce = true
                        kb_bounce_timer.restart()
                    })
                }
            }
        }
        Variants {
            model: Quickshell.screens

            delegate: PanelWindow {
                // screen
                required property var modelData
                // fn to switch states
                readonly property var change_state: AppState.change_state

                screen: modelData
                id: panel

                anchors {
                    // full width
                    left: true
                    right: true

                    top: true
                }
                implicitHeight: screen.height

                color: st === "launcher" || st === "network" ? "#57000000" : "transparent"
                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                // only for bar when locked and half when hovered
                exclusiveZone: AppState.bar_locked ? (Vars.bar_height - 4) : 0

                // interacive elements
                Region {
                    id: mask_region

                    Region {
                        item: morph_container
                    }

                    Region {
                        item: morpher
                    }

                    Region {
                        item: extra_rec
                    }
                    
                    Region {
                        item: player
                    }
                    Region {
                        item: launcher_list
                    }

                    Region {
                        item: AppState.notif ? notification_container : null
                    }
                }
                

                // make whole panel interactive when in these states
                mask: st === "launcher" || st === "network" || st === "wallpaper" || AppState.bar_expanded ? null : mask_region

                // dismiss 
                MouseArea {
                    id: panel_mouse

                    anchors.fill: parent

                    onClicked: {
                        AppState.change_state("bar")
                        AppState.bar_expanded = false
                    }
                }

                WlrLayershell.layer: st === "bar" ? WlrLayer.Top : WlrLayer.Overlay
                WlrLayershell.keyboardFocus: st === "launcher" || st === "network" || st === "wallpaper" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

                // morpher's container and for handling slide hiding the bar
                Item {
                    id: morph_container

                    anchors {
                        top: parent.top
                        horizontalCenter: parent.horizontalCenter  
                    }

                    implicitHeight: morpher.anchors.topMargin > 0 ? morpher.height + 3 : 3
                    implicitWidth: morpher.width

                    // toggle bar locked state and hover show/hide
                    HoverHandler {
                        id: morph_container_hover_handler

                        enabled: st === "bar"
                    }
                    MouseArea {
                        id: morph_container_tap_handler

                        enabled: st === "bar"

                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton

                        onClicked: {
                            AppState.toggle_bar_lock()
                        }
                            
                    }

                    // morpher
                    Rectangle {
                        // heights for the d/t states
                        readonly property int bar_height: Vars.bar_height
                        readonly property int bar_width: ((panel.screen.width > panel.screen.height ? panel.screen.width : panel.screen.height) > panel.screen.height ? (panel.screen.width > panel.screen.height ? panel.screen.width : panel.screen.height) : panel.screen.height) / 2
                        readonly property int launcher_height: Vars.bar_height * 1.5//Vars.launcher_height - ((6 - launcher.vis) * 58)// - (launcher.vis * 58))
                        readonly property int launcher_width: (panel.screen.width > panel.screen.height ? panel.screen.width : panel.screen.height) / 3.2
                        readonly property int osd_volume_height: Vars.bar_height
                        readonly property int osd_volume_width: (panel.screen.width > panel.screen.height ? panel.screen.width : panel.screen.height) / 7
                        readonly property int osd_brightness_height: Vars.osd_brightness_height
                        readonly property int osd_brightness_width: (panel.screen.width > panel.screen.height ? panel.screen.width : panel.screen.height) / 7
                        readonly property int network_panel_height: Vars.network_panel_height
                        readonly property int network_panel_width: bar_width / 2
                        readonly property int wallpaper_height: bar_height * 8
                        readonly property int wallpaper_width: bar_width
                        readonly property int control_center_height: Vars.control_center_height
                        readonly property int control_center_width: (panel.screen.width > panel.screen.height ? panel.screen.width : panel.screen.height) / 3

                        readonly property int notification_height: Vars.notification_height
                        readonly property int notification_width: (panel.screen.width > panel.screen.height ? panel.screen.width : panel.screen.height) / 4

                        id: morpher

                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: st === "bar" ? (AppState.bar_locked || morph_container_hover_handler.hovered ? 3 : -(height)) : (Vars.bar_height / 2)
                        Behavior on anchors.topMargin {
                            SpringAnimation {
                                spring: 4
                                damping: 0.35
                                mass: 1.0
                                epsilon: 0.5
                            }
                        }

                        color: Colors.background

                        radius: Vars.rad

                        implicitHeight: {
                            if (st === "bar")
                                return bar_height
                            if (st === "launcher")
                                return launcher_height
                            if (st === "osd-volume")
                              return osd_volume_height
                            if (st === "osd-brightness")
                              return osd_brightness_height
                            if ( st === "network")
                              return network_panel_height
                            if ( st == "wallpaper")
                              return wallpaper_height
                            // if (st === "notification")
                            //     return notification_height
                            return bar_height
                        }
                        Behavior on implicitHeight {
                            SpringAnimation {
                                spring: 4
                                damping: 0.35
                                mass: 1.0
                                epsilon: 0.5
                            }
                        }

                        implicitWidth: {
                            if (st === "bar")
                                return bar_width
                            if (st === "launcher")
                                return launcher_width
                            if (st === "osd-volume")
                              return osd_volume_width
                            if ( st == "osd-brightness")
                              return osd_brightness_width
                            if ( st == "network")
                              return network_panel_width
                            if ( st == "wallpaper")
                              return wallpaper_width
                            // if (st === "notification")
                            //     return notification_width
                            return bar_width
                        }
                        Behavior on implicitWidth {
                            SpringAnimation {
                                spring: 4
                                damping: 0.35
                                mass: 1.0
                                epsilon: 0.5
                            }
                        }

                        RectangularShadow {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Qt.rgba(0, 0, 0, 1)
                            spread: st === "notification" ? 5 : 1
                            z: -1
                            blur: 8
                        }

                        Bar {
                            id: bar

                            visible: st === "bar" && (morpher.height < (morpher.bar_height * 2)) && (morpher.width > ((panel.screen.width > panel.screen.height ? panel.screen.width : panel.screen.height) / 5))
                        }

                        AppSearch {
                            id: launcher

                            visible: opacity > 0.5
                            opacity: st === "launcher" ? 1 : 0 //&& (morpher.height > (morpher.bar_height * 8))
                            Behavior on opacity {
                                NumAnim {
                                    dur: "slow"
                                }
                            }
                        }

                        NetworkPanel {
                            id: network_panel

                            visible: st === "network"
                        }

                        Wallpaper {
                            id: wallpaper

                            visible: opacity > 0
                            opacity: st === "wallpaper" ? 1 : 0

                            Behavior on opacity {
                                NumAnim {}
                            }
                        }

                        // osd
                        Volume {
                            visible: st === "osd-volume" && (morpher.width < (morpher.bar_width/2))
                        }

                        Brightness {
                          visible: st === "osd-brightness" && (morpher.width < (morpher.bar_width/2))
                        }
                    }
                    Item {
                        id: launcher_list

                        anchors.top: morpher.top
                        anchors.topMargin: app_launcher.in_view > 0 ? ((Vars.bar_height * 1.5) + ((Vars.bar_height * 1.5) / 4)) : app_launcher.radius / 2
                        anchors.horizontalCenter: morpher.horizontalCenter

                        z: -1

                        implicitWidth: (panel.screen.width > panel.screen.height ? panel.screen.width : panel.screen.height) / 3.2

                        visible: opacity > 0
                        opacity: app_launcher.in_view > 0 ? 1 : 0 //&& (morpher.height > (morpher.bar_height * 8))
                        Behavior on opacity {
                            NumAnim {
                                dur: "fast"
                            }
                        }
                        Behavior on anchors.topMargin {
                            SpringAnimation {
                                spring: 4
                                damping: 0.35
                                mass: 1.0
                                epsilon: 0.5
                            }
                        }

                        Applauncher {
                            id: app_launcher
                        }
                    }
                    Item {
                        id: player

                        anchors.top: parent.top
                        anchors.right: morpher.left
                        anchors.rightMargin: 5
                        implicitHeight: p.height
                        implicitWidth: p.width
                        HoverHandler {
                            id: player_hover_handler
                        }
                        Rectangle {
                            visible: p.is_available

                            anchors.top: parent.top
                            anchors.topMargin: !AppState.player_locked ? (morpher.anchors.topMargin < -(morpher.height * 0.5) && !player_hover_handler.hovered ? -(height * 0.5) : 3) : (Vars.bar_height / 2) // morpher.anchors.topMargin

                            implicitHeight: p.height
                            implicitWidth: p.width

                            color: "transparent"

                            Behavior on anchors.topMargin {
                                SpringAnimation {
                                    spring: 8
                                    damping: 0.25
                                    mass: 0
                                    epsilon: 0.5
                                }
                            }

                            Player {
                                id: p
                                extra_hover: player_hover_handler.hovered
                            }
                        }
                    }
                    Item {
                        id: extra_rec
                        anchors.top: parent.top
                        anchors.left: morpher.right
                        anchors.leftMargin: 5

                        implicitHeight: Vars.bar_height
                        implicitWidth: (height * AppState.systray_items) + 8

                        HoverHandler {
                            id: tray_hover_handler
                            onHoveredChanged: {
                                print(hovered)
                            }
                        }

                        Rectangle {
                            //visible: AppState.systray_active

                            anchors.top: parent.top
                            anchors.topMargin: morpher.anchors.topMargin < -(morpher.height * 0.5) && !tray_hover_handler.hovered && !morph_container_hover_handler.hovered ? -(height * 0.5) : 3 // morpher.anchors.topMargin

                            implicitHeight: Vars.bar_height
                            implicitWidth: (height * AppState.systray_items) + 8


                            color: "transparent"//Colors.background

                            radius: Vars.rad

                            Behavior on anchors.topMargin {
                                SpringAnimation {
                                    spring: 8
                                    damping: 0.25
                                    mass: 0
                                    epsilon: 0.5
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

                            SysTray {
                                id: systray
                            }
                        }
                    }
                }
                PanelWindow {
                    anchors.top: true
                    anchors.right: true
                    color: "transparent"
                    WlrLayershell.layer: WlrLayer.Overlay
                    visible: AppState.notif
                    implicitHeight: notification_container.height * 1.25
                    implicitWidth: notification_container.width * 1.5
                    Rectangle {
                        id: notification_container

                        visible: AppState.notif

                        // onVisibleChanged: {
                        //     print(AppState.notif)
                        // }
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 12

                        implicitWidth: morpher.notification_width
                        implicitHeight: morpher.notification_height //* AppState.notifications.count

                        y: 15 + morpher.bar_height

                        radius: morpher.radius

                        color: "transparent"

                        Notification {
                            //visible: //st === "notification" && (morpher.width < (morpher.notification_width * 1.2))
                        }
                    }
                }                
            }
        }
    }
}
