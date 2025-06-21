import QtQuick
import QtQuick.Controls
import Quickshell
import "root:/Data" as Data
import "root:/Core" as Core

// Clock with border integration
Item {
    id: clockRoot
    width: clockBackground.width
    height: clockBackground.height

    Rectangle {
        id: clockBackground
        width: clockText.implicitWidth + 24
        height: 32
        
        color: Data.Colors.bgColor
        
        // Right-side radius for positioning
        topRightRadius: height / 2

        Text {
            id: clockText
            anchors.centerIn: parent
            font.family: "JetBrains Mono"
            font.pixelSize: 14
            font.bold: true
            color: Data.Colors.accentColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: Qt.formatTime(new Date(), "HH:mm")
        }
    }

    // Update every minute
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: clockText.text = Qt.formatTime(new Date(), "HH:mm")
    }

    // Border integration corners
    Core.Corners {
        id: topLeftCorner
        position: "topleft"
        size: 1.3
        fillColor: Data.Colors.bgColor
        offsetX: -39
        offsetY: -26
    }
        Core.Corners {
        id: topLeftCorner2
        position: "topleft"
        size: 1.3
        fillColor: Data.Colors.bgColor
        offsetX: 25
        offsetY: 6
    }
}