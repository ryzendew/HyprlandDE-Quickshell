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

    // Policies Section
    // REMOVE: Content Policies card/section and all related controls

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
                anchors.left: parent.left
                anchors.leftMargin: 0
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

            // Bar appearance
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

                GridLayout {
                    columns: 2
                    columnSpacing: 32
                    rowSpacing: 16
                    anchors.left: parent.left
                    anchors.leftMargin: 0

                    RowLayout {
                        spacing: 12
                ConfigSwitch {
                    checked: Config.options.bar.borderless
                            onCheckedChanged: { Config.options.bar.borderless = checked; }
                        }
                        StyledText {
                            text: "Borderless"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: "#fff"
                        }
                    }

                    RowLayout {
                        spacing: 12
                ConfigSwitch {
                    checked: Config.options.bar.showBackground
                            onCheckedChanged: { Config.options.bar.showBackground = checked; }
                        }
                        StyledText {
                            text: "Show background"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: "#fff"
                        }
                    }
                }
            }

            // Utility buttons
            ColumnLayout {
                spacing: 16
                anchors.left: parent.left
                anchors.leftMargin: 0

                StyledText {
                    text: "Utility Buttons"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: "#fff"
                }

                RowLayout {
                    spacing: 24
                    RowLayout {
                        spacing: 12
                ConfigSwitch {
                    checked: Config.options.bar.utilButtons.showScreenSnip
                            onCheckedChanged: { Config.options.bar.utilButtons.showScreenSnip = checked; }
                        }
                        StyledText {
                            text: "Screen capture"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: "#fff"
                        }
                    }
                    RowLayout {
                        spacing: 12
                        ConfigSwitch {
                            checked: Config.options.bar.utilButtons.showColorPicker
                            onCheckedChanged: { Config.options.bar.utilButtons.showColorPicker = checked; }
                        }
                        StyledText {
                    text: "Color picker"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: "#fff"
                        }
                    }
                }
                RowLayout {
                    spacing: 24
                    RowLayout {
                        spacing: 12
                ConfigSwitch {
                            checked: Config.options.bar.utilButtons.showMicToggle
                            onCheckedChanged: { Config.options.bar.utilButtons.showMicToggle = checked; }
                        }
                        StyledText {
                            text: "Microphone toggle"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: "#fff"
                        }
                    }
                    RowLayout {
                        spacing: 12
                ConfigSwitch {
                            checked: Config.options.bar.utilButtons.showKeyboardToggle
                            onCheckedChanged: { Config.options.bar.utilButtons.showKeyboardToggle = checked; }
                        }
                        StyledText {
                            text: "Virtual keyboard"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: "#fff"
                        }
                    }
                }
                RowLayout {
                    spacing: 24
                    RowLayout {
                        spacing: 12
                ConfigSwitch {
                            checked: Config.options.bar.utilButtons.showDarkModeToggle
                            onCheckedChanged: { Config.options.bar.utilButtons.showDarkModeToggle = checked; }
                        }
                        StyledText {
                            text: "Theme toggle"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: "#fff"
                        }
                    }
                }
            }

            // Workspaces
            ColumnLayout {
                spacing: 16
                anchors.left: parent.left
                anchors.leftMargin: 0

                RowLayout {
                    spacing: 12
                    StyledText {
                        text: "Workspaces"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: "#fff"
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 24; height: 24
                        radius: 12
                        color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "help"
                            iconSize: 14
                            color: "#000"
                        }

                        StyledToolTip {
                            content: "Tip: Hide icons and always show numbers for\nthe classic illogical-impulse experience"
                        }
                    }
                }

                GridLayout {
                    columns: 2
                    columnSpacing: 32
                    rowSpacing: 16
                    anchors.left: parent.left
                    anchors.leftMargin: 0

                    RowLayout {
                        spacing: 12
                ConfigSwitch {
                    checked: Config.options.bar.workspaces.showAppIcons
                            onCheckedChanged: { Config.options.bar.workspaces.showAppIcons = checked; }
                        }
                        StyledText {
                            text: "Show app icons"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: "#fff"
                        }
                    }

                    RowLayout {
                        spacing: 12
                ConfigSwitch {
                    checked: Config.options.bar.workspaces.alwaysShowNumbers
                            onCheckedChanged: { Config.options.bar.workspaces.alwaysShowNumbers = checked; }
                        }
                        StyledText {
                            text: "Always show numbers"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: "#fff"
                        }
                    }
                }

                StyledText {
                    text: "Workspaces shown"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: "#fff"
            }
            ConfigSpinBox {
                text: "Workspaces shown"
                value: Config.options.bar.workspaces.shown
                from: 1
                to: 30
                stepSize: 1
                    onValueChanged: { Config.options.bar.workspaces.shown = value; }
                }
            }

            // Weather
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
                        onCheckedChanged: { ConfigOptions.bar.weather.enable = checked; }
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
        }
    }

    // Battery & Power Section
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
                anchors.left: parent.left
                anchors.leftMargin: 0
                Layout.topMargin: 24

                Rectangle {
                    width: 40; height: 40
                    radius: Appearance.rounding.normal
                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "battery_std"
                        iconSize: 20
                        color: "#000"
                    }
                }
                ColumnLayout {
                    spacing: 4
                    StyledText {
                        text: "Battery & Power"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Bold
                        color: "#fff"
                    }
                    StyledText {
                        text: "Manage power settings and battery behavior"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: "#fff"
                        opacity: 0.9
                    }
                }
            }

            // Battery settings
            RowLayout {
                spacing: 12
                ConfigSwitch {
                    checked: ConfigOptions.battery.automaticSuspend
                    onCheckedChanged: { ConfigOptions.battery.automaticSuspend = checked; }
                }
                StyledText {
                    text: "Automatic suspend when battery is low"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: "#fff"
                }
            }

            StyledText {
                text: "Automatically suspend the system when battery level becomes critically low"
                font.pixelSize: Appearance.font.pixelSize.small
                color: "#fff"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.topMargin: 8
            }
        }
    }

    // Dock & Overview Section
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
                anchors.left: parent.left
                anchors.leftMargin: 0
                Layout.topMargin: 24

                Rectangle {
                    width: 40; height: 40
                    radius: Appearance.rounding.normal
                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "dock"
                        iconSize: 20
                        color: "#000"
                    }
                }
                ColumnLayout {
                    spacing: 4
                    StyledText {
                        text: "Dock & Overview"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Bold
                        color: "#fff"
                    }
                    StyledText {
                        text: "Configure application dock and window overview"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: "#fff"
                        opacity: 0.9
                    }
                }
            }

            // Dock settings
            ColumnLayout {
                spacing: 16
                anchors.left: parent.left
                anchors.leftMargin: 0

                RowLayout {
                    spacing: 12
                    ConfigSwitch {
                        checked: ConfigOptions.dock.enable
                        onCheckedChanged: { ConfigOptions.dock.enable = checked; }
                    }
                    StyledText {
                        text: "Enable dock"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: "#fff"
                    }
                }

                StyledText {
                    text: "Show a dock for quick access to frequently used applications"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: "#fff"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                }
            }

            // Overview settings
            ColumnLayout {
                spacing: 16
                anchors.left: parent.left
                anchors.leftMargin: 0

                StyledText {
                    text: "Overview Layout"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: "#fff"
                }

                GridLayout {
                    columns: 2
                    columnSpacing: 24
                    rowSpacing: 16
                    anchors.left: parent.left
                    anchors.leftMargin: 0

                    ConfigSpinBox {
                        text: "Rows"
                        value: ConfigOptions.overview.rows
                        from: 1
                        to: 10
                        stepSize: 1
                        onValueChanged: { ConfigOptions.overview.rows = value; }
                    }

                    ConfigSpinBox {
                        text: "Columns"
                        value: ConfigOptions.overview.columns
                        from: 1
                        to: 10
                        stepSize: 1
                        onValueChanged: { ConfigOptions.overview.columns = value; }
                    }

                    ColumnLayout {
                        spacing: 8
                        StyledText {
                            text: "Scale"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: "#fff"
                        }
                        StyledSlider {
                            from: 0.05
                            to: 0.5
                            value: ConfigOptions.overview.scale
                            stepSize: 0.01
                            onValueChanged: { ConfigOptions.overview.scale = value; }
                        }
                        StyledText {
                            text: `${Math.round(ConfigOptions.overview.scale * 100)}%`
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: "#fff"
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    RowLayout {
                        spacing: 12
                        ConfigSwitch {
                            checked: ConfigOptions.overview.showXwaylandIndicator
                            onCheckedChanged: { ConfigOptions.overview.showXwaylandIndicator = checked; }
                        }
                        StyledText {
                            text: "Show Xwayland indicator"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: "#fff"
                        }
                    }
                }

                StyledText {
                    text: "Configure the grid layout for the window overview screen"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: "#fff"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                }
            }
        }
    }

    // Spacer at bottom
    Item {
        Layout.fillHeight: true
        Layout.minimumHeight: 32
    }
}
