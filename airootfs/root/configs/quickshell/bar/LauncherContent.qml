import QtQuick
import QtQuick.Controls
import "components/theme"

Item {
    id: root
    objectName: "launcherContent"

    implicitWidth: 560
    implicitHeight: 640
    clip: true

    signal appLaunchRequested(string appId)
    signal closeRequested()

    // The fallbacks also keep the content usable when it is instantiated by a
    // Loader from another Quickshell configuration (where singleton discovery
    // can differ), while matching theme/Colors.qml.
    readonly property color backgroundColor: Theme.Colors && Theme.Colors.background !== undefined
        ? Theme.Colors.background
        : "#282828"
    readonly property color foregroundColor: Theme.Colors && Theme.Colors.foreground !== undefined
        ? Theme.Colors.foreground
        : "#ebdbb2"
    readonly property color accentColor: Theme.Colors && Theme.Colors.green !== undefined
        ? Theme.Colors.green
        : "#98971a"

    readonly property var dummyApps: [
        { id: "terminal", name: "Terminal", description: "Command line", category: "System", color: "#a89984", keywords: "console shell command prompt" },
        { id: "files", name: "Files", description: "Browse your files", category: "Utilities", color: "#689d6a", keywords: "folder browser nautilus" },
        { id: "browser", name: "Web Browser", description: "Browse the web", category: "Internet", color: "#83a598", keywords: "internet firefox chrome web" },
        { id: "editor", name: "Text Editor", description: "Edit text files", category: "Development", color: "#d79921", keywords: "write document gedit" },
        { id: "settings", name: "Settings", description: "Configure your system", category: "System", color: "#928374", keywords: "preferences control center configuration" },
        { id: "mail", name: "Mail", description: "Read and send email", category: "Internet", color: "#458588", keywords: "email inbox message" },
        { id: "calendar", name: "Calendar", description: "Manage events", category: "Productivity", color: "#b16286", keywords: "events schedule agenda" },
        { id: "music", name: "Music", description: "Play your library", category: "Media", color: "#cc241d", keywords: "audio player song" },
        { id: "photos", name: "Photos", description: "View your pictures", category: "Media", color: "#8ec07c", keywords: "images gallery picture" },
        { id: "calculator", name: "Calculator", description: "Perform calculations", category: "Utilities", color: "#98971a", keywords: "math numbers" },
        { id: "code", name: "Code Editor", description: "Edit source code", category: "Development", color: "#fb4934", keywords: "ide programming developer" },
        { id: "notes", name: "Notes", description: "Write quick notes", category: "Productivity", color: "#fabd2f", keywords: "note taking todo" }
    ]
    property var filteredApps: []

    function focusSearch() {
        if (visible && enabled) {
            searchInput.forceActiveFocus()
        }
    }

    function updateFilter() {
        const rawQuery = searchInput.text.trim()
        const query = rawQuery.toLocaleLowerCase()
        const terms = query.length === 0 ? [] : query.split(/\s+/)
        const matches = []

        for (let i = 0; i < dummyApps.length; ++i) {
            const app = dummyApps[i]
            const searchable = [
                app.name,
                app.description,
                app.category,
                app.keywords
            ].join(" ").toLocaleLowerCase()
            const matchesEveryTerm = terms.every(term => searchable.indexOf(term) !== -1)

            if (matchesEveryTerm) {
                matches.push(app)
            }
        }

        filteredApps = matches
        resetSelection()
    }

    function resetSelection() {
        appList.currentIndex = appList.count === 0 ? -1 : 0
        appList.positionViewAtBeginning()
    }

    function moveSelection(amount) {
        if (appList.count === 0) {
            return
        }

        const count = appList.count
        appList.currentIndex = (appList.currentIndex + amount + count) % count
        appList.positionViewAtIndex(appList.currentIndex, ListView.Contain)
    }

    function moveToBoundary(useEnd) {
        if (appList.count === 0) {
            return
        }

        appList.currentIndex = useEnd ? appList.count - 1 : 0
        appList.positionViewAtIndex(
            appList.currentIndex,
            useEnd ? ListView.End : ListView.Beginning
        )
    }

    function activateApp(index) {
        if (index < 0 || index >= appList.count) {
            return
        }

        const app = appList.model[index]
        console.log("Dummy launcher requested app:", app.id)
        appLaunchRequested(app.id)
    }

    function activateCurrentApp() {
        activateApp(appList.currentIndex)
    }

    function clearSearch() {
        searchInput.clear()
        searchInput.forceActiveFocus()
    }

    function reset() {
        searchInput.clear()
        updateFilter()
        focusSearch()
    }

    onVisibleChanged: {
        if (visible) {
            Qt.callLater(root.focusSearch)
        }
    }

    onEnabledChanged: {
        if (enabled) {
            Qt.callLater(root.focusSearch)
        }
    }

    Component.onCompleted: {
        updateFilter()
        Qt.callLater(root.focusSearch)
    }

    Rectangle {
        objectName: "launcherBackground"
        anchors.fill: parent
        radius: 24
        color: root.backgroundColor
        border.width: 1
        border.color: Qt.alpha(root.foregroundColor, 0.08)

        // Clicks on empty space must never leave keyboard focus elsewhere.
        MouseArea {
            anchors.fill: parent
            onPressed: root.focusSearch()
        }
    }

    TextField {
        id: searchInput
        objectName: "launcherSearchInput"

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 18
        }
        height: 52
        activeFocusOnTab: true
        focus: visible && enabled
        focusPolicy: Qt.StrongFocus
        selectByMouse: true
        selectionColor: Qt.alpha(root.accentColor, 0.45)
        selectedTextColor: root.foregroundColor
        color: root.foregroundColor
        placeholderText: "Search applications..."
        placeholderTextColor: Qt.alpha(root.foregroundColor, 0.42)
        font.pixelSize: 17
        padding: 0
        leftPadding: 46
        rightPadding: clearButton.visible ? 46 : 14
        verticalAlignment: TextInput.AlignVCenter

        background: Rectangle {
            radius: 14
            color: Qt.alpha(root.foregroundColor, 0.055)
            border.width: 1
            border.color: searchInput.activeFocus
                ? Qt.alpha(root.accentColor, 0.75)
                : Qt.alpha(root.foregroundColor, 0.08)

            Behavior on border.color {
                ColorAnimation {
                    duration: 120
                }
            }
        }

        Text {
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            text: "search"
            color: searchInput.activeFocus
                ? root.accentColor
                : Qt.alpha(root.foregroundColor, 0.48)
            font.family: "Material Symbols Rounded"
            font.pixelSize: 22
        }

        ToolButton {
            id: clearButton

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: 7
            }
            width: 34
            height: 34
            visible: searchInput.text.length > 0
            focusPolicy: Qt.NoFocus
            padding: 0

            onClicked: root.clearSearch()

            contentItem: Text {
                text: "close"
                color: clearButton.hovered
                    ? root.foregroundColor
                    : Qt.alpha(root.foregroundColor, 0.6)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: "Material Symbols Rounded"
                font.pixelSize: 18
            }

            background: Rectangle {
                radius: width / 2
                color: clearButton.hovered
                    ? Qt.alpha(root.foregroundColor, 0.1)
                    : "transparent"
            }
        }

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
            const controlPressed = (event.modifiers & Qt.ControlModifier) !== 0

            if (event.key === Qt.Key_Escape) {
                root.closeRequested()
                event.accepted = true
                return
            }

            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.activateCurrentApp()
                event.accepted = true
                return
            }

            if (event.key === Qt.Key_Down
                    || (controlPressed && event.key === Qt.Key_N)) {
                root.moveSelection(1)
                event.accepted = true
                return
            }

            if (event.key === Qt.Key_Up
                    || (controlPressed && event.key === Qt.Key_P)) {
                root.moveSelection(-1)
                event.accepted = true
                return
            }

            if (event.key === Qt.Key_PageDown) {
                root.moveSelection(Math.max(1, Math.floor(appList.height / 62)))
                event.accepted = true
                return
            }

            if (event.key === Qt.Key_PageUp) {
                root.moveSelection(-Math.max(1, Math.floor(appList.height / 62)))
                event.accepted = true
                return
            }

            if (controlPressed && event.key === Qt.Key_Home) {
                root.moveToBoundary(false)
                event.accepted = true
                return
            }

            if (controlPressed && event.key === Qt.Key_End) {
                root.moveToBoundary(true)
                event.accepted = true
                return
            }

            if (controlPressed && event.key === Qt.Key_U) {
                root.clearSearch()
                event.accepted = true
                return
            }

            // Keep Tab from dropping focus into controls behind the overlay.
            if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                root.focusSearch()
                event.accepted = true
            }
        }

        onTextChanged: root.updateFilter()
    }

    Text {
        id: resultLabel

        anchors {
            top: searchInput.bottom
            left: parent.left
            right: parent.right
            topMargin: 16
            leftMargin: 20
            rightMargin: 20
        }
        text: appList.count === 1 ? "1 application" : appList.count + " applications"
        color: Qt.alpha(root.foregroundColor, 0.48)
        font.pixelSize: 12
    }

    ListView {
        id: appList
        objectName: "launcherApplicationList"

        anchors {
            top: resultLabel.bottom
            left: parent.left
            right: parent.right
            bottom: footer.top
            topMargin: 8
            leftMargin: 12
            rightMargin: 12
            bottomMargin: 6
        }
        clip: true
        spacing: 4
        model: root.filteredApps
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: -1
        highlightMoveDuration: 100
        cacheBuffer: 400

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        delegate: Rectangle {
            id: appDelegate

            required property var modelData
            required property int index

            width: appList.width
            height: 58
            radius: 13
            color: appList.currentIndex === index
                ? Qt.alpha(root.accentColor, 0.16)
                : "transparent"
            border.width: 1
            border.color: appList.currentIndex === index
                ? Qt.alpha(root.accentColor, 0.3)
                : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: 100
                }
            }

            Rectangle {
                id: appIcon

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: 10
                }
                width: 38
                height: 38
                radius: 11
                color: Qt.alpha(appDelegate.modelData.color, 0.2)

                Text {
                    anchors.centerIn: parent
                    text: appDelegate.modelData.name.charAt(0)
                    color: appDelegate.modelData.color
                    font {
                        family: "SF Pro Display"
                        pixelSize: 18
                        weight: Font.DemiBold
                    }
                }
            }

            Column {
                anchors {
                    left: appIcon.right
                    right: launchHint.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: 12
                    rightMargin: 10
                }
                spacing: 2

                Text {
                    width: parent.width
                    text: appDelegate.modelData.name
                    color: root.foregroundColor
                    elide: Text.ElideRight
                    font {
                        family: "SF Pro Display"
                        pixelSize: 15
                        weight: Font.DemiBold
                    }
                }

                Text {
                    width: parent.width
                    text: appDelegate.modelData.description
                    color: Qt.alpha(root.foregroundColor, 0.55)
                    elide: Text.ElideRight
                    font {
                        family: "SF Pro Display"
                        pixelSize: 12
                    }
                }
            }

            Text {
                id: launchHint

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    rightMargin: 13
                }
                text: "↵"
                opacity: appList.currentIndex === index ? 0.75 : 0
                color: root.accentColor
                font.pixelSize: 17

                Behavior on opacity {
                    NumberAnimation {
                        duration: 100
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    appList.currentIndex = appDelegate.index
                    root.activateApp(appDelegate.index)
                    root.focusSearch()
                }
            }
        }
    }

    Column {
        id: emptyState

        anchors.centerIn: appList
        width: parent.width - 64
        spacing: 7
        visible: appList.count === 0

        Text {
            width: parent.width
            text: "search_off"
            horizontalAlignment: Text.AlignHCenter
            color: Qt.alpha(root.foregroundColor, 0.28)
            font.family: "Material Symbols Rounded"
            font.pixelSize: 34
        }

        Text {
            width: parent.width
            text: "No applications found"
            horizontalAlignment: Text.AlignHCenter
            color: root.foregroundColor
            font {
                family: "SF Pro Display"
                pixelSize: 15
                weight: Font.DemiBold
            }
        }

        Text {
            width: parent.width
            text: "Try a different search"
            horizontalAlignment: Text.AlignHCenter
            color: Qt.alpha(root.foregroundColor, 0.45)
            font {
                family: "SF Pro Display"
                pixelSize: 12
            }
        }
    }

    Rectangle {
        id: footer

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 18
            rightMargin: 18
            bottomMargin: 14
        }
        implicitHeight: 1
        color: Qt.alpha(root.foregroundColor, 0.08)
    }

    Row {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 26
        }
        spacing: 18

        Repeater {
            model: [
                { keys: "↑ ↓", label: "Navigate" },
                { keys: "↵", label: "Open" },
                { keys: "Esc", label: "Close" }
            ]

            delegate: Row {
                required property var modelData
                spacing: 6

                Text {
                    text: modelData.keys
                    color: root.foregroundColor
                    font.pixelSize: 11
                }

                Text {
                    text: modelData.label
                    color: Qt.alpha(root.foregroundColor, 0.45)
                    font.pixelSize: 11
                }
            }
        }
    }
}
