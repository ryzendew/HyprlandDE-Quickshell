import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland

import "root:/Core" as Core
import "root:/Widgets/Notifications" as Notifications
import "root:/Widgets/System" as System
import "root:/Data" as Data
import "root:/Widgets/Panel" as TopPanel
import "root:/Widgets/Panel" as WidgetsBar
import "root:/Widgets/ControlPanel" as ControlPanel

// Multi-monitor shell window manager
Scope {
    id: shellWindows

    property var shell
    property var notificationService
    property var notificationWindow: null

    // Wallpaper layer - one per screen
    Variants {
        model: Quickshell.screens
        Core.Wallpaper {
            required property var modelData
            screen: modelData
        }
    }

    // Global notification window on primary screen
    PanelWindow {
        id: primaryNotificationWindow
        screen: Quickshell.primaryScreen || Quickshell.screens[0]
        anchors.top: true
        anchors.right: true
        margins.right: 0
        margins.top: 0
        implicitWidth: 420
        implicitHeight: Math.max(notificationPopup.calculatedHeight, 1)
        color: "transparent"
        visible: false
        
        WlrLayershell.namespace: "quickshell-notifications"

        Component.onCompleted: {
            if (screen) {
                shellWindows.notificationWindow = primaryNotificationWindow
            }
        }

        Notifications.Notification {
            id: notificationPopup
            anchors.fill: parent
            shell: shellWindows.shell
            notificationServer: shellWindows.notificationService ? shellWindows.notificationService.notificationServer : null
            visible: true

            onNotificationQueueChanged: {
                // Show/hide window based on notification queue
                primaryNotificationWindow.visible = notificationQueue.length > 0
            }
        }
    }

    // Global volume OSD
    System.VolumeOSD {
        shell: shellWindows.shell
    }

    // Shell overlay layer - one per screen
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: shellWindow
            required property var modelData

            screen: modelData
            
            implicitWidth: Screen.width
            implicitHeight: Screen.height
            color: "transparent"
            exclusiveZone: 0
            
            WlrLayershell.namespace: "quickshell-shell"

            mask: Region {}

            anchors {
                top: true
                left: true
                bottom: true
                right: true
            }

            // Version info on primary screen only
            Core.Version {
                visible: shellWindow.screen === Quickshell.primaryScreen
            }

            // Control panel on all screens
            ControlPanel.ControlPanel {
                shell: shellWindows.shell
            }
        }
    }
}
