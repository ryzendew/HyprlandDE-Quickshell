import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

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
            Layout.preferredHeight: 40
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

                MaterialSymbol {
                    symbol: "wifi"
                    size: 20
                    color: Appearance.colors.colOnLayer0
                }

                StyledText {
                    text: qsTr("WiFi Networks")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer0
                }

                Item { Layout.fillWidth: true }

                QuickToggleButton {
                    buttonIcon: "refresh"
                    onClicked: {
                        // Refresh WiFi networks
                        console.log("Refreshing WiFi networks...")
                    }
                    StyledToolTip {
                        content: qsTr("Refresh networks")
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

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    MaterialSymbol {
                        symbol: Network.connected ? "wifi" : "wifi_off"
                        size: 18
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
                        text: Network.connected ? Network.networkStrength + "%" : qsTr("N/A")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer0
                    }

                    Item { Layout.fillWidth: true }

                    StyledText {
                        text: qsTr("Type:")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                    }

                    StyledText {
                        text: Network.connected ? (Network.ethernet ? qsTr("Ethernet") : qsTr("WiFi")) : qsTr("N/A")
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
                                spacing: 8

                                MaterialSymbol {
                                    symbol: "wifi"
                                    size: 16
                                    color: connected ? "#4CAF50" : Appearance.colors.colOnLayer1
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
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

                                MaterialSymbol {
                                    symbol: connected ? "check_circle" : "radio_button_unchecked"
                                    size: 16
                                    color: connected ? "#4CAF50" : Appearance.colors.colOnLayer1
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (!connected) {
                                        console.log("Connecting to:", ssid)
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