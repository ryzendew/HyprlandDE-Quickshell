import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/services/"
import "root:/modules/common/"
import "root:/modules/common/widgets/"
import "root:/modules/common/functions/color_utils.js" as ColorUtils

Flickable {
    id: barConfigFlickable
    contentWidth: parent ? parent.width : 800
    contentHeight: barConfigColumn.implicitHeight
    clip: true
    interactive: true
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: barConfigColumn
        width: barConfigFlickable.width
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

        // Two-column layout for settings
        RowLayout {
            Layout.fillWidth: true
            spacing: 24

            // Left Column - Basic Settings
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: (parent.width - parent.spacing) / 2
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

                    // Left Column Header
                    StyledText {
                        text: "Basic Settings"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: "#fff"
                        Layout.topMargin: 8
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
                                    checked: ConfigOptions.bar.showBackground ?? true
                                    onCheckedChanged: { ConfigLoader.setConfigValue("bar.showBackground", checked); }
                                }
                                StyledText {
                                    text: "Show background"
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: "#fff"
                                }
                            }
                        }
                    }

                    // Bar transparency
                    ColumnLayout {
                        spacing: 8
                        Layout.topMargin: 16

                        StyledText {
                            text: "Transparency"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: "#fff"
                        }
                        RowLayout {
                            spacing: 8
                            StyledSlider {
                                from: 0.0
                                to: 1.0
                                value: ConfigOptions.bar.transparency ?? 0.55
                                stepSize: 0.05
                                onValueChanged: { ConfigLoader.setConfigValue("bar.transparency", value); }
                                Layout.fillWidth: true
                            }
                            Item { width: 8 }
                            StyledText {
                                text: `${Math.round((ConfigOptions.bar.transparency ?? 0.55) * 100)}%`
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: "#fff"
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    // Icon sizes
                    ColumnLayout {
                        spacing: 16
                        Layout.topMargin: 16

                        StyledText {
                            text: "Icon Sizes"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: "#fff"
                        }

                        GridLayout {
                            columns: 2
                            columnSpacing: 24
                            rowSpacing: 12
                            Layout.fillWidth: true

                            StyledText { text: "Bar height"; font.pixelSize: Appearance.font.pixelSize.normal; color: "#fff" }
                            ConfigSpinBox {
                                value: ConfigOptions.bar.height ?? 40
                                from: 24
                                to: 120
                                stepSize: 2
                                onValueChanged: { ConfigLoader.setConfigValue("bar.height", value); }
                            }

                            StyledText { text: "Icon size"; font.pixelSize: Appearance.font.pixelSize.normal; color: "#fff" }
                            ConfigSpinBox {
                                value: ConfigOptions.bar.iconSize ?? 24
                                from: 12
                                to: 64
                                stepSize: 2
                                onValueChanged: { ConfigLoader.setConfigValue("bar.iconSize", value); }
                            }

                            StyledText { text: "Workspace icon size"; font.pixelSize: Appearance.font.pixelSize.normal; color: "#fff" }
                            ConfigSpinBox {
                                value: ConfigOptions.bar.workspaceIconSize ?? 24
                                from: 12
                                to: 64
                                stepSize: 2
                                onValueChanged: { ConfigLoader.setConfigValue("bar.workspaceIconSize", value); }
                            }

                            StyledText { text: "Indicator icon size"; font.pixelSize: Appearance.font.pixelSize.normal; color: "#fff" }
                            ConfigSpinBox {
                                value: ConfigOptions.bar.indicatorIconSize ?? 24
                                from: 12
                                to: 64
                                stepSize: 2
                                onValueChanged: { ConfigLoader.setConfigValue("bar.indicatorIconSize", value); }
                            }

                            StyledText { text: "Systray icon size"; font.pixelSize: Appearance.font.pixelSize.normal; color: "#fff" }
                            ConfigSpinBox {
                                value: ConfigOptions.bar.systrayIconSize ?? 24
                                from: 12
                                to: 64
                                stepSize: 2
                                onValueChanged: { ConfigLoader.setConfigValue("bar.systrayIconSize", value); }
                            }

                            StyledText { text: "Logo icon size"; font.pixelSize: Appearance.font.pixelSize.normal; color: "#fff" }
                            ConfigSpinBox {
                                value: ConfigOptions.bar.logoIconSize ?? 32
                                from: 12
                                to: 128
                                stepSize: 2
                                onValueChanged: { ConfigLoader.setConfigValue("bar.logoIconSize", value); }
                            }
                        }
                    }

                    Layout.bottomMargin: 24
                }
            }

            // Right Column - Advanced Settings
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: (parent.width - parent.spacing) / 2
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

                    // Right Column Header
                    StyledText {
                        text: "Advanced Settings"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: "#fff"
                        Layout.topMargin: 8
                    }

                    // Bar border color settings
                    ColumnLayout {
                        spacing: 12
                        Layout.topMargin: 16

                        StyledText {
                            text: "Border Color"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: "#fff"
                        }

                        StyledText {
                            text: "Customize the bar border appearance"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: "#fff"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        // Border color preview and controls
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 80
                            radius: 8
                            color: "#232323"
                            border.width: 1
                            border.color: "#505050"
                            
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    
                                    // Border color preview
                                    Rectangle {
                                        Layout.preferredWidth: 40
                                        Layout.preferredHeight: 40
                                        radius: 8
                                        color: Qt.rgba(
                                            barBorderRedSlider.value / 255,
                                            barBorderGreenSlider.value / 255,
                                            barBorderBlueSlider.value / 255,
                                            barBorderOpacitySlider.value
                                        )
                                        border.width: 2
                                        border.color: "#505050"
                                    }
                                    
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 4
                                        
                                        StyledText {
                                            text: "Current"
                                            font.pixelSize: 12
                                            color: "#ffffff"
                                            font.weight: Font.Medium
                                        }
                                        
                                        StyledText {
                                            text: `Opacity: ${Math.round((barBorderOpacitySlider.value) * 100)}%`
                                            font.pixelSize: 12
                                            color: "#cccccc"
                                        }
                                    }
                                    
                                    // Reset button
                                    RippleButton {
                                        text: "Reset"
                                        onClicked: {
                                            barBorderRedSlider.value = 255
                                            barBorderGreenSlider.value = 255
                                            barBorderBlueSlider.value = 255
                                            barBorderOpacitySlider.value = 0.12
                                            updateBarBorderColor()
                                        }
                                        Layout.preferredWidth: 60
                                        Layout.preferredHeight: 32
                                    }
                                }
                            }
                        }

                        // RGB Sliders for border color
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            
                            StyledText {
                                text: "Border Color"
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                color: "#ffffff"
                            }
                            
                            // Red slider
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    StyledText {
                                        text: "Red"
                                        font.pixelSize: 12
                                        color: "#ffffff"
                                        Layout.preferredWidth: 40
                                    }
                                    
                                    StyledSlider {
                                        id: barBorderRedSlider
                                        Layout.fillWidth: true
                                        from: 0
                                        to: 255
                                        value: 255 // Will be set by initializeBarBorderSlidersFromColor
                                        onValueChanged: {
                                            updateBarBorderColor()
                                            ConfigLoader.setConfigValueAndSave("bar.borderColor", currentBarBorderColor)
                                            // Small delay to ensure config is saved
                                            Qt.callLater(() => {
                                                MaterialThemeLoader.reapplyTheme()
                                            })
                                        }
                                        highlightColor: "#ff0000"
                                        trackColor: Qt.rgba(1, 0, 0, 0.3)
                                    }
                                    
                                    StyledText {
                                        text: Math.round(barBorderRedSlider.value)
                                        font.pixelSize: 12
                                        color: "#cccccc"
                                        Layout.preferredWidth: 30
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                            
                            // Green slider
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    StyledText {
                                        text: "Green"
                                        font.pixelSize: 12
                                        color: "#ffffff"
                                        Layout.preferredWidth: 40
                                    }
                                    
                                    StyledSlider {
                                        id: barBorderGreenSlider
                                        Layout.fillWidth: true
                                        from: 0
                                        to: 255
                                        value: 255 // Will be set by initializeBarBorderSlidersFromColor
                                        onValueChanged: {
                                            updateBarBorderColor()
                                            ConfigLoader.setConfigValueAndSave("bar.borderColor", currentBarBorderColor)
                                            // Small delay to ensure config is saved
                                            Qt.callLater(() => {
                                                MaterialThemeLoader.reapplyTheme()
                                            })
                                        }
                                        highlightColor: "#00ff00"
                                        trackColor: Qt.rgba(0, 1, 0, 0.3)
                                    }
                                    
                                    StyledText {
                                        text: Math.round(barBorderGreenSlider.value)
                                        font.pixelSize: 12
                                        color: "#cccccc"
                                        Layout.preferredWidth: 30
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                            
                            // Blue slider
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    StyledText {
                                        text: "Blue"
                                        font.pixelSize: 12
                                        color: "#ffffff"
                                        Layout.preferredWidth: 40
                                    }
                                    
                                    StyledSlider {
                                        id: barBorderBlueSlider
                                        Layout.fillWidth: true
                                        from: 0
                                        to: 255
                                        value: 255 // Will be set by initializeBarBorderSlidersFromColor
                                        onValueChanged: {
                                            updateBarBorderColor()
                                            ConfigLoader.setConfigValueAndSave("bar.borderColor", currentBarBorderColor)
                                            // Small delay to ensure config is saved
                                            Qt.callLater(() => {
                                                MaterialThemeLoader.reapplyTheme()
                                            })
                                        }
                                        highlightColor: "#0000ff"
                                        trackColor: Qt.rgba(0, 0, 1, 0.3)
                                    }
                                    
                                    StyledText {
                                        text: Math.round(barBorderBlueSlider.value)
                                        font.pixelSize: 12
                                        color: "#cccccc"
                                        Layout.preferredWidth: 30
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                            
                            // Border opacity slider
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    StyledText {
                                        text: "Opacity"
                                        font.pixelSize: 12
                                        color: "#ffffff"
                                        Layout.preferredWidth: 40
                                    }
                                    
                                    StyledSlider {
                                        id: barBorderOpacitySlider
                                        Layout.fillWidth: true
                                        from: 0.0
                                        to: 1.0
                                        value: ConfigOptions.bar.borderOpacity || 0.12
                                        stepSize: 0.01
                                        onValueChanged: {
                                            ConfigLoader.setConfigValueAndSave("bar.borderOpacity", value)
                                            // Small delay to ensure config is saved
                                            Qt.callLater(() => {
                                                MaterialThemeLoader.reapplyTheme()
                                            })
                                        }
                                        highlightColor: "#ffffff"
                                        trackColor: Qt.rgba(1, 1, 1, 0.3)
                                    }
                                    
                                    StyledText {
                                        text: `${Math.round((barBorderOpacitySlider.value) * 100)}%`
                                        font.pixelSize: 12
                                        color: "#cccccc"
                                        Layout.preferredWidth: 30
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                        }
                    }

                    // Border visibility settings
                    ColumnLayout {
                        spacing: 12
                        Layout.topMargin: 24

                        StyledText {
                            text: "Border Visibility"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: "#fff"
                        }

                        StyledText {
                            text: "Choose which borders to display on the bar"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: "#fff"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        // Border toggle buttons
                        GridLayout {
                            columns: 2
                            columnSpacing: 16
                            rowSpacing: 12
                            Layout.fillWidth: true
                            Layout.topMargin: 8

                            // Top border
                            RowLayout {
                                spacing: 12
                                ConfigSwitch {
                                    checked: ConfigOptions.bar.borderTop ?? false
                                    onCheckedChanged: { 
                                        ConfigLoader.setConfigValueAndSave("bar.borderTop", checked)
                                        Qt.callLater(() => {
                                            MaterialThemeLoader.reapplyTheme()
                                        })
                                    }
                                }
                                StyledText {
                                    text: "Top border"
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: "#fff"
                                }
                            }

                            // Bottom border
                            RowLayout {
                                spacing: 12
                                ConfigSwitch {
                                    checked: ConfigOptions.bar.borderBottom ?? true
                                    onCheckedChanged: { 
                                        ConfigLoader.setConfigValueAndSave("bar.borderBottom", checked)
                                        Qt.callLater(() => {
                                            MaterialThemeLoader.reapplyTheme()
                                        })
                                    }
                                }
                                StyledText {
                                    text: "Bottom border"
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: "#fff"
                                }
                            }

                            // Left border
                            RowLayout {
                                spacing: 12
                                ConfigSwitch {
                                    checked: ConfigOptions.bar.borderLeft ?? false
                                    onCheckedChanged: { 
                                        ConfigLoader.setConfigValueAndSave("bar.borderLeft", checked)
                                        Qt.callLater(() => {
                                            MaterialThemeLoader.reapplyTheme()
                                        })
                                    }
                                }
                                StyledText {
                                    text: "Left border"
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: "#fff"
                                }
                            }

                            // Right border
                            RowLayout {
                                spacing: 12
                                ConfigSwitch {
                                    checked: ConfigOptions.bar.borderRight ?? false
                                    onCheckedChanged: { 
                                        ConfigLoader.setConfigValueAndSave("bar.borderRight", checked)
                                        Qt.callLater(() => {
                                            MaterialThemeLoader.reapplyTheme()
                                        })
                                    }
                                }
                                StyledText {
                                    text: "Right border"
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: "#fff"
                                }
                            }
                        }
                    }

                    // Workspaces settings
                    ColumnLayout {
                        spacing: 16
                        Layout.topMargin: 24

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
                                value: ConfigOptions.bar.workspaces?.shown ?? 10
                                onValueChanged: { ConfigLoader.setConfigValue("bar.workspaces.shown", value); }
                            }
                        }
                    }

                    // Weather toggle
                    ColumnLayout {
                        spacing: 16
                        Layout.topMargin: 24

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
    }
    
    // Property to track current slider color
    property string currentBarBorderColor: "#ffffff"
    
            // Function to update bar border color
        function updateBarBorderColor() {
            currentBarBorderColor = Qt.rgba(
                barBorderRedSlider.value / 255,
                barBorderGreenSlider.value / 255,
                barBorderBlueSlider.value / 255,
                1.0
            ).toString()
        }
    
    // Function to initialize sliders from color
    function initializeBarBorderSlidersFromColor(color) {
        if (color) {
            // Convert string color to QML color object if needed
            let colorObj = color
            if (typeof color === 'string') {
                colorObj = Qt.color(color)
            }
            
            if (colorObj && colorObj.r !== undefined) {
                barBorderRedSlider.value = Math.round(colorObj.r * 255)
                barBorderGreenSlider.value = Math.round(colorObj.g * 255)
                barBorderBlueSlider.value = Math.round(colorObj.b * 255)
                currentBarBorderColor = color
            }
        }
    }
    
            // Initialize sliders with current bar border color
        Component.onCompleted: {
            initializeBarBorderSlidersFromColor(ConfigOptions.bar.borderColor || "#ffffff")
            barBorderOpacitySlider.value = ConfigOptions.bar.borderOpacity || 0.12
        }
} 