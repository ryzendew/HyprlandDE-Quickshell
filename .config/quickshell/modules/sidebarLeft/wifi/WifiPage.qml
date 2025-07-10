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

    property bool showPasswordDialog: false
    property string selectedNetwork: ""
    property string passwordInput: ""
    property bool isConnecting: false

    // Auto-scan timer based on config
    Timer {
        interval: ConfigOptions.networking.wifi.scanInterval
        running: ConfigOptions.networking.wifi.autoScan && Network.wifiEnabled
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
        anchors.margins: 8
        spacing: 12

        // Header with WiFi toggle and status
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
                anchors.margins: 12
                spacing: 8

                // WiFi toggle button
                QuickToggleButton {
                    toggled: Network.wifiEnabled
                    buttonIcon: Network.wifiEnabled ? (
                        Network.networkStrength > 80 ? "signal_wifi_4_bar" :
                        Network.networkStrength > 60 ? "network_wifi_3_bar" :
                        Network.networkStrength > 40 ? "network_wifi_2_bar" :
                        Network.networkStrength > 20 ? "network_wifi_1_bar" :
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
                    spacing: 0
                    Layout.alignment: Qt.AlignVCenter
                    StyledText {
                        text: Network.networkName.length > 0 ? Network.networkName : qsTr("Wired connection 1")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        visible: Network.networkStrength > 0
                        text: qsTr("Signal: %1%").arg(Network.networkStrength)
                            font.pixelSize: Appearance.font.pixelSize.tiny
                        color: Appearance.colors.colSubtext
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
                        Hyprland.dispatch(`exec ${ConfigOptions.apps.network}`);
                        GlobalStates.sidebarLeftOpen = false;
                    }
                    StyledToolTip {
                        content: qsTr("Network settings")
                    }
                }
            }
        }

        // Connection status
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            radius: Appearance.rounding.normal
            color: Qt.rgba(
                Appearance.colors.colLayer1.r,
                Appearance.colors.colLayer1.g,
                Appearance.colors.colLayer1.b,
                0.2
            )
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            visible: Network.wifiEnabled

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                MaterialSymbol {
                    text: Network.isScanning ? "sync" : (Network.connected ? "wifi" : "wifi_off")
                    iconSize: 18
                    color: Network.isScanning ? Appearance.colors.colAccent :
                           Network.connected ? "#4CAF50" : "#F44336"
                }

                StyledText {
                    text: Network.isScanning ? qsTr("Scanning...") :
                          Network.connected ? qsTr("Connected") : qsTr("Disconnected")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer0
                }

                Item { Layout.fillWidth: true }

                // Show connected SSID on the right
                StyledText {
                    visible: Network.connected && Network.ssid.length > 0
                    text: Network.ssid
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    horizontalAlignment: Text.AlignRight
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                }

                StyledText {
                    text: Network.isConnecting ? qsTr("Connecting...") : ""
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colAccent
                    visible: Network.isConnecting
                }
            }
        }

        // Error message
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: Appearance.rounding.normal
            color: Qt.rgba(244, 67, 54, 0.1)
            border.color: Qt.rgba(244, 67, 54, 0.3)
            border.width: 1
            visible: Network.connectionError.length > 0

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                MaterialSymbol {
                    text: "error"
                    iconSize: 16
                    color: "#F44336"
                }

                StyledText {
                    text: Network.connectionError
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: "#F44336"
                    Layout.fillWidth: true
                }

                QuickToggleButton {
                    buttonIcon: "close"
                    implicitWidth: 24
                    implicitHeight: 24
                    onClicked: {
                        Network.connectionError = "";
                    }
                }
            }
        }

        // Available networks
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
                        text: Network.networks.length + " networks"
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
                        model: Network.networks
                        spacing: 4

                        delegate: Rectangle {
                            width: networkListView.width
                            implicitHeight: Math.max(48, rowContent.implicitHeight + 16)
                            radius: Appearance.rounding.small
                            color: modelData.connected ? Qt.rgba(76, 175, 80, 0.1) : 
                                   mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
                            border.color: modelData.connected ? Qt.rgba(76, 175, 80, 0.3) : 
                                         mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.05)
                            border.width: 1

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
                                        text: modelData.signal > 80 ? "signal_wifi_4_bar" :
                                              modelData.signal > 60 ? "network_wifi_3_bar" :
                                              modelData.signal > 40 ? "network_wifi_2_bar" :
                                              modelData.signal > 20 ? "network_wifi_1_bar" :
                                              "signal_wifi_0_bar"
                                        iconSize: 24
                                        color: modelData.connected ? "#4CAF50" : Appearance.colors.colOnLayer1
                                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                    }

                                    // Network info
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 2

                                        Text {
                                            text: modelData.ssid
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                            font.weight: modelData.connected ? Font.Medium : Font.Normal
                                            color: Appearance.colors.colOnLayer0
                                            horizontalAlignment: Text.AlignLeft
                                            verticalAlignment: Text.AlignVCenter
                                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                            Layout.fillWidth: true
                                        }
                                        StyledText {
                                            visible: modelData.connected || modelData.ssid.toLowerCase() === Network.ssid.toLowerCase()
                                            text: qsTr("Connected")
                                            font.pixelSize: Appearance.font.pixelSize.tiny
                                            color: Appearance.colors.colAccent
                                            font.weight: Font.Medium
                                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8
                                            Layout.alignment: Qt.AlignVCenter
                                            StyledText {
                                                visible: ConfigOptions.networking.wifi.showSecurityType
                                                text: modelData.security
                                                font.pixelSize: Appearance.font.pixelSize.tiny
                                                color: Appearance.colors.colSubtext
                                                horizontalAlignment: Text.AlignLeft
                                                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                            }
                                            StyledText {
                                                visible: ConfigOptions.networking.wifi.showSignalStrength
                                                text: modelData.signal + "%"
                                                font.pixelSize: Appearance.font.pixelSize.tiny
                                                color: Appearance.colors.colSubtext
                                                horizontalAlignment: Text.AlignLeft
                                                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                            }
                                        }
                                    }

                                    // Connection status
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
                radius: Qt.binding(function() { return Appearance.rounding.normal; })
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
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 12
                anchors.bottomMargin: 12
                anchors.left: parent.left
                anchors.right: parent.right
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
                    echoMode: ConfigOptions.networking.wifi.connection.showPassword ? TextInput.Normal : TextInput.Password
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
                            console.log("[WiFi] Attempting to connect to", selectedNetwork, "with password", passwordInput)
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