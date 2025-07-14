import "root:/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Rectangle {
    id: root
    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        spacing: 32

        // Dock Settings Section
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
                            text: "Dock Settings"
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.weight: Font.Bold
                            color: "#fff"
                        }
                        StyledText {
                            text: "Configure application dock appearance and behavior"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: "#fff"
                            opacity: 0.9
                        }
                    }
                }

                // Dock enable/disable
                ColumnLayout {
                    spacing: 16
                    anchors.left: parent.left
                    anchors.leftMargin: 0

                    RowLayout {
                        spacing: 12
                        ConfigSwitch {
                            checked: ConfigOptions.dock.enable
                            onCheckedChanged: {
                                // console.log("[DOCK SETTINGS] Enable dock toggled to:", checked)
                                // console.log("[DOCK SETTINGS] ConfigOptions.dock.enable before:", ConfigOptions.dock.enable)
                                ConfigLoader.setConfigValueAndSave("dock.enable", checked);
                                // console.log("[DOCK SETTINGS] ConfigOptions.dock.enable after:", ConfigOptions.dock.enable)
                            }
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

                    // Dock appearance settings
                    ColumnLayout {
                        spacing: 12
                        Layout.topMargin: 16

                        StyledText {
                            text: "Appearance"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: "#fff"
                        }

                        GridLayout {
                            columns: 2
                            columnSpacing: 24
                            rowSpacing: 16

                            ConfigSpinBox {
                                text: "Height"
                                value: ConfigOptions.dock.height
                                from: 40
                                to: 120
                                stepSize: 1
                                onValueChanged: { ConfigLoader.setConfigValue("dock.height", value); }
                            }

                            ConfigSpinBox {
                                text: "Icon Size"
                                value: ConfigOptions.dock.iconSize
                                from: 24
                                to: 80
                                stepSize: 4
                                onValueChanged: { ConfigLoader.setConfigValue("dock.iconSize", value); }
                            }

                            ConfigSpinBox {
                                text: "Radius"
                                value: ConfigOptions.dock.radius
                                from: 0
                                to: 30
                                stepSize: 2
                                onValueChanged: { ConfigLoader.setConfigValue("dock.radius", value); }
                            }

                            ConfigSpinBox {
                                text: "Spacing"
                                value: ConfigOptions.dock.spacing
                                from: 0
                                to: 20
                                stepSize: 2
                                onValueChanged: { ConfigLoader.setConfigValue("dock.spacing", value); }
                            }

                            ConfigSpinBox {
                                text: "Hover Region Height"
                                value: ConfigOptions.dock.hoverRegionHeight
                                from: 1
                                to: 20
                                stepSize: 1
                                onValueChanged: { ConfigLoader.setConfigValue("dock.hoverRegionHeight", value); }
                            }

                            ColumnLayout {
                                spacing: 8
                                StyledText {
                                    text: "Transparency"
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: "#fff"
                                }
                                StyledSlider {
                                    from: 0.0
                                    to: 1.0
                                    value: ConfigOptions.dock.transparency
                                    stepSize: 0.05
                                    onValueChanged: { ConfigLoader.setConfigValue("dock.transparency", value); }
                                }
                                StyledText {
                                    text: `${Math.round(ConfigOptions.dock.transparency * 100)}%`
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: "#fff"
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }

                    // Dock behavior settings
                    ColumnLayout {
                        spacing: 12
                        Layout.topMargin: 16

                        StyledText {
                            text: "Behavior"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: "#fff"
                        }

                        RowLayout {
                            spacing: 12
                            ConfigSwitch {
                                checked: ConfigOptions.dock.autoHide
                                onCheckedChanged: { ConfigLoader.setConfigValue("dock.autoHide", checked); }
                            }
                            StyledText {
                                text: "Auto-hide dock"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: "#fff"
                            }
                        }

                        RowLayout {
                            spacing: 12
                            ConfigSwitch {
                                checked: ConfigOptions.dock.hoverToReveal
                                onCheckedChanged: { ConfigLoader.setConfigValue("dock.hoverToReveal", checked); }
                            }
                            StyledText {
                                text: "Reveal on hover"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: "#fff"
                            }
                        }

                        RowLayout {
                            spacing: 12
                            ConfigSwitch {
                                checked: ConfigOptions.dock.showPreviews
                                onCheckedChanged: { ConfigLoader.setConfigValue("dock.showPreviews", checked); }
                            }
                            StyledText {
                                text: "Show window previews"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: "#fff"
                            }
                        }

                        RowLayout {
                            spacing: 12
                            ConfigSwitch {
                                checked: ConfigOptions.dock.showLabels
                                onCheckedChanged: { ConfigLoader.setConfigValue("dock.showLabels", checked); }
                            }
                            StyledText {
                                text: "Show app labels"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: "#fff"
                            }
                        }

                        RowLayout {
                            spacing: 12
                            ConfigSwitch {
                                checked: ConfigOptions.dock.pinnedOnStartup
                                onCheckedChanged: { ConfigLoader.setConfigValue("dock.pinnedOnStartup", checked); }
                            }
                            StyledText {
                                text: "Show pinned apps on startup"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: "#fff"
                            }
                        }

                        StyledText {
                            text: "When enabled, pinned apps will be visible in the dock even when no windows are open"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: "#fff"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                        }

                        // Auto-hide timing settings
                        ColumnLayout {
                            spacing: 12
                            Layout.topMargin: 16

                            StyledText {
                                text: "Auto-hide Timing"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: "#fff"
                            }

                            GridLayout {
                                columns: 2
                                columnSpacing: 24
                                rowSpacing: 16

                                ConfigSpinBox {
                                    text: "Hide Delay (ms)"
                                    value: ConfigOptions.dock.hideDelay
                                    from: 100
                                    to: 1000
                                    stepSize: 50
                                    onValueChanged: { ConfigLoader.setConfigValue("dock.hideDelay", value); }
                                }

                                ConfigSpinBox {
                                    text: "Show Delay (ms)"
                                    value: ConfigOptions.dock.showDelay
                                    from: 0
                                    to: 500
                                    stepSize: 25
                                    onValueChanged: { ConfigLoader.setConfigValue("dock.showDelay", value); }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
} 