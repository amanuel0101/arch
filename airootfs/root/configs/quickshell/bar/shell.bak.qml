import Quickshell
import QtQuick
import QtQuick.Controls
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Io
import "./theme" as Theme

ShellRoot {
	IpcHandler {
		target: "launcher"

		function launch() {
			panel.change_state(
				morpher.type === "bar" ? "launcher" : "bar"
			)
		}
	}

	PanelWindow {
		id: panel

		// full screen panelwindow
		anchors {
			top: true
			// bottom: true
			left: true
			right: true
		}

		property var pre_launcher_workspace: null
		property var pre_launcher_special_workspace_id: null

		HyprlandFocusGrab {
			id: focusGrab
			windows: [ panel ]
			active:false
		}
		
		implicitHeight: screen.height
		color: morpher.type === "bar" ? '#00000000' : '#57000000'

		// only for bar when locked and half when hovered
		exclusiveZone: bar.bar_locked ? (morpher.bar_height - 5) : 0

		// dismiss control centerhow 
		MouseArea {
			anchors.fill: morpher.type==="launcher" ? parent : null
			onClicked: {
				panel.change_state("bar")
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

		mask: mask_region

		Timer {
			id: launcher_search_bar_input_clear_timer
			interval: 150
			running: false
			repeat: false

			onTriggered: {
				launcher_search_bar_input.clear()
				launcher.selected_id = 1
				// launcher_search_bar_input.
			}
		}

		Process {
			id: pre_launcher_special_tracker
			command: ["hyprctl", "monitors", "-j"]
			stdout: StdioCollector {
				onStreamFinished: {
					const monitors = JSON.parse(text)
					const focused = monitors.find(m => m.focused)
					print(JSON.stringify(focused.specialWorkspace))
					panel.pre_launcher_special_workspace_id = focused?.specialWorkspace?.id ? focused.specialWorkspace.id : null
				}
			}

			onExited: {
				print("before: ", panel.pre_launcher_special_workspace_id)
				const special = Hyprland.workspaces.values.filter( ws => ws.id === panel.pre_launcher_special_workspace_id)[0]
				panel.pre_launcher_workspace = special || Hyprland.focusedWorkspace
				morpher.type = "launcher"
				panel.mask = null
				focusGrab.active = true

				panel.pre_launcher_special_workspace_id = null
			}
		}

		function change_state(t) {
			if (t === "bar") {
				morpher.type = t
				panel.mask = mask_region
				launcher_search_bar_input_clear_timer.running = true
				if (panel.pre_launcher_workspace) {
					print("aft: ", panel.pre_launcher_workspace.name)
					panel.pre_launcher_workspace.activate()
					panel.pre_launcher_workspace = null
				}
				focusGrab.active = false
			}
			else if (t === "launcher") {
				// focusGrab.active = true
				pre_launcher_special_tracker.running = true
				morpher = ClippingRectangle
			}

			console.log("state: " + morpher.type)
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
				enabled: morpher.type == "bar"
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

				implicitHeight: {
					if (type === "bar")
						return bar_height
					if (type === "launcher")
						return 435
				}

				implicitWidth: {
					if (type === "bar")
						return panel.width / 2
					if (type === "launcher")
						return panel.width / 3
				}

				radius: 30

				property string type: "bar"
				property real bar_height: 30

				// morph animations
				Behavior on implicitHeight {
					SpringAnimation {
						spring: 4
						damping: 0.35
						mass: 1
					}
				}
				Behavior on implicitWidth {
					SpringAnimation {
						spring: 4
						damping: 0.35
						mass: 1
					}
				}

				// bar slider
				y: (type === "bar" && !bar.bar_locked && !bar_mouse.containsMouse && !morph_container_mouse.containsMouse) ? (-height) : 2

				Behavior on y {
					SpringAnimation {
						spring: 3
						damping: 0.25
						mass: 1
					}
				}

				// bar
				Item {
					id: bar
					visible: morpher.type === "bar"
					opacity: morpher.type === "bar" ? 1 : 0
					anchors.fill: parent

					property bool bar_locked: true

					MouseArea {
						id: bar_mouse
						anchors.fill: parent
						hoverEnabled: true
						acceptedButtons: Qt.LeftButton | Qt.RightButton
						onClicked: function(mouse) {
							if (mouse.button === Qt.RightButton){
								bar.bar_locked = !bar.bar_locked
							}
						}
					}
					Rectangle {
						id: btn
						width: 22
						height: 22
						anchors.left: parent.left
						anchors.verticalCenter: parent.verticalCenter
						anchors.leftMargin: 6
						radius: 20
						color: "transparent" //Theme.Colors.green
						border {
							width: 1
							color: Theme.Colors.green
						}

						Text {
							text: "blur_on"
							anchors.centerIn: parent
							color: Theme.Colors.green
							font {
								pixelSize: 16
								family: "Material Symbols Rounded"
							}
						}
						MouseArea {
							anchors.fill: parent
							onClicked: {
								panel.change_state("launcher")
							}
						}
					}

					Workspaces {}
					Clock {}

					Rectangle {
						implicitHeight: rr.height
						implicitWidth: rr.width + 10
						anchors.right: parent.right
						anchors.verticalCenter: parent.verticalCenter
						anchors.rightMargin: 7
						radius: morpher.radius
						color: "transparent"
						Row {
							id: rr
							anchors.centerIn: parent
							spacing: 5
							Network {
								id: network
							}
							Battery {}
						}
					}

					// animations
					Behavior on opacity {
						NumberAnimation {
							duration: 300
							easing.type: Easing.OutCubic
						}
					}

				} // bar

				

				// launcher
				Item {
					id: launcher
					visible: !(opacity == 0)
					opacity: morpher.type === "launcher" ? 1 : 0
					anchors.fill: parent
					clip: true

					property int selected_id: 1
					property int max_items: DesktopEntries.applications.values.length

					// keyboard navigation
					Keys.onPressed: function (e){
						if (e.key === Qt.Key_Down) {
							launcher.selected_id = (launcher.selected_id % launcher.max_items) + 1
						}
						if (e.key === Qt.Key_Up) {
							launcher.selected_id = ((launcher.selected_id - 2 + launcher.max_items) % launcher.max_items) + 1
						}

						if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
							launcher_item_list.model[launcher_item_list.currentIndex].execute()
						}
						e.accepted = true
					}

					MouseArea {
						anchors.fill: parent
					}

					Rectangle {
						id: launcher_search_bar_container
						anchors.top: parent.top
						anchors.topMargin: 15
						anchors.horizontalCenter: parent.horizontalCenter
						implicitHeight: morpher.bar_height * 1.25
						implicitWidth: parent.width - 20

						radius: morpher.radius
						color: morpher.color
						Row{
							anchors.fill: parent
							anchors.leftMargin: 10
							spacing: 5
							Text {
								id: launcher_search_bar_icon
								text: ""
								anchors.verticalCenter: parent.verticalCenter
								color: Qt.alpha(Theme.Colors.foreground, 0.5)

								font {
									family: "SF Pro Display"
									pixelSize: 17
								}
							}
							TextField {
								id: launcher_search_bar_input
								implicitHeight: parent.height
								implicitWidth: parent.width - launcher_search_bar_icon.width - 10

								palette.text: Theme.Colors.foreground
								focus: true
								placeholderText: "Search..."
								placeholderTextColor: Qt.alpha(Theme.Colors.foreground, 0.4)

								background: Rectangle {
									color: "transparent"
								}
								
								font {
									pixelSize: 17
								}

								Keys.onPressed: function(event) {
									if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
										launcher_item_list.model[launcher_item_list.currentIndex].execute()
										panel.change_state("bar")
										event.accepted = true
									}
								}
							}
						}
					}

					Rectangle {
						id: launcher_item_container

						implicitHeight: parent.height - launcher_search_bar_container.height - launcher_search_bar_container.anchors.topMargin - 15
						implicitWidth: parent.width - 10
						anchors.horizontalCenter: parent.horizontalCenter
						anchors.bottom: parent.bottom
						radius: morpher.radius
						color: morpher.color
						clip: true
						ListView{
							id: launcher_item_list
							
							anchors.fill: parent
							anchors.bottomMargin: 5
							model: [...DesktopEntries.applications.values].filter(app=>{let q=launcher_search_bar_input.text.toLowerCase(),n=app.name.toLowerCase(),i=0;return !q||n.includes(q)||[...q].every(c=>(i=n.indexOf(c,i))>=0&&++i)}).sort((a,b)=>{let q=launcher_search_bar_input.text.toLowerCase(),x=a.name.toLowerCase(),y=b.name.toLowerCase();return (y===q)-(x===q)||(y.startsWith(q)-x.startsWith(q))||(y.includes(q)-x.includes(q))||x.localeCompare(y)})
							anchors.horizontalCenter: parent.horizontalCenter
							spacing: 2
							clip: true

							currentIndex: launcher.selected_id - 1

							highlightMoveDuration: 80
							onCurrentIndexChanged: {
								launcher_item_list.positionViewAtIndex(
									currentIndex,
									ListView.Contain
								)
							}
							width: launcher_item_container.width - 8
							height: 58

							delegate: Rectangle {
								id: launcher_item

								required property DesktopEntry modelData
								required property int index
								property bool selected: launcher.selected_id === (index + 1)

								implicitHeight: 58// morpher.bar_height * 2
								implicitWidth: launcher_item_container.width - 8
								color: selected ? Qt.lighter(launcher_item_container.color, 1.35) : "transparent"

								anchors.horizontalCenter: parent.horizontalCenter
								radius: launcher_item_container.radius - 4


								Rectangle {
									id: launcher_item_selected_indicator

									opacity: selected ? 1 : 0

									implicitHeight: parent.height - (radius * 1.2)
									implicitWidth: 2.5

									anchors.verticalCenter: parent.verticalCenter
									anchors.left: parent.left
									anchors.leftMargin: 10

									radius: launcher_item_container.radius
									color: Theme.Colors.green

									// animations
									Behavior on opacity {
										NumberAnimation {
											duration: 100
										}
									}
								}
								
									
									Image {
										id: launcher_item_icon
										readonly property string defaultFallback: "file:///home/Downloads/gemini-svg.svg"
										source: (modelData.icon ? Quickshell.iconPath(modelData.icon) : defaultFallback) || defaultFallback
										height: 22
										width: 22
										anchors.verticalCenter: parent.verticalCenter
										anchors.left: parent.left
										anchors.leftMargin: launcher_item_selected_indicator.anchors.leftMargin * 2.25
										clip: true
										fillMode: Image.PreserveAspectFit
									}
								Column{
									anchors.verticalCenter: parent.verticalCenter
									Text {
										id: launcher_item_name
										text: modelData.name

										anchors.left: parent.left
										anchors.leftMargin: (launcher_item_selected_indicator.anchors.leftMargin + launcher_item_icon.anchors.leftMargin + launcher_item_icon.width + launcher_item_selected_indicator.width)

										color: Theme.Colors.foreground

										font {
											pixelSize: 15

										}
									}
									Text {
										id: launcher_item_comment
										text: modelData.genericName || modelData.comment

										anchors.left: parent.left
										anchors.leftMargin: (launcher_item_selected_indicator.anchors.leftMargin + launcher_item_icon.anchors.leftMargin + launcher_item_icon.width + launcher_item_selected_indicator.width)

										color: Qt.alpha(Theme.Colors.foreground, 0.8)

										font {
											pixelSize: 12

										}
									}
								}
								MouseArea {
									anchors.fill: parent
									onClicked: launcher.selected_id = index + 1
									onDoubleClicked: {
										modelData.execute()
										panel.change_state("bar")
									}
								}
								// animations
								Behavior on color {
									ColorAnimation {
										duration: 100
									}
								}
							}
						}
					}
					Text {
						text: "no match"
						anchors.centerIn: parent
						color: Qt.alpha(Theme.Colors.foreground, 0.5)
						visible: launcher_item_list.count === 0

						font {
							pixelSize: 15
						}
					}

					// animations
					Behavior on opacity {
						NumberAnimation {
							duration: 300
							easing.type: Easing.OutCubic
						}
					}
				} // launcher
			} // morpher
		} // morpher container
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

// 			property var margin_top: panel.is_hidden & !bar_mouse.containsMouse ? (-height): 0


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
// 				id: bar_mouse
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








