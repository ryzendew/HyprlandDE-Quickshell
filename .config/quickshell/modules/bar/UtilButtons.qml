import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Rectangle {
    id: root
    property bool borderless: ConfigOptions.bar?.borderless || false
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: 32
    color: borderless ? "transparent" : Appearance.colors.colLayer1
    radius: Appearance.rounding.small

    RowLayout {
        id: rowLayout

        spacing: 4
        anchors.centerIn: parent

        CircleUtilButton {
            Layout.alignment: Qt.AlignVCenter
            visible: ConfigOptions.bar?.utilButtons?.showScreenSnip || false
            onClicked: Hyprland.dispatch("exec hyprshot --freeze --clipboard-only --mode region --silent")

            MaterialSymbol {
                horizontalAlignment: Qt.AlignHCenter
                fill: 1
                text: "screenshot_region"
                iconSize: ConfigOptions.getIconSize()
                color: Appearance.colors.colOnLayer2
            }

        }

        CircleUtilButton {
            Layout.alignment: Qt.AlignVCenter
            visible: ConfigOptions.bar?.utilButtons?.showColorPicker || false
            onClicked: Hyprland.dispatch("exec hyprpicker -a")

            MaterialSymbol {
                horizontalAlignment: Qt.AlignHCenter
                fill: 1
                text: "colorize"
                iconSize: ConfigOptions.getIconSize()
                color: Appearance.colors.colOnLayer2
            }

        }

        CircleUtilButton {
            Layout.alignment: Qt.AlignVCenter
            visible: ConfigOptions.bar?.utilButtons?.showKeyboardToggle || false
            onClicked: Hyprland.dispatch("global quickshell:oskToggle")

            MaterialSymbol {
                horizontalAlignment: Qt.AlignHCenter
                fill: 0
                text: "keyboard"
                iconSize: ConfigOptions.getIconSize()
                color: Appearance.colors.colOnLayer2
            }

        }

        CircleUtilButton {
            Layout.alignment: Qt.AlignVCenter
            visible: ConfigOptions.bar?.utilButtons?.showMicToggle || false
            onClicked: Hyprland.dispatch("global quickshell:micToggle")

            MaterialSymbol {
                horizontalAlignment: Qt.AlignHCenter
                fill: 0
                text: "mic"
                iconSize: ConfigOptions.getIconSize()
                color: Appearance.colors.colOnLayer2
            }

        }

        CircleUtilButton {
            Layout.alignment: Qt.AlignVCenter
            visible: ConfigOptions.bar?.utilButtons?.showDarkModeToggle || false
            onClicked: Hyprland.dispatch("global quickshell:toggleDarkMode")

            MaterialSymbol {
                horizontalAlignment: Qt.AlignHCenter
                fill: 0
                text: "dark_mode"
                iconSize: ConfigOptions.getIconSize()
                color: Appearance.colors.colOnLayer2
            }

        }

    }

}
