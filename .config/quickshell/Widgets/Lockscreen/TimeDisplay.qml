import QtQuick
import "root:/Data" as Data

// Time and date display
Column {
    id: timeColumn
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.topMargin: 60
    anchors.leftMargin: 60
    spacing: 16
    
    required property bool isVisible
    
    // Subtle slide-left animation (after main slide)
    transform: Translate {
        id: timeTransform
        x: isVisible ? 0 : -100
        Behavior on x {
            SequentialAnimation {
                PauseAnimation { duration: 400 }  // Wait for main slide to be visible
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.OutQuart
                }
            }
        }
    }
    
    opacity: isVisible ? 1.0 : 0.0
    Behavior on opacity {
        SequentialAnimation {
            PauseAnimation { duration: 500 }  // Wait for main slide
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }
        }
    }
    
    // Current time
    Text {
        id: timeText
        font.family: "JetBrains Mono"
        font.pixelSize: 84
        font.weight: Font.ExtraLight
        color: Data.Colors.brightText
        text: Qt.formatTime(new Date(), "hh:mm")
    }
    
    // Current date
    Text {
        id: dateText
        font.family: "JetBrains Mono"
        font.pixelSize: 28
        font.weight: Font.Light
        color: Data.Colors.secondaryText
        text: Qt.formatDate(new Date(), "dddd, MMMM d, yyyy")
    }
    
    // Time update timer
    Timer {
        id: timeTimer
        interval: 1000
        running: isVisible
        repeat: true
        onTriggered: {
            timeText.text = Qt.formatTime(new Date(), "hh:mm")
            dateText.text = Qt.formatDate(new Date(), "dddd, MMMM d, yyyy")
        }
    }
} 