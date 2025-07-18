import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils

ColumnLayout {
    id: appsTab
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
                    { "id": "defaultApps", "title": "Default Apps", "icon": "apps", "subtitle": "Browser, terminal & handlers" }
                ]

                delegate: Rectangle {
                    Layout.preferredWidth: baseTabWidth * scaleFactor
                    Layout.fillHeight: true
                    radius: Appearance.rounding.normal * scaleFactor
                    color: appsTab.selectedSubTab === modelData.id ? Appearance.colors.colPrimaryContainer : "transparent"
                    border.width: appsTab.selectedSubTab === modelData.id ? 2 : 0
                    border.color: Appearance.colors.colPrimary
                    z: appsTab.selectedSubTab === modelData.id ? 1 : 0
                    antialiasing: true
                    opacity: subTabMouseArea.containsMouse || appsTab.selectedSubTab === modelData.id ? 1.0 : 0.85
                    
                    MouseArea {
                        id: subTabMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: appsTab.selectedSubTab = modelData.id
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: baseSpacing * scaleFactor
                        spacing: baseSpacing * scaleFactor

                        Rectangle {
                            Layout.preferredWidth: 28 * scaleFactor
                            Layout.preferredHeight: 28 * scaleFactor
                            radius: 8 * scaleFactor
                            color: appsTab.selectedSubTab === modelData.id ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colPrimary, 0.08)
                            anchors.verticalCenter: parent.verticalCenter
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: modelData.icon
                                iconSize: baseIconSize * scaleFactor
                                color: appsTab.selectedSubTab === modelData.id ? "#000" : Appearance.colors.colPrimary
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
                                color: appsTab.selectedSubTab === modelData.id ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                            }

                            StyledText {
                                text: modelData.subtitle
                                font.pixelSize: (Appearance.font.pixelSize.smaller * scaleFactor)
                                color: Appearance.colors.colSubtext
                                opacity: appsTab.selectedSubTab === modelData.id ? 0.9 : 0.6
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
            switch(appsTab.selectedSubTab) {
                case "defaultApps": return defaultAppsComponent;
                default: return defaultAppsComponent;
            }
        }
    }

    // Default Apps tab content
    Component {
        id: defaultAppsComponent
        ColumnLayout {
            spacing: 32 * scaleFactor
            Layout.fillWidth: true

            // Header
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8 * scaleFactor

                StyledText {
                    text: "Default Applications"
                    font.pixelSize: (Appearance.font.pixelSize.large * scaleFactor)
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer0
                }

                StyledText {
                    text: "Choose which applications are used by default for common tasks and file types."
                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            // Card container for app rows
            Rectangle {
                Layout.fillWidth: true
                radius: Appearance.rounding.large * scaleFactor
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.10)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.leftMargin: 0
                anchors.rightMargin: 0
                anchors.margins: 0
                // Padding inside the card
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 32 * scaleFactor
                    spacing: 24 * scaleFactor

                    property var appRows: [
                        { icon: "language", label: "Web", model: ["firefox", "chromium", "brave", "vivaldi", "google-chrome", "custom..."] },
                        { icon: "mail", label: "Mail", model: ["thunderbird", "geary", "evolution", "mailspring", "custom..."] },
                        { icon: "event", label: "Calendar", model: ["gnome-calendar", "korganizer", "evolution", "custom..."] },
                        { icon: "music_note", label: "Music", model: ["rhythmbox", "lollypop", "clementine", "custom..."] },
                        { icon: "movie", label: "Video", model: ["vlc", "mpv", "totem", "custom..."] },
                        { icon: "photo", label: "Photos", model: ["shotwell", "gthumb", "eog", "custom..."] },
                        { icon: "edit", label: "Text Editor", model: ["code", "sublime_text", "gedit", "mousepad", "leafpad", "custom..."] },
                        { icon: "folder", label: "File Manager", model: ["nautilus", "dolphin", "thunar", "pcmanfm", "nemo", "custom..."] }
                    ]

                    Repeater {
                        model: parent.appRows
                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: 18 * scaleFactor
                            // Icon
                            Rectangle {
                                Layout.preferredWidth: 32 * scaleFactor
                                Layout.preferredHeight: 32 * scaleFactor
                                radius: 8 * scaleFactor
                                color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.12)
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: model.icon
                                    iconSize: 18 * scaleFactor
                                    color: Appearance.colors.colPrimary
                                }
                            }
                            // Label
                            StyledText {
                                text: model.label
                                font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer0
                                Layout.preferredWidth: 140 * scaleFactor
                                verticalAlignment: Text.AlignVCenter
                            }
                            // ComboBox (dark themed)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 44 * scaleFactor
                                radius: Appearance.rounding.normal * scaleFactor
                                color: Appearance.colors.colLayer2
                                border.width: 1
                                border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.18)
                                ComboBox {
                                    anchors.fill: parent
                                    anchors.margins: 4 * scaleFactor
                                    model: model.model
                                    currentIndex: 0
                                    font.pixelSize: Appearance.font.pixelSize.normal * scaleFactor
                                    // color: Appearance.colors.colOnLayer0 (removed)
                                    background: Rectangle {
                                        color: "transparent"
                                    }
                                    contentItem: Text {
                                        text: control.displayText
                                        color: Appearance.colors.colOnLayer0
                                        font.pixelSize: Appearance.font.pixelSize.normal * scaleFactor
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                    }
                                    onCurrentIndexChanged: {
                                        // TODO: Save to config
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Add Custom button
            Rectangle {
                Layout.preferredHeight: 40 * scaleFactor
                Layout.fillWidth: true
                radius: Appearance.rounding.normal * scaleFactor
                color: Appearance.colors.colPrimaryContainer
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.2)
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        // TODO: Add custom handler logic
                    }
                }
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8 * scaleFactor
                    MaterialSymbol { text: "add"; color: Appearance.colors.colPrimary; iconSize: 18 * scaleFactor }
                    StyledText {
                        text: "+ Add Custom"
                        font.pixelSize: Appearance.font.pixelSize.normal * scaleFactor
                        font.weight: Font.Medium
                        color: Appearance.colors.colPrimary
                    }
                }
            }
        }
    }

    property string selectedSubTab: "defaultApps"
} 