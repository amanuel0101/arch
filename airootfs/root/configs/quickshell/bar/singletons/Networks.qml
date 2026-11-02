pragma Singleton

import QtQuick
import Quickshell.Networking
import Quickshell.Io

QtObject {
    readonly property var wifi_device: {
        const devices = Networking.devices.values;

        for (let i = 0; i < devices.length; i++)
            if (devices[i].type === DeviceType.Wifi)
                return devices[i];
        return null;
    }

    readonly property var wired_device: {
        const devices = Networking.devices.values;

        for (let i = 0; i < devices.length; i++)
            if (devices[i].type === DeviceType.Wired)
                return devices[i];
        return null;
    }

    function state_to_string(state) {
        switch (state) {
            case ConnectionState.Connected:
                return "connected";
            case ConnectionState.Connecting:
                return "connecting";
            case ConnectionState.Disconnecting:
                return "disconnecting";
            case ConnectionState.Disconnected:
                return "disconnected";
            default:
                return "unknown-state";
        }
    }
    readonly property string wifi_state: wifi_device ? state_to_string(wifi_device.state) : "off"
    readonly property string wired_state: wired_device ? state_to_string(wired_device.state) : "off"



    function conn_fail_reason_to_string(reason) {
        if (reason === ConnectionFailReason.NoSecrets)
            return "nosecrets"
        if (reason === ConnectionFailReason.WifiClientDisconnected)
            return "clientdisconnected"
        if (reason === ConnectionFailReason.Unknown)
            return "unknown"
        if (reason === ConnectionFailReason.WifiClientFailed)
            return "clientfailed"
        if (reason === ConnectionFailReason.WifiNetworkLost)
            return "networklost"
        if (reason === ConnectionFailReason.WifiAuthTimeout)
            return "timeout"
    }
}