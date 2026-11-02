
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick.Controls
import QtQuick.Effects
import "theme"
import ".."

Rectangle {
    id: root

    property string folder: Quickshell.env("HOME") + "/Pictures/backgrounds"
    property string current_wall: ""
    property var walls: []

    property int current_wall_idx: walls.indexOf(current_wall)

    property bool active: AppState.morpher_state === "wallpaper"

    property int wall_width: 250
    property int item_spacing: 5

    property int scrollAccum: 0
    property int scrollThreshold: 300

    property bool initialPositionRestored: false

    anchors.fill: parent

    color: "transparent"
    radius: Vars.rad

    // -------------------------------------------------------------------------
    // WALLPAPER LOADING
    // -------------------------------------------------------------------------

    Process {
        id: get_curr_wall

        running: true

        command: [
            "readlink",
            "-e",
            Quickshell.env("HOME") + "/.config/current/background.jpg"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                root.current_wall = text.trim()
                root.restoreSelection()
            }
        }
    }

    Process {
        id: proc

        command: [
            "find",
            root.folder,
            "-maxdepth", "1",
            "-type", "f"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                root.walls = text.trim()
                    .split("\n")
                    .filter(path => path.trim() !== "")

                root.restoreSelection()
            }
        }
    }

    // -------------------------------------------------------------------------
    // WALLPAPER APPLY
    // -------------------------------------------------------------------------

    Process {
        id: proc_set_wallpaper

        property string to_set: ""

        command: [
            "sh", "-c",
            'ln -sfn "$1" "$HOME/.config/current/background.jpg" && hyprctl hyprpaper wallpaper "eDP-1, $HOME/.config/current/background.jpg, cover"',
            "sh",
            to_set
        ]

        onExited: (code, status) => {
            if (code === 0) {
                root.current_wall = to_set
                root.restoreSelection()
            }
        }
    }

    function set_wallpaper(path) {
        if (!path || proc_set_wallpaper.running)
            return

        proc_set_wallpaper.to_set = path
        proc_set_wallpaper.running = true
    }

    // -------------------------------------------------------------------------
    // SELECTION RESTORE
    // -------------------------------------------------------------------------

    function restoreSelection() {
        if (walls.length === 0)
            return

        let index = walls.indexOf(current_wall)

        if (index < 0)
            index = 0

        flick.currentIndex = index
        initialPositionRestored = true
    }

    // -------------------------------------------------------------------------
    // ACTIVE STATE
    // -------------------------------------------------------------------------

    onActiveChanged: {
        if (active) {
            if (!initialPositionRestored)
                restoreSelection()

            proc.running = true
        } else {
            flick.currentIndex = current_wall_idx >= 0
                ? current_wall_idx
                : 0
        }
    }

    onCurrent_wall_idxChanged: {
        if (!active && current_wall_idx >= 0) {
            flick.currentIndex = current_wall_idx
        }
    }

    // -------------------------------------------------------------------------
    // NAVIGATION
    // -------------------------------------------------------------------------

    function moveSelection(direction) {
        if (!active || flick.count === 0)
            return

        let nextIndex = Math.max(
            0,
            Math.min(
                flick.count - 1,
                flick.currentIndex + direction
            )
        )

        flick.currentIndex = nextIndex
    }

    function applySelection() {
        if (flick.currentIndex < 0 ||
            flick.currentIndex >= walls.length)
            return

        set_wallpaper(walls[flick.currentIndex])
    }

    // -------------------------------------------------------------------------
    // HEADER
    // -------------------------------------------------------------------------

    Text {
        id: folder_name

        text: root.folder

        anchors.top: parent.top
        anchors.left: parent.left

        anchors.topMargin: 10
        anchors.leftMargin: parent.radius

        color: Colors.foreground

        font {
            family: "SF Mono"
        }
    }

    Text {
        id: counter

        text: walls.length > 0
            ? (flick.currentIndex + 1) + "/" + walls.length
            : "0/0"

        anchors.top: parent.top
        anchors.right: parent.right

        anchors.topMargin: 10
        anchors.rightMargin: parent.radius

        color: Colors.foreground

        font {
            family: "SF Mono"
        }
    }

    // -------------------------------------------------------------------------
    // WALLPAPER LIST
    // -------------------------------------------------------------------------

    ClippingRectangle {
        id: walls_container

        anchors.bottom: parent.bottom

        implicitHeight: parent.height
            - (folder_name.height + folder_name.anchors.topMargin)
            - (counter.height + counter.anchors.topMargin)

        implicitWidth: parent.width

        color: "transparent"

        focus: active

        Keys.onPressed: (event) => {
            if (!root.active)
                return

            if (event.key === Qt.Key_Right) {
                root.moveSelection(1)
                event.accepted = true
            }
            else if (event.key === Qt.Key_Left) {
                root.moveSelection(-1)
                event.accepted = true
            }
            else if (
                event.key === Qt.Key_Enter ||
                event.key === Qt.Key_Return
            ) {
                root.applySelection()
                event.accepted = true
            }
        }

        ListView {
            id: flick

            anchors.fill: parent

            orientation: ListView.Horizontal

            model: root.walls

            spacing: root.item_spacing

            clip: false

            interactive: root.active &&
                         !proc_set_wallpaper.running

            boundsBehavior: Flickable.StopAtBounds

            // Same snapping architecture as the first picker.
            highlightRangeMode: ListView.StrictlyEnforceRange

            preferredHighlightBegin:
                (width - root.wall_width) / 2

            preferredHighlightEnd:
                (width + root.wall_width) / 2

            highlightMoveDuration: 300
            highlightMoveVelocity: -1

            cacheBuffer: root.wall_width * 4

            currentIndex: root.current_wall_idx >= 0
                ? root.current_wall_idx
                : 0

            // -----------------------------------------------------------------
            // MOVEMENT
            // -----------------------------------------------------------------

            onMovementStarted: {
                mid_.opacity = 0.25
            }

            onMovementEnded: {
                mid_.opacity = 1

                // Synchronize the selected item after touchpad/finger flicks.
                let itemWidth = root.wall_width + root.item_spacing

                var index = Math.round(contentX / root.item_width)

                if (index >= 0 && index !== currentIndex)
                    currentIndex = index
            }

            onCurrentIndexChanged: {
                root.scrollAccum = 0
            }

            // -----------------------------------------------------------------
            // WHEEL NAVIGATION
            // -----------------------------------------------------------------

            MouseArea {
                anchors.fill: parent

                acceptedButtons: Qt.NoButton

                enabled: root.active

                onWheel: (wheel) => {
                    if (proc_set_wallpaper.running) {
                        wheel.accepted = true
                        return
                    }

                    let dx = wheel.angleDelta.x
                    let dy = wheel.angleDelta.y

                    let delta = Math.abs(dx) > Math.abs(dy)
                        ? dx
                        : dy

                    root.scrollAccum += delta

                    if (Math.abs(root.scrollAccum) >= root.scrollThreshold) {
                        root.moveSelection(
                            root.scrollAccum > 0 ? -1 : 1
                        )

                        root.scrollAccum = 0
                    }

                    wheel.accepted = true
                }
            }

            // -----------------------------------------------------------------
            // WALLPAPER DELEGATES
            // -----------------------------------------------------------------

            delegate: Item {
                id: delegateRoot

                required property var modelData
                required property int index

                property bool is_set:
                    root.current_wall === modelData

                property bool is_center:
                    ListView.isCurrentItem

                width: root.wall_width + root.item_spacing
                height: flick.height

                Item {
                    anchors.centerIn: parent

                    width: root.wall_width
                    height: parent.height / 1.25

                    ClippingRectangle {
                        id: rec

                        anchors.fill: parent

                        radius: Vars.rad

                        color: Qt.lighter(
                            Colors.background,
                            1.25
                        )

                        scale: delegateRoot.is_center
                            ? 1.05
                            : 0.7

                        Behavior on scale {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.InOutQuad
                            }
                        }

                        Image {
                            anchors.fill: parent

                            asynchronous: true
                            cache: true
                            antialiasing: true

                            source: delegateRoot.modelData

                            sourceSize.height: 200
                            sourceSize.width: 300

                            fillMode: Image.PreserveAspectCrop
                        }

                        MouseArea {
                            anchors.fill: parent

                            acceptedButtons:
                                Qt.LeftButton | Qt.RightButton

                            enabled: root.active &&
                                     !proc_set_wallpaper.running

                            cursorShape: Qt.PointingHandCursor

                            onClicked: (mouse) => {
                                flick.currentIndex = delegateRoot.index

                                if (mouse.button === Qt.RightButton) {
                                    root.set_wallpaper(
                                        delegateRoot.modelData
                                    )
                                }
                            }
                        }
                    }

                    // ---------------------------------------------------------
                    // CURRENT WALLPAPER INDICATOR
                    // ---------------------------------------------------------

                    Rectangle {
                        visible: delegateRoot.is_set

                        anchors.fill: rec

                        color: "transparent"

                        radius: Vars.rad

                        scale: delegateRoot.is_center
                            ? 1.05
                            : 0.7

                        border {
                            width: 2
                            color: Colors.green
                        }

                        MultiEffect {
                            anchors.fill: parent

                            source: parent

                            shadowEnabled: true
                            shadowColor: "#aa000000"
                            shadowBlur: 10
                            shadowScale: 10
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }
                }
            }
        }

        // ---------------------------------------------------------------------
        // CENTER INDICATOR
        // ---------------------------------------------------------------------

        Rectangle {
            id: mid_

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom

            anchors.bottomMargin: 6

            implicitHeight: mid__mouse.containsMouse ? 8 : 3
            implicitWidth: 32

            color: Colors.foreground

            opacity: 1

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: 150
                }
            }

            radius: Vars.rad

            MouseArea {
                id: mid__mouse

                anchors.fill: parent

                hoverEnabled: true

                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    root.restoreSelection()
                }
            }
        }
    }
}