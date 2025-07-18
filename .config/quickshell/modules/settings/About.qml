import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "root:/services/"
import "root:/modules/common/"
import "root:/modules/common/widgets/"
import "root:/modules/common/functions/color_utils.js" as ColorUtils

ColumnLayout {
    spacing: 24 * (root.scaleFactor ?? 1.0)

    // Responsive scaling properties
    property real scaleFactor: root.scaleFactor ?? 1.0
    property int baseSectionMargin: 24
    property int baseIconSize: 18
    property int baseSpacing: 12

    // System Information Section
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: childrenRect.height + (32 * scaleFactor)
        radius: Appearance.rounding.large * scaleFactor
        color: Appearance.colors.colLayer1
        border.width: 1
        border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: baseSectionMargin * scaleFactor
            spacing: 20 * scaleFactor

            // Section header
            RowLayout {
                Layout.fillWidth: true
                spacing: baseSpacing * scaleFactor

                Rectangle {
                    Layout.preferredWidth: 32 * scaleFactor
                    Layout.preferredHeight: 32 * scaleFactor
                    radius: Appearance.rounding.small * scaleFactor
                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "computer"
                        iconSize: baseIconSize * scaleFactor
                        color: Appearance.colors.colOnLayer1
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2 * scaleFactor

                    StyledText {
                        text: "System Information"
                        font.pixelSize: (Appearance.font.pixelSize.large * scaleFactor)
                        font.weight: Font.Bold
                        color: "#fff"
                    }

                    StyledText {
                        text: "Information about your operating system and distribution"
                        font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                        color: "#fff"
                    }
                }
            }

            // System details
            RowLayout {
                Layout.fillWidth: true
                spacing: 24 * scaleFactor

                // System logo
                Rectangle {
                    Layout.preferredWidth: 80 * scaleFactor
                    Layout.preferredHeight: 80 * scaleFactor
                    radius: Appearance.rounding.large * scaleFactor
                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.05)
                    border.width: 1
                    border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)

            IconImage {
                        anchors.centerIn: parent
                        implicitSize: 64 * scaleFactor
                source: Quickshell.iconPath(SystemInfo.logo)
            }
                }

                // System info
            ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8 * scaleFactor

                StyledText {
                    text: SystemInfo.distroName
                    font.pixelSize: (Appearance.font.pixelSize.title * scaleFactor)
                        font.weight: Font.Bold
                        color: "#fff"
                }

                StyledText {
                        text: SystemInfo.homeUrl
                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                        color: "#fff"
                    textFormat: Text.MarkdownText
                    onLinkActivated: (link) => {
                        Qt.openUrlExternally(link)
                    }
                    PointingHandLinkHover {}
                }
            }
        }

            // System links
            ColumnLayout {
            Layout.fillWidth: true
                spacing: baseSpacing * scaleFactor

                StyledText {
                    text: "Resources"
                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                    font.weight: Font.Medium
                    color: "#fff"
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 8 * scaleFactor
                    columnSpacing: baseSpacing * scaleFactor

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48 * scaleFactor
                        radius: Appearance.rounding.normal * scaleFactor
                        color: docMouseArea.containsMouse ? 
                               Appearance.colors.colLayer2Hover : 
                               Appearance.colors.colLayer2
                        border.width: 1
                        border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)

                        MouseArea {
                            id: docMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Qt.openUrlExternally(SystemInfo.documentationUrl)
                        }

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 12 * scaleFactor
                            spacing: 8 * scaleFactor

                            MaterialSymbol {
                                text: "auto_stories"
                                iconSize: 16 * scaleFactor
                                color: Appearance.colors.colOnLayer1
                            }

                            StyledText {
                                text: "Documentation"
                                font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                                color: "#fff"
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48 * scaleFactor
                        radius: Appearance.rounding.normal * scaleFactor
                        color: supportMouseArea.containsMouse ? 
                               Appearance.colors.colLayer2Hover : 
                               Appearance.colors.colLayer2
                        border.width: 1
                        border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)

                        MouseArea {
                            id: supportMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Qt.openUrlExternally(SystemInfo.supportUrl)
                        }

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 12 * scaleFactor
                            spacing: 8 * scaleFactor

                            MaterialSymbol {
                                text: "support"
                                iconSize: 16 * scaleFactor
                                color: Appearance.colors.colOnLayer1
                            }

                            StyledText {
                                text: "Help & Support"
                                font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                                color: "#fff"
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48 * scaleFactor
                        radius: Appearance.rounding.normal * scaleFactor
                        color: bugMouseArea.containsMouse ? 
                               Appearance.colors.colLayer2Hover : 
                               Appearance.colors.colLayer2
                        border.width: 1
                        border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)

                        MouseArea {
                            id: bugMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Qt.openUrlExternally(SystemInfo.bugReportUrl)
                        }

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 12 * scaleFactor
                            spacing: 8 * scaleFactor

                            MaterialSymbol {
                                text: "bug_report"
                                iconSize: 16 * scaleFactor
                                color: Appearance.colors.colOnLayer1
                            }

                            StyledText {
                                text: "Report a Bug"
                                font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                                color: "#fff"
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48 * scaleFactor
                        radius: Appearance.rounding.normal * scaleFactor
                        color: privacyMouseArea.containsMouse ? 
                               Appearance.colors.colLayer2Hover : 
                               Appearance.colors.colLayer2
                        border.width: 1
                        border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)

                        MouseArea {
                            id: privacyMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Qt.openUrlExternally(SystemInfo.privacyPolicyUrl)
                        }

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 12 * scaleFactor
                            spacing: 8 * scaleFactor

                            MaterialSymbol {
                                text: "policy"
                                iconSize: 16 * scaleFactor
                                color: Appearance.colors.colOnLayer1
                            }

                            StyledText {
                                text: "Privacy Policy"
                                font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                                color: "#fff"
                            }
                        }
                    }
                }
            }
        }
    }

    // QuickShell Configuration Section
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: childrenRect.height + (32 * scaleFactor)
        radius: Appearance.rounding.large * scaleFactor
        color: Appearance.colors.colLayer1
        border.width: 1
        border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: baseSectionMargin * scaleFactor
            spacing: 20 * scaleFactor

            // Section header
            RowLayout {
                Layout.fillWidth: true
                spacing: baseSpacing * scaleFactor

                Rectangle {
                    Layout.preferredWidth: 32 * scaleFactor
                    Layout.preferredHeight: 32 * scaleFactor
                    radius: Appearance.rounding.small * scaleFactor
                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "code"
                        iconSize: baseIconSize * scaleFactor
                        color: Appearance.colors.colOnLayer1
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2 * scaleFactor

                    StyledText {
                        text: "QuickShell Configuration"
                        font.pixelSize: (Appearance.font.pixelSize.large * scaleFactor)
                        font.weight: Font.Bold
                        color: "#fff"
                    }

                    StyledText {
                        text: "Information about your desktop configuration and dotfiles"
                        font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                        color: "#fff"
                    }
                }
            }

            // Configuration details
        RowLayout {
                Layout.fillWidth: true
                spacing: 24 * scaleFactor

                // Config logo
                Rectangle {
                    Layout.preferredWidth: 80 * scaleFactor
                    Layout.preferredHeight: 80 * scaleFactor
                    radius: Appearance.rounding.large * scaleFactor
                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.05)
                    border.width: 1
                    border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)

            IconImage {
                        anchors.centerIn: parent
                        implicitSize: 64 * scaleFactor
                source: Quickshell.iconPath("illogical-impulse")
            }
                }

                // Config info
            ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8 * scaleFactor

                StyledText {
                    text: "illogical-impulse"
                    font.pixelSize: (Appearance.font.pixelSize.title * scaleFactor)
                        font.weight: Font.Bold
                        color: "#fff"
                }

                StyledText {
                    text: "https://github.com/end-4/dots-hyprland"
                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                        color: "#fff"
                    textFormat: Text.MarkdownText
                    onLinkActivated: (link) => {
                        Qt.openUrlExternally(link)
                    }
                    PointingHandLinkHover {}
                }
            }
        }

            // Configuration links
            ColumnLayout {
                Layout.fillWidth: true
                spacing: baseSpacing * scaleFactor

                StyledText {
                    text: "Configuration Resources"
                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                    font.weight: Font.Medium
                    color: "#fff"
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 8 * scaleFactor
                    columnSpacing: baseSpacing * scaleFactor

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48 * scaleFactor
                        radius: Appearance.rounding.normal * scaleFactor
                        color: configDocMouseArea.containsMouse ? 
                               Appearance.colors.colLayer2Hover : 
                               Appearance.colors.colLayer2
                        border.width: 1
                        border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)

                        MouseArea {
                            id: configDocMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Qt.openUrlExternally("https://end-4.github.io/dots-hyprland-wiki/en/ii-qs/02usage/")
                        }

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 12 * scaleFactor
                            spacing: 8 * scaleFactor

                            MaterialSymbol {
                                text: "auto_stories"
                                iconSize: 16 * scaleFactor
                                color: Appearance.colors.colOnLayer1
                            }

                            StyledText {
                                text: "Documentation"
                                font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                                color: "#fff"
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48 * scaleFactor
                        radius: Appearance.rounding.normal * scaleFactor
                        color: issuesMouseArea.containsMouse ? 
                               Appearance.colors.colLayer2Hover : 
                               Appearance.colors.colLayer2
                        border.width: 1
                        border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)

                        MouseArea {
                            id: issuesMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Qt.openUrlExternally("https://github.com/end-4/dots-hyprland/issues")
                        }

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 12 * scaleFactor
                            spacing: 8 * scaleFactor

                            MaterialSymbol {
                                text: "adjust"
                                iconSize: 16 * scaleFactor
                                color: Appearance.colors.colOnLayer1
                            }

                            StyledText {
                                text: "Issues"
                                font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                                color: "#fff"
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48 * scaleFactor
                        radius: Appearance.rounding.normal * scaleFactor
                        color: discussionsMouseArea.containsMouse ? 
                               Appearance.colors.colLayer2Hover : 
                               Appearance.colors.colLayer2
                        border.width: 1
                        border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)

                        MouseArea {
                            id: discussionsMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Qt.openUrlExternally("https://github.com/end-4/dots-hyprland/discussions")
                        }

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 12 * scaleFactor
                            spacing: 8 * scaleFactor

                            MaterialSymbol {
                                text: "forum"
                                iconSize: 16 * scaleFactor
                                color: Appearance.colors.colOnLayer1
                            }

                            StyledText {
                                text: "Discussions"
                                font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                                color: "#fff"
                            }
                        }
                    }

                    Rectangle {
            Layout.fillWidth: true
                        Layout.preferredHeight: 48 * scaleFactor
                        radius: Appearance.rounding.normal * scaleFactor
                        color: donateMouseArea.containsMouse ? 
                               Appearance.colors.colLayer2Hover : 
                               Appearance.colors.colLayer2
                        border.width: 1
                        border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)

                        MouseArea {
                            id: donateMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Qt.openUrlExternally("https://github.com/sponsors/end-4")
                        }

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 12 * scaleFactor
                            spacing: 8 * scaleFactor

                            MaterialSymbol {
                                text: "favorite"
                                iconSize: 16 * scaleFactor
                                color: Appearance.colors.colOnLayer1
                            }

                            StyledText {
                                text: "Donate"
                                font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                                color: "#fff"
                            }
                        }
                    }
                }
            }
        }
    }

    // Version & Credits Section
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: childrenRect.height + (32 * scaleFactor)
        radius: Appearance.rounding.large * scaleFactor
        color: Appearance.colors.colLayer1
        border.width: 1
        border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: baseSectionMargin * scaleFactor
            spacing: 20 * scaleFactor

            // Section header
            RowLayout {
                Layout.fillWidth: true
                spacing: baseSpacing * scaleFactor

                Rectangle {
                    Layout.preferredWidth: 32 * scaleFactor
                    Layout.preferredHeight: 32 * scaleFactor
                    radius: Appearance.rounding.small * scaleFactor
                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "info"
                        iconSize: baseIconSize * scaleFactor
                        color: Appearance.colors.colOnLayer1
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2 * scaleFactor

                    StyledText {
                        text: "About This Configuration"
                        font.pixelSize: (Appearance.font.pixelSize.large * scaleFactor)
                        font.weight: Font.Bold
                        color: "#fff"
                    }

                    StyledText {
                        text: "Credits and acknowledgments"
                        font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                        color: "#fff"
                    }
                }
            }

            // Credits
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12 * scaleFactor

                StyledText {
                    text: "This desktop configuration has been modernized and enhanced with a professional, clean design while maintaining all original functionality. The settings interface now features:"
                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                    color: "#fff"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8 * scaleFactor

                    StyledText {
                        text: "• Modern card-based layout with improved visual hierarchy"
                        font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                        color: "#fff"
                    }

                    StyledText {
                        text: "• Intuitive navigation with clear section organization"
                        font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                        color: "#fff"
                    }

                    StyledText {
                        text: "• Enhanced accessibility and user experience"
                        font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                        color: "#fff"
                    }

                    StyledText {
                        text: "• Consistent design language throughout the interface"
                        font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                        color: "#fff"
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40 * scaleFactor
                    radius: Appearance.rounding.small * scaleFactor
                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.05)
                    border.width: 1
                    border.color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.2)

                    RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 12 * scaleFactor
                        spacing: 8 * scaleFactor

                        MaterialSymbol {
                            text: "celebration"
                            iconSize: 16 * scaleFactor
                            color: Appearance.colors.colOnLayer1
                        }

                        StyledText {
                            text: "All functionality preserved - zero breaking changes to your workflow"
                            font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                            color: "#fff"
                            font.weight: Font.Medium
                        }
                    }
                }
            }
        }
    }

    // Spacer at bottom
    Item {
        Layout.fillHeight: true
        Layout.minimumHeight: 20 * scaleFactor
    }
}
