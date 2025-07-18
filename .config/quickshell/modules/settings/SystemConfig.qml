import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Hyprland
import "root:/services/"
import "root:/modules/common/"
import "root:/modules/common/widgets/"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import "root:/modules/common/functions/file_utils.js" as FileUtils

ColumnLayout {
    id: systemTab
    spacing: 24 * (root.scaleFactor ?? 1.0)

    // Responsive scaling properties
    property real scaleFactor: root.scaleFactor ?? 1.0
    property int baseTabHeight: 56
    property int baseTabWidth: 240
    property int baseIconSize: 16
    property int baseSpacing: 10

    // Horizontal tab navigation with responsive sizing
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: baseTabHeight * scaleFactor
        radius: Appearance.rounding.large * scaleFactor
        color: Appearance.colors.colLayer1
        border.width: 1
        border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.12)

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8 * scaleFactor
            spacing: 12 * scaleFactor

            Repeater {
                model: [
                    { "id": "services", "title": "Services", "icon": "settings", "subtitle": "Audio, battery & networking" },
                    { "id": "time", "title": "Time & Date", "icon": "schedule", "subtitle": "Timezone, format & display" },
                    { "id": "keyboard", "title": "Keyboard", "icon": "keyboard", "subtitle": "Layout, repeat rate & accessibility" }
                ]

                delegate: Rectangle {
                    Layout.preferredWidth: baseTabWidth * scaleFactor
                    Layout.fillHeight: true
                    radius: Appearance.rounding.normal * scaleFactor
                    color: systemTab.selectedSubTab === modelData.id ? Appearance.colors.colPrimaryContainer : "transparent"
                    border.width: systemTab.selectedSubTab === modelData.id ? 2 : 0
                    border.color: Appearance.colors.colPrimary
                    z: systemTab.selectedSubTab === modelData.id ? 1 : 0
                    antialiasing: true
                    opacity: subTabMouseArea.containsMouse || systemTab.selectedSubTab === modelData.id ? 1.0 : 0.85
                    
                    MouseArea {
                        id: subTabMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: systemTab.selectedSubTab = modelData.id
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: baseSpacing * scaleFactor
                        spacing: baseSpacing * scaleFactor

                        Rectangle {
                            Layout.preferredWidth: 28 * scaleFactor
                            Layout.preferredHeight: 28 * scaleFactor
                            radius: 8 * scaleFactor
                            color: systemTab.selectedSubTab === modelData.id ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colPrimary, 0.08)
                            anchors.verticalCenter: parent.verticalCenter
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: modelData.icon
                                iconSize: baseIconSize * scaleFactor
                                color: systemTab.selectedSubTab === modelData.id ? "#000" : Appearance.colors.colPrimary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            anchors.verticalCenter: parent.verticalCenter

                            StyledText {
                                text: modelData.title
                                font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                                font.weight: Font.Medium
                                color: systemTab.selectedSubTab === modelData.id ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                            }

                            StyledText {
                                text: modelData.subtitle
                                font.pixelSize: (Appearance.font.pixelSize.smaller * scaleFactor)
                                color: Appearance.colors.colSubtext
                                opacity: systemTab.selectedSubTab === modelData.id ? 0.9 : 0.6
                                visible: true
                            }
                        }
                    }
                }
            }
        }
    }

    // Content area
    Loader {
        Layout.fillWidth: true
        Layout.fillHeight: true
        sourceComponent: {
            switch(systemTab.selectedSubTab) {
                case "services": return servicesComponent;
                case "time": return timeComponent;
                case "keyboard": return keyboardComponent;
                default: return servicesComponent;
            }
        }
    }

    // Sub-components
    Component { id: servicesComponent; ServicesConfig {} }
    Component { id: timeComponent; TimeConfig {} }
    Component { id: keyboardComponent; KeyboardConfig {} }

    property string selectedSubTab: "services"
} 