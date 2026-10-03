
import QtQuick

QtObject {
    property string morpher_state: "bar"
    readonly property bool deBUG: false

    property bool is_launcher: morpher_state === "launcher"
    property bool is_bar: morpher_state === "bar"
    property bool is_vol: morpher_state === "volume-osd"
    property bool is_brightness: morpher_state === "brightness-osd"
    property bool is_notification: morpher_state === "notification"
    property bool is_notification_panel: morpher_state === "notification_panel"
    property int visible_notifications: 0
    property var unread_notifications: []

    property Timer timer: Timer {
        interval: 1500
        running: false
        repeat: false

        onTriggered: {
            change_state("bar")
        }
    }
    
    property var not_interval: 5000

    property Timer notification_timer: Timer {
        interval: not_interval
        running: false
        repeat: false

        onTriggered: {
            change_state("bar")
        }
    }
    
    // functions -----------------------------------------
    
    function change_state(st="bar") { // change the morpher to any available state
        if (st === "bar") {
            morpher_state = st
        }
        else if (st === "launcher") {
            if (morpher_state === st) { // if launcher is already open change to bar
                st = "bar"
            }
            morpher_state = st
        }
        else if (st === "volume-osd") {
            timer.restart()
            morpher_state = st

        }
        else if (st === "brightness-osd") {
            timer.restart()
            morpher_state = st
        }
        else if (st === "notification") {
            morpher_state = st
            // not_interval+=1000
            // notification_timer.start()
        }
        else if (st === "notification_panel") {
            morpher_state = st
            // not_interval+=1000
            // notification_timer.start()
        }
        
        else {
            console.warn("unknown state: ", st)
            return
        }

        if (deBUG)
            console.log("state: " + st)
    }

    //----------------------------------------------------
}