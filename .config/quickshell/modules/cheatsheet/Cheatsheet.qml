import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: cheatsheetScope
    
    Variants {
        id: cheatsheetVariants
        model: Quickshell.screens
        
        PanelWindow {
            id: root
            required property var modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
            property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor.id)
            screen: modelData
            visible: GlobalStates.cheatsheetOpen

            WlrLayershell.namespace: "quickshell:cheatsheet"
            WlrLayershell.layer: WlrLayer.Overlay
            color: "transparent"

            mask: Region {
                item: GlobalStates.cheatsheetOpen ? cheatsheetContent : null
            }
            HyprlandWindow.visibleMask: Region {
                item: GlobalStates.cheatsheetOpen ? cheatsheetContent : null
            }

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            // No focus grab - let it stay open until manually closed

            implicitWidth: cheatsheetContent.implicitWidth
            implicitHeight: cheatsheetContent.implicitHeight

            Item {
                id: cheatsheetContent
                visible: GlobalStates.cheatsheetOpen
                anchors.centerIn: parent
                width: Math.min(parent.width - 48, 1400)
                height: Math.min(parent.height - 48, 800)

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        GlobalStates.cheatsheetOpen = false;
                    }
                }

                CheatsheetKeybinds {
                    anchors.fill: parent
                }
            }
        }
    }

    IpcHandler {
        target: "cheatsheet"

        function toggle() {
            GlobalStates.cheatsheetOpen = !GlobalStates.cheatsheetOpen
        }
        function close() {
            GlobalStates.cheatsheetOpen = false
        }
        function open() {
            GlobalStates.cheatsheetOpen = true
        }
    }

    GlobalShortcut {
        name: "cheatsheetToggle"
        description: qsTr("Toggles cheatsheet on press")

        onPressed: {
            GlobalStates.cheatsheetOpen = !GlobalStates.cheatsheetOpen   
        }
    }
}