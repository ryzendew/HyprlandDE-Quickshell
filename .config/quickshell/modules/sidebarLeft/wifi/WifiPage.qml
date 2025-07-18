import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/sidebarRight/quickToggles"
import "root:/services"
import "root:/"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    radius: Appearance.rounding.normal
    color: "transparent"

    function safeSignal(val) {
        if (val === undefined || val === null) return 0;
        if (typeof val === "number" && !isNaN(val)) return val;
        var n = parseInt(val);
        return (!isNaN(n) && n >= 0) ? n : 0;
    }

    property bool showPasswordDialog: false
    property string selectedNetwork: ""
    property string passwordInput: ""
    property bool isConnecting: false

    // Auto-scan timer based on config
    Timer {
        interval: ConfigOptions.networking?.wifi?.scanInterval || 30000
        running: (ConfigOptions.networking?.wifi?.autoScan || false) && Network.wifiEnabled
        repeat: true
        onTriggered: {
            if (Network.wifiEnabled) {
                Network.scanNetworks();
            }
        }
    }

    // Initial scan
    Component.onCompleted: {
        if (Network.wifiEnabled) {
            Network.scanNetworks();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0

        // Header with WiFi toggle and status
        Rectangle {
            Layout.fillWidth: true
            Layout.minimumHeight: 54
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
                anchors.topMargin: 8
                anchors.margins: 8
                spacing: 8

                // WiFi toggle button
                QuickToggleButton {
                    toggled: Network.wifiEnabled
                    buttonIcon: Network.wifiEnabled ? (
                        (Network.networkStrength ?? 0) > 80 ? "signal_wifi_4_bar" :
                        (Network.networkStrength ?? 0) > 60 ? "network_wifi_3_bar" :
                        (Network.networkStrength ?? 0) > 40 ? "network_wifi_2_bar" :
                        (Network.networkStrength ?? 0) > 20 ? "network_wifi_1_bar" :
                        "signal_wifi_0_bar"
                    ) : "signal_wifi_off"
                    implicitWidth: 36
                    implicitHeight: 36
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: {
                        Network.toggleWifi();
                    }
                    StyledToolTip {
                        content: Network.wifiEnabled ? 
                            (Network.connected ? qsTr("Connected to %1").arg(Network.ssid) : qsTr("WiFi enabled")) :
                            qsTr("WiFi disabled")
                    }
                }

                // Status info (wired connection and signal)
                ColumnLayout {
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter
                    StyledText {
                        text: Network.wifiEnabled ? qsTr("WiFi is enabled") : qsTr("WiFi is disabled")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Network.wifiEnabled ? "#2196F3" : "#F44336"
                        font.weight: Font.Medium
                    }
                }

                Item { Layout.fillWidth: true }

                // Refresh button
                QuickToggleButton {
                    buttonIcon: "refresh"
                    implicitWidth: 32
                    implicitHeight: 32
                    Layout.alignment: Qt.AlignVCenter
                    enabled: Network.wifiEnabled && !Network.isScanning
                    onClicked: {
                        Network.scanNetworks();
                    }
                    StyledToolTip {
                        content: qsTr("Refresh networks")
                    }
                }

                // Settings button
                QuickToggleButton {
                    buttonIcon: "settings"
                    implicitWidth: 32
                    implicitHeight: 32
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: {
                        Hyprland.dispatch(`exec ${ConfigOptions.apps?.network || "nm-connection-editor"}`);
                        GlobalStates.sidebarLeftOpen = false;
                    }
                    StyledToolTip {
                        content: qsTr("Network settings")
                    }
                }
            }
        }

        // Connected network section
        ColumnLayout {
            Layout.topMargin: -18
            spacing: 0
            visible: Network.wifiEnabled && Network.connected
            Text {
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer0
                padding: 0
            }
            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(72, 72 * (Network.connected ? 1 : 0))
                model: Network.connected ? [{
                    ssid: Network.ssid || Network.networkName,
                    security: "Unknown",
                    signal: Network.networkStrength || 0,
                    connected: true
                }] : []
                spacing: 4
                delegate: Rectangle {
                    width: parent.width * 1.0
                    implicitHeight: modelData.connected ? 72 : Math.max(48, rowContent.implicitHeight + 16)
                    color: modelData.connected ? Qt.rgba(30/255, 30/255, 32/255, 0.92) : mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
                    radius: modelData.connected ? 12 : Appearance.rounding.small
                    border.color: modelData.connected ? Qt.rgba(255/255,255/255,255/255,0.13) : (mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.05))
                    border.width: modelData.connected ? 1.5 : 1

                    // Overlay for connected network
                    Rectangle {
                        anchors.fill: parent
                        radius: modelData.connected ? 12 : Appearance.rounding.small
                        color: modelData.connected ? Qt.rgba(0, 200/255, 255/255, 0.18) : "transparent"
                        z: 2
                        visible: modelData.connected
                    }

                    Item {
                        id: rowContent
                        anchors.fill: parent
                        RowLayout {
                            id: rowLayout
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 12
                            spacing: 12
                            Layout.alignment: Qt.AlignVCenter

                            // Signal strength icon
                            MaterialSymbol {
                                        text: {
                                            const signal = safeSignal(modelData.signal);
                                            return signal > 80 ? "signal_wifi_4_bar" :
                                                   signal > 60 ? "network_wifi_3_bar" :
                                                   signal > 40 ? "network_wifi_2_bar" :
                                                   signal > 20 ? "network_wifi_1_bar" :
                                                   "signal_wifi_0_bar";
                                        }
                                iconSize: 24
                                color: modelData.connected ? "#4CAF50" : Appearance.colors.colOnLayer1
                                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            }

                            // Network info
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2
                                // Blue 'Connected' label above SSID
                                Text {
                                    visible: modelData.connected
                                    text: qsTr("Connected")
                                    font.pixelSize: Appearance.font.pixelSize.tiny
                                    color: "#1ec8ff"
                                    font.weight: Font.Medium
                                    horizontalAlignment: Text.AlignLeft
                                    verticalAlignment: Text.AlignVCenter
                                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                }
                                Text {
                                    text: modelData.ssid
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: modelData.connected ? Font.Medium : Font.Normal
                                    color: Appearance.colors.colOnLayer0
                                    horizontalAlignment: Text.AlignLeft
                                    verticalAlignment: Text.AlignVCenter
                                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                    Layout.fillWidth: true
                                    wrapMode: Text.Wrap
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Right side: Connected, security, signal (stacked)
                            RowLayout {
                                spacing: 8
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                ColumnLayout {
                                    spacing: 4
                                    StyledText {
                                        visible: modelData.connected
                                        text: qsTr("Connected")
                                        font.pixelSize: Appearance.font.pixelSize.tiny
                                        color: Appearance.colors.colAccent
                                        font.weight: Font.Medium
                                    }
                                    StyledText {
                                        visible: ConfigOptions.networking?.wifi?.showSecurityType || false
                                        text: modelData.security
                                        font.pixelSize: Appearance.font.pixelSize.tiny
                                        color: Appearance.colors.colSubtext
                                        horizontalAlignment: Text.AlignLeft
                                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                    }
                                    StyledText {
                                        visible: ConfigOptions.networking?.wifi?.showSignalStrength || false
                                        text: safeSignal(modelData.signal) + "%"
                                        font.pixelSize: Appearance.font.pixelSize.tiny
                                        color: Appearance.colors.colSubtext
                                        horizontalAlignment: Text.AlignLeft
                                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                    }
                                }
                                // Status icon
                                MaterialSymbol {
                                    text: modelData.connected ? "check_circle" : 
                                          (Network.isConnecting && selectedNetwork === modelData.ssid ? "sync" : "radio_button_unchecked")
                                    iconSize: 18
                                    color: modelData.connected ? "#4CAF50" : 
                                          (Network.isConnecting && selectedNetwork === modelData.ssid ? Appearance.colors.colAccent : Appearance.colors.colOnLayer1)
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!modelData.connected && !Network.isConnecting) {
                                selectedNetwork = modelData.ssid;
                                if (modelData.security === "Open") {
                                    Network.connectToNetwork(modelData.ssid);
                                } else {
                                    showPasswordDialog = true;
                                }
                            }
                        }
                    }
                }
            }
        }

        // Available networks section
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
                anchors.margins: 12
                spacing: 8

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    StyledText {
                        text: qsTr("Available Networks")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer0
                    }

                    Item { Layout.fillWidth: true }

                    StyledText {
                        text: ((Network.networks || []).filter(function(n) { return !n.connected; }).length || 0) + " networks"
                        font.pixelSize: Appearance.font.pixelSize.tiny
                        color: Appearance.colors.colSubtext
                    }
                }

                // Networks list
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ListView {
                        id: networkListView
                        model: (Network.networks || []).filter(function(n) { return !n.connected; })
                        spacing: 4
                        delegate: Rectangle {
                            width: networkListView.width
                            implicitHeight: modelData.connected ? 72 : Math.max(48, rowContent.implicitHeight + 16)
                            color: modelData.connected ? Qt.rgba(30/255, 30/255, 32/255, 0.92) : mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
                            radius: modelData.connected ? 12 : Appearance.rounding.small
                            border.color: modelData.connected ? Qt.rgba(255/255,255/255,255/255,0.13) : (mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.05))
                            border.width: modelData.connected ? 1.5 : 1

                            // Overlay for connected network
                            Rectangle {
                                anchors.fill: parent
                                radius: modelData.connected ? 12 : Appearance.rounding.small
                                color: modelData.connected ? Qt.rgba(0, 200/255, 255/255, 0.18) : "transparent"
                                z: 2
                                visible: modelData.connected
                            }

                            Item {
                                id: rowContent
                                anchors.fill: parent
                                RowLayout {
                                    id: rowLayout
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.margins: 8
                                    spacing: 12
                                    Layout.alignment: Qt.AlignVCenter

                                    // Signal strength icon
                                    MaterialSymbol {
                                        text: {
                                            const signal = safeSignal(modelData.signal);
                                            return signal > 80 ? "signal_wifi_4_bar" :
                                                   signal > 60 ? "network_wifi_3_bar" :
                                                   signal > 40 ? "network_wifi_2_bar" :
                                                   signal > 20 ? "network_wifi_1_bar" :
                                                   "signal_wifi_0_bar";
                                        }
                                        iconSize: 24
                                        color: modelData.connected ? "#4CAF50" : Appearance.colors.colOnLayer1
                                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                    }

                                    // Network info
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 2
                                        // Blue 'Connected' label above SSID
                                        Text {
                                            visible: modelData.connected
                                            text: qsTr("Connected")
                                            font.pixelSize: Appearance.font.pixelSize.tiny
                                            color: "#1ec8ff"
                                            font.weight: Font.Medium
                                            horizontalAlignment: Text.AlignLeft
                                            verticalAlignment: Text.AlignVCenter
                                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                        }
                                        Text {
                                            text: modelData.ssid
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                            font.weight: modelData.connected ? Font.Medium : Font.Normal
                                            color: Appearance.colors.colOnLayer0
                                            horizontalAlignment: Text.AlignLeft
                                            verticalAlignment: Text.AlignVCenter
                                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                            Layout.fillWidth: true
                                            wrapMode: Text.Wrap
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    // Right side: Connected, security, signal (stacked)
                                    RowLayout {
                                        spacing: 8
                                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                        ColumnLayout {
                                            spacing: 2
                                        StyledText {
                                                visible: modelData.connected
                                            text: qsTr("Connected")
                                            font.pixelSize: Appearance.font.pixelSize.tiny
                                            color: Appearance.colors.colAccent
                                            font.weight: Font.Medium
                                        }
                                            StyledText {
                                                visible: ConfigOptions.networking?.wifi?.showSecurityType || false
                                                text: modelData.security
                                                font.pixelSize: Appearance.font.pixelSize.tiny
                                                color: Appearance.colors.colSubtext
                                                horizontalAlignment: Text.AlignLeft
                                                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                            }
                                            StyledText {
                                                visible: ConfigOptions.networking?.wifi?.showSignalStrength || false
                                                text: safeSignal(modelData.signal) + "%"
                                                font.pixelSize: Appearance.font.pixelSize.tiny
                                                color: Appearance.colors.colSubtext
                                                horizontalAlignment: Text.AlignLeft
                                                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                            }
                                        }
                                        // Status icon
                                    MaterialSymbol {
                                        text: modelData.connected ? "check_circle" : 
                                              (Network.isConnecting && selectedNetwork === modelData.ssid ? "sync" : "radio_button_unchecked")
                                        iconSize: 18
                                        color: modelData.connected ? "#4CAF50" : 
                                              (Network.isConnecting && selectedNetwork === modelData.ssid ? Appearance.colors.colAccent : Appearance.colors.colOnLayer1)
                                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!modelData.connected && !Network.isConnecting) {
                                        selectedNetwork = modelData.ssid;
                                        if (modelData.security === "Open") {
                                            Network.connectToNetwork(modelData.ssid);
                                        } else {
                                            showPasswordDialog = true;
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

    // Password dialog
    Dialog {
        id: passwordDialog
        title: ""
        modal: true
        visible: showPasswordDialog
        anchors.centerIn: parent
        width: 340
        height: 220
        background: Rectangle {
            color: Qt.rgba(
                Appearance.colors.colLayer1.r,
                Appearance.colors.colLayer1.g,
                Appearance.colors.colLayer1.b,
                0.97
            )
            radius: Appearance.rounding.normal
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
        }

        onVisibleChanged: {
            if (visible) {
                passwordInput = "";
                passwordField.forceActiveFocus();
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 0
            spacing: 0

            // Custom title bar
            Rectangle {
                width: parent.width
                height: 44
                color: Qt.rgba(
                    Appearance.colors.colLayer1.r * 0.85,
                    Appearance.colors.colLayer1.g * 0.85,
                    Appearance.colors.colLayer1.b * 0.85,
                    1.0
                )
                radius: Appearance.rounding.normal
                border.color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 0
                StyledText {
                    anchors.centerIn: parent
                    text: qsTr("Connect to %1").arg(selectedNetwork)
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer0
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 12
                Layout.bottomMargin: 12
                spacing: 16
                Layout.fillWidth: true

                StyledText {
                    text: qsTr("Enter password for %1").arg(selectedNetwork)
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer0
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                }

                TextField {
                    id: passwordField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Password")
                    echoMode: (ConfigOptions.networking?.wifi?.connection?.showPassword || false) ? TextInput.Normal : TextInput.Password
                    text: passwordInput
                    onTextChanged: passwordInput = text
                    onAccepted: connectButton.clicked()
                    focus: true
                    color: Appearance.colors.colOnLayer0
                    selectionColor: Appearance.colors.colAccent
                    selectedTextColor: Appearance.colors.colLayer1
                    background: Rectangle {
                        color: Qt.rgba(
                            Appearance.colors.colLayer1.r * 1.1,
                            Appearance.colors.colLayer1.g * 1.1,
                            Appearance.colors.colLayer1.b * 1.1,
                            1.0
                        )
                        radius: Appearance.rounding.small
                        border.color: Qt.rgba(1, 1, 1, 0.12)
                        border.width: 1
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Item { Layout.fillWidth: true }
                    Button {
                        text: qsTr("Cancel")
                        onClicked: {
                            showPasswordDialog = false;
                            selectedNetwork = "";
                        }
                        background: Rectangle {
                            color: Appearance.colors.colLayer1
                            radius: Appearance.rounding.small
                        }
                        contentItem: StyledText {
                            text: parent.text
                            color: Appearance.colors.colOnLayer0
                            font.pixelSize: Appearance.font.pixelSize.normal
                        }
                    }
                    Button {
                        id: connectButton
                        text: qsTr("Connect")
                        enabled: passwordInput.length > 0
                        onClicked: {
                            // console.log("[WiFi] Attempting to connect to", selectedNetwork, "with password", passwordInput)
                            Network.connectToNetwork(selectedNetwork, passwordInput);
                            showPasswordDialog = false;
                            selectedNetwork = "";
                        }
                        background: Rectangle {
                            color: enabled ? Appearance.colors.colAccent : Appearance.colors.colLayer1
                            radius: Appearance.rounding.small
                        }
                        contentItem: StyledText {
                            text: parent.text
                            color: enabled ? Appearance.colors.colOnLayer0 : Appearance.colors.colOnLayer1
                            font.pixelSize: Appearance.font.pixelSize.normal
                        }
                    }
                }
            }
        }
    }
} 