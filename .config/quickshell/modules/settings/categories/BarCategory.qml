import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/services/"
import "root:/modules/common/"
import "root:/modules/common/widgets/"
import "root:/modules/common/functions/color_utils.js" as ColorUtils

ColumnLayout {
    spacing: 24 * (root.scaleFactor ?? 1.0)
    anchors.left: parent ? parent.left : undefined
    anchors.leftMargin: 40 * (root.scaleFactor ?? 1.0)

    // Responsive scaling properties
    property real scaleFactor: root.scaleFactor ?? 1.0
    property int baseSectionMargin: 16
    property int baseIconSize: 20
    property int baseSpacing: 12

    // Bar Configuration Section
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: childrenRect.height + (40 * scaleFactor)
        Layout.topMargin: baseSectionMargin * scaleFactor
        Layout.bottomMargin: baseSectionMargin * scaleFactor
        radius: Appearance.rounding.large * scaleFactor
        color: Appearance.colors.colLayer1
        border.width: 2
        border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.4)

        ColumnLayout {
            anchors.left: parent.left
            anchors.leftMargin: 40 * scaleFactor
            anchors.right: undefined
            anchors.top: parent.top
            anchors.margins: baseSectionMargin * scaleFactor
            spacing: 24 * scaleFactor

            // Section header
            RowLayout {
                spacing: 16 * scaleFactor
                Layout.topMargin: 24 * scaleFactor

                Rectangle {
                    width: 40 * scaleFactor; height: 40 * scaleFactor
                    radius: Appearance.rounding.normal * scaleFactor
                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "view_agenda"
                        iconSize: baseIconSize * scaleFactor
                        color: "#000"
                    }
                }
                ColumnLayout {
                    spacing: 4 * scaleFactor
                    StyledText {
                        text: "Top Bar"
                        font.pixelSize: (Appearance.font.pixelSize.large * scaleFactor)
                        font.weight: Font.Bold
                        color: "#fff"
                    }
                    StyledText {
                        text: "Configure the main panel appearance and behavior"
                        font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                        color: "#fff"
                        opacity: 0.9
                    }
                }
            }

            // Bar appearance settings
            ColumnLayout {
                spacing: 16 * scaleFactor
                anchors.left: parent.left
                anchors.leftMargin: 0

                StyledText {
                    text: "Appearance"
                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                    font.weight: Font.Medium
                    color: "#fff"
                }

                RowLayout {
                    spacing: 24 * scaleFactor
                    RowLayout {
                        spacing: baseSpacing * scaleFactor
                        ConfigSwitch {
                            checked: Config.options.bar.showBackground ?? true
                            onCheckedChanged: { ConfigLoader.setConfigValue("bar.showBackground", checked); }
                        }
                        StyledText {
                            text: "Show background"
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                            color: "#fff"
                        }
                    }
                    RowLayout {
                        spacing: baseSpacing * scaleFactor
                        ConfigSwitch {
                            checked: Config.options.bar.borderless ?? false
                            onCheckedChanged: { ConfigLoader.setConfigValue("bar.borderless", checked); }
                        }
                        StyledText {
                            text: "Borderless mode"
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                            color: "#fff"
                        }
                    }
                }
                GridLayout {
                    columns: 2
                    columnSpacing: 24 * scaleFactor
                    rowSpacing: baseSpacing * scaleFactor
                    Layout.fillWidth: true

                    StyledText { text: "Bar height"; font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor); color: "#fff" }
                    ConfigSpinBox {
                        value: Config.options.bar.height ?? 40
                        from: 24
                        to: 120
                        stepSize: 2
                        onValueChanged: { ConfigLoader.setConfigValue("bar.height", value); }
                    }

                    StyledText { text: "Icon size"; font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor); color: "#fff" }
                    ConfigSpinBox {
                        value: Config.options.bar.iconSize ?? 24
                        from: 12
                        to: 64
                        stepSize: 2
                        onValueChanged: { ConfigLoader.setConfigValue("bar.iconSize", value); }
                    }

                    StyledText { text: "Workspace icon size"; font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor); color: "#fff" }
                    ConfigSpinBox {
                        value: Config.options.bar.workspaceIconSize ?? 24
                        from: 12
                        to: 64
                        stepSize: 2
                        onValueChanged: { ConfigLoader.setConfigValue("bar.workspaceIconSize", value); }
                    }

                    StyledText { text: "Indicator icon size"; font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor); color: "#fff" }
                    ConfigSpinBox {
                        value: Config.options.bar.indicatorIconSize ?? 24
                        from: 12
                        to: 64
                        stepSize: 2
                        onValueChanged: { ConfigLoader.setConfigValue("bar.indicatorIconSize", value); }
                    }

                    StyledText { text: "Systray icon size"; font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor); color: "#fff" }
                    ConfigSpinBox {
                        value: Config.options.bar.systrayIconSize ?? 24
                        from: 12
                        to: 64
                        stepSize: 2
                        onValueChanged: { ConfigLoader.setConfigValue("bar.systrayIconSize", value); }
                    }

                    StyledText { text: "Logo icon size"; font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor); color: "#fff" }
                    ConfigSpinBox {
                        value: Config.options.bar.logoIconSize ?? 32
                        from: 12
                        to: 128
                        stepSize: 2
                        onValueChanged: { ConfigLoader.setConfigValue("bar.logoIconSize", value); }
                    }
                }
            }

            // Bar transparency
            RowLayout {
                spacing: 8 * scaleFactor
                StyledText {
                    text: "Transparency"
                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                    color: "#fff"
                }
                StyledSlider {
                    from: 0.0
                    to: 1.0
                    value: Config.options.bar.transparency ?? 0.55
                    stepSize: 0.05
                    onValueChanged: { ConfigLoader.setConfigValue("bar.transparency", value); }
                    Layout.fillWidth: true
                }
                Item { width: 8 * scaleFactor }
                StyledText {
                    text: `${Math.round((Config.options.bar.transparency ?? 0.55) * 100)}%`
                    font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                    color: "#fff"
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // Workspaces settings (only number of workspaces)
            ColumnLayout {
                spacing: 16 * scaleFactor
                anchors.left: parent.left
                anchors.leftMargin: 0

                StyledText {
                    text: "Workspaces"
                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                    font.weight: Font.Medium
                    color: "#fff"
                }

                RowLayout {
                    spacing: baseSpacing * scaleFactor
                    StyledText {
                        text: "Number of workspaces:"
                        font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                        color: "#fff"
                    }
                    ConfigSpinBox {
                        value: Config.options.bar.workspaces ?? 10
                        from: 1
                        to: 20
                        stepSize: 1
                        onValueChanged: { ConfigLoader.setConfigValue("bar.workspaces", value); }
                    }
                }
            }

            // Weather toggle
            ColumnLayout {
                spacing: 16 * scaleFactor
                anchors.left: parent.left
                anchors.leftMargin: 0

                StyledText {
                    text: "Weather Widget"
                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                    font.weight: Font.Medium
                    color: "#fff"
                }

                RowLayout {
                    spacing: baseSpacing * scaleFactor
                    ConfigSwitch {
                        checked: ConfigOptions.bar.weather.enable
                        onCheckedChanged: { ConfigLoader.setConfigValue("bar.weather.enable", checked); }
                    }
                    StyledText {
                        text: "Show weather in bar"
                        font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                        color: "#fff"
                    }
                }

                StyledText {
                    text: "Display current weather conditions in the top bar"
                    font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                    color: "#fff"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.topMargin: 8 * scaleFactor
                }
            }

            Layout.bottomMargin: 24 * scaleFactor
        }
    }
} 