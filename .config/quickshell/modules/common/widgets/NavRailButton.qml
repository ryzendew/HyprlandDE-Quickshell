import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

Button {
    id: button

    property bool toggled
    property string buttonIcon
    property string buttonText

    Layout.alignment: Qt.AlignHCenter
    implicitHeight: columnLayout.implicitHeight
    implicitWidth: columnLayout.implicitWidth

    background: null
    PointingHandInteraction {}

    // Real stuff
    ColumnLayout {
        id: columnLayout
        spacing: 5
        Rectangle {
            width: 62
            implicitHeight: navRailButtonIcon.height + 2 * 2
            Layout.alignment: Qt.AlignHCenter
            radius: Appearance.rounding.full
            color: toggled ? 
                (button.down ? Qt.rgba(Appearance.colors.colSecondaryContainerActive.r, Appearance.colors.colSecondaryContainerActive.g, Appearance.colors.colSecondaryContainerActive.b, 0.8) : 
                 button.hovered ? Qt.rgba(Appearance.colors.colSecondaryContainerHover.r, Appearance.colors.colSecondaryContainerHover.g, Appearance.colors.colSecondaryContainerHover.b, 0.8) : 
                 Qt.rgba(Appearance.m3colors.m3secondaryContainer.r, Appearance.m3colors.m3secondaryContainer.g, Appearance.m3colors.m3secondaryContainer.b, 0.8)) :
                (button.down ? Qt.rgba(Appearance.colors.colLayer1Active.r, Appearance.colors.colLayer1Active.g, Appearance.colors.colLayer1Active.b, 0.8) : 
                 button.hovered ? Qt.rgba(Appearance.colors.colLayer1Hover.r, Appearance.colors.colLayer1Hover.g, Appearance.colors.colLayer1Hover.b, 0.8) : 
                 Qt.rgba(Appearance.colors.colLayer1Hover.r, Appearance.colors.colLayer1Hover.g, Appearance.colors.colLayer1Hover.b, 0.6))

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
            MaterialSymbol {
                id: navRailButtonIcon
                anchors.centerIn: parent
                iconSize: Appearance.font.pixelSize.hugeass
                fill: toggled ? 1 : 0
                text: buttonIcon
                color: toggled ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer1

                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: buttonText
            color: Appearance.colors.colOnLayer1
        }
    }

}
