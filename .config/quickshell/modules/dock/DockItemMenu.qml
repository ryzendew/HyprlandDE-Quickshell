import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "root:/modules/common"

Menu {
    id: dockItemMenu
    
    property var appInfo: ({})
    property bool isPinned: false
    
    // Signal emitted when user wants to pin an app
    signal pinApp()
    
    // Signal emitted when pinning has been processed
    signal pinAppProcessed()
    
    // Signal emitted when user wants to unpin an app
    signal unpinApp()
    
    // Signal emitted when user wants to close an app
    signal closeApp()

    // Menu background styling
    background: Rectangle {
        implicitWidth: 200
        color: Qt.rgba(
            Appearance.colors.colLayer0.r,
            Appearance.colors.colLayer0.g,
            Appearance.colors.colLayer0.b,
            1.0
        )
        radius: Appearance.rounding.small
        
        // Add a subtle border
        border.width: 1
        border.color: Qt.rgba(
            Appearance.colors.colOnLayer0.r,
            Appearance.colors.colOnLayer0.g,
            Appearance.colors.colOnLayer0.b,
            0.1
        )
    }
    
    // Menu items
    MenuItem {
        id: pinMenuItem
        text: isPinned ? qsTr("Unpin from dock") : qsTr("Pin to dock")
        icon.name: isPinned ? "window-unpin" : "window-pin"
        
        contentItem: Text {
            text: pinMenuItem.text
            color: "#ffffff"
            font: pinMenuItem.font
        }
        
        background: Rectangle {
            color: pinMenuItem.highlighted ? Qt.rgba(
                Appearance.colors.colPrimary.r,
                Appearance.colors.colPrimary.g,
                Appearance.colors.colPrimary.b,
                0.2
            ) : "transparent"
            radius: Appearance.rounding.small
        }
        
        onTriggered: {
            console.log("[DOCK DEBUG] Pin/Unpin triggered", isPinned)
            if (isPinned) {
                dockItemMenu.unpinApp()
            } else {
                dockItemMenu.pinApp()
            }
        }
    }
    
    MenuItem {
        id: newInstanceMenuItem
        text: qsTr("Launch new instance")
        icon.name: "window-new"
        
        contentItem: Text {
            text: newInstanceMenuItem.text
            color: "#ffffff"
            font: newInstanceMenuItem.font
        }
        
        background: Rectangle {
            color: newInstanceMenuItem.highlighted ? Qt.rgba(
                Appearance.colors.colPrimary.r,
                Appearance.colors.colPrimary.g,
                Appearance.colors.colPrimary.b,
                0.2
            ) : "transparent"
            radius: Appearance.rounding.small
        }
        
        onTriggered: {
            console.log("[DOCK DEBUG] Launch new instance triggered", appInfo.class)
            // Use the mapped command from desktopIdToCommand if available
            var command = ""
            if (appInfo.class) {
                // Try different variations of the class name
                var classLower = appInfo.class.toLowerCase()
                var classWithDesktop = appInfo.class + ".desktop"
                if (dock.desktopIdToCommand[appInfo.class]) {
                    command = dock.desktopIdToCommand[appInfo.class]
                } else if (dock.desktopIdToCommand[classLower]) {
                    command = dock.desktopIdToCommand[classLower]
                } else if (dock.desktopIdToCommand[classWithDesktop]) {
                    command = dock.desktopIdToCommand[classWithDesktop]
                } else {
                    command = appInfo.command || appInfo.class.toLowerCase()
                }
            }
            console.log("Launching new instance with command:", command)
            Hyprland.dispatch(`exec ${command}`)
        }
    }
    
    MenuSeparator {
        contentItem: Rectangle {
            implicitWidth: 200
            implicitHeight: 1
            color: Qt.rgba(
                Appearance.colors.colOnLayer0.r,
                Appearance.colors.colOnLayer0.g,
                Appearance.colors.colOnLayer0.b,
                0.1
            )
        }
    }
    
    MenuItem {
        id: moveToWorkspaceMenuItem
        text: qsTr("Move to workspace")
        icon.name: "window-move"
        
        contentItem: Text {
            text: moveToWorkspaceMenuItem.text
            color: "#ffffff"
            font: moveToWorkspaceMenuItem.font
        }
        
        background: Rectangle {
            color: moveToWorkspaceMenuItem.highlighted ? Qt.rgba(
                Appearance.colors.colPrimary.r,
                Appearance.colors.colPrimary.g,
                Appearance.colors.colPrimary.b,
                0.2
            ) : "transparent"
            radius: Appearance.rounding.small
        }
        
        onTriggered: {
            console.log("[DOCK DEBUG] Move to workspace triggered", appInfo.address)
            if (appInfo.address) {
                // TODO: Add workspace selection submenu
                // For now just move to next workspace
                Hyprland.dispatch(`movetoworkspace +1,address:${appInfo.address}`)
            }
        }
    }
    
    MenuItem {
        id: floatMenuItem
        text: qsTr("Toggle floating")
        icon.name: "window-float"
        
        contentItem: Text {
            text: floatMenuItem.text
            color: "#ffffff"
            font: floatMenuItem.font
        }
        
        background: Rectangle {
            color: floatMenuItem.highlighted ? Qt.rgba(
                Appearance.colors.colPrimary.r,
                Appearance.colors.colPrimary.g,
                Appearance.colors.colPrimary.b,
                0.2
            ) : "transparent"
            radius: Appearance.rounding.small
        }
        
        onTriggered: {
            console.log("[DOCK DEBUG] Toggle floating triggered", appInfo.address)
            if (appInfo.address) {
                Hyprland.dispatch(`togglefloating address:${appInfo.address}`)
            }
        }
    }
    
    MenuSeparator {
        contentItem: Rectangle {
            implicitWidth: 200
            implicitHeight: 1
            color: Qt.rgba(
                Appearance.colors.colOnLayer0.r,
                Appearance.colors.colOnLayer0.g,
                Appearance.colors.colOnLayer0.b,
                0.1
            )
        }
    }
    
    MenuItem {
        id: closeMenuItem
        text: qsTr("Close")
        icon.name: "window-close"
        
        contentItem: Text {
            text: closeMenuItem.text
            color: "#ff4444"  // Keep close button text red
            font: closeMenuItem.font
        }
        
        background: Rectangle {
            color: closeMenuItem.highlighted ? Qt.rgba(
                Appearance.colors.colError.r,
                Appearance.colors.colError.g,
                Appearance.colors.colError.b,
                0.2
            ) : "transparent"
            radius: Appearance.rounding.small
        }
        
        onTriggered: {
            console.log("[DOCK DEBUG] Close triggered", appInfo.address, appInfo.pid, appInfo.class)
            if (appInfo.address) {
                Hyprland.dispatch(`closewindow address:${appInfo.address}`)
            } else if (appInfo.pid) {
                Hyprland.dispatch(`closewindow pid:${appInfo.pid}`)
            } else {
                Hyprland.dispatch(`closewindow class:${appInfo.class}`)
            }
            dockItemMenu.closeApp()
        }
    }
}
