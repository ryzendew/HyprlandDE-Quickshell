import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/services/"
import "root:/modules/common/"
import "root:/modules/common/widgets/"
import "root:/modules/common/functions/color_utils.js" as ColorUtils

Flickable {
    id: blurConfigFlickable
    contentWidth: parent ? parent.width : 800
    contentHeight: blurConfigColumn.implicitHeight
    clip: true
    interactive: true
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: blurConfigColumn
        width: blurConfigFlickable.width
        spacing: 24
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 40

        // Section header
        RowLayout {
            spacing: 16
            Layout.topMargin: 24
            Layout.fillWidth: true

            Rectangle {
                width: 40; height: 40
                radius: Appearance.rounding.normal
                color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "blur_on"
                    iconSize: 20
                    color: "#000"
                }
            }
            ColumnLayout {
                spacing: 4
                StyledText {
                    text: "Blur Effects"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Bold
                    color: "#fff"
                }
                StyledText {
                    text: "Configure global blur effects for all windows"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: "#fff"
                    opacity: 0.9
                }
            }
        }

        // Main blur settings
        Rectangle {
            Layout.fillWidth: true
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

                // Header
                StyledText {
                    text: "Global Blur Settings"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: "#fff"
                    Layout.topMargin: 8
                }

                // Blur toggle
                ColumnLayout {
                    spacing: 16
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 24
                        RowLayout {
                            spacing: 12
                            ConfigSwitch {
                                checked: AppearanceSettingsState.barBlurEnabled
                                onCheckedChanged: { 
                                    AppearanceSettingsState.barBlurEnabled = checked;
                                    ConfigLoader.setConfigValueAndSave("bar.blurEnabled", checked);
                                }
                            }
                            StyledText {
                                text: "Enable blur"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: "#fff"
                            }
                        }
                    }
                }

                // Blur amount
                ColumnLayout {
                    spacing: 8
                    Layout.topMargin: 16
                    enabled: AppearanceSettingsState.barBlurEnabled

                    StyledText {
                        text: "Blur Amount"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: AppearanceSettingsState.barBlurEnabled ? "#fff" : "#666"
                    }
                    RowLayout {
                        spacing: 8
                        StyledSlider {
                            from: 0
                            to: 20
                            value: AppearanceSettingsState.barBlurAmount
                            stepSize: 1
                            onValueChanged: { 
                                AppearanceSettingsState.barBlurAmount = value;
                                ConfigLoader.setConfigValueAndSave("bar.blurAmount", value);
                            }
                            Layout.fillWidth: true
                        }
                        Item { width: 8 }
                        StyledText {
                            text: `${AppearanceSettingsState.barBlurAmount}`
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: AppearanceSettingsState.barBlurEnabled ? "#fff" : "#666"
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                // Blur passes
                ColumnLayout {
                    spacing: 8
                    Layout.topMargin: 16
                    enabled: AppearanceSettingsState.barBlurEnabled

                    StyledText {
                        text: "Blur Passes"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: AppearanceSettingsState.barBlurEnabled ? "#fff" : "#666"
                    }
                    RowLayout {
                        spacing: 8
                        StyledSlider {
                            from: 1
                            to: 8
                            value: AppearanceSettingsState.barBlurPasses
                            stepSize: 1
                            onValueChanged: { 
                                AppearanceSettingsState.barBlurPasses = value;
                                ConfigLoader.setConfigValueAndSave("bar.blurPasses", value);
                            }
                            Layout.fillWidth: true
                        }
                        Item { width: 8 }
                        StyledText {
                            text: `${AppearanceSettingsState.barBlurPasses}`
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: AppearanceSettingsState.barBlurEnabled ? "#fff" : "#666"
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                // Xray toggle
                ColumnLayout {
                    spacing: 16
                    Layout.topMargin: 16
                    enabled: AppearanceSettingsState.barBlurEnabled

                    RowLayout {
                        spacing: 24
                        RowLayout {
                            spacing: 12
                            ConfigSwitch {
                                checked: AppearanceSettingsState.barXray
                                onCheckedChanged: { 
                                    AppearanceSettingsState.barXray = checked;
                                    ConfigLoader.setConfigValueAndSave("bar.xray", checked);
                                }
                            }
                            StyledText {
                                text: "Enable xray (transparency)"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: AppearanceSettingsState.barBlurEnabled ? "#fff" : "#666"
                            }
                        }
                    }
                }

                Layout.bottomMargin: 24
            }
        }

        Layout.bottomMargin: 24
    }
} 