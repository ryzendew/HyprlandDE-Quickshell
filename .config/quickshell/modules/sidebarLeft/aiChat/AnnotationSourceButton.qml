import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import Qt5Compat.GraphicalEffects
import Qt.labs.platform
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Hyprland

RippleButton {
    id: root
    property string displayText
    property string url

    property real faviconSize: 20
    implicitHeight: 30
    leftPadding: (implicitHeight - faviconSize) / 2
    rightPadding: 10
    buttonRadius: Appearance.rounding.full
    colBackground: Qt.rgba(Appearance.m3colors.m3surfaceContainerHighest.r, Appearance.m3colors.m3surfaceContainerHighest.g, Appearance.m3colors.m3surfaceContainerHighest.b, 0.8)
    colBackgroundHover: Qt.rgba(Appearance.colors.colSurfaceContainerHighestHover.r, Appearance.colors.colSurfaceContainerHighestHover.g, Appearance.colors.colSurfaceContainerHighestHover.b, 0.8)
    colRipple: Qt.rgba(Appearance.colors.colSurfaceContainerHighestActive.r, Appearance.colors.colSurfaceContainerHighestActive.g, Appearance.colors.colSurfaceContainerHighestActive.b, 0.8)

    PointingHandInteraction {}
    onClicked: {
        if (url) {
            Qt.openUrlExternally(url)
            Hyprland.dispatch("global quickshell:sidebarLeftClose")
        }
    }

    contentItem: Item {
        anchors.centerIn: parent
        implicitWidth: rowLayout.implicitWidth
        implicitHeight: rowLayout.implicitHeight
        RowLayout {
            id: rowLayout
            anchors.fill: parent
            spacing: 5
            Favicon {
                url: root.url
                size: root.faviconSize
                displayText: root.displayText
            }
            StyledText {
                id: text
                horizontalAlignment: Text.AlignHCenter
                text: displayText
                color: Appearance.m3colors.m3onSurface
            }
        }
    }
}
