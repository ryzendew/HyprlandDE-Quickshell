import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

GroupButton {
    id: button
    property string buttonText

    horizontalPadding: 8
    verticalPadding: 6

    baseWidth: contentItem.implicitWidth + horizontalPadding * 2
    clickedWidth: baseWidth + 20
    baseHeight: contentItem.implicitHeight + verticalPadding * 2

    colBackground: Qt.rgba(Appearance.colors.colLayer2.r, Appearance.colors.colLayer2.g, Appearance.colors.colLayer2.b, 0.8)
    colBackgroundHover: Qt.rgba(Appearance.colors.colLayer2Hover.r, Appearance.colors.colLayer2Hover.g, Appearance.colors.colLayer2Hover.b, 0.8)
    colBackgroundActive: Qt.rgba(Appearance.colors.colLayer2Active.r, Appearance.colors.colLayer2Active.g, Appearance.colors.colLayer2Active.b, 0.8)

    contentItem: StyledText {
        horizontalAlignment: Text.AlignHCenter
        text: buttonText
        color: Appearance.m3colors.m3onSurface
    }
}