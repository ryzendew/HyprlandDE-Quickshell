import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/Data" as Data
import "root:/Widgets/System" as System
import "root:/Core" as Core
import "root:/Widgets" as Widgets

// Desktop with borders and UI widgets
Scope {
    id: desktop
    
    property var shell

    // Desktop layer per screen
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            
            implicitWidth: Screen.width
            implicitHeight: Screen.height
            color: "transparent"
            exclusiveZone: 0
            
            WlrLayershell.namespace: "quickshell-desktop"

            // Make workspace indicator interactive only
            mask: Region {
                item: workspaceIndicator
            }

            anchors {
                top: true
                left: true
                bottom: true
                right: true
            }

            // Workspace indicator aligned to left border
            System.NiriWorkspaces {
                id: workspaceIndicator
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: Data.Settings.borderWidth
                }
                z: 10
                width: 32
            }

            // Volume OSD aligned to right border (primary screen only)
            System.VolumeOSD {
                id: volumeOsd
                shell: desktop.shell
                visible: modelData === Quickshell.primaryScreen
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    rightMargin: Data.Settings.borderWidth
                }
                z: 10
            }

            // Screen border background layer
            Border {
                id: screenBorder
                anchors.fill: parent
                workspaceIndicator: workspaceIndicator
                volumeOSD: volumeOsd
                clockWidget: clockWidget
                z: -1
            }

            // Clock widget at bottom-left corner
            Widgets.Clock {
                id: clockWidget
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                    bottomMargin: Data.Settings.borderWidth
                    leftMargin: Data.Settings.borderWidth
                }
                z: 10
            }

            // UI overlay layer
            Item {
                id: uiLayer
                anchors.fill: parent
                z: 20

                Core.Version {
                    visible: modelData === Quickshell.primaryScreen
                }
            }
        }
    }

    // Monitor screen configuration changes
    Connections {
        target: Quickshell
        function onScreensChanged() {
            // Handle dynamic screen changes
        }
    }
} 