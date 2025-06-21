import QtQuick
import QtQuick.Effects
import "root:/Data" as Data
import "root:/Widgets/System" as System
import "root:/Widgets/Calendar" as Calendar

// Vertical sidebar
Rectangle {
    id: bar
    
    // Clean bar background
    color: Data.Colors.bgColor
    
    // Workspace indicator at top of bar
    System.NiriWorkspaces {
        id: workspaceIndicator
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            horizontalCenterOffset: Data.Settings.borderWidth / 2
            topMargin: 20
        }
    }

    // Clock widget at bottom of bar
    Calendar.Clock {
        id: clockWidget
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            horizontalCenterOffset: Data.Settings.borderWidth / 2
            bottomMargin: 20
        }
    }
} 