pragma Singleton

import QtQuick

QtObject {
    property string morpher_state: "bar"
    property string past_morpher_state: "bar"
    property bool bar_locked: true
    
    property int osd_close_interval: 2000
    property var timer: Timer {
        id: osd_close_timer

        interval: osd_close_interval

        running: morpher_state.startsWith("osd")

        onTriggered: {
            morpher_state = past_morpher_state
        }
    }

    function toggle_bar_lock() {
        if (morpher_state === "bar")
            bar_locked = !bar_locked
    }

    function change_state(st) {
        if (st === "bar") {
            past_morpher_state = morpher_state
            morpher_state = st
        }
        else if (st === "launcher") {
            if (morpher_state === st) {
                past_morpher_state = morpher_state
                morpher_state = "bar"
            }
            else {
                past_morpher_state = morpher_state
                morpher_state = st
            }
        }
        else if (st === "osd-volume") {
            if (morpher_state != st)
                past_morpher_state = morpher_state
            morpher_state = st
            osd_close_timer.restart()
        }
    }
}