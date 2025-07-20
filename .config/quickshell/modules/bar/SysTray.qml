import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

// TODO: More fancy animation
Item {
    id: root

    required property var bar

    height: parent.height
    implicitWidth: rowLayout.implicitWidth
    Layout.leftMargin: Appearance.rounding.screenRounding

    RowLayout {
        id: rowLayout

        anchors.fill: parent
        spacing: 15

        Repeater {
            model: SystemTray.items

            SysTrayItem {
                required property SystemTrayItem modelData

                bar: root.bar
                item: modelData
                systrayWidget: root
            }

        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colSubtext
            text: "•"
            visible: {
                SystemTray.items.values.length > 0
            }
            
            layer.enabled: true
            layer.smooth: true
            
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 2
                radius: 4.0
                samples: 9
                color: Qt.rgba(0, 0, 0, 0.3)
            }
        }

    }

}
