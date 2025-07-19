import "root:/modules/common/"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    property bool sidebarLeftOpen: false
    property bool sidebarRightOpen: false
    property bool overviewOpen: false
    property bool cheatsheetOpen: false
    property bool hyprMenuOpen: false
    property bool windowSwitcherOpen: false
    property bool workspaceShowNumbers: false
    property bool superReleaseMightTrigger: true

    // When user is not reluctant while pressing super, they probably don't need to see workspace numbers
    onSuperReleaseMightTriggerChanged: { 
        workspaceShowNumbersTimer.stop()
    }

    Timer {
        id: workspaceShowNumbersTimer
        interval: ConfigOptions.bar?.workspaces?.showNumberDelay || 500
        // interval: 0
        repeat: false
        onTriggered: {
            workspaceShowNumbers = true
        }
    }

    GlobalShortcut {
        name: "workspaceNumber"
        description: qsTr("Hold to show workspace numbers, release to show icons")

        onPressed: {
            workspaceShowNumbersTimer.start()
        }
        onReleased: {
            workspaceShowNumbersTimer.stop()
            workspaceShowNumbers = false
        }
    }

    GlobalShortcut {
        name: "windowClose"
        description: qsTr("Close active window")

        onPressed: {
            Hyprland.dispatch("killactive")
        }
    }

    GlobalShortcut {
        name: "hyprmenu"
        description: qsTr("Open application menu")

        onPressed: {
            hyprMenuOpen = !hyprMenuOpen
        }
    }
}