import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/services/"
import "root:/modules/common/"
import "root:/modules/common/widgets/"
import "root:/modules/common/functions/color_utils.js" as ColorUtils

ColumnLayout {
    clip: false
    spacing: 24 * (root.scaleFactor ?? 1.0)

    // Responsive scaling properties
    property real scaleFactor: root.scaleFactor ?? 1.0
    property int baseSectionMargin: 24
    property int baseIconSize: 18
    property int baseSpacing: 12

    // Audio Settings Section
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
                        text: "volume_up"
                        iconSize: baseIconSize * scaleFactor
                        color: Appearance.colors.colOnLayer1
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2 * scaleFactor

                    StyledText {
                        text: "Audio Protection"
                        font.pixelSize: (Appearance.font.pixelSize.large * scaleFactor)
                        font.weight: Font.Bold
                        color: "#fff"
                    }

                    StyledText {
                        text: "Protect your hearing with volume limits and controls"
                        font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                        color: "#fff"
                    }
                }
            }

            // Audio protection toggle
            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * scaleFactor

        ConfigSwitch {
                    text: ""
            checked: Config.options.audio.protection.enable
            onCheckedChanged: {
                        ConfigLoader.setConfigValue("audio.protection.enable", checked);
            }
                }

                StyledText {
                    text: "Enable audio protection"
                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                    color: "#fff"
                }
            }

            StyledText {
                text: "Prevents sudden volume spikes and restricts maximum volume to protect your hearing"
                font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                color: "#fff"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            // Volume settings
            RowLayout {
                Layout.fillWidth: true
                spacing: 16 * scaleFactor

            ConfigSpinBox {
                    Layout.fillWidth: true
                    text: "Max volume increase"
                value: Config.options.audio.protection.maxAllowedIncrease
                from: 0
                to: 100
                stepSize: 2
                onValueChanged: {
                        ConfigLoader.setConfigValue("audio.protection.maxAllowedIncrease", value);
                    }
                }

            ConfigSpinBox {
                    Layout.fillWidth: true
                text: "Volume limit"
                value: Config.options.audio.protection.maxAllowed
                from: 0
                to: 100
                stepSize: 2
                onValueChanged: {
                        ConfigLoader.setConfigValue("audio.protection.maxAllowed", value);
                }
            }
        }
    }
    }

    // Battery Settings Section
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
                        text: "battery_alert"
                        iconSize: baseIconSize * scaleFactor
                        color: Appearance.colors.colOnLayer1
                    }
                }

                ColumnLayout {
            Layout.fillWidth: true
                    spacing: 2 * scaleFactor

                    StyledText {
                        text: "Battery Management"
                        font.pixelSize: (Appearance.font.pixelSize.large * scaleFactor)
                        font.weight: Font.Bold
                        color: "#fff"
                    }

                    StyledText {
                        text: "Configure battery warnings and power management"
                        font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                        color: "#fff"
                    }
            }
        }

            // Battery warning levels
            ColumnLayout {
                Layout.fillWidth: true
                spacing: baseSpacing * scaleFactor

                StyledText {
                    text: "Warning Levels"
                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                    font.weight: Font.Medium
                    color: "#fff"
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16 * scaleFactor

            ConfigSpinBox {
                        Layout.fillWidth: true
                        text: "Low battery warning"
                        value: ConfigOptions.battery.low
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                            ConfigLoader.setConfigValue("battery.low", value);
                }
            }

            ConfigSpinBox {
                        Layout.fillWidth: true
                        text: "Critical battery warning"
                        value: ConfigOptions.battery.critical
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                            ConfigLoader.setConfigValue("battery.critical", value);
                }
            }
        }
            }

            // Auto suspend settings
            ColumnLayout {
                Layout.fillWidth: true
                spacing: baseSpacing * scaleFactor

                StyledText {
                    text: "Power Management"
                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                    font.weight: Font.Medium
                    color: "#fff"
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16 * scaleFactor

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8 * scaleFactor

            ConfigSwitch {
                            text: ""
                            checked: ConfigOptions.battery.automaticSuspend
                onCheckedChanged: {
                                ConfigLoader.setConfigValue("battery.automaticSuspend", checked);
                }
                        }

                        StyledText {
                            text: "Auto suspend"
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                            color: "#fff"
                }
            }

            ConfigSpinBox {
                        Layout.fillWidth: true
                        text: "Suspend at (%)"
                        value: ConfigOptions.battery.suspend
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                            ConfigLoader.setConfigValue("battery.suspend", value);
                }
            }
        }

                StyledText {
                    text: "Automatically suspend the system when battery level drops below the specified threshold"
                    font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                    color: "#fff"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }

    // Networking Section
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
                        text: "language"
                        iconSize: baseIconSize * scaleFactor
                        color: Appearance.colors.colOnLayer1
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2 * scaleFactor

                    StyledText {
                        text: "Network Settings"
                        font.pixelSize: (Appearance.font.pixelSize.large * scaleFactor)
                        font.weight: Font.Bold
                        color: "#fff"
                    }

                    StyledText {
                        text: "Configure network and web service settings"
                        font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                        color: "#fff"
                    }
                }
            }

            // User agent
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8 * scaleFactor

                StyledText {
                    text: "User Agent"
                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                    font.weight: Font.Medium
                    color: "#fff"
                }

        MaterialTextField {
            Layout.fillWidth: true
                    placeholderText: "Enter custom user agent string for web services"
                    text: ConfigOptions.networking.userAgent
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                        ConfigLoader.setConfigValue("networking.userAgent", text);
                    }
                }

                StyledText {
                    text: "Custom user agent string used when making web requests to external services"
                    font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                    color: "#fff"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }

    // System Resources Section
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
                        text: "monitor_heart"
                        iconSize: baseIconSize * scaleFactor
        }
    }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2 * scaleFactor

                    StyledText {
                        text: "System Resources"
                        font.pixelSize: (Appearance.font.pixelSize.large * scaleFactor)
                        font.weight: Font.Bold
                        color: "#fff"
                    }

                    StyledText {
                        text: "Configure system monitoring and resource usage"
                        font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                        color: "#fff"
                    }
                }
            }

            // Resource monitoring
            ColumnLayout {
                Layout.fillWidth: true
                spacing: baseSpacing * scaleFactor

                StyledText {
                    text: "Monitoring Frequency"
                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                    font.weight: Font.Medium
                    color: "#fff"
                }

        ConfigSpinBox {
                    Layout.fillWidth: true
                    text: "Update interval (ms)"
                    value: ConfigOptions.resources.updateInterval
            from: 100
            to: 10000
            stepSize: 100
            onValueChanged: {
                        ConfigLoader.setConfigValue("resources.updateInterval", value);
            }
        }

                StyledText {
                    text: "How often system resource usage is updated. Lower values provide more responsive monitoring but use more CPU"
                    font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                    color: "#fff"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
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
