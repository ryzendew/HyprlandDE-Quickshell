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
    property int trayItemWidth: Appearance.font.pixelSize.larger

    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    Layout.fillHeight: true
    implicitWidth: trayItemWidth
    hoverEnabled: true
    
    onClicked: function(mouse) {
        if (mouse.button === Qt.LeftButton) {
            item.activate()
        } else if (mouse.button === Qt.RightButton) {
            if (item.hasMenu) {
                // Debug logging
                console.log("=== SYSTRAY MENU DEBUG ===")
                console.log("root.x:", root.x, "root.y:", root.y)
                console.log("systrayWidget.x:", systrayWidget.x, "systrayWidget.y:", systrayWidget.y)
                console.log("systrayWidget.parent.x:", systrayWidget.parent?.x, "systrayWidget.parent.y:", systrayWidget.parent?.y)
                console.log("systrayWidget.parent.parent.x:", systrayWidget.parent?.parent?.x, "systrayWidget.parent.parent.y:", systrayWidget.parent?.parent?.y)
                console.log("calculated x:", root.x + systrayWidget.x)
                console.log("calculated y:", root.y + systrayWidget.y)
                
                // Try to find the actual position by walking up the hierarchy
                var totalX = root.x + systrayWidget.x
                var totalY = root.y + systrayWidget.y
                var currentItem = systrayWidget.parent
                while (currentItem && currentItem !== bar) {
                    console.log("Adding parent coords:", currentItem.x, currentItem.y)
                    totalX += currentItem.x
                    totalY += currentItem.y
                    currentItem = currentItem.parent
                }
                console.log("Total calculated position:", totalX, totalY)
                
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
        width: parent.width
        height: parent.height
    }

}
