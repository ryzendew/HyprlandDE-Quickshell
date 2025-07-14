import "root:/modules/common/"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

MouseArea {
    id: root

    required property var bar
    required property SystemTrayItem item
    required property var systrayWidget
    property bool targetMenuOpen: false
    property int trayItemWidth: ConfigOptions.getSystrayIconSize()

    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    Layout.fillHeight: true
    implicitWidth: trayItemWidth
    implicitHeight: trayItemWidth
    hoverEnabled: true
    
    onClicked: function(mouse) {
        if (mouse.button === Qt.LeftButton) {
            item.activate()
        } else if (mouse.button === Qt.RightButton) {
            if (item.hasMenu) {
                menu.open()
            }
        } else if (mouse.button === Qt.MiddleButton) {
            item.secondaryActivate()
        }
    }
    
    onWheel: function(wheel) {
        item.scroll(wheel.angleDelta.x, wheel.angleDelta.y)
    }

    QsMenuAnchor {
        id: menu

        menu: root.item.menu
        anchor.window: bar
        // Try calculating the full position by walking up the hierarchy
        anchor.rect.x: {
            var totalX = root.x + systrayWidget.x
            var currentItem = systrayWidget.parent
            while (currentItem && currentItem !== bar) {
                totalX += currentItem.x
                currentItem = currentItem.parent
            }
            return totalX
        }
        anchor.rect.y: {
            var totalY = root.y + systrayWidget.y
            var currentItem = systrayWidget.parent
            while (currentItem && currentItem !== bar) {
                totalY += currentItem.y
                currentItem = currentItem.parent
            }
            return totalY
        }
        anchor.rect.width: root.width
        anchor.rect.height: root.height
        anchor.edges: Edges.Bottom
    }

    IconImage {
        id: trayIcon
        visible: true // There's already color overlay
        source: root.item.icon
        anchors.centerIn: parent
        width: trayItemWidth
        height: trayItemWidth
    }

}
