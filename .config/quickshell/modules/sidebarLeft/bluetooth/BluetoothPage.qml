import "root:/modules/common"
import "../../common/widgets" // For QuickToggleButton
import "../../sidebarRight/quickToggles"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../"
import Quickshell.Io
import "../../../helpers/BluetoothManager.qml" as BluetoothManager

Rectangle {
    id: root
    radius: Appearance.rounding.normal
    color: "transparent"

    property var connectedDeviceHistory: []
    property var deviceList: []
    property bool loadingDevices: false

    function updateConnectedDeviceHistory() {
        // Add new connected devices to history
        for (let i = 0; i < Bluetooth.connectedDevices.length; ++i) {
            let addr = Bluetooth.connectedDevices[i].address;
            if (!connectedDeviceHistory.some(d => d.address === addr)) {
                connectedDeviceHistory.push(Bluetooth.connectedDevices[i]);
            }
        }
        // Update connection status for all in history
        for (let i = 0; i < connectedDeviceHistory.length; ++i) {
            let addr = connectedDeviceHistory[i].address;
            connectedDeviceHistory[i].connected = Bluetooth.connectedDevices.some(d => d.address === addr);
        }
    }

    // After refreshDevices updates deviceList, check connection status for each device
    function refreshDevices() {
        loadingDevices = true;
        BluetoothManager.listDevices(function(devs) {
            deviceList = devs;
            let checked = 0;
            if (devs.length === 0) {
                loadingDevices = false;
                return;
            }
            for (let i = 0; i < devs.length; ++i) {
                let mac = devs[i].mac;
                BluetoothManager.checkConnected(mac, function(isConnected) {
                    devs[i].connected = isConnected;
                    checked++;
                    if (checked === devs.length) {
                        deviceList = devs.slice(); // force UI update
                        loadingDevices = false;
                    }
                });
            }
        });
    }

    function isDeviceConnected(mac, callback) {
        BluetoothManager.checkConnected(mac, callback);
    }

    Component.onCompleted: {
//         console.log('[BT SIMPLE TEST] Using custom Bluetooth service')
//         console.log('[BT SIMPLE TEST] Bluetooth.bluetoothEnabled:', Bluetooth.bluetoothEnabled)
//         console.log('[BT SIMPLE TEST] Connected devices:', Bluetooth.connectedDevices.length)
//         console.log('[BT SIMPLE TEST] Available devices:', Bluetooth.availableDevices.length)
//         console.log('[BT SIMPLE TEST] Paired devices:', Bluetooth.pairedDevices.length)
        // Do not auto-start scan
        refreshDevices();
    }

    // Debug: Log adapter and device info every 5 seconds
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
//             console.log("[BT DEBUG] Bluetooth.bluetoothEnabled:", Bluetooth.bluetoothEnabled, "scanning:", Bluetooth.scanning)
//             console.log("[BT DEBUG] Connected devices:", Bluetooth.connectedDevices.length)
//             console.log("[BT DEBUG] Available devices:", Bluetooth.availableDevices.length)
//             console.log("[BT DEBUG] Paired devices:", Bluetooth.pairedDevices.length)
            // Log connected devices
            for (let i = 0; i < Bluetooth.connectedDevices.length; ++i) {
                let d = Bluetooth.connectedDevices[i]
//                 console.log(`[BT DEBUG] Connected Device ${i}: name='${d.name}', address='${d.address}', type='${d.type}'`)
            }
            // Log available devices
            for (let i = 0; i < Bluetooth.availableDevices.length; ++i) {
                let d = Bluetooth.availableDevices[i]
//                 console.log(`[BT DEBUG] Available Device ${i}: name='${d.name}', address='${d.address}', type='${d.type}'`)
            }
        }
    }

    // Clear device lists when sidebar is closed
    Connections {
        target: root.parent // SidebarLeft or parent container
        onVisibleChanged: {
            if (!root.visible) {
                Bluetooth.connectedDevices = [];
                Bluetooth.pairedDevices = [];
                Bluetooth.availableDevices = [];
            }
        }
    }

    // Call updateConnectedDeviceHistory() after every device update (e.g., after scan or device list update)
    Connections {
        target: Bluetooth
        onConnectedDevicesChanged: updateConnectedDeviceHistory()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 12

        // Header with toggle
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            radius: Appearance.rounding.normal
            color: Qt.rgba(
                Appearance.colors.colLayer1.r,
                Appearance.colors.colLayer1.g,
                Appearance.colors.colLayer1.b,
                0.3
            )
            border.color: Qt.rgba(1, 1, 1, 0.1)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                    spacing: 8
                Layout.alignment: Qt.AlignVCenter

                // QuickToggleButton (Bluetooth on/off)
                    QuickToggleButton {
                    id: bluetoothToggle
                        toggled: Bluetooth.bluetoothEnabled
                        buttonIcon: Bluetooth.bluetoothConnected ? "bluetooth_connected" : Bluetooth.bluetoothEnabled ? "bluetooth" : "bluetooth_disabled"
                    onClicked: {
                        if (Bluetooth.bluetoothEnabled) {
                            Bluetooth.powerOff()
                        } else {
                            Bluetooth.powerOn()
                        }
                    }
                    onRightClicked: {
                                    Hyprland.dispatch('global quickshell:bluetoothOpen')
                        }
                        StyledToolTip {
                        content: Bluetooth.bluetoothEnabled ? qsTr("Bluetooth") : qsTr("Bluetooth | Right-click to configure")
                        }
                    }

                    StyledText {
                        text: qsTr("Bluetooth Devices")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer0
                    }

                    Item { Layout.fillWidth: true }

                // Status indicator
                StyledText {
                    text: Bluetooth.scanning ? qsTr("Scanning...") : ""
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    visible: Bluetooth.bluetoothEnabled && Bluetooth.scanning
                        Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        // Device list container
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Appearance.rounding.normal
            color: Qt.rgba(
                Appearance.colors.colLayer1.r,
                Appearance.colors.colLayer1.g,
                Appearance.colors.colLayer1.b,
                0.2
            )
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                // Connected Devices Section (shows all paired devices, highlights connected)
                Column {
                    spacing: 8
                    StyledText {
                        text: "Connected Devices"
                        font.bold: true
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer0
                    }
                    Repeater {
                        model: deviceList.filter(function(d) { return d.connected; })
                        delegate: Row {
                            spacing: 8
                            StyledText {
                                text: modelData.name + " (" + modelData.address + ")"
                                color: modelData.connected ? "lightgreen" : "#fff"
                            }
                            QuickToggleButton {
                                buttonIcon: "bluetooth_connected"
                                toggled: true
                                onClicked: {
                                    Bluetooth.disconnectDevice(modelData.address)
                                }
                                StyledToolTip {
                                    content: qsTr("Disconnect")
                                }
                            }
                            QuickToggleButton {
                                buttonIcon: "delete"
                                onClicked: {
                                    Bluetooth.removeDevice(modelData.address)
                                }
                                StyledToolTip {
                                    content: qsTr("Forget")
                                }
                            }
                        }
                    }
                    // Placeholder if none
                    StyledText {
                        visible: deviceList.filter(function(d) { return d.connected; }).length === 0
                        text: "No connected devices yet"
                        color: "#888"
                        font.pixelSize: Appearance.font.pixelSize.small
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // Device list header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    StyledText {
                        text: qsTr("Devices")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer0
                    }
                    Item { Layout.fillWidth: true }

                    // Scan button
                    QuickToggleButton {
                        id: scanButton
                        text: Bluetooth.scanning ? qsTr("Scanning...") : qsTr("Scan")
                        toggled: false
                        buttonIcon: Bluetooth.scanning ? "refresh" : "bluetooth"
                        enabled: Bluetooth.bluetoothEnabled && !Bluetooth.scanning
                        onClicked: {
                            Bluetooth.update();
                            Bluetooth.startScan();
                        }
                        StyledToolTip {
                            content: Bluetooth.scanning ? qsTr("Scanning for devices...") : qsTr("Scan for new devices")
                        }
                    }
                    // Discoverable toggle
                    QuickToggleButton {
                        id: discoverableToggle
                        text: qsTr("Discoverable")
                        toggled: Bluetooth.discoverable
                        buttonIcon: Bluetooth.discoverable ? "visibility" : "visibility_off"
                        enabled: Bluetooth.bluetoothEnabled
                        onClicked: {
                            if (Bluetooth.discoverable) {
                                Bluetooth.setDiscoverable(false);
                            } else {
                                Bluetooth.setDiscoverable(true);
                            }
                        }
                        StyledToolTip {
                            content: Bluetooth.discoverable ? qsTr("Your device is discoverable to others") : qsTr("Make your device discoverable")
                        }
                    }
                }

                // Device list
                ListView {
                    id: deviceListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4
                    boundsBehavior: Flickable.StopAtBounds
                    // Remove duplicates by address
                    model: (function() {
                        let seen = {};
                        let out = [];
                        let all = Bluetooth.connectedDevices.concat(Bluetooth.pairedDevices).concat(Bluetooth.availableDevices);
                        for (let i = 0; i < all.length; ++i) {
                            let d = all[i];
                            if (!seen[d.address]) {
                                seen[d.address] = true;
                                out.push(d);
                            }
                        }
                        return out;
                    })()
                    
                    // Show message when no devices
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - 16
                        height: 60
                        color: "transparent"
                        visible: deviceListView.count === 0
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                    spacing: 8

                    StyledText {
                                text: Bluetooth.scanning ? qsTr("Scanning for devices...") : qsTr("No devices found")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer0
                                horizontalAlignment: Text.AlignHCenter
                    }

                    StyledText {
                                text: Bluetooth.scanning ? "" : qsTr("Click Scan to search for devices")
                                font.pixelSize: Appearance.font.pixelSize.tiny
                                color: Appearance.colors.colSubtext
                                horizontalAlignment: Text.AlignHCenter
                                visible: !Bluetooth.scanning
                            }
                        }
                    }

                    delegate: Rectangle {
                        width: parent.width
                        height: 50
                        color: "transparent"
                        radius: Appearance.rounding.small
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.small
                            color: modelData.connected ? 
                                Qt.rgba(33, 150, 243, 0.15) : 
                                (deviceMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
                            border.color: modelData.connected ? 
                                Qt.rgba(33, 150, 243, 0.3) : 
                                Qt.rgba(1, 1, 1, 0.05)
                        border.width: 1
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                                spacing: 12

                                MaterialSymbol {
                                text: modelData.connected ? "bluetooth_connected" : "bluetooth"
                                iconSize: 20
                                color: modelData.connected ? "#2196F3" : Appearance.colors.colOnLayer1
                                verticalAlignment: Text.AlignVCenter
                                }

                            ColumnLayout {
                                Layout.fillWidth: true
                                    spacing: 2

                                    StyledText {
                                    text: modelData.name || qsTr("Unknown Device")
                                    color: modelData.connected ? "#2196F3" : Appearance.colors.colOnLayer0
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.weight: modelData.connected ? Font.Medium : Font.Normal
                                    elide: Text.ElideRight
                                    }

                                    StyledText {
                                    text: modelData.address + (modelData.type ? " • " + modelData.type : "")
                                    color: modelData.connected ? "#2196F3" : Appearance.colors.colOnLayer1
                                        font.pixelSize: Appearance.font.pixelSize.tiny
                                    elide: Text.ElideRight
                                }
                            }

                            // Connect/Disconnect button
                            QuickToggleButton {
                                buttonIcon: modelData.connected ? "bluetooth_connected" : "add"
                                toggled: modelData.connected
                                onClicked: {
                                    if (modelData.connected) {
                                        Bluetooth.disconnectDevice(modelData.address)
                                    } else {
                                        if (modelData.paired) {
                                            Bluetooth.connectDevice(modelData.address)
                                        } else {
                                            BluetoothManager.pair(modelData.mac, function() {
                                                refreshDevices();
                                            });
                                        }
                                    }
                                }
                                StyledToolTip {
                                    content: modelData.connected ? qsTr("Disconnect") : 
                                             (modelData.paired ? qsTr("Connect") : qsTr("Pair device"))
                                }
                            }
                        }
                        
                        MouseArea {
                            id: deviceMouseArea
                anchors.fill: parent
                            hoverEnabled: true
                                    onClicked: {
                                if (modelData.connected) {
                                    Bluetooth.disconnectDevice(modelData.address)
                                } else {
                                    if (modelData.paired) {
                                        Bluetooth.connectDevice(modelData.address)
                                    } else {
                                        BluetoothManager.pair(modelData.mac, function() {
                                            refreshDevices();
                                        });
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
} 
