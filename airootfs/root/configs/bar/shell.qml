import Quickshell
import QtQuick
import QtQuick.Controls
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import "./theme" as Theme
import "AppState.qml"

ShellRoot {

	Variants {
		model: Quickshell.screens

		delegate: PanelWindow {
			required property var modelData
			readonly property var st: AppState.morpher_state
			readonly property var change_state: AppState.change_state

			screen: modelData
			id: panel

			// Component.onCompleted: {
			// 	print(AppState.morpher_state)
			// }

			// full screen panelwindow
			anchors {
				top: true
				// bottom: true
				left: true
				right: true
			}
			implicitHeight: screen.height

			property var pre_launcher_workspace: null
			property var pre_launcher_special_workspace_id: null

			IpcHandler {
				target: "launcher"

				function launch() {
					change_state("launcher")
				}
			}
			IpcHandler {
				target: "vol"

				function display() {
					change_state("volume-osd")
				}
			}
			IpcHandler {
				target: "brightness"

				function displayy() {
					change_state("brightness-osd")
				}
			}

			Connections {
				target: AppState

				function onMorpher_stateChanged() {
					if (st === "bar") {
						launcher.clear_inp() // clear input
						launcher.scroll_top()

						// restore focus
						set_current_ws_active.running = true // set focus ws so HyprlandFocusGrab can focus to it
						restore_focus_timer.restart() // release HyprlandFocusGrap's focus after a delay to give the above async line to set the active ws as focused
					}
					else if (st === "launcher") {
						focusGrab.active = true // grap keyboard focus
					}
					else if (st === "volume-osd" || st === "brightness-osd") {
						launcher.clear_inp() // clear input
						launcher.scroll_top()

						// restore focus
						set_current_ws_active.running = true // set focus ws so HyprlandFocusGrab can focus to it
						restore_focus_timer.restart() // release HyprlandFocusGrap's focus after a delay to give the above async line to set the active ws as focused
					}
				}
			}

			HyprlandFocusGrab {
				id: focusGrab
				windows: [ panel ]
				active: st === "launcher"
			}

			color: st === "launcher" ? '#60000000' : '#00000000'
			Behavior on color {
				ColorAnimation {
					duration: 150
				}
			}

			// only for bar when locked and half when hovered
			exclusiveZone: bar.bar_locked ? (morpher.bar_height - 5) : 0

			// dismiss back to bar 
			MouseArea {
				anchors.fill: st === "launcher" ? parent : null
				onClicked: {
					change_state("bar")
				}
			}

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

			mask: st === "bar" || st === "volume-osd" || st === "brightness-osd" ? mask_region : null

			Process {
				id: set_current_ws_active

				command: ["hyprctl", "monitors", "-j"]

				stdout: StdioCollector {
					onStreamFinished: {
						const monitors = JSON.parse(text)
						const focused = monitors.find(m => m.focused)

						const special_id = focused && focused.specialWorkspace && focused.specialWorkspace.id

						if (special_id) {
							const ws = Hyprland.workspaces.values.find(w => w.id === special_id)

							if (ws) // if special ws is focusec
								ws.activate()
						} else {
							if (Hyprland.focusedWorkspace)
								Hyprland.focusedWorkspace.activate()
						}
					}
				}
			}

			Timer {
				id: restore_focus_timer
				interval: 30
				repeat: false

				onTriggered: {
					focusGrab.active = false
				}
			}
			// morpher container
			Item {
				id: morph_container
				anchors {
					top: parent.top
					left: parent.left
					right: parent.right
				}
				height: 2

				// bar slide handler
				MouseArea {
					id: morph_container_mouse
					enabled: st == "bar"
					anchors.fill: parent
					hoverEnabled: true
					acceptedButtons: Qt.LeftButton | Qt.RightButton
					onClicked: function(mouse) {
						if (mouse.button === Qt.RightButton){
							bar.bar_locked = !bar.bar_locked
						}
					}
				}

				// morpher
				Rectangle {
					id: morpher

					anchors.horizontalCenter: parent.horizontalCenter
					color: Qt.alpha(Theme.Colors.background, 1)
					layer.enabled: true
					layer.effect: DropShadow {
						horizontalOffset: 0
						verticalOffset: 0
						radius: 30
						samples: 25
						color: "#80000000"
					}

					implicitHeight: {
						if (st === "bar")
							return bar_height
						if (st === "launcher")
							return 435
						if (st === "volume-osd" || st === "volume-osd")
							return bar_height
						return bar_height
					}

					implicitWidth: {
						if (st === "bar")
							return panel.screen.width / 2
						if (st === "launcher")
							return panel.screen.width / 3
						if (st === "volume-osd" || st === "brightness-osd")
							return panel.screen.width / 7
						return panel.screen.width / 2
					}

					radius: 30

					property real bar_height: 30

					Keys.onPressed: function (e){
						if (e.key === Qt.Key_Escape) {
							panel.change_state("bar")
						}
						e.accepted = true
					}

					// morph animations
					Behavior on implicitHeight {
						NumberAnimation {
							duration: 250
							easing.type: Easing.OutCubic

						}
						// SpringAnimation {
						// 	spring: 4
						// 	damping: 0.35
						// 	mass: 1
						// }
					}
					Behavior on implicitWidth {
						NumberAnimation {
							duration: 250
							easing.type: Easing.OutCubic
						}
						// SpringAnimation {
						// 	spring: 4
						// 	damping: 0.35
						// 	mass: 1
						// }
					}

					// bar slider
					y: (st === "bar" && !bar.bar_locked && !bar.has_mouse && !morph_container_mouse.containsMouse) ? (-height) : 2.5

					Behavior on y {
						NumberAnimation {
							duration: 250
							easing.type: Easing.OutCubic
						}
					}

					// bar
					Bar {
						id: bar

						visible: st === "bar"
    					opacity: st === "bar" ? 1 : 0
					}

					// launcher
					Applauncher {
						id: launcher

						is_visible: st === "launcher"

						visible: st === "launcher"
						opacity: st === "launcher" ? 1 : 0

						implicitHeight: st === "launcher" ? parent.height : 0
					}

					// osd
					Volume {
						id: vol

						visible: st === "volume-osd"
					}
					Brightness {
						id: brightness

						visible: st === "brightness-osd"
					}
				} // morpher
			} // morpher container
		}
	}
}




















