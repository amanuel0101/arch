import Quickshell
import QtQuick
import QtQuick.Controls
import "./theme" as Theme


Item {
    id: launcher

    anchors.fill: parent
    anchors.topMargin: 6
    clip: true
    onVisibleChanged: {
        search_bar_input.clear()
        item_list.contentY = 0
        __selected_id = 1
    }

    // var
    property bool is_visible: false
    property int input_clear_interval: 150

    // priv
    property int __selected_id: 1 // default selected item
    property int __max_items: DesktopEntries.applications.values.length // apps list length

    Timer {
        id: input_clear_timer
        interval: input_clear_interval
        running: false
        repeat: false

        property var callback

        onTriggered: {
            search_bar_input.clear()
        }
    }

    Timer {
        id: delay_timer
        running: false
        repeat: false

        property var callback

        onTriggered: {
            if (callback) {
                callback()
            }
        }
    }

    // functions -----------------------------------------------------------
    // activate
    function focus_input() {
        search_bar_input.forceActiveFocus()
    }
    // reuseable timer
    function timer(interv=150, callback) {
        delay_timer.interval = interv
        delay_timer.callback = callback
        delay_timer.restart()
    }
    // delayed input clear when launcher is closed
    function clear_inp() { 
        input_clear_timer.restart()
    }
    // delayed scroll to the top when launcher is closed
    function scroll_top() {
        timer(150, () => item_list.positionViewAtBeginning())
        __selected_id = 1
    }
    // ---------------------------------------------------------------------

    // keyboard navigation
    Keys.onPressed: function (e){
        if (e.key === Qt.Key_Down) {
            launcher.__selected_id = (launcher.__selected_id % launcher.__max_items) + 1
        }
        if (e.key === Qt.Key_Up) {
            launcher.__selected_id = ((launcher.__selected_id - 2 + launcher.__max_items) % launcher.__max_items) + 1
        }
        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
            item_list.model[item_list.currentIndex].execute()
        }
        if (e.key === Qt.Key_Escape) {
            panel.change_state("bar")
        }
        e.accepted = true
    }

    MouseArea {
        anchors.fill: parent
    }

    Behavior on height {
        NumberAnimation {
            duration: 1000
        }
    }

    Rectangle {
        id: search_bar_container
        z: 100
        anchors.top: parent.top
        anchors.topMargin: 15
        anchors.horizontalCenter: parent.horizontalCenter
        implicitHeight: morpher.bar_height * 1.25
        implicitWidth: parent.width - 20

        radius: morpher.radius
        color: Theme.Colors.background
        Row{
            anchors.fill: parent
            anchors.leftMargin: 10
            spacing: 5
            Text {
                id: search_bar_icon
                text: ""
                anchors.verticalCenter: parent.verticalCenter
                color: Qt.alpha(Theme.Colors.foreground, 0.5)

                font {
                    family: "SF Pro Display"
                    pixelSize: 17
                }
            }
            TextField {
                id: search_bar_input
                implicitHeight: parent.height
                implicitWidth: parent.width - search_bar_icon.width - 10
                z: 100

                palette.text: Theme.Colors.foreground
                focus: launcher.visible
                onFocusChanged: {
                    focus = true
                }
                placeholderText: "Search..."
                placeholderTextColor: Qt.alpha(Theme.Colors.foreground, 0.4)

                onTextChanged: {
                    __selected_id = 1
                }

                background: Rectangle {
                    color: "transparent"
                }
                
                font {
                    pixelSize: 17
                }

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        item_list.model[item_list.currentIndex].execute()
                        panel.change_state("bar")
                        event.accepted = true
                    }
                }
            }
        }
    }

    Rectangle {
        id: separator
        implicitHeight: 1
        implicitWidth: parent.width - 20
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: search_bar_container.height + search_bar_container.anchors.topMargin
        color: Qt.alpha(Theme.Colors.foreground, 0.05)
    }

    Rectangle {
        id: item_container

        implicitHeight: parent.height - search_bar_container.height - search_bar_container.anchors.topMargin - separator.height - 17
        implicitWidth: parent.width - 5
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        radius: morpher.radius
        color: "transparent"
        clip: true
        ListView{
            id: item_list
            
            anchors.fill: parent

            model: [...DesktopEntries.applications.values].filter(app=>{let q=search_bar_input.text.toLowerCase(),n=app.name.toLowerCase(),i=0;return !q||n.includes(q)||[...q].every(c=>(i=n.indexOf(c,i))>=0&&++i)}).sort((a,b)=>{let q=search_bar_input.text.toLowerCase(),x=a.name.toLowerCase(),y=b.name.toLowerCase();return (y===q)-(x===q)||(y.startsWith(q)-x.startsWith(q))||(y.includes(q)-x.includes(q))||x.localeCompare(y)})
            spacing: 2
            clip: true

            currentIndex: launcher.__selected_id - 1
            height: Math.min(model.values.length, 6) * 58
            boundsMovement: Flickable.StopAtBounds
            boundsBehavior: Flickable.DragOverBounds
            opacity: Math.max(0.5, 1.0 - Math.abs(verticalOvershoot) / height)

            highlightMoveDuration: 100
            cacheBuffer: 400
            snapMode: ScrollBar.SnapOnRelease
            delegate: Rectangle {
                id: item

                required property DesktopEntry modelData
                required property int index
                property bool selected: launcher.__selected_id === (index + 1)

                implicitHeight: 58// morpher.bar_height * 2
                implicitWidth: item_container.width - 25
                color: selected ? Qt.alpha(Theme.Colors.foreground, 0.1) : "transparent"

                anchors.horizontalCenter: parent.horizontalCenter
                radius: item_container.radius - 4

                // Behavior on color {
                //     ColorAnimation {
                //         duration: 100
                //     }
                // }


                Rectangle {
                    id: item_selected_indicator

                    opacity: selected ? 1 : 0

                    implicitHeight: parent.height - (radius)
                    implicitWidth: 2.5

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10

                    radius: item_container.radius
                    color: Theme.Colors.green

                    // animations
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 100
                        }
                    }
                }
                
                    
                    Image {
                        id: item_icon

                        readonly property string defaultFallback: "file:///home/arch/airootfs/root/configs/quickshell/bar/icons/default_app_icon.svg"
                        property var icon: Quickshell.iconPath(modelData.icon, true) || defaultFallback

                        source: icon
                        height: 22
                        width: 22
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: item_selected_indicator.anchors.leftMargin * 2.25
                        clip: true
                        fillMode: Image.PreserveAspectFit
                    }

                Column{
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        id: item_name
                        text: modelData.name

                        // explicit height keeps layout on integer pixels
                        height: 20

                        anchors.left: parent.left
                        anchors.leftMargin: (item_selected_indicator.anchors.leftMargin + item_icon.anchors.leftMargin + item_icon.width + item_selected_indicator.width)

                        color: Theme.Colors.foreground

                        font {
                            pixelSize: 15

                        }
                    }
                    Text {
                        id: item_comment
                        text: modelData.genericName || modelData.comment

                        // explicit height keeps layout on integer pixels
                        height: 16

                        anchors.left: parent.left
                        anchors.leftMargin: (item_selected_indicator.anchors.leftMargin + item_icon.anchors.leftMargin + item_icon.width + item_selected_indicator.width)

                        color: Qt.alpha(Theme.Colors.foreground, 0.8)

                        font {
                            pixelSize: 12

                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: launcher.__selected_id = index + 1
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
        visible: item_list.count === 0

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
    }