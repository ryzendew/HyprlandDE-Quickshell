import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import Quickshell.Wayland
import Quickshell
import Quickshell.Bluetooth
import "root:/Settings" as Settings
import "root:/Components" as Components

PanelWindow {
    id: bluetoothPanelModal
    implicitWidth: 480
    implicitHeight: 720
    visible: false
    color: "transparent"
    anchors.top: true
    anchors.right: true
    margins.right: 0
    margins.top: -24
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: Settings.Theme.backgroundPrimary
        radius: 24

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 32
            spacing: 0

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 20
                Layout.preferredHeight: 48
                Text {
                    text: "bluetooth"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 32
                    color: Settings.Theme.accentPrimary
                }
                Text {
                    text: "Bluetooth"
                    font.pixelSize: 26
                    font.bold: true
                    color: Settings.Theme.textPrimary
                    Layout.fillWidth: true
                }
                Rectangle {
                    width: 36; height: 36; radius: 18
                    color: closeButtonArea.containsMouse ? Settings.Theme.accentPrimary : "transparent"
                    border.color: Settings.Theme.accentPrimary
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "close"
                        font.family: closeButtonArea.containsMouse ? "Material Symbols Rounded" : "Material Symbols Outlined"
                        font.pixelSize: 20
                        color: closeButtonArea.containsMouse ? Settings.Theme.onAccent : Settings.Theme.accentPrimary
                    }
                    MouseArea {
                        id: closeButtonArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: bluetoothPanelModal.visible = false
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Settings.Theme.outline
                opacity: 0.12
            }

            // Content area
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 520
                Layout.alignment: Qt.AlignHCenter
                Layout.margins: 0
                color: Settings.Theme.surfaceVariant
                radius: 18
                border.color: Settings.Theme.outline
                border.width: 1
                anchors.topMargin: 32
                anchors.bottomMargin: 0
                anchors.leftMargin: 0
                anchors.rightMargin: 0

                property var anchorItem: null
                property real anchorX
                property real anchorY

                // Device list UI
                Rectangle {
                    id: bg
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Settings.Theme.backgroundPrimary
                    radius: 12
                    border.width: 1
                    border.color: Settings.Theme.surfaceVariant
                    z: 0
                }
                // Header
                Rectangle {
                    id: header
                    Layout.fillWidth: true
                    height: 56
                    color: "transparent"
                    Text {
                        text: "Bluetooth"
                        font.pixelSize: 18
                        font.bold: true
                        color: Settings.Theme.textPrimary
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                    }
                }
                // Device list
                Rectangle {
                    id: listContainer
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    anchors.top: header.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 8
                    color: "transparent"
                    clip: true
                    ListView {
                        id: deviceListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4
                        boundsBehavior: Flickable.StopAtBounds
                        model: Bluetooth.devices
                        delegate: Rectangle {
                            width: parent.width
                            height: 42
                            color: "transparent"
                            radius: 8
                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                color: modelData.connected ? Qt.rgba(Settings.Theme.accentPrimary.r, Settings.Theme.accentPrimary.g, Settings.Theme.accentPrimary.b, 0.18)
                                    : (deviceMouseArea.containsMouse ? Settings.Theme.highlight : "transparent")
                            }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12
                                Text {
                                    text: modelData.connected ? "bluetooth" : "bluetooth_disabled"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 20
                                    color: modelData.connected ? Settings.Theme.accentPrimary : Settings.Theme.textSecondary
                                    verticalAlignment: Text.AlignVCenter
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text {
                                        text: modelData.name || "Unknown Device"
                                        color: modelData.connected ? Settings.Theme.accentPrimary : Settings.Theme.textPrimary
                                        font.pixelSize: 14
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: modelData.address
                                        color: modelData.connected ? Settings.Theme.accentPrimary : Settings.Theme.textSecondary
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                            MouseArea {
                                id: deviceMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (modelData.connected) {
                                        modelData.disconnect()
                                    } else {
                                        modelData.connect()
                                    }
                                }
                            }
                        }
                    }
                }
                // Scroll indicator
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 2
                    anchors.top: listContainer.top
                    anchors.bottom: listContainer.bottom
                    width: 4
                    radius: 2
                    color: Settings.Theme.textSecondary
                    opacity: deviceListView.contentHeight > deviceListView.height ? 0.3 : 0
                    visible: opacity > 0
                }
            }
        }
    }
} 