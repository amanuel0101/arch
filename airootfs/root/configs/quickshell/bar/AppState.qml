pragma Singleton

import QtQuick
import Quickshell.Services.SystemTray
import "."

QtObject {
    // morpher
    property string morpher_state: "bar"
    property string past_morpher_state: "bar"
    function change_state(st) {
        let next = morpher_state

        if (st != "bar") {
            bar_expanded = false
        }

        if (st === "bar") {
            next = st
        }
        else if (st === "launcher") {
            next = (morpher_state === st) ? "bar" : st
        }
        else if (st === "osd-volume") {
            next = st
            osd_close_timer.restart()
        }
        else if (st === "osd-brightness") {
            next = st
            osd_close_timer.restart()
        }
        else if (st === "network") {
            next = st
        }
        else if (st === "wallpaper") {
            next = (morpher_state === st) ? "bar" : st
        }
        // if (st === "notification") {
        //     next = st
        // }

        if (next !== morpher_state) {
            past_morpher_state = morpher_state   // record before switching
            morpher_state = next
        }
    }

    // bar
    property bool bar_locked: true
    property bool bar_expanded: false
    function toggle_bar_lock() {
        if (morpher_state === "bar")
            bar_locked = !bar_locked
    }

    // notifcation
    property var notifications: ListModel {}
    property bool notif: false

    // player
    property bool player_locked: false
    property bool mini_mode: false

    // system tray
    property bool systray_active: false
    property int systray_items: SystemTray.items.values.length

    // osd
    property int osd_close_interval: 2000
    property var timer: Timer {
        id: osd_close_timer

        interval: osd_close_interval
        running: morpher_state === "osd-volume" || morpher_state === "osd-brightness"

        onTriggered: {
            past_morpher_state = morpher_state
            morpher_state = "bar"
        }
    }
}
