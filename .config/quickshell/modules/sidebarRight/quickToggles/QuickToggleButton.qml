import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Controls
import Quickshell.Io

Button {
    id: button

    property bool toggled
    property string buttonIcon
    property bool hasRightClickAction: false
    property real buttonSize: hasRightClickAction ? 48 : 40

    implicitWidth: buttonSize
    implicitHeight: buttonSize

    // Scale animation for press feedback
    transform: Scale {
        id: buttonScale
        origin.x: button.width / 2
        origin.y: button.height / 2
        xScale: button.down ? 0.92 : 1.0
        yScale: button.down ? 0.92 : 1.0
        Behavior on xScale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
        Behavior on yScale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
    }

    PointingHandInteraction {}

    background: Rectangle {
        anchors.fill: parent
        radius: hasRightClickAction ? Appearance.rounding.medium : Appearance.rounding.full
        color: toggled ? 
            (button.down ? Qt.rgba(0.90, 0.22, 0.21, 1.0) : // #e53935
             button.hovered ? Qt.rgba(0.90, 0.22, 0.21, 0.85) : 
             Qt.rgba(0.90, 0.22, 0.21, 0.95)) :
            (button.down ? Qt.rgba(Appearance.colors.colLayer1Active.r, Appearance.colors.colLayer1Active.g, Appearance.colors.colLayer1Active.b, 0.8) : 
             button.hovered ? Qt.rgba(Appearance.colors.colLayer1Hover.r, Appearance.colors.colLayer1Hover.g, Appearance.colors.colLayer1Hover.b, 0.8) : 
             Qt.rgba(Appearance.colors.colLayer1.r, Appearance.colors.colLayer1.g, Appearance.colors.colLayer1.b, 0.8))

        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
            }
        }
        
        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: hasRightClickAction ? Appearance.font.pixelSize.huge : Appearance.font.pixelSize.larger
            fill: toggled ? 1 : 0
            text: buttonIcon
            color: toggled ? "#FFFFFF" : "#B0B0B0"

            Behavior on color {
                ColorAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: if (hasRightClickAction && mouse.button === Qt.RightButton) button.rightClicked()
    }

    signal rightClicked()
}
