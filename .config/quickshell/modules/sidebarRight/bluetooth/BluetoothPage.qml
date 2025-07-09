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
                    symbol: "bluetooth"
                    size: 20
                    color: Appearance.colors.colOnLayer0
                }

                StyledText {
                    text: qsTr("Bluetooth Devices")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer0
                }

                Item { Layout.fillWidth: true }

                QuickToggleButton {
                    buttonIcon: "refresh"
                    onClicked: {
                        // Refresh Bluetooth devices
                        console.log("Refreshing Bluetooth devices...")
                    }
                    StyledToolTip {
                        content: qsTr("Refresh devices")
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
                        symbol: Bluetooth.enabled ? "bluetooth" : "bluetooth_disabled"
                        size: 18
                        color: Bluetooth.enabled ? "#2196F3" : "#F44336"
                    }

                    StyledText {
                        text: Bluetooth.enabled ? qsTr("Enabled") : qsTr("Disabled")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer0
                    }

                    Item { Layout.fillWidth: true }

                    StyledText {
                        text: Bluetooth.enabled ? qsTr("Discoverable") : ""
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                        visible: Bluetooth.enabled
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
                        text: Bluetooth.enabled ? "2" : "0"
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
                        text: Bluetooth.enabled ? "85%" : qsTr("N/A")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer0
                    }
                }
            }
        }

        // Connected Devices
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
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
                    text: qsTr("Connected Devices")
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer0
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: ListModel {
                        ListElement { name: "AirPods Pro"; type: "Headphones"; battery: 85; connected: true }
                        ListElement { name: "Magic Mouse"; type: "Mouse"; battery: 72; connected: true }
                    }

                    delegate: Rectangle {
                        width: parent.width
                        height: 45
                        radius: Appearance.rounding.small
                        color: Qt.rgba(33, 150, 243, 0.1)
                        border.color: Qt.rgba(33, 150, 243, 0.3)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            MaterialSymbol {
                                symbol: type === "Headphones" ? "headphones" : "mouse"
                                size: 16
                                color: "#2196F3"
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    text: name
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnLayer0
                                }

                                StyledText {
                                    text: type + " • " + battery + "%"
                                    font.pixelSize: Appearance.font.pixelSize.tiny
                                    color: Appearance.colors.colOnLayer1
                                }
                            }

                            QuickToggleButton {
                                buttonIcon: "bluetooth_connected"
                                toggled: connected
                                onClicked: {
                                    console.log("Disconnecting from:", name)
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
                    text: qsTr("Available Devices")
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer0
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ListView {
                        id: deviceListView
                        model: ListModel {
                            ListElement { name: "Sony WH-1000XM4"; type: "Headphones"; signal: 85; paired: false }
                            ListElement { name: "Logitech MX Master 3"; type: "Mouse"; signal: 72; paired: false }
                            ListElement { name: "iPhone 15 Pro"; type: "Phone"; signal: 45; paired: false }
                            ListElement { name: "Samsung TV"; type: "TV"; signal: 30; paired: false }
                        }

                        delegate: Rectangle {
                            width: deviceListView.width
                            height: 50
                            radius: Appearance.rounding.small
                            color: "transparent"
                            border.color: Qt.rgba(1, 1, 1, 0.05)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                MaterialSymbol {
                                    symbol: {
                                        switch(type) {
                                            case "Headphones": return "headphones"
                                            case "Mouse": return "mouse"
                                            case "Phone": return "smartphone"
                                            case "TV": return "tv"
                                            default: return "bluetooth"
                                        }
                                    }
                                    size: 16
                                    color: Appearance.colors.colOnLayer1
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    StyledText {
                                        text: name
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnLayer0
                                    }

                                    StyledText {
                                        text: type + " • " + signal + "%"
                                        font.pixelSize: Appearance.font.pixelSize.tiny
                                        color: Appearance.colors.colOnLayer1
                                    }
                                }

                                QuickToggleButton {
                                    buttonIcon: "add"
                                    onClicked: {
                                        console.log("Pairing with:", name)
                                    }
                                    StyledToolTip {
                                        content: qsTr("Pair device")
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    console.log("Selected device:", name)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
} 