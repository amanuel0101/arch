import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root
    objectName: "launcherPanelWindow"

    readonly property int maxWidth: 560
    readonly property int maxHeight: 640
    readonly property int screenMargin: 48

    property bool open: true
    property bool focusHeld: true

    signal appLaunchRequested(string appId)
    signal closeRequested()

    // With no panel anchors, wlr-layer-shell centers the surface on the output.
    implicitWidth: screen
        ? Math.max(1, Math.min(maxWidth, screen.width - screenMargin))
        : maxWidth
    implicitHeight: screen
        ? Math.max(1, Math.min(maxHeight, screen.height - screenMargin))
        : maxHeight

    visible: open
    color: "transparent"
    surfaceFormat.opaque: false

    // This is an unanchored popup, not a bar reservation.
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "dummy-launcher"
    WlrLayershell.layer: WlrLayer.Overlay

    // Keep the layer keyboard-interactive for the entire time it is mapped.
    // HyprlandFocusGrab directs the seat to this surface; unmapping lets
    // Hyprland return focus to the previously active application.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    function focusSearch() {
        if (open && launcherContent.item) {
            launcherContent.item.focusSearch()
        }
    }

    function scheduleFocus() {
        if (!open) {
            return
        }

        Qt.callLater(root.focusSearch)
        focusSettler.restart()
    }

    function reset() {
        if (launcherContent.item) {
            launcherContent.item.reset()
        }
    }

    function show() {
        if (!open) {
            // Arm the compositor grab before mapping the panel.
            focusHeld = true
            open = true
            reset()
        }

        scheduleFocus()
    }

    function hide() {
        dismiss()
    }

    function dismiss() {
        if (!open) {
            return
        }

        // Do not clear focusHeld here. The grab and keyboard-interactive layer
        // role must survive until backingWindowVisible becomes false.
        open = false
        closeRequested()
    }

    function toggle() {
        if (open) {
            dismiss()
        } else {
            show()
        }
    }

    onVisibleChanged: {
        if (visible && open) {
            focusHeld = true
            scheduleFocus()
        }
    }

    onBackingWindowVisibleChanged: {
        if (backingWindowVisible) {
            if (open) {
                focusHeld = true
                scheduleFocus()
            }
        } else {
            // The layer surface is gone, so it is now safe to destroy the
            // compositor focus grab. Hyprland restores the previous client.
            focusHeld = false
        }
    }

    onWindowConnected: scheduleFocus()

    Component.onCompleted: scheduleFocus()

    HyprlandFocusGrab {
        id: focusGrab
        objectName: "launcherFocusGrab"

        windows: [root]
        active: root.focusHeld

        onActiveChanged: {
            if (active) {
                root.scheduleFocus()
            }
        }

        onCleared: {
            // Hyprland clears the grab when the user clicks outside the small
            // launcher surface. Treat that exactly like Escape.
            if (root.open) {
                root.dismiss()
            }
        }
    }

    Loader {
        id: launcherContent
        objectName: "launcherContentLoader"

        anchors.fill: parent
        visible: root.open
        source: "LauncherContent.qml"

        onLoaded: {
            if (root.open) {
                root.scheduleFocus()
            }
        }
    }

    Connections {
        target: launcherContent.item

        function onAppLaunchRequested(appId) {
            root.appLaunchRequested(appId)
        }

        function onCloseRequested() {
            root.dismiss()
        }
    }

    Timer {
        id: focusSettler
        interval: 80
        repeat: false

        onTriggered: root.focusSearch()
    }
}
