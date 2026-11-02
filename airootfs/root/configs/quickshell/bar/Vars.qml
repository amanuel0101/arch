pragma Singleton

import QtQuick
import Quickshell
import "components/theme"

QtObject {
    readonly property int rad: 40

    readonly property int bar_edge_space: 8

    readonly property int bar_height: 30
    readonly property int launcher_height: 435
    readonly property int osd_volume_height: 30
    readonly property int osd_brightness_height: 30
    readonly property int notification_height: bar_height * 2.5
    readonly property int network_panel_height: launcher_height
    readonly property int control_center_height: 400

    readonly property int systray_icon_size: 20

    readonly property int auto_dismiss_interval: 10000
}
