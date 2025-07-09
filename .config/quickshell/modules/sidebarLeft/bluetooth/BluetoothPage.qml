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

Rectangle {
    id: root
    radius: Appearance.rounding.normal
    color: "transparent"

    // Device lists
    ListModel {
        id: connectedDevicesModel
    }

    ListModel {
        id: availableDevicesModel
    }

    // Helper function to check if a device is real
    function isRealDevice(address, name) {
        const macPattern = /^([A-Fa-f0-9]{2}:){5}[A-Fa-f0-9]{2}$/;
        if (!macPattern.test(address)) return false;
        if (!name || name === "Media") return false;
        if (address === "/org/bluez/hci0") return false;
        return true;
    }

    // Function to scan for bluetooth devices using bluetoothctl
    function scanForDevices() {
        console.log("Starting bluetooth scan...")
        availableDevicesModel.clear() // Clear previous scan results
        scanDevices.running = true
    }

    // Function to update device lists from bluetoothctl
    function updateDeviceLists() {
        connectedDevicesModel.clear()
        availableDevicesModel.clear()
        
        // Get connected devices
        getConnectedDevices.running = true
        // Get available devices
        getAvailableDevices.running = true
    }

    // Power on Bluetooth on page load
    Component.onCompleted: {
        powerOnBluetooth.running = true
        updateDeviceLists()
    }

    // Update device lists when bluetooth state changes
    Connections {
        target: Bluetooth
        function onBluetoothEnabledChanged() {
            if (Bluetooth.bluetoothEnabled) {
                scanForDevices()
            }
            updateDeviceLists()
        }
    }

    // Process to power on Bluetooth
    Process {
        id: powerOnBluetooth
        command: ["bash", "-c", "source /etc/environment && export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $USER -f dbus-daemon)/environ | tr -d '\\0' | cut -d= -f2-) && bluetoothctl power on"]
        onRunningChanged: {
            if (!running) {
                console.log("Bluetooth powered on, ready to scan.")
            }
        }
    }

    // Process to scan for devices with real-time discovery
    Process {
        id: scanDevices
        command: ["bash", "-c", "source /etc/environment && export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $USER -f dbus-daemon)/environ | tr -d '\\0' | cut -d= -f2-) && bluetoothctl scan on & sleep 60 && bluetoothctl scan off"]
        onRunningChanged: {
            if (!running) {
                console.log("Scan completed")
                // After scan, get all discovered devices
                getDiscoveredDevices.running = true
            }
        }
        stdout: SplitParser {
            onRead: data => {
                console.log('RAW BLUETOOTH DATA (scan):', data)
                // Only add real devices (not hci0/controller)
                // Match lines like: [NEW] Device XX:XX:XX:XX:XX:XX DeviceName
                let match = data.match(/Device\s+(([A-F0-9]{2}:){5}[A-F0-9]{2})\s+(.+)/)
                if (match) {
                    let address = match[1]
                    let name = match[3].trim()
                    if (!isRealDevice(address, name)) {
                        console.log('Filtered out (scan):', address, name)
                        return;
                    }
                    // Check if device is not already in connected or available list
                    let isConnected = false
                    for (let i = 0; i < connectedDevicesModel.count; i++) {
                        if (connectedDevicesModel.get(i).address === address) {
                            isConnected = true
                            break
                        }
                    }
                    let isAlreadyListed = false
                    for (let i = 0; i < availableDevicesModel.count; i++) {
                        if (availableDevicesModel.get(i).address === address) {
                            isAlreadyListed = true
                            break
                        }
                    }
                    if (!isConnected && !isAlreadyListed) {
                        availableDevicesModel.append({
                            "name": name,
                            "type": "Unknown",
                            "address": address,
                            "connected": false,
                            "device": null
                        })
                    }
                }
            }
        }
    }

    // Process to get all discovered devices after scan
    Process {
        id: getDiscoveredDevices
        command: ["bash", "-c", "source /etc/environment && export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $USER -f dbus-daemon)/environ | tr -d '\\0' | cut -d= -f2-) && bluetoothctl devices"]
        onRunningChanged: {
            if (!running) {
                console.log("Discovered devices list updated")
            }
        }
        stdout: SplitParser {
            onRead: data => {
                console.log('RAW BLUETOOTH DATA (discovered):', data)
                // Only add real devices (not hci0/controller)
                // Match lines like: Device XX:XX:XX:XX:XX:XX DeviceName
                let match = data.match(/Device\s+(([A-F0-9]{2}:){5}[A-F0-9]{2})\s+(.+)/)
                if (match) {
                    let address = match[1]
                    let name = match[3].trim()
                    if (!isRealDevice(address, name)) {
                        console.log('Filtered out (discovered):', address, name)
                        return;
                    }
                    // Check if device is not already in connected or available list
                    let isConnected = false
                    for (let i = 0; i < connectedDevicesModel.count; i++) {
                        if (connectedDevicesModel.get(i).address === address) {
                            isConnected = true
                            break
                        }
                    }
                    let isAlreadyListed = false
                    for (let i = 0; i < availableDevicesModel.count; i++) {
                        if (availableDevicesModel.get(i).address === address) {
                            isAlreadyListed = true
                            break
                        }
                    }
                    if (!isConnected && !isAlreadyListed) {
                        availableDevicesModel.append({
                            "name": name,
                            "type": "Unknown",
                            "address": address,
                            "connected": false,
                            "device": null
                        })
                    }
                }
            }
        }
    }

    // Process to get connected devices
    Process {
        id: getConnectedDevices
        command: ["bash", "-c", "source /etc/environment && export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $USER -f dbus-daemon)/environ | tr -d '\\0' | cut -d= -f2-) && bluetoothctl devices Connected"]
        onRunningChanged: {
            if (!running) {
                console.log("Connected devices updated")
            }
        }
        stdout: SplitParser {
            onRead: data => {
                console.log('RAW BLUETOOTH DATA (connected):', data)
                // Parse the device info and add to connectedDevicesModel
                let parts = data.trim().split(/\s+/)
                if (parts.length >= 3) {
                    let address = parts[1]
                    let name = parts.slice(2).join(" ")
                    if (!isRealDevice(address, name)) {
                        console.log('Filtered out (connected):', address, name)
                        return;
                    }
                    connectedDevicesModel.append({
                        "name": name,
                        "type": "Unknown",
                        "address": address,
                        "connected": true,
                        "device": null
                    })
                }
            }
        }
    }

    // Process to get available devices
    Process {
        id: getAvailableDevices
        command: ["bash", "-c", "source /etc/environment && export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $USER -f dbus-daemon)/environ | tr -d '\\0' | cut -d= -f2-) && bluetoothctl devices"]
        onRunningChanged: {
            if (!running) {
                console.log("Available devices updated")
            }
        }
        stdout: SplitParser {
            onRead: data => {
                console.log('RAW BLUETOOTH DATA (available):', data)
                // Parse the device info and add to availableDevicesModel
                let parts = data.trim().split(/\s+/)
                if (parts.length >= 3) {
                    let address = parts[1]
                    let name = parts.slice(2).join(" ")
                    if (!isRealDevice(address, name)) {
                        console.log('Filtered out (available):', address, name)
                        return;
                    }
                    // Check if device is not already in connected list
                    let isConnected = false
                    for (let i = 0; i < connectedDevicesModel.count; i++) {
                        if (connectedDevicesModel.get(i).address === address) {
                            isConnected = true
                            break
                        }
                    }
                    if (!isConnected) {
                        availableDevicesModel.append({
                            "name": name,
                            "type": "Unknown",
                            "address": address,
                            "connected": false,
                            "device": null
                        })
                    }
                }
            }
        }
    }

    // Process to enable discovery and pairable mode
    Process {
        id: enableDiscovery
        command: ["bash", "-c", "source /etc/environment && export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $USER -f dbus-daemon)/environ | tr -d '\\0' | cut -d= -f2-) && bluetoothctl discoverable on && bluetoothctl pairable on"]
        onRunningChanged: {
            if (!running) {
                console.log("Discovery enabled, starting scan...")
                scanDevices.running = true
            }
        }
    }

    // Process to connect to a device
    Process {
        id: connectDevice
        property string deviceAddress: ""
        command: ["bash", "-c", `source /etc/environment && export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $USER -f dbus-daemon)/environ | tr -d '\\0' | cut -d= -f2-) && bluetoothctl connect ${deviceAddress}`]
        onRunningChanged: {
            if (!running) {
                console.log("Connect attempt completed for:", deviceAddress)
                // Update device lists after connection attempt
                updateDeviceLists()
            }
        }
    }

    // Process to disconnect from a device
    Process {
        id: disconnectDevice
        property string deviceAddress: ""
        command: ["bash", "-c", `source /etc/environment && export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $USER -f dbus-daemon)/environ | tr -d '\\0' | cut -d= -f2-) && bluetoothctl disconnect ${deviceAddress}`]
        onRunningChanged: {
            if (!running) {
                console.log("Disconnect attempt completed for:", deviceAddress)
                // Update device lists after disconnection attempt
                updateDeviceLists()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 12

        // Header
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

            Item {
                anchors.fill: parent
                anchors.margins: 8
                RowLayout {
                    anchors.fill: parent
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    // Bluetooth QuickToggleButton
                    QuickToggleButton {
                        toggled: Bluetooth.bluetoothEnabled
                        buttonIcon: Bluetooth.bluetoothConnected ? "bluetooth_connected" : Bluetooth.bluetoothEnabled ? "bluetooth" : "bluetooth_disabled"
                        implicitWidth: 32
                        implicitHeight: 32
                        Layout.alignment: Qt.AlignVCenter
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.RightButton | Qt.LeftButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.LeftButton) {
                                    toggleBluetooth.running = true
                                }
                                if (mouse.button === Qt.RightButton) {
                                    Hyprland.dispatch('global quickshell:bluetoothOpen')
                                }
                            }
                            hoverEnabled: false
                            propagateComposedEvents: true
                            cursorShape: Qt.PointingHandCursor 
                        }
                        Process {
                            id: toggleBluetooth
                            command: ["bash", "-c", `source /etc/environment && export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $USER -f dbus-daemon)/environ | tr -d '\\0' | cut -d= -f2-) && bluetoothctl power ${Bluetooth.bluetoothEnabled ? "off" : "on"}`]
                            onRunningChanged: {
                                if(!running) {
                                    updateDeviceLists()
                                }
                            }
                        }
                        StyledToolTip {
                            content: (Bluetooth.bluetoothEnabled && Bluetooth.bluetoothDeviceName.length > 0) ? Bluetooth.bluetoothDeviceName : qsTr("Bluetooth | Right-click to configure")
                        }
                    }

                    StyledText {
                        text: qsTr("Bluetooth Devices")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer0
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item { Layout.fillWidth: true }

                    QuickToggleButton {
                        buttonIcon: "refresh"
                        implicitWidth: 32
                        implicitHeight: 32
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: {
                            // Start bluetooth discovery using lysec
                            if (Bluetooth.bluetoothEnabled) {
                                scanForDevices()
                            }
                            updateDeviceLists()
                        }
                        StyledToolTip {
                            content: qsTr("Refresh devices")
                        }
                    }
                }
            }
        }

        // Bluetooth Status
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
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
                anchors.margins: 12
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    MaterialSymbol {
                        text: Bluetooth.bluetoothEnabled ? "bluetooth" : "bluetooth_disabled"
                        iconSize: 18
                        color: Bluetooth.bluetoothEnabled ? "#2196F3" : "#F44336"
                    }

                    StyledText {
                        text: Bluetooth.bluetoothEnabled ? qsTr("Enabled") : qsTr("Disabled")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer0
                    }

                    Item { Layout.fillWidth: true }

                    StyledText {
                        text: Bluetooth.scanning ? qsTr("Scanning...") : (Bluetooth.bluetoothEnabled ? qsTr("Discoverable") : "")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                        visible: Bluetooth.bluetoothEnabled
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    StyledText {
                        text: qsTr("Connected devices:")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                    }

                    StyledText {
                        text: connectedDevicesModel.count.toString()
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer0
                    }

                    Item { Layout.fillWidth: true }

                    StyledText {
                        text: qsTr("Battery:")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                    }

                    StyledText {
                        text: Bluetooth.bluetoothEnabled ? "85%" : qsTr("N/A")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer0
                    }
                }
            }
        }

        // Connected Devices
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 0.3
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
                spacing: 14

                StyledText {
                    text: qsTr("Connected Devices")
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer0
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: connectedDevicesModel

                    delegate: Rectangle {
                        width: parent.width
                        height: 56
                        radius: Appearance.rounding.small
                        color: Qt.rgba(33, 150, 243, 0.1)
                        border.color: Qt.rgba(33, 150, 243, 0.3)
                        border.width: 1
                        anchors.leftMargin: 0
                        anchors.rightMargin: 0
                        anchors.topMargin: 0
                        anchors.bottomMargin: index < (ListView.view.count - 1) ? 8 : 0 // 8px space except last

                        Item {
                            anchors.fill: parent
                            anchors.margins: 12

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12

                                MaterialSymbol {
                                    text: "bluetooth_connected"
                                    iconSize: 32
                                    color: "#2196F3"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Column {
                                    spacing: 2
                                    anchors.verticalCenter: parent.verticalCenter

                                                                    StyledText {
                                    text: name || "Unknown Device"
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnLayer0
                                }

                                StyledText {
                                    text: type + " • " + address
                                    font.pixelSize: Appearance.font.pixelSize.tiny
                                    color: Appearance.colors.colOnLayer1
                                }
                                }
                            }

                            QuickToggleButton {
                                buttonIcon: "bluetooth_connected"
                                toggled: connected
                                implicitWidth: 32
                                implicitHeight: 32
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                onClicked: {
                                    disconnectDevice.deviceAddress = address
                                    disconnectDevice.running = true
                                }
                                StyledToolTip {
                                    content: qsTr("Disconnect")
                                }
                            }
                        }
                    }
                }
            }
        }

        // Available Devices
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 0.7
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
                spacing: 14

                StyledText {
                    text: qsTr("Available Devices")
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer0
                }

                // Replace ScrollView with Flickable for available devices
                Flickable {
                    id: availableDevicesFlickable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: deviceListView.width
                    contentHeight: deviceListView.contentHeight
                    clip: true
                    interactive: true

                    ListView {
                        id: deviceListView
                        width: availableDevicesFlickable.width
                        height: availableDevicesFlickable.height
                        model: availableDevicesModel
                        spacing: 4
                        anchors.fill: parent

                        delegate: Rectangle {
                            width: deviceListView.width
                            height: 56
                            radius: Appearance.rounding.small
                            color: "transparent"
                            border.color: Qt.rgba(1, 1, 1, 0.05)
                            border.width: 1
                            anchors.leftMargin: 0
                            anchors.rightMargin: 0
                            anchors.topMargin: 0
                            anchors.bottomMargin: index < deviceListView.count - 1 ? 8 : 0 // 8px space except last

                            Item {
                                anchors.fill: parent
                                anchors.margins: 12

                                Row {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 12

                                    MaterialSymbol {
                                        text: "bluetooth"
                                        iconSize: 32
                                        color: Appearance.colors.colOnLayer1
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Column {
                                        spacing: 2
                                        anchors.verticalCenter: parent.verticalCenter

                                        StyledText {
                                            text: name || "Unknown Device"
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                            font.weight: Font.Medium
                                            color: Appearance.colors.colOnLayer0
                                        }

                                        StyledText {
                                            text: type + " • " + address
                                            font.pixelSize: Appearance.font.pixelSize.tiny
                                            color: Appearance.colors.colOnLayer1
                                        }
                                    }
                                }

                                QuickToggleButton {
                                    buttonIcon: "add"
                                    implicitWidth: 32
                                    implicitHeight: 32
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    onClicked: {
                                        connectDevice.deviceAddress = address
                                        connectDevice.running = true
                                    }
                                    StyledToolTip {
                                        content: qsTr("Connect device")
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    // Select device
                                }
                            }
                        }
                    }
                }

                // Show message when no devices are found
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                    visible: availableDevicesModel.count === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        MaterialSymbol {
                            text: "bluetooth_disabled"
                            iconSize: 48
                            color: Appearance.colors.colOnLayer1
                            Layout.alignment: Qt.AlignHCenter
                        }

                        StyledText {
                            text: qsTr("No devices found")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                            Layout.alignment: Qt.AlignHCenter
                        }

                        StyledText {
                            text: qsTr("Click refresh to scan for devices")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer1
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }
        // Add spacing between Connected and Available Devices
        // Item { height: 16 } // Removed for proportional layout
    }
} 