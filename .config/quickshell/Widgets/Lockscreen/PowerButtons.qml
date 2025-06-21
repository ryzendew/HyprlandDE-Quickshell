import QtQuick
import "root:/Data" as Data

// Reboot and shutdown buttons positioned at bottom right
Row {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: 40
    spacing: 16
    
    required property bool isVisible
    
    signal rebootRequested()
    signal shutdownRequested()
    
    // Fade in with delay
    opacity: isVisible ? 1.0 : 0.0
    Behavior on opacity {
        SequentialAnimation {
            PauseAnimation { duration: 900 }  // Wait for most elements to appear
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }
        }
    }
    
    // Reboot button
    Rectangle {
        width: 45
        height: 45
        radius: 22
        color: rebootMouseArea.containsMouse ? Data.Colors.withOpacity(Data.Colors.secondaryText, 0.3) : Data.Colors.withOpacity(Data.Colors.secondaryText, 0.2)
        border.color: Data.Colors.withOpacity(Data.Colors.secondaryText, 0.6)
        border.width: 1
        
        Text {
            anchors.centerIn: parent
            text: "restart_alt"
            font.family: "Material Symbols Outlined"
            font.pixelSize: 20
            color: Data.Colors.secondaryText
        }
        
        MouseArea {
            id: rebootMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: rebootRequested()
        }
        
        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }
    
    // Shutdown button
    Rectangle {
        width: 45
        height: 45
        radius: 22
        color: shutdownMouseArea.containsMouse ? Data.Colors.withOpacity(Data.Colors.secondaryText, 0.3) : Data.Colors.withOpacity(Data.Colors.secondaryText, 0.2)
        border.color: Data.Colors.withOpacity(Data.Colors.secondaryText, 0.6)
        border.width: 1
        
        Text {
            anchors.centerIn: parent
            text: "power_settings_new"
            font.family: "Material Symbols Outlined"
            font.pixelSize: 18
            color: Data.Colors.secondaryText
        }
        
        MouseArea {
            id: shutdownMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: shutdownRequested()
        }
        
        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }
} 