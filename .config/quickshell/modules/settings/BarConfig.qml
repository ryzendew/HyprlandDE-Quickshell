import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/services/"
import "root:/modules/common/"
import "root:/modules/common/widgets/"
import "root:/modules/common/functions/color_utils.js" as ColorUtils

ColumnLayout {
    spacing: 24
    anchors.left: parent ? parent.left : undefined
    anchors.leftMargin: 40

    // Bar Configuration Section
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: childrenRect.height + 40
        Layout.topMargin: 16
        Layout.bottomMargin: 16
        radius: Appearance.rounding.large
        color: Appearance.colors.colLayer1
        border.width: 2
        border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.4)

        ColumnLayout {
            anchors.left: parent.left
            anchors.leftMargin: 40
            anchors.right: undefined
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 24

            // Section header
            RowLayout {
                spacing: 16
                Layout.topMargin: 24

                Rectangle {
                    width: 40; height: 40
                    radius: Appearance.rounding.normal
                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "view_agenda"
                        iconSize: 20
                        color: "#000"
                    }
                }
                ColumnLayout {
                    spacing: 4
                    StyledText {
                        text: "Top Bar"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Bold
                        color: "#fff"
                    }
                    StyledText {
                        text: "Configure the main panel appearance and behavior"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: "#fff"
                        opacity: 0.9
                    }
                }
            }

            // Bar appearance settings
            ColumnLayout {
                spacing: 16
                anchors.left: parent.left
                anchors.leftMargin: 0

                StyledText {
                    text: "Appearance"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: "#fff"
                }

                RowLayout {
                    spacing: 24
                    RowLayout {
                        spacing: 12
                        ConfigSwitch {
                            checked: Config.options.bar.showBackground ?? true
                            onCheckedChanged: { ConfigLoader.setConfigValue("bar.showBackground", checked); }
                        }
                        StyledText {
                            text: "Show background"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: "#fff"
                        }
                    }
                    RowLayout {
                        spacing: 12
                        ConfigSwitch {
                            checked: Config.options.bar.borderless ?? false
                            onCheckedChanged: { ConfigLoader.setConfigValue("bar.borderless", checked); }
                        }
                        StyledText {
                            text: "Borderless mode"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: "#fff"
                        }
                    }
                }
                GridLayout {
                    columns: 2
                    columnSpacing: 24
                    rowSpacing: 12
                    Layout.fillWidth: true

                    StyledText { text: "Bar height"; font.pixelSize: Appearance.font.pixelSize.normal; color: "#fff" }
                    ConfigSpinBox {
                        value: Config.options.bar.height ?? 40
                        from: 24
                        to: 120
                        stepSize: 2
                        onValueChanged: { ConfigLoader.setConfigValue("bar.height", value); }
                    }

                    StyledText { text: "Icon size"; font.pixelSize: Appearance.font.pixelSize.normal; color: "#fff" }
                    ConfigSpinBox {
                        value: Config.options.bar.iconSize ?? 24
                        from: 12
                        to: 64
                        stepSize: 2
                        onValueChanged: { ConfigLoader.setConfigValue("bar.iconSize", value); }
                    }

                    StyledText { text: "Workspace icon size"; font.pixelSize: Appearance.font.pixelSize.normal; color: "#fff" }
                    ConfigSpinBox {
                        value: Config.options.bar.workspaceIconSize ?? 24
                        from: 12
                        to: 64
                        stepSize: 2
                        onValueChanged: { ConfigLoader.setConfigValue("bar.workspaceIconSize", value); }
                    }

                    StyledText { text: "Indicator icon size"; font.pixelSize: Appearance.font.pixelSize.normal; color: "#fff" }
                    ConfigSpinBox {
                        value: Config.options.bar.indicatorIconSize ?? 24
                        from: 12
                        to: 64
                        stepSize: 2
                        onValueChanged: { ConfigLoader.setConfigValue("bar.indicatorIconSize", value); }
                    }

                    StyledText { text: "Systray icon size"; font.pixelSize: Appearance.font.pixelSize.normal; color: "#fff" }
                    ConfigSpinBox {
                        value: Config.options.bar.systrayIconSize ?? 24
                        from: 12
                        to: 64
                        stepSize: 2
                        onValueChanged: { ConfigLoader.setConfigValue("bar.systrayIconSize", value); }
                    }

                    StyledText { text: "Logo icon size"; font.pixelSize: Appearance.font.pixelSize.normal; color: "#fff" }
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
                spacing: 8
                StyledText {
                    text: "Transparency"
                    font.pixelSize: Appearance.font.pixelSize.normal
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
                Item { width: 8 }
                StyledText {
                    text: `${Math.round((Config.options.bar.transparency ?? 0.55) * 100)}%`
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: "#fff"
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // Workspaces settings (only number of workspaces)
            ColumnLayout {
                spacing: 16
                anchors.left: parent.left
                anchors.leftMargin: 0

                StyledText {
                    text: "Workspaces"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: "#fff"
                }

                RowLayout {
                    spacing: 12
                    StyledText {
                        text: "Number of workspaces:"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: "#fff"
                    }
                    ConfigSpinBox {
                        from: 1
                        to: 20
                        value: Config.options.bar.workspaces?.shown ?? 10
                        onValueChanged: { ConfigLoader.setConfigValue("bar.workspaces.shown", value); }
                    }
                }
            }

            // Weather toggle
            ColumnLayout {
                spacing: 16
                anchors.left: parent.left
                anchors.leftMargin: 0

                StyledText {
                    text: "Weather Widget"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: "#fff"
                }

                RowLayout {
                    spacing: 12
                    ConfigSwitch {
                        checked: ConfigOptions.bar.weather.enable
                        onCheckedChanged: { ConfigLoader.setConfigValue("bar.weather.enable", checked); }
                    }
                    StyledText {
                        text: "Show weather in bar"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: "#fff"
                    }
                }

                StyledText {
                    text: "Display current weather conditions in the top bar"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: "#fff"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                }
            }

            Layout.bottomMargin: 24
        }
    }
} 