import QtQuick
import Quickshell
import Quickshell.Wayland
import QtQuick.Layouts
import QtQuick.Shapes
import "root:/Data/" as Data
import "root:/Core" as Core

// Volume OSD with slide animation
Item {
    id: volumeOsd
    property var shell
    
    // Size and visibility
    width: osdBackground.width
    height: osdBackground.height
    visible: false
    
    // Auto-hide timer (2.5 seconds of inactivity)
    Timer {
        id: hideTimer
        interval: 2500
        onTriggered: hideOsd()
    }
    
    property int lastVolume: -1
    
    // Monitor volume changes from shell and trigger OSD
    Connections {
        target: shell
        function onVolumeChanged() {
            if (shell.volume !== lastVolume && lastVolume !== -1) {
                showOsd()
            }
            lastVolume = shell.volume
        }
    }
    
    Component.onCompleted: {
        // Initialize lastVolume on startup
        if (shell && shell.volume !== undefined) {
            lastVolume = shell.volume
        }
    }
    
    // Show OSD
    function showOsd() {
        if (!volumeOsd.visible) {
            volumeOsd.visible = true
            slideInAnimation.start()
        }
        hideTimer.restart()
    }
    
    // Start slide-out animation to hide OSD
    function hideOsd() {
        slideOutAnimation.start()
    }
    
    // Slide in from right edge
    NumberAnimation {
        id: slideInAnimation
        target: osdBackground
        property: "x"
        from: volumeOsd.width
        to: 0
        duration: 300
        easing.type: Easing.OutCubic
    }
    
    // Slide out to right edge
    NumberAnimation {
        id: slideOutAnimation
        target: osdBackground
        property: "x"
        from: 0
        to: volumeOsd.width
        duration: 250
        easing.type: Easing.InCubic
        onFinished: {
            volumeOsd.visible = false
            osdBackground.x = 0  // Reset position
        }
    }
    
    Rectangle {
        id: osdBackground
        width: 45
        height: 250
        color: Data.Colors.bgColor
        topLeftRadius: 20
        bottomLeftRadius: 20
        
        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12
            
            // Dynamic volume icon
            Text {
                id: volumeIcon
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
                color: Data.Colors.fgColor
                text: {
                    if (!shell || shell.volume === undefined) return "󰝟"
                    var vol = shell.volume
                    if (vol === 0) return "󰝟"      // Muted
                    else if (vol < 33) return "󰕿"  // Low
                    else if (vol < 66) return "󰖀"  // Medium
                    else return "󰕾"               // High
                }
                anchors.horizontalCenter: parent.horizontalCenter
                
                // Scale animation on volume change
                Behavior on text {
                    SequentialAnimation {
                        PropertyAnimation { target: volumeIcon; property: "scale"; to: 1.2; duration: 100 }
                        PropertyAnimation { target: volumeIcon; property: "scale"; to: 1.0; duration: 100 }
                    }
                }
            }
            
            // Vertical volume bar
            Rectangle {
                width: 10
                height: parent.height - volumeIcon.height - volumeLabel.height - 36
                radius: 5
                color: Qt.darker(Data.Colors.accentColor, 1.5)
                border.color: Qt.darker(Data.Colors.accentColor, 2.0)
                border.width: 1
                anchors.horizontalCenter: parent.horizontalCenter
                
                // Animated volume fill indicator
                Rectangle {
                    id: volumeFill
                    width: parent.width - 2
                    radius: parent.radius - 1
                    x: 1
                    color: Data.Colors.accentColor
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 1
                    height: {
                        if (!shell || shell.volume === undefined) return 0
                        var maxHeight = parent.height - 2
                        return maxHeight * Math.max(0, Math.min(1, shell.volume / 100))
                    }
                    Behavior on height {
                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                    }
                }
            }
            
            // Volume percentage text
            Text {
                id: volumeLabel
                text: (shell && shell.volume !== undefined ? shell.volume + "%" : "0%")
                font.pixelSize: 10
                font.weight: Font.Bold
                color: Data.Colors.fgColor
                anchors.horizontalCenter: parent.horizontalCenter
                
                // Fade animation on volume change
                Behavior on text {
                    PropertyAnimation { target: volumeLabel; property: "opacity"; from: 0.7; to: 1.0; duration: 150 }
                }
            }
        }
    }

    Core.Corners {
        id: bottomRightCorner
        position: "bottomright"
        size: 1.3
        fillColor: Data.Colors.bgColor
        offsetX: 39 + osdBackground.x
        offsetY: 78
    }

    Core.Corners {
        id: topRightCorner
        position: "topright"
        size: 1.3
        fillColor: Data.Colors.bgColor
        offsetX: 39 + osdBackground.x
        offsetY: -26
    }
}
