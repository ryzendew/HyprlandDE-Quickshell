import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Quickshell.Bluetooth 1.0
import "root:/modules/common/widgets"

Rectangle {
    id: root
    width: 480
    height: 600
    color: Qt.rgba(0.10, 0.11, 0.13, 0.98) // dark background
    radius: 18
    border.color: "#222"
    border.width: 2

    Bluetooth {
        id: bluetooth
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 18

        RowLayout {
            spacing: 12
            StyledText {
                text: qsTr("\uF293  Bluetooth Devices")
                font.pixelSize: 22
                font.bold: true
                color: "#fff"
            }
            Item { Layout.fillWidth: true }
            Switch {
                checked: bluetooth.bluetoothEnabled
                onCheckedChanged: bluetooth.bluetoothEnabled = checked
                palette.highlight: "#00e676"
            }
        }

        RowLayout {
            spacing: 10
            StyledText {
                text: qsTr("Bluetooth")
                font.pixelSize: 16
                font.bold: true
                color: "#bbb"
            }
            Item { Layout.fillWidth: true }
            Button {
                text: bluetooth.scanning ? qsTr("\u21BB Scanning...") : qsTr("Scan")
                enabled: bluetooth.bluetoothEnabled && !bluetooth.scanning
                background: Rectangle { color: "#2979ff"; radius: 8 }
                contentItem: StyledText { text: parent.text; color: "#fff"; font.pixelSize: 14 }
                onClicked: bluetooth.startDiscovery()
            }
        }

        StyledText {
            text: qsTr("Available Devices")
            font.pixelSize: 15
            font.bold: true
            color: "#fff"
            padding: 8
        }

        Rectangle {
            color: Qt.rgba(0.13, 0.14, 0.16, 0.95)
            radius: 12
            border.color: "#222"
            border.width: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            anchors.leftMargin: 0
            anchors.rightMargin: 0
            anchors.topMargin: 0
            anchors.bottomMargin: 0
            
            ListView {
                id: deviceList
                anchors.fill: parent
                model: bluetooth.devices
                delegate: Rectangle {
                    width: deviceList.width
                    height: 64
                    color: "transparent"
                    border.color: "#222"
                    border.width: 0
                    radius: 8
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 16
                        Image {
                            source: device.icon || "qrc:/icons/bluetooth.svg"
                            width: 32; height: 32
                            fillMode: Image.PreserveAspectFit
                        }
                        ColumnLayout {
                            spacing: 2
                            StyledText {
                                text: device.name || qsTr("Unknown Device")
                                font.pixelSize: 16
                                color: "#fff"
                                font.bold: true
                            }
                            StyledText {
                                text: device.address
                                font.pixelSize: 12
                                color: "#aaa"
                            }
                            StyledText {
                                text: device.type
                                font.pixelSize: 12
                                color: "#80cbc4"
                            }
                        }
                        Item { Layout.fillWidth: true }
                        RowLayout {
                            spacing: 8
                            Button {
                                text: qsTr("Forget")
                                enabled: device.paired
                                background: Rectangle { color: "#ff7043"; radius: 8 }
                                contentItem: StyledText { text: parent.text; color: "#fff"; font.pixelSize: 13 }
                                onClicked: device.forget()
                            }
                            Button {
                                text: qsTr("Disconnect")
                                enabled: device.connected
                                background: Rectangle { color: "#f44336"; radius: 8 }
                                contentItem: StyledText { text: parent.text; color: "#fff"; font.pixelSize: 13 }
                                onClicked: device.disconnect()
                            }
                            Button {
                                text: qsTr("Connect")
                                enabled: !device.connected
                                background: Rectangle { color: "#00e676"; radius: 8 }
                                contentItem: StyledText { text: parent.text; color: "#222"; font.pixelSize: 13 }
                                onClicked: device.connect()
                            }
                        }
                    }
                }
                ScrollBar.vertical: ScrollBar { }
            }
        }
    }
} 