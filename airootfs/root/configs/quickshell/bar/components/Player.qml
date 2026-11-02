import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import ".."
import "theme"

Rectangle {
    property int idx: 0
    property var players: Mpris.players.values
    readonly property bool is_playing: {
        if (players.length === 0)
            return ""

        return players[idx].isPlaying ? true : false
    }
    readonly property bool is_available: players.length > 0
    property bool extra_hover: false

    onIdxChanged: {
        sound_name_flickable.contentX = 0
    }

    id: root

    anchors.top: parent.top
    anchors.right: parent.right

    implicitHeight: AppState.player_locked || root_hover_handler.hovered || extra_hover ? 150 : Vars.bar_height
    implicitWidth: AppState.player_locked || root_hover_handler.hovered || extra_hover ? 400 : Vars.bar_height
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

    radius: Vars.rad

    color: Colors.background

    HoverHandler {
        id: root_hover_handler
    }

    WheelHandler {
    id: player_wheel_handler

    target: null
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

    onWheel: (event) => {
        const count = players.length || 0
        if (count === 0)
            return

        if (event.angleDelta.y > 0)
            root.idx = (root.idx - 1 + count) % count
        else if (event.angleDelta.y < 0)
            root.idx = (root.idx + 1) % count

        event.accepted = true
    }
}

    property real dragStartX: 0
    property real dragDistance: 0
    property int dragThreshold: 30
    property bool dragTriggered: false
    property bool leftDragging: false

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onPressed: (mouse) => {
            root.leftDragging = mouse.button === Qt.LeftButton
            root.dragStartX = mouse.x
            root.dragDistance = 0
            root.dragTriggered = false
        }

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                AppState.player_locked = !AppState.player_locked
        }

        onPositionChanged: (mouse) => {
            if (!pressed || !root.leftDragging || root.dragTriggered)
                return

            const count = players.length || 0
            if (count < 2)
                return

            const delta = mouse.x - root.dragStartX
            root.dragDistance += delta
            root.dragStartX = mouse.x

            if (root.dragDistance >= root.dragThreshold) {
                root.idx = (root.idx + 1) % count
                root.dragTriggered = true
            } else if (root.dragDistance <= -root.dragThreshold) {
                root.idx = (root.idx - 1 + count) % count
                root.dragTriggered = true
            }
        }

        onReleased: {
            root.leftDragging = false
        }
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        Image {
            visible: true
            id: backdrop
            anchors.fill: parent
            source: poster.source
            fillMode: Image.PreserveAspectCrop
        }
        FastBlur {
        anchors.fill: parent
        source: backdrop
        radius: 32
        //samples: 16
    }
    }

    RectangularShadow {
        anchors.fill: poster_container
        radius: poster_container.radius
        color: Qt.rgba(0, 0, 0, 0.5)
        spread: root_hover_handler.hovered || AppState.player_locked || extra_hover ? 5 : 0
        blur: 10
    }
    ClippingRectangle {
        id: poster_container

        anchors.top: parent.top
        anchors.topMargin: AppState.player_locked || root_hover_handler.hovered || extra_hover ? radius/3 : 0
        anchors.left: parent.left
        anchors.leftMargin: AppState.player_locked || root_hover_handler.hovered || extra_hover ? radius/3 : 0

        height: AppState.player_locked || root_hover_handler.hovered || extra_hover ? (parent.height - (anchors.topMargin * 2)) : parent.height
        width: AppState.player_locked || root_hover_handler.hovered || extra_hover ? (parent.height - (anchors.topMargin * 2)) : (height)

        Behavior on implicitHeight {
            NumAnim {}
        }

        Behavior on implicitWidth {
            NumAnim {}
        }

        radius: Vars.rad

        color: Colors.background

        Image {
            id: poster
            anchors.fill: parent

            asynchronous: true
            cache: true

            source: {
                if (players.length === 0 || !players[idx])
                    return Qt.resolvedUrl("../icons/sound_disk.svg");

                return players[idx].trackArtUrl || Qt.resolvedUrl("../icons/sound_disk.svg");
            }
            fillMode: Image.PreserveAspectCrop
        }

        // Rectangle {
        //     anchors.fill: parent

        //     color: Qt.alpha(Colors.green, 0.25)
        // }
    }

    ClippingRectangle {
        anchors.bottom: poster_container.bottom
        anchors.right: poster_container.right
        anchors.rightMargin: -(width/3)

        visible: opacity > 0
        opacity: (root_hover_handler.hovered || extra_hover || AppState.player_locked) && root.height > 140 ? 1 : 0

        implicitHeight: poster.height * 0.25
        implicitWidth: poster.width * 0.25

        Behavior on opacity {
            NumAnim {}
        }

        radius: Vars.rad

        color: "transparent"



        Image {
            id: desk
            anchors.fill: parent

            fillMode: Image.PreserveAspectFit

            source: {
                if (players.length === 0 || !players[idx])
                    return Qt.resolvedUrl("../icons/sound_disk.svg");

                const player = players[idx];
                const entry = DesktopEntries.heuristicLookup(
                    player.desktopEntry || player.identity
                );

                if (!entry || !entry.icon)
                    return Qt.resolvedUrl("../icons/sound_disk.svg");

                return Quickshell.iconPath(entry.icon);
            }
        }
    }

    Rectangle {
        id: sound_name_container

        anchors.top: parent.top
        anchors.topMargin: (parent.radius/3) * 2
        anchors.left: poster_container.right
        anchors.leftMargin: 20

        implicitHeight: sound_name.height
        implicitWidth: parent.width - poster_container.width - poster_container.anchors.leftMargin - parent.radius

        opacity: AppState.player_locked || root_hover_handler.hovered || extra_hover ? 1 : 0
        Behavior on opacity {
            NumAnim {}
        }

        radius: Vars.rad

        color: "transparent"

        clip: true

        Flickable {
            id: sound_name_flickable
            anchors.fill: parent
            contentWidth: sound_name.width
            Text {
                id: sound_name

                text: {
                    if (players.length === 0)
                        return "No music playing"

                    return players[idx].trackTitle || "Unknown Title"
                }

                color: Colors.foreground

                font {
                    family: "SF Mono"
                    pixelSize: 15
                    bold: true
                }
            }
        }
    }
    Rectangle {
        id: sound_creator_container

        anchors.top: sound_name_container.bottom
        anchors.topMargin: 5
        anchors.left: poster_container.right
        anchors.leftMargin: 20

        implicitHeight: sound_name.height
        implicitWidth: parent.width - poster_container.width - poster_container.anchors.leftMargin - parent.radius

        opacity: AppState.player_locked || root_hover_handler.hovered || extra_hover ? 1 : 0
        Behavior on opacity {
            NumAnim {}
        }

        radius: Vars.rad

        color: "transparent"

        clip: true

        Text {
            id: sound_creator

            text: {
                if (players.length === 0)
                    return "No music playing"

                return players[idx].trackArtist || "Unknown Artist"
            }

            color: Colors.foreground

            font {
                family: "SF Mono"
                pixelSize: 12
            }
        }
    }

    Rectangle {
        id: sound_bar

        anchors.top: sound_creator_container.bottom
        anchors.topMargin: 10
        anchors.left: poster_container.right
        anchors.leftMargin: 20

        implicitHeight: 20
        implicitWidth: parent.width - poster_container.width - poster_container.anchors.leftMargin - parent.radius

        visible: opacity > 0.25
        opacity: (AppState.player_locked || root_hover_handler.hovered || extra_hover) && root.height > 140 ? 1 : 0
        Behavior on opacity {
            NumAnim {}
        }

        color: "transparent"

        clip: true

        Timer {
            id: position_timer

            interval: 500
            running: is_playing
            repeat: true

            property int tick: 0

            onTriggered: tick++
        }

        Row {
            anchors.left: parent.left
            height: parent.height
            width: parent.width - 10
            
            spacing: 5

            Text {
                text: {
                    position_timer.tick
                    if (players.length === 0)
                        return "0:00"

                    const seconds = Math.floor(players[idx].position)
                    const minutes = Math.floor(seconds / 60)
                    const remainingSeconds = seconds % 60

                    return `${minutes}:${remainingSeconds.toString().padStart(2, "0")}`
                }

                anchors.verticalCenter: parent.verticalCenter

                color: Colors.foreground

                font {
                    family: "SF Mono"
                    pixelSize: 10
                }
            }

            ClippingRectangle {
                anchors.verticalCenter: parent.verticalCenter

                implicitHeight: bar_hover_handler.hovered ? parent.height * 0.35 : parent.height * 0.25
                implicitWidth: parent.width - dummy.width

                Text {
                    id: dummy
                    text: "00:0000:00"
                    visible: false

                    anchors.verticalCenter: parent.verticalCenter

                    color: Colors.foreground

                    font {
                        family: "SF Mono"
                        pixelSize: 10
                    }
                }

                color: Qt.lighter(Colors.foreground, 0.5)

                radius: Vars.rad

                HoverHandler {
                    id: bar_hover_handler
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: (mouse) => {
                        var h_pos = mouse.x
                        var percent = h_pos / parent.width
                        players[idx].position = percent * players[idx].length
                    }
                }

                Rectangle {
                    id: scroll_bar
                    anchors.left: parent.left

                    implicitHeight: parent.height
                    implicitWidth: {
                        position_timer.tick
                        if (players.length === 0 || players[idx].length <= 0)
                            return 0

                        return parent.width * Math.max(
                            0, Math.min(1,
                                players[idx].position / players[idx].length
                            )
                        )
                    }

                    // radius: Vars.rad

                    color: Colors.foreground
                }
            }

            Text {
                text: {
                    if (players.length === 0)
                        return "0:00"

                    const seconds = Math.floor(players[idx].length)
                    const minutes = Math.floor(seconds / 60)
                    const remainingSeconds = seconds % 60

                    return `${minutes}:${remainingSeconds.toString().padStart(2, "0")}`
                }

                anchors.verticalCenter: parent.verticalCenter

                color: Colors.foreground

                font {
                    family: "SF Mono"
                    pixelSize: 10
                }
            }
        }
    }
    Rectangle {
        id: controls

        anchors.top: sound_bar.bottom
        anchors.topMargin: 5
        anchors.horizontalCenter: sound_bar.horizontalCenter

        implicitHeight: 30
        implicitWidth: parent.width - poster_container.width - poster_container.anchors.leftMargin - parent.radius

        visible: opacity > 0
        opacity: (root_hover_handler.hovered || extra_hover || AppState.player_locked) && root.height > 140 ? 1 : 0
        Behavior on opacity {
            NumAnim {
                duration: 100
            }
        }

        color: "transparent"

        clip: true

        Row{
            anchors.centerIn: parent

            spacing: 8

            Image {
                id: rewind_icon

                source: "../icons/apple_rewind.svg"

                anchors.verticalCenter: parent.verticalCenter

                height: 30
                width: 30

                function click_handler(mouse) {
                    if (mouse.button === Qt.RightButton) {
                        if (players.length > 0 && players[idx].canSeek)
                            players[idx].position = Math.max(0, players[idx].position - 10)
                    }
                    else if (mouse.button === Qt.LeftButton){
                        if (players.length > 0 && players[idx].canGoPrevious)
                            players[idx].previous()
                    }
                }
                
                OnClickBounce {
                    action: parent.click_handler
                }
                Behavior on scale {
                    SpringAnimation {
                        spring: 8
                        damping: 0.25
                        mass: 0
                        epsilon: 0.5
                    }
                }
            }
            Rectangle {
                implicitHeight: play_icon.height
                implicitWidth: play_icon.width

                radius: Vars.rad

                color: "transparent"

                function click_handler() {

                    if (players.length > 0 && players[idx].canTogglePlaying)
                        players[idx].togglePlaying()
                }
                OnClickBounce {
                    action: parent.click_handler
                }
                Behavior on scale {
                    SpringAnimation {
                        spring: 8
                        damping: 0.25
                        mass: 0
                        epsilon: 0.5
                    }
                }

                Image {
                    id: play_icon

                    source: "../icons/apple_play.svg"
                    visible: !is_playing
                    
                    anchors.verticalCenter: parent.verticalCenter

                    height: 30
                    width: 30
                }
                Image {
                    id: pause_icon

                    source: "../icons/apple_pause.svg"

                    visible: is_playing
                    
                    anchors.verticalCenter: parent.verticalCenter

                    height: 30
                    width: 30
                }
            }
            Image {
                id: fast_forward_icon

                source: "../icons/apple_fast_forward.svg"

                anchors.verticalCenter: parent.verticalCenter

                height: 30
                width: 30


                function click_handler(mouse) {
                    if (mouse.button === Qt.RightButton) {
                        if (players.length > 0 && players[idx].canSeek)
                            players[idx].position = Math.max(
                                0,
                                Math.min(players[idx].position + 10, players[idx].length)
                            )
                    }
                    else if (mouse.button === Qt.LeftButton){
                        if (players.length > 0 && players[idx].canGoNext)
                            players[idx].next()
                    }
                }
                OnClickBounce {
                    action: parent.click_handler
                }
                Behavior on scale {
                    SpringAnimation {
                        spring: 8
                        damping: 0.25
                        mass: 0
                        epsilon: 0.5
                    }
                }
            }
        }
    }
}