// 		// all
// 		Item {
// 			id: bar
// 			anchors.top: parent.top
// 			anchors.left: parent.left
// 			anchors.right: parent.right
// 			height: panel.control_center_open ? 320 : 32
// 			y: margin_top < 0 ? margin_top + 5: 0

// 			property var margin_top: panel.is_hidden & !bar.bar_mouse.containsMouse ? (-height): 0


// 			Behavior on y {
// 				NumberAnimation {
// 					duration: 180
// 					easing.type: Easing.OutCubic
// 				}
// 			}

// 			Behavior on height {
// 				NumberAnimation {
// 					duration: 250
// 				}
// 			}

// 			MouseArea {
// 				id: bar.bar_mouse
// 				anchors.fill: parent
// 				hoverEnabled: true
// 				acceptedButtons: Qt.LeftButton | Qt.RightButton
// 				onClicked: function(mouse) {
// 				if (mouse.button === Qt.RightButton)
// 				{
// 					panel.is_hidden = !panel.is_hidden
// 				}
// 			}
// 			onDoubleClicked: {
// 				panel.control_center_open = !panel.control_center_open
// 			}
// 		}

// 		Rectangle {
// 			id: bar_container
// 			anchors.centerIn: parent
// 			implicitHeight: parent.height - 2
// 			implicitWidth: parent.width / 2
// 			color: Theme.Colors.background

// 			radius: height * 0.5

// 			Clock {}
// 			Workspaces {}
// 			Row {
// 				anchors.right: parent.right
// 				spacing: 2
// 				Network {}
// 				Battery {}
// 			}

// 		} // container
// 	} // bar
// } // panel
// }
