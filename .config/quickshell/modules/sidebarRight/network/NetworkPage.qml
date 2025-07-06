import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool isScanning: false
    property bool hasError: false
    property bool isActive: false
    property string errorMessage: ""
    property bool showPassword: false
    property string currentSsid: ""
    property bool isConnecting: false
    property bool settingsExpanded: false

    // Use SystemPaths for network interface detection
    readonly property string wirelessInterface: SystemPaths.detectedWirelessInterface
    


    function toggleWifi() {
        const cmd = Network.wifiEnabled ? "nmcli radio wifi off" : "nmcli radio wifi on"
        Process.launch(cmd)
    }

    // Initialize the ListModel
    ListModel {
        id: networksModel
    }

    // Add debug rectangle to see the component bounds
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "red"
        border.width: 1
        visible: isActive
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        visible: isActive  // Ensure visibility is tied to active state

        // Error Message Display
        PanelWindow {
            Layout.fillWidth: true
            visible: hasError
            height: visible ? errorText.implicitHeight + 20 : 0

            StyledText {
                id: errorText
                anchors.fill: parent
                anchors.margins: 10
                text: errorMessage
                color: Appearance.colors.colError
                wrapMode: Text.WordWrap
            }
        }

        // WiFi Toggle Section
        PanelWindow {
            Layout.fillWidth: true
            Layout.preferredHeight: wifiToggleLayout.implicitHeight + 20
            visible: true  // Force visible for debugging

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: "blue"
                border.width: 1
                visible: true  // Debug border
            }

            RowLayout {
                id: wifiToggleLayout
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                MaterialSymbol {
                    text: Network.wifiEnabled ? (
                        Network.networkStrength > 80 ? "signal_wifi_4_bar" :
                        Network.networkStrength > 60 ? "network_wifi_3_bar" :
                        Network.networkStrength > 40 ? "network_wifi_2_bar" :
                        Network.networkStrength > 20 ? "network_wifi_1_bar" :
                        "signal_wifi_0_bar"
                    ) : "signal_wifi_off"
                    iconSize: Appearance.font.pixelSize.huge
                    color: Network.wifiEnabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colOnLayer1Inactive
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        text: qsTr("WiFi")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                    }

                    StyledText {
                        text: Network.wifiEnabled ? 
                            (Network.networkName || qsTr("Not connected")) : 
                            qsTr("WiFi is turned off")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        visible: Network.wifiEnabled && Network.networkName
                        text: Network.networkStrength ? qsTr("Signal Strength: %1%").arg(Network.networkStrength) : ""
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }

                Switch {
                    checked: Network.wifiEnabled
                    onClicked: toggleWifi()
                    
                    // Add proper styling
                    indicator: Rectangle {
                        implicitWidth: 40
                        implicitHeight: 20
                        x: parent.leftPadding
                        y: parent.height / 2 - height / 2
                        radius: 10
                        color: parent.checked ? Appearance.colors.colAccent : Appearance.colors.colLayer2
                        border.color: parent.checked ? Appearance.colors.colAccent : Appearance.colors.colOnLayer1Inactive

                        Rectangle {
                            x: parent.parent.checked ? parent.width - width - 4 : 4
                            y: 4
                            width: 12
                            height: 12
                            radius: 6
                            color: parent.parent.checked ? "white" : Appearance.colors.colOnLayer1Inactive

                            Behavior on x {
                                NumberAnimation {
                                    duration: Appearance.animation.elementMoveFast.duration
                                    easing.type: Appearance.animation.elementMoveFast.type
                                }
                            }
                        }
                    }
                }
            }
        }

        // Available Networks Section
        PanelWindow {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: Network.wifiEnabled

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: "green"
                border.width: 1
                visible: true  // Debug border
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                // Network Settings Section
                Rectangle {
                    Layout.fillWidth: true
                    height: settingsColumn.implicitHeight + 20
                    color: Qt.rgba(
                        Appearance.colors.colLayer2.r,
                        Appearance.colors.colLayer2.g,
                        Appearance.colors.colLayer2.b,
                        0.55
                    )
                    radius: Appearance.rounding.small

                    ColumnLayout {
                        id: settingsColumn
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            MaterialSymbol {
                                text: settingsExpanded ? "expand_more" : "chevron_right"
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                            }

                            StyledText {
                                text: qsTr("Network Settings")
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: settingsExpanded = !settingsExpanded
                            }
                        }

                        // Settings content
                        ColumnLayout {
                            visible: settingsExpanded
                            Layout.fillWidth: true
                            spacing: 8

                            // Auto-connect option
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                StyledText {
                                    text: qsTr("Auto-connect to known networks")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colOnLayer1
                                    Layout.fillWidth: true
                                }

                                Switch {
                                    checked: autoConnectEnabled
                                    onClicked: toggleAutoConnect()
                                    
                                    indicator: Rectangle {
                                        implicitWidth: 36
                                        implicitHeight: 18
                                        radius: 9
                                        color: parent.checked ? Appearance.colors.colAccent : Appearance.colors.colLayer2
                                        border.color: parent.checked ? Appearance.colors.colAccent : Appearance.colors.colOnLayer1Inactive

                                        Rectangle {
                                            x: parent.parent.checked ? parent.width - width - 3 : 3
                                            y: 3
                                            width: 12
                                            height: 12
                                            radius: 6
                                            color: parent.parent.checked ? "white" : Appearance.colors.colOnLayer1Inactive
                                        }
                                    }
                                }
                            }

                            // Random MAC address option
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                StyledText {
                                    text: qsTr("Use random MAC address")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colOnLayer1
                                    Layout.fillWidth: true
                                }

                                Switch {
                                    checked: randomMacEnabled
                                    onClicked: toggleRandomMac()
                                    
                                    indicator: Rectangle {
                                        implicitWidth: 36
                                        implicitHeight: 18
                                        radius: 9
                                        color: parent.checked ? Appearance.colors.colAccent : Appearance.colors.colLayer2
                                        border.color: parent.checked ? Appearance.colors.colAccent : Appearance.colors.colOnLayer1Inactive

                                        Rectangle {
                                            x: parent.parent.checked ? parent.width - width - 3 : 3
                                            y: 3
                                            width: 12
                                            height: 12
                                            radius: 6
                                            color: parent.parent.checked ? "white" : Appearance.colors.colOnLayer1Inactive
                                        }
                                    }
                                }
                            }

                            // Power saving mode
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                StyledText {
                                    text: qsTr("Power saving mode")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colOnLayer1
                                    Layout.fillWidth: true
                                }

                                Switch {
                                    checked: powerSaveEnabled
                                    onClicked: togglePowerSave()
                                    
                                    indicator: Rectangle {
                                        implicitWidth: 36
                                        implicitHeight: 18
                                        radius: 9
                                        color: parent.checked ? Appearance.colors.colAccent : Appearance.colors.colLayer2
                                        border.color: parent.checked ? Appearance.colors.colAccent : Appearance.colors.colOnLayer1Inactive

                                        Rectangle {
                                            x: parent.parent.checked ? parent.width - width - 3 : 3
                                            y: 3
                                            width: 12
                                            height: 12
                                            radius: 6
                                            color: parent.parent.checked ? "white" : Appearance.colors.colOnLayer1Inactive
                                        }
                                    }
                                }
                            }

                            // Hidden network connection button
                            Button {
                                Layout.fillWidth: true
                                text: qsTr("Connect to Hidden Network")
                                
                                background: Rectangle {
                                    implicitHeight: 36
                                    color: parent.down ? Appearance.colors.colLayer2Active :
                                           parent.hovered ? Appearance.colors.colLayer2Hover :
                                           Appearance.colors.colLayer2
                                    radius: Appearance.rounding.small
                                    border.color: Appearance.colors.colOnLayer1Inactive
                                    border.width: 1
                                }
                                
                                contentItem: RowLayout {
                                    spacing: 8
                                    MaterialSymbol {
                                        text: "wifi_tethering"
                                        iconSize: Appearance.font.pixelSize.normal
                                        color: "#FFFFFF"
                                    }
                                    Text {
                                        text: parent.parent.text
                                        color: Appearance.colors.colOnLayer1
                                        Layout.fillWidth: true
                                    }
                                }
                                
                                onClicked: showHiddenNetworkDialog()
                            }

                            // Manage saved networks button
                            Button {
                                Layout.fillWidth: true
                                text: qsTr("Manage Saved Networks")
                                
                                background: Rectangle {
                                    implicitHeight: 36
                                    color: parent.down ? Appearance.colors.colLayer2Active :
                                           parent.hovered ? Appearance.colors.colLayer2Hover :
                                           Appearance.colors.colLayer2
                                    radius: Appearance.rounding.small
                                    border.color: Appearance.colors.colOnLayer1Inactive
                                    border.width: 1
                                }
                                
                                contentItem: RowLayout {
                                    spacing: 8
                                    MaterialSymbol {
                                        text: "settings"
                                        iconSize: Appearance.font.pixelSize.normal
                                        color: "#FFFFFF"
                                    }
                                    Text {
                                        text: parent.parent.text
                                        color: Appearance.colors.colOnLayer1
                                        Layout.fillWidth: true
                                    }
                                }
                                
                                onClicked: showSavedNetworksDialog()
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: settingsExpanded = !settingsExpanded
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    StyledText {
                        text: qsTr("Available Networks")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                    }

                    Item { Layout.fillWidth: true }

                    BusyIndicator {
                        running: isScanning || isConnecting
                        visible: isScanning || isConnecting
                        width: Appearance.font.pixelSize.normal
                        height: width
                    }

                    MaterialSymbol {
                        text: "refresh"
                        iconSize: Appearance.font.pixelSize.normal
                        color: "#FFFFFF"
                        visible: !isScanning && !isConnecting
                        MouseArea {
                            anchors.fill: parent
                            onClicked: rescanNetworks()
                        }
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 5
                    clip: true
                    model: networksModel

                    // Add placeholder text when no networks
                    Text {
                        anchors.centerIn: parent
                        text: qsTr("No networks found")
                        color: Appearance.colors.colSubtext
                        visible: networksModel.count === 0
                        font.pixelSize: Appearance.font.pixelSize.normal
                    }

                    delegate: ItemDelegate {
                        width: parent.width
                        height: networkItemLayout.implicitHeight + 20
                        hoverEnabled: true

                        Rectangle {
                            anchors.fill: parent
                            color: parent.hovered ? Appearance.colors.colLayer2 : "transparent"
                            radius: Appearance.rounding.small
                        }

                        RowLayout {
                            id: networkItemLayout
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            MaterialSymbol {
                                text: model.strength > 80 ? "signal_wifi_4_bar" :
                                      model.strength > 60 ? "network_wifi_3_bar" :
                                      model.strength > 40 ? "network_wifi_2_bar" :
                                      model.strength > 20 ? "network_wifi_1_bar" :
                                      "signal_wifi_0_bar"
                                iconSize: Appearance.font.pixelSize.larger
                                color: model.connected ? "#FFFFFF" : "#FFFFFF"
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    text: model.ssid
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: model.connected ? "#FFFFFF" : "#FFFFFF"
                                }

                                RowLayout {
                                    spacing: 5
                                    visible: model.connected || model.saved || model.secured

                                    MaterialSymbol {
                                        text: "check_circle"
                                        visible: model.connected
                                        iconSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colAccent
                                    }

                                    MaterialSymbol {
                                        text: "lock"
                                        visible: model.secured
                                        iconSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colSubtext
                                    }

                                    StyledText {
                                        text: model.connected ? qsTr("Connected") : 
                                              model.saved ? qsTr("Saved") : ""
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: model.connected ? "#FFFFFF" : "#FFFFFF"
                                        visible: text !== ""
                                    }

                                    StyledText {
                                        text: qsTr("Signal: %1%").arg(model.strength)
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colSubtext
                                    }
                                }
                            }

                            MaterialSymbol {
                                text: model.connected ? "more_vert" : "login"
                                iconSize: Appearance.font.pixelSize.normal
                                color: "#FFFFFF"
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (model.connected) {
                                            disconnectFromNetwork(model.ssid)
                                        } else if (model.saved) {
                                            connectToNetwork(model.ssid)
                                        } else {
                                            showConnectDialog(model.ssid, model.secured)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                GroupButton {
                    Layout.fillWidth: true
                    Layout.margins: 5
                    text: qsTr("Open Network Settings")
                    MaterialSymbol {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "settings"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                    }
                    onClicked: openNetworkSettings()
                }
            }
        }

        // Connection Dialog
        PanelWindow {
            id: connectDialog
            Layout.fillWidth: true
            visible: currentSsid !== ""
            height: visible ? connectDialogLayout.implicitHeight + 20 : 0

            ColumnLayout {
                id: connectDialogLayout
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                StyledText {
                    text: qsTr("Connect to %1").arg(currentSsid)
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                }

                TextField {
                    id: passwordField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Password")
                    echoMode: showPassword ? TextInput.Normal : TextInput.Password
                    color: Appearance.colors.colOnLayer1
                    background: Rectangle {
                        color: Appearance.colors.colLayer2
                        radius: Appearance.rounding.small
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CheckBox {
                        text: qsTr("Show password")
                        checked: showPassword
                        onCheckedChanged: showPassword = checked
                        
                        // Add proper styling
                        indicator: Rectangle {
                            implicitWidth: 16
                            implicitHeight: 16
                            x: parent.leftPadding
                            y: parent.height / 2 - height / 2
                            radius: 3
                            color: parent.checked ? Appearance.colors.colAccent : Appearance.colors.colLayer2
                            border.color: parent.checked ? Appearance.colors.colAccent : Appearance.colors.colOnLayer1Inactive

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "check"
                                iconSize: 12
                                color: "white"
                                visible: parent.parent.checked
                            }
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            color: Appearance.colors.colOnLayer1
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: parent.indicator.width + parent.spacing
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: qsTr("Cancel")
                        onClicked: {
                            currentSsid = ""
                            passwordField.text = ""
                        }
                        
                        // Add proper styling
                        background: Rectangle {
                            implicitWidth: 60
                            implicitHeight: 30
                            color: parent.down ? Appearance.colors.colLayer2Active :
                                   parent.hovered ? Appearance.colors.colLayer2Hover :
                                   Appearance.colors.colLayer2
                            radius: Appearance.rounding.small
                            border.color: Appearance.colors.colOnLayer1Inactive
                            border.width: 1
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            color: Appearance.colors.colOnLayer1
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Button {
                        text: qsTr("Connect")
                        enabled: passwordField.text.length >= 8
                        onClicked: {
                            connectToNewNetwork(currentSsid, passwordField.text)
                            currentSsid = ""
                            passwordField.text = ""
                        }
                        
                        // Add proper styling
                        background: Rectangle {
                            implicitWidth: 60
                            implicitHeight: 30
                            color: !parent.enabled ? Appearance.colors.colLayer2Inactive :
                                   parent.down ? Appearance.colors.colAccentActive :
                                   parent.hovered ? Appearance.colors.colAccentHover :
                                   Appearance.colors.colAccent
                            radius: Appearance.rounding.small
                            opacity: parent.enabled ? 1.0 : 0.5
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
    }

    // Add properties for settings
    property bool autoConnectEnabled: false
    property bool randomMacEnabled: false
    property bool powerSaveEnabled: false

    function openNetworkSettings() {
        if (ConfigOptions.apps.network) {
            Hyprland.dispatch("global quickshell:sidebarRightClose")
            Qt.callLater(() => {
                Hyprland.dispatch("exec", ConfigOptions.apps.network)
            })
        }
    }

    function showConnectDialog(ssid, secured) {
        if (!secured) {
            connectToNewNetwork(ssid, "")
        } else {
            currentSsid = ssid
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
    }

    function connectToNewNetwork(ssid, password) {
        isConnecting = true
        const cmd = password ? 
            `nmcli device wifi connect "${ssid}" password "${password}"` :
            `nmcli device wifi connect "${ssid}"`
        
        Io.shellCommand(cmd, (exitCode) => {
            isConnecting = false
            if (exitCode === 0) {
                Network.update()
                updateNetworkList()
            } else {
                showError("Failed to connect to " + ssid)
            }
        })
    }

    // Network management functions
    function connectToNetwork(ssid) {
        isConnecting = true
        const cmd = `nmcli connection up id "${ssid}"`
        Io.shellCommand(cmd, (exitCode) => {
            isConnecting = false
            if (exitCode === 0) {
                Network.update()
                updateNetworkList()
            } else {
                showError("Failed to connect to " + ssid)
            }
        })
    }

    function disconnectFromNetwork(ssid) {
        const cmd = `nmcli connection down id "${ssid}"`
        Io.shellCommand(cmd, (exitCode) => {
            if (exitCode === 0) {
                Network.update()
                updateNetworkList()
            } else {
                showError("Failed to disconnect from " + ssid)
            }
        })
    }

    function rescanNetworks() {
        isScanning = true
        const cmd = "nmcli device wifi rescan"
        Io.shellCommand(cmd, (exitCode) => {
            if (exitCode === 0) {
                updateNetworkList()
            } else {
                showError("Failed to scan for networks")
            }
            isScanning = false
        })
    }

    function updateNetworkList() {
        if (!ConfigOptions.logging.enabled && !ConfigOptions.logging.info) {
            // console.log("Updating network list...")
        }
        NetworkManager.scan().then((stdout) => {
            // console.log("Network scan successful:", stdout)
            const lines = stdout.trim().split('\n');
            const newNetworks = [];
            lines.forEach(line => {
                if (line) {
                    const [ssid, signal, security, inUse] = line.split(":")
                    if (ssid) {
                        newNetworks.push({
                            ssid: ssid,
                            strength: parseInt(signal) || 0,
                            secured: security !== "",
                            connected: inUse === "*",
                            saved: false
                        })
                    }
                }
            })
            networksModel.model = newNetworks;
            if (!ConfigOptions.logging.enabled && !ConfigOptions.logging.info) {
                // console.log("Added", networksModel.count, "networks to model")
            }
            updateSavedNetworks()
        }).catch((stderr, exitCode) => {
            // console.log("Failed to get network list, exit code:", exitCode)
            // TODO: Show error to user
        });
    }

    function updateSavedNetworks() {
        const cmd = "nmcli -t -f NAME connection show"
        Io.shellCommand(cmd, (exitCode, stdout) => {
            if (exitCode === 0) {
                const savedNetworks = stdout.split("\n")
                for (let i = 0; i < networksModel.count; i++) {
                    const network = networksModel.get(i)
                    network.saved = savedNetworks.includes(network.ssid)
                    networksModel.set(i, network)
                }
            } else {
                showError("Failed to get saved networks")
            }
        })
    }

    function showError(message) {
        errorMessage = message
        hasError = true
        errorTimer.restart()
    }

    Timer {
        id: errorTimer
        interval: 3000
        onTriggered: {
            hasError = false
            errorMessage = ""
        }
    }

    Timer {
        id: networkUpdateTimer
        interval: 10000
        running: isActive
        repeat: true
        onTriggered: updateNetworkList()
    }

    onIsActiveChanged: {
        if (isActive) {
            updateNetworkList()
        }
    }

    Component.onCompleted: {
        if (isActive) {
            updateNetworkList()
            loadNetworkSettings()
        }
    }

    // Add functions for settings
    function toggleAutoConnect() {
        const cmd = autoConnectEnabled ?
            "nmcli connection modify type wifi autoconnect no" :
            "nmcli connection modify type wifi autoconnect yes"
        Io.shellCommand(cmd, (exitCode) => {
            if (exitCode === 0) {
                autoConnectEnabled = !autoConnectEnabled
            } else {
                showError("Failed to toggle auto-connect")
            }
        })
    }

    function toggleRandomMac() {
        const cmd = randomMacEnabled ?
            "nmcli connection modify type wifi wifi.cloned-mac-address permanent" :
            "nmcli connection modify type wifi wifi.cloned-mac-address random"
        Io.shellCommand(cmd, (exitCode) => {
            if (exitCode === 0) {
                randomMacEnabled = !randomMacEnabled
            } else {
                showError("Failed to toggle random MAC")
            }
        })
    }

    function togglePowerSave() {
        const cmd = powerSaveEnabled ?
            `iwconfig ${wirelessInterface} power off` :
            `iwconfig ${wirelessInterface} power on`
        Io.shellCommand(cmd, (exitCode) => {
            if (exitCode === 0) {
                powerSaveEnabled = !powerSaveEnabled
            } else {
                showError("Failed to toggle power save mode")
            }
        })
    }

    function showHiddenNetworkDialog() {
        // TODO: Implement hidden network dialog
        // console.log("Hidden network dialog not implemented yet")
    }

    function showSavedNetworksDialog() {
        // TODO: Implement saved networks dialog
        // console.log("Saved networks dialog not implemented yet")
    }

    // Add function to load current settings
    function loadNetworkSettings() {
        // Check auto-connect setting
        Io.shellCommand("nmcli connection show type wifi | grep autoconnect", (exitCode, stdout) => {
            autoConnectEnabled = stdout.includes("yes")
        })

        // Check MAC address randomization
        Io.shellCommand("nmcli connection show type wifi | grep cloned-mac-address", (exitCode, stdout) => {
            randomMacEnabled = stdout.includes("random")
        })

        // Check power save mode using detected interface
        Io.shellCommand(`iwconfig ${wirelessInterface} | grep Power`, (exitCode, stdout) => {
            powerSaveEnabled = stdout.includes("Power Management:on")
        })
    }
} 