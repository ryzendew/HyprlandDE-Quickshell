import "../"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

QuickToggleButton {
    toggled: Bluetooth.bluetoothEnabled
    buttonIcon: Bluetooth.bluetoothConnected ? "bluetooth_connected" : Bluetooth.bluetoothEnabled ? "bluetooth" : "bluetooth_disabled"
    property bool showBluetoothDialog: false
    signal requestBluetoothDialog()
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton | Qt.LeftButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                toggleBluetooth.running = true
            }
            if (mouse.button === Qt.RightButton) {
                requestBluetoothDialog()
            }
        }
        hoverEnabled: false
        propagateComposedEvents: true
        cursorShape: Qt.PointingHandCursor 
    }
    Process {
        id: toggleBluetooth
        command: ["bash", "-c", `bluetoothctl power ${Bluetooth.bluetoothEnabled ? "off" : "on"}`]
        onRunningChanged: {
            if(!running) {
                Bluetooth.update()
            }
        }
    }
    StyledToolTip {
        content: StringUtils.format(qsTr("{0} | Right-click to configure"), 
            (Bluetooth.bluetoothEnabled && Bluetooth.bluetoothDeviceName.length > 0) ? 
            Bluetooth.bluetoothDeviceName : qsTr("Bluetooth"))
    }
    // Custom overlay dialog for BluetoothConnectModule
    Rectangle {
        visible: showBluetoothDialog
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.66) // semi-transparent black
        z: 1000

        Rectangle {
            width: 500
            height: 640
            anchors.centerIn: parent
            radius: 18
            color: "#18191b"
            border.color: "#222"
            border.width: 2

            // Close button
            MouseArea {
                anchors.right: parent.right
                anchors.top: parent.top
                width: 40; height: 40
                onClicked: showBluetoothDialog = false
                cursorShape: Qt.PointingHandCursor
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: "#fff"
                        font.pixelSize: 22
                    }
                }
            }

            Loader {
                anchors.fill: parent
                source: "modules/sidebarRight/quickToggles/BluetoothConnectModule.qml"
            }
        }

        // Click outside to close
        MouseArea {
            anchors.fill: parent
            z: 999
            onClicked: showBluetoothDialog = false
            propagateComposedEvents: false
        }
    }
}
