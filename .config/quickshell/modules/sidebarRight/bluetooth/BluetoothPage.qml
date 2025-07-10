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

    Component.onCompleted: {
        if (!Bluetooth.bluetoothEnabled) {
            Bluetooth.powerOn()
        }
    }

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
                        content: (Bluetooth.bluetoothEnabled && Bluetooth.bluetoothDeviceName.length > 0) ? Bluetooth.bluetoothDeviceName : qsTr("Bluetooth | Right-click to configure")
                    }
                }

                StyledText {
                    text: qsTr("Bluetooth Devices")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer0
                }

                Item { Layout.fillWidth: true }

                // Refresh button
                Button {
                    id: refreshButton
                    width: 28; height: 28
                    background: Rectangle {
                        color: Qt.rgba(1,1,1,0.08)
                        radius: height/2
                    }
                    contentItem: MaterialSymbol {
                        text: "refresh"
                        iconSize: 18
                        color: Appearance.colors.colOnLayer0
                        anchors.centerIn: parent
                    }
                    onClicked: {
                        if (Bluetooth.bluetoothEnabled) {
                            Bluetooth.startScan()
                        }
                    }
                    StyledToolTip {
                        content: qsTr("Refresh devices")
                    }
                }

                // Debug button (temporary)
                Button {
                    id: debugButton
                    width: 28; height: 28
                    background: Rectangle {
                        color: Qt.rgba(1,1,1,0.08)
                        radius: height/2
                    }
                    contentItem: MaterialSymbol {
                        text: "bug_report"
                        iconSize: 18
                        color: Appearance.colors.colOnLayer0
                        anchors.centerIn: parent
                    }
                    onClicked: {
                        Bluetooth.debugScan()
                    }
                    StyledToolTip {
                        content: qsTr("Debug scan")
                    }
                }
            }
        }

        // Bluetooth Status
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: Appearance.rounding.normal
            color: Qt.rgba(
                Appearance.colors.colLayer1.r,
                Appearance.colors.colLayer1.g,
                Appearance.colors.colLayer1.b,
                0.2
            )
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                    spacing: 8
                // Bluetooth status icon
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
                    text: Bluetooth.scanning ? qsTr("Scanning...") : ""
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                    visible: Bluetooth.bluetoothEnabled
                }
                    StyledText {
                        text: qsTr("Connected devices:")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                    text: Bluetooth.bluetoothEnabled ? Bluetooth.connectedDevices.length.toString() : "0"
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer0
                    }
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
                    model: Bluetooth.connectedDevices

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
                                text: {
                                    switch(modelData.type) {
                                        case "Headphones": return "headphones"
                                        case "Mouse": return "mouse"
                                        case "Phone": return "smartphone"
                                        case "Computer": return "computer"
                                        case "TV": return "tv"
                                        default: return "bluetooth"
                                    }
                                }
                                iconSize: 16
                                color: "#2196F3"
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    text: modelData.name
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnLayer0
                                }

                                StyledText {
                                    text: modelData.type + " • " + (modelData.battery ? modelData.battery + "%" : "N/A")
                                    font.pixelSize: Appearance.font.pixelSize.tiny
                                    color: Appearance.colors.colOnLayer1
                                }
                            }

                            QuickToggleButton {
                                buttonIcon: "bluetooth_connected"
                                toggled: modelData.connected
                                onClicked: {
                                    Bluetooth.disconnectDevice(modelData.address)
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

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentHeight: deviceListView.contentHeight

                    ListView {
                        id: deviceListView
                        width: parent.width
                        model: Bluetooth.availableDevices

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
                                    text: {
                                        switch(modelData.type) {
                                            case "Headphones": return "headphones"
                                            case "Mouse": return "mouse"
                                            case "Phone": return "smartphone"
                                            case "Computer": return "computer"
                                            case "TV": return "tv"
                                            default: return "bluetooth"
                                        }
                                    }
                                    iconSize: 16
                                    color: Appearance.colors.colOnLayer1
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    StyledText {
                                        text: modelData.name
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnLayer0
                                    }

                                    StyledText {
                                        text: modelData.type + " • " + (modelData.battery ? modelData.battery + "%" : "N/A")
                                        font.pixelSize: Appearance.font.pixelSize.tiny
                                        color: Appearance.colors.colOnLayer1
                                    }
                                }

                                QuickToggleButton {
                                    buttonIcon: "add"
                                    onClicked: {
                                        if (modelData.paired) {
                                            Bluetooth.connectDevice(modelData.address)
                                        } else {
                                            Bluetooth.pairDevice(modelData.address)
                                        }
                                    }
                                    StyledToolTip {
                                        content: modelData.paired ? qsTr("Connect") : qsTr("Pair device")
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    console.log("Selected device:", modelData.name)
                                }
                            }
                        }
                    }

                    // No devices found message
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width
                        height: 120
                        color: "transparent"
                        visible: Bluetooth.availableDevices.length === 0
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
        }
    }
} 