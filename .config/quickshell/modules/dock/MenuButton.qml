import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "root:/modules/common"

Button {
    id: button
    property string buttonText
    
    implicitHeight: 45
    leftPadding: 15
    rightPadding: 15
    
    enabled: true
    
    background: Rectangle {
        id: buttonBackground
        
        // Use a computed property that explicitly defines the target color
        readonly property color targetColor: {
            if (button.down && button.enabled) {
                return Qt.rgba(
            Appearance.colors.colPrimary.r,
            Appearance.colors.colPrimary.g,
            Appearance.colors.colPrimary.b,
            0.2
                )
            } else if (button.hovered && button.enabled) {
                return Qt.rgba(
            Appearance.colors.colPrimary.r,
            Appearance.colors.colPrimary.g,
            Appearance.colors.colPrimary.b,
            0.1
                )
            } else {
                return "transparent"
            }
        }
        
        color: targetColor
        radius: Appearance.rounding.small
        
        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
            }
        }
    }
    
    contentItem: Text {
        id: buttonText
        text: button.buttonText
        
        // Use a computed property for text color as well
        readonly property color targetTextColor: {
            if (button.enabled) {
                return Appearance.colors.colOnLayer0
            } else {
                return Qt.rgba(
            Appearance.colors.colOnLayer0.r,
            Appearance.colors.colOnLayer0.g,
            Appearance.colors.colOnLayer0.b,
            0.5
        )
            }
        }
        
        color: targetTextColor
        font: button.font
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        
        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
            }
        }
    }
    
    PointingHandInteraction {}
} 