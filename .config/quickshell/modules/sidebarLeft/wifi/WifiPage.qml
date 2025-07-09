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

                    // WiFi QuickToggleButton
                    QuickToggleButton {
                        toggled: Network.networkName.length > 0 && Network.networkName != "lo"
                        buttonIcon: toggled ? (
                            Network.networkStrength > 80 ? "signal_wifi_4_bar" :
                            Network.networkStrength > 60 ? "network_wifi_3_bar" :
                            Network.networkStrength > 40 ? "network_wifi_2_bar" :
                            Network.networkStrength > 20 ? "network_wifi_1_bar" :
                            "signal_wifi_0_bar"
                        ) : "signal_wifi_off"
                        implicitWidth: 32
                        implicitHeight: 32
                        Layout.alignment: Qt.AlignVCenter
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.RightButton | Qt.LeftButton
                            onClicked: (mouse) =>{
                                if (mouse.button === Qt.LeftButton) {
                                    toggleNetwork.running = true
                                }
                                if (mouse.button === Qt.RightButton) {
                                    Hyprland.dispatch(`exec ${ConfigOptions.apps.network}`)
                                    Hyprland.dispatch("global quickshell:sidebarRightClose")
                                }
                            }
                            hoverEnabled: false
                            propagateComposedEvents: true
                            cursorShape: Qt.PointingHandCursor 
                        }
                        Process {
                            id: toggleNetwork
                            command: ["bash", "-c", "nmcli radio wifi | grep -q enabled && nmcli radio wifi off || nmcli radio wifi on"]
                            onRunningChanged: {
                                if(!running) {
                                    Network.update()
                                }
                            }
                        }
                        StyledToolTip {
                            content: Network.networkName.length > 0 ? Network.networkName : qsTr("WiFi | Right-click to configure")
                        }
                    }

                    StyledText {
                        text: qsTr("WiFi Networks")
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
                            // Refresh WiFi networks
                        }
                        StyledToolTip {
                            content: qsTr("Refresh networks")
                        }
                    }
                }
            }
        }

        // WiFi Status
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
            anchors.leftMargin: 10
            anchors.rightMargin: 10

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    MaterialSymbol {
                        text: Network.connected ? "wifi" : "wifi_off"
                        iconSize: 18
                        color: Network.connected ? "#4CAF50" : "#F44336"
                    }

                    StyledText {
                        text: Network.connected ? qsTr("Connected") : qsTr("Disconnected")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer0
                    }

                    Item { Layout.fillWidth: true }

                    StyledText {
                        text: Network.connected ? Network.ssid : ""
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                        visible: Network.connected
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    StyledText {
                        text: qsTr("Signal:")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                    }

                    StyledText {
                        text: Network.connected ? Network.signalStrength + "%" : qsTr("N/A")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer0
                    }

                    Item { Layout.fillWidth: true }

                    StyledText {
                        text: qsTr("Speed:")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                    }

                    StyledText {
                        text: Network.connected ? Network.bitrate + " Mbps" : qsTr("N/A")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer0
                    }
                }
            }
        }

        // Available Networks List
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
            anchors.leftMargin: 10
            anchors.rightMargin: 10

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                StyledText {
                    text: qsTr("Available Networks")
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer0
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ListView {
                        id: networkListView
                        model: ListModel {
                            // Placeholder data - in a real implementation this would be populated from Network service
                            ListElement { ssid: "Home WiFi"; signal: 85; security: "WPA2"; connected: true }
                            ListElement { ssid: "Office Network"; signal: 72; security: "WPA3"; connected: false }
                            ListElement { ssid: "Guest WiFi"; signal: 45; security: "Open"; connected: false }
                            ListElement { ssid: "Neighbor's WiFi"; signal: 30; security: "WPA2"; connected: false }
                        }

                        delegate: Rectangle {
                            width: networkListView.width
                            height: 50
                            radius: Appearance.rounding.small
                            color: connected ? Qt.rgba(76, 175, 80, 0.1) : "transparent"
                            border.color: connected ? Qt.rgba(76, 175, 80, 0.3) : Qt.rgba(1, 1, 1, 0.05)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 12

                                MaterialSymbol {
                                    text: "wifi"
                                    iconSize: 16
                                    color: connected ? "#4CAF50" : Appearance.colors.colOnLayer1
                                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                    spacing: 2

                                    StyledText {
                                        text: ssid
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: connected ? Font.Medium : Font.Normal
                                        color: Appearance.colors.colOnLayer0
                                    }

                                    RowLayout {
                                        spacing: 8

                                        StyledText {
                                            text: security
                                            font.pixelSize: Appearance.font.pixelSize.tiny
                                            color: Appearance.colors.colOnLayer1
                                        }

                                        StyledText {
                                            text: signal + "%"
                                            font.pixelSize: Appearance.font.pixelSize.tiny
                                            color: Appearance.colors.colOnLayer1
                                        }
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                MaterialSymbol {
                                    text: connected ? "check_circle" : "radio_button_unchecked"
                                    iconSize: 16
                                    color: connected ? "#4CAF50" : Appearance.colors.colOnLayer1
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (!connected) {
                                        // In a real implementation, this would trigger connection
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