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
    property var kb_bounce: false
    // current morph state
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

        Connections {
            target: AppState

            function onMorpher_stateChanged() {
                // if switching from launcher, release keyboard focus
                if (AppState. past_morpher_state != "launcher") {
                    kb_bounce = true
                    kb_bounce_timer.restart()
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

                color: st === "launcher" ? "#57000000" : "transparent"
                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                // only for bar when locked and half when hovered
                exclusiveZone: AppState.bar_locked ? (morpher.bar_height - 4) : 0

                // interacive elements
                Region {
                    id: mask_region

                    Region {
                        item: morph_container
                    }

                    Region {
                        item: morpher
                    }
                }

                // make whole panel interactive when in these states
                mask: st === "launcher" || st === "notification_panel" ? null : mask_region

                // dismiss 
                MouseArea {
                    id: panel_mouse

                    anchors.fill: parent

                    onClicked: {
                        AppState.change_state("bar")
                    }
                }

                WlrLayershell.layer: st === "bar" ? WlrLayer.Top : WlrLayer.Overlay
                WlrLayershell.keyboardFocus: st === "launcher" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

                // morpher's container and for handling slide hiding the bar
                Item {
                    id: morph_container

                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }

                    implicitHeight: morpher.anchors.topMargin > 0 ? morpher.height + 3 : 3

                    // toggle bar locked state and hover show/hide
                    HoverHandler {
                        id: morph_container_hover_handler

                        enabled: st === "bar"
                    }
                    MouseArea {
                        id: morph_container_tap_handler

                        enabled: st === "bar"

                        anchors.fill: parent
                        z: 1
                        acceptedButtons: Qt.RightButton

                        onClicked: {
                            AppState.toggle_bar_lock()
                        }
                            
                    }

                    // morpher
                    Rectangle {
                        // heights for the d/t states
                        readonly property int bar_height: Vars.bar_height
                        readonly property int bar_width: panel.screen.width / 2
                        readonly property int launcher_height: Vars.launcher_height
                        readonly property int launcher_width: panel.screen.width / 3
                        readonly property int osd_volume_height: Vars.bar_height
                        readonly property int osd_volume_width: panel.screen.width / 7

                        readonly property int notification_height: ((AppState.max_visible_notification - 1) * 15) + (bar_height * 3)
                        readonly property int notification_width: panel.screen.width / 4

                        id: morpher

                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: st === "bar" ? (AppState.bar_locked || morph_container_hover_handler.hovered ? 3 : -(height)) : 10
                        Behavior on anchors.topMargin {
                            NumAnim {}
                        }

                        // transparent if there is a notification popup
                        color: st === "notification" ? "transparent" : Colors.background

                        radius: Vars.rad

                        implicitHeight: {
                            if (st === "bar")
                                return bar_height
                            if (st === "launcher")
                                return launcher_height
                            if (st === "osd-volume")
                                return osd_volume_height
                            if (st === "notification")
                                return notification_height
                            return bar_height
                        }
                        Behavior on implicitHeight {
                            NumAnim {}
                        }
                        implicitWidth: {
                            if (st === "bar")
                                return bar_width
                            if (st === "launcher")
                                return launcher_width
                            if (st === "osd-volume")
                                return osd_volume_width
                            if (st === "notification")
                                return notification_width
                            return bar_width
                        }
                        Behavior on implicitWidth {
                            NumAnim {}
                        }

                        RectangularShadow {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Qt.rgba(0, 0, 0, 0.55)
                            spread: 0
                            z: -1
                            blur: 8
                            offset: Qt.vector2d(0, 0)

                            
                        }

                        Bar {
                            id: bar

                            visible: st === "bar" && (morpher.height < (morpher.bar_height * 10)) && (morpher.width > (panel.screen.width / 4))
                        }

                        Applauncher {
                            id: launcher

                            visible: st === "launcher" && (morpher.height > (morpher.bar_height * 8))
                        }

                        // osd
                        Volume {
                            visible: st === "osd-volume"
                        }
                    }
                }
            }
        }
    }
}