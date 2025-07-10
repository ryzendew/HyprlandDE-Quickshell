import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import "root:/services/"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland


Scope {
    id: root
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)

    Loader {
        id: bluetoothLoader
        active: false

        sourceComponent: PanelWindow {
            id: bluetoothRoot
            visible: bluetoothLoader.active
            
            function hide() {
                bluetoothLoader.active = false
            }

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:bluetooth"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
            }

            implicitWidth: root.focusedScreen?.width ?? 0
            implicitHeight: root.focusedScreen?.height ?? 0

            // Backdrop blur effect
            Rectangle {
                anchors.fill: parent
                color: ColorUtils.transparentize(Appearance.m3colors.m3scrim, 0.4)
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: bluetoothRoot.hide()
                }
            }

            // Main bluetooth window
            Rectangle {
                id: bluetoothWindow
                anchors.centerIn: parent
                width: Math.min(parent.width - 80, 1200)
                height: Math.min(parent.height - 80, 800)
                
                radius: Appearance.rounding.verylarge
                color: "transparent"
                
                // Modern elevation with subtle shadow
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -4
                    radius: parent.radius + 2
                    color: ColorUtils.transparentize(Appearance.m3colors.m3shadow, 0.08)
                    z: -1
                }

                // Subtle border
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        bluetoothRoot.hide();
                    }
                }

                // Background for content (allows blur to show through)
                Rectangle {
                    anchors.fill: parent
                    color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.9)
                    radius: parent.radius
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 0
                    spacing: 0

                    // Sidebar navigation
                    Rectangle {
                        Layout.preferredWidth: 300
                        Layout.fillHeight: true
                        color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.95)
                        radius: Appearance.rounding.verylarge
                        
                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.radius
                            color: parent.color
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 32
                            spacing: 24

                            // Header
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                StyledText {
                                    text: "Bluetooth Settings"
                                    font.family: Appearance.font.family.title
                                    font.pixelSize: 26
                                    font.weight: Font.Bold
                                    color: Appearance.colors.colOnLayer0
                                }

                                StyledText {
                                    text: "Manage your Bluetooth devices"
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                    opacity: 0.9
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.2)
                            }

                            // Navigation items
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 80
                                    radius: Appearance.rounding.normal
                                    color: Appearance.colors.colPrimaryContainer
                                    border.width: 2
                                    border.color: Appearance.colors.colPrimary

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 20
                                        spacing: 16

                                        Rectangle {
                                            Layout.preferredWidth: 44
                                            Layout.preferredHeight: 44
                                            radius: Appearance.rounding.normal
                                            color: Appearance.colors.colPrimary

                                            MaterialSymbol {
                                                anchors.centerIn: parent
                                                text: "bluetooth"
                                                iconSize: 22
                                                color: "#000"
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 4

                                            StyledText {
                                                text: "Bluetooth"
                                                font.pixelSize: Appearance.font.pixelSize.normal
                                                font.weight: Font.Medium
                                                color: Appearance.colors.colPrimary
                                            }

                                            StyledText {
                                                text: "Devices, connections & settings"
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                color: Appearance.colors.colSubtext
                                                opacity: 0.9
                                                wrapMode: Text.WordWrap
                                                Layout.fillWidth: true
                                            }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }

                            // Footer with close button
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                // Close button
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 48
                                    radius: Appearance.rounding.normal
                                    color: closeMouseArea.containsMouse ? 
                                           Appearance.colors.colLayer2Hover : 
                                           Appearance.colors.colLayer2
                                    border.width: 1
                                    border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.2)

                                    MouseArea {
                                        id: closeMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            bluetoothRoot.hide();
                                        }
                                    }

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 12

                                        MaterialSymbol {
                                            text: "close"
                                            iconSize: 20
                                            color: Appearance.colors.colOnLayer0
                                        }

                                        StyledText {
                                            text: "Close Bluetooth Settings"
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                            font.weight: Font.Medium
                                            color: Appearance.colors.colOnLayer0
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Content area
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.95)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 40
                            spacing: 32

                            // Page header
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 20

                                Rectangle {
                                    Layout.preferredWidth: 56
                                    Layout.preferredHeight: 56
                                    radius: Appearance.rounding.normal
                                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "bluetooth"
                                        iconSize: 28
                                        color: Appearance.colors.colPrimary
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    StyledText {
                                        text: "Bluetooth Settings"
                                        font.family: Appearance.font.family.title
                                        font.pixelSize: 32
                                        font.weight: Font.Bold
                                        color: Appearance.colors.colOnLayer0
                                    }

                                    StyledText {
                                        text: "Manage your Bluetooth devices and connections"
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        color: Appearance.colors.colSubtext
                                        opacity: 0.9
                                    }
                                }
                            }

                            // Content area with modern scroll view
                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                contentWidth: availableWidth
                                clip: true

                                ScrollBar.vertical: ScrollBar {
                                    policy: ScrollBar.AsNeeded
                                    width: 12
                                    background: Rectangle {
                                        color: "transparent"
                                        radius: 6
                                    }
                                    contentItem: Rectangle {
                                        radius: 6
                                        color: parent.pressed ? 
                                               Appearance.colors.colPrimary :
                                               ColorUtils.transparentize(Appearance.colors.colSubtext, 0.4)
                                    }
                                }

                                // BluetoothConfig {} // Removed, file no longer exists
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "bluetooth"

        function toggle(): void {
            bluetoothLoader.active = !bluetoothLoader.active;
        }

        function close(): void {
            bluetoothLoader.active = false;
        }

        function open(): void {
            bluetoothLoader.active = true;
        }
    }

    GlobalShortcut {
        name: "bluetoothToggle"
        description: qsTr("Toggles bluetooth settings dialog on press")

        onPressed: {
            bluetoothLoader.active = !bluetoothLoader.active;
        }
    }

    GlobalShortcut {
        name: "bluetoothOpen"
        description: qsTr("Opens bluetooth settings dialog on press")

        onPressed: {
            bluetoothLoader.active = true;
        }
    }
} 