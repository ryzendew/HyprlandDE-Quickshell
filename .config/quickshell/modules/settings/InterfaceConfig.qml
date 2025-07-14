import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/services/"
import "root:/modules/common/"
import "root:/modules/common/widgets/"
import "root:/modules/common/functions/color_utils.js" as ColorUtils

ColumnLayout {
    clip: false
    spacing: 24
    anchors.left: parent ? parent.left : undefined
    anchors.leftMargin: 40

    // Policies Section
    // REMOVE: Content Policies card/section and all related controls

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
                    onCheckedChanged: { ConfigLoader.setConfigValue("battery.automaticSuspend", checked); }
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

        // Overview Section
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
                        text: "grid_view"
                        iconSize: 20
                        color: "#000"
                    }
                }
                ColumnLayout {
                    spacing: 4
                    StyledText {
                        text: "Overview Layout"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Bold
                        color: "#fff"
                    }
                    StyledText {
                        text: "Configure window overview grid layout"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: "#fff"
                        opacity: 0.9
                    }
                }
            }

            // Overview settings
            ColumnLayout {
                spacing: 16
                anchors.left: parent.left
                anchors.leftMargin: 0

                GridLayout {
                    columns: 2
                    columnSpacing: 24
                    rowSpacing: 16
                    // anchors.left: parent.left
                    // anchors.leftMargin: 0

            ConfigSpinBox {
                text: "Rows"
                        value: ConfigOptions.overview.rows
                from: 1
                        to: 10
                stepSize: 1
                        onValueChanged: { ConfigLoader.setConfigValue("overview.rows", value); }
                }

            ConfigSpinBox {
                text: "Columns"
                        value: ConfigOptions.overview.columns
                from: 1
                        to: 10
                stepSize: 1
                        onValueChanged: { ConfigLoader.setConfigValue("overview.columns", value); }
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
                            onValueChanged: { ConfigLoader.setConfigValue("overview.scale", value); }
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
                            onCheckedChanged: { ConfigLoader.setConfigValue("overview.showXwaylandIndicator", checked); }
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
