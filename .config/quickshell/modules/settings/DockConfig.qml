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

Flickable {
    id: dockConfigFlickable
    contentWidth: parent ? parent.width : 800
    contentHeight: dockConfigColumn.implicitHeight
    clip: true
    interactive: true
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: dockConfigColumn
        width: dockConfigFlickable.width
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

                    // Dock enable/disable
                    ColumnLayout {
                        spacing: 16

                        RowLayout {
                            spacing: 12
                            ConfigSwitch {
                                checked: ConfigOptions.dock.enable
                                onCheckedChanged: {
                                    ConfigLoader.setConfigValueAndSave("dock.enable", checked);
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
                    }

                    // Dock appearance settings
                    ColumnLayout {
                        spacing: 16
                        Layout.topMargin: 24

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

                            ConfigSpinBox {
                                text: "Bottom Margin"
                                value: ConfigOptions.dock.margin
                                from: 0
                                to: 100
                                stepSize: 1
                                onValueChanged: { ConfigLoader.setConfigValue("dock.margin", value); }
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
                        spacing: 16
                        Layout.topMargin: 24

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

                    // Dock border color settings
                    ColumnLayout {
                        spacing: 12

                        StyledText {
                            text: "Border Color"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: "#fff"
                        }

                        StyledText {
                            text: "Customize the dock border appearance"
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
                                            Qt.color(currentDockBorderColor).r,
                                            Qt.color(currentDockBorderColor).g,
                                            Qt.color(currentDockBorderColor).b,
                                            dockBorderOpacitySlider.value
                                        )
                                        border.width: 2
                                        border.color: "#505050"
                                    }
                                    
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 4
                                        
                                        StyledText {
                                            text: "Main Border"
                                            font.pixelSize: 14
                                            font.weight: Font.Medium
                                            color: "#ffffff"
                                        }
                                        
                                        StyledText {
                                            text: `Opacity: ${Math.round((dockBorderOpacitySlider.value) * 100)}%`
                                            font.pixelSize: 12
                                            color: "#cccccc"
                                        }
                                    }
                                    
                                    // Reset button
                                    RippleButton {
                                        text: "Reset"
                                        onClicked: {
                                            ConfigLoader.setConfigValueAndSave("dock.borderColor", "#ffffff")
                                            ConfigLoader.setConfigValueAndSave("dock.borderOpacity", 0.15)
                                            ConfigLoader.setConfigValueAndSave("dock.innerBorderColor", "#ffffff")
                                            ConfigLoader.setConfigValueAndSave("dock.innerBorderOpacity", 0.05)
                                            initializeDockBorderSlidersFromColor("#ffffff")
                                            dockBorderOpacitySlider.value = 0.15
                                            dockInnerBorderOpacitySlider.value = 0.05
                                        }
                                        Layout.preferredWidth: 60
                                        Layout.preferredHeight: 32
                                    }
                                }
                            }
                        }

                        // RGB Sliders for main border
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            
                            StyledText {
                                text: "Main Border Color"
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
                                        id: dockBorderRedSlider
                                        Layout.fillWidth: true
                                        from: 0
                                        to: 255
                                        value: 255
                                        onValueChanged: {
                                            updateDockBorderColor()
                                        }
                                        highlightColor: "#ff0000"
                                        trackColor: Qt.rgba(1, 0, 0, 0.3)
                                    }
                                    
                                    StyledText {
                                        text: Math.round(dockBorderRedSlider.value)
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
                                        id: dockBorderGreenSlider
                                        Layout.fillWidth: true
                                        from: 0
                                        to: 255
                                        value: 255
                                        onValueChanged: {
                                            updateDockBorderColor()
                                        }
                                        highlightColor: "#00ff00"
                                        trackColor: Qt.rgba(0, 1, 0, 0.3)
                                    }
                                    
                                    StyledText {
                                        text: Math.round(dockBorderGreenSlider.value)
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
                                        id: dockBorderBlueSlider
                                        Layout.fillWidth: true
                                        from: 0
                                        to: 255
                                        value: 255
                                        onValueChanged: {
                                            updateDockBorderColor()
                                        }
                                        highlightColor: "#0000ff"
                                        trackColor: Qt.rgba(0, 0, 1, 0.3)
                                    }
                                    
                                    StyledText {
                                        text: Math.round(dockBorderBlueSlider.value)
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
                                        id: dockBorderOpacitySlider
                                        Layout.fillWidth: true
                                        from: 0
                                        to: 1
                                        value: ConfigOptions.dock.borderOpacity || 0.15
                                        stepSize: 0.01
                                        onValueChanged: {
                                            ConfigLoader.setConfigValue("dock.borderOpacity", value)
                                        }
                                        highlightColor: Appearance.colors.colPrimary
                                        trackColor: Appearance.colors.colPrimaryContainer
                                    }
                                    
                                    StyledText {
                                        text: `${Math.round((dockBorderOpacitySlider.value) * 100)}%`
                                        font.pixelSize: 12
                                        color: "#cccccc"
                                        Layout.preferredWidth: 30
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                        }

                        // Inner border opacity slider
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            
                            StyledText {
                                text: "Inner Border Opacity"
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                color: "#ffffff"
                            }
                            
                            RowLayout {
                                Layout.fillWidth: true
                                
                                StyledText {
                                    text: "Opacity"
                                    font.pixelSize: 12
                                    color: "#ffffff"
                                    Layout.preferredWidth: 40
                                }
                                
                                StyledSlider {
                                    id: dockInnerBorderOpacitySlider
                                    Layout.fillWidth: true
                                    from: 0
                                    to: 1
                                    value: ConfigOptions.dock.innerBorderOpacity || 0.05
                                    stepSize: 0.01
                                    onValueChanged: {
                                        ConfigLoader.setConfigValue("dock.innerBorderOpacity", value)
                                    }
                                    highlightColor: Appearance.colors.colPrimary
                                    trackColor: Appearance.colors.colPrimaryContainer
                                }
                                
                                StyledText {
                                    text: `${Math.round((dockInnerBorderOpacitySlider.value) * 100)}%`
                                    font.pixelSize: 12
                                    color: "#cccccc"
                                    Layout.preferredWidth: 30
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }

                    Layout.bottomMargin: 24
                }
            }
        }
    }
    
    // Timer to debounce slider changes
    Timer {
        id: dockBorderChangeTimer
        interval: 100 // 100ms delay
        repeat: false
        onTriggered: {
            ConfigLoader.setConfigValueAndSave("dock.borderColor", currentDockBorderColor)
            MaterialThemeLoader.reapplyTheme()
        }
    }
    
    // Property to track current slider color
    property string currentDockBorderColor: "#ffffff"
    
    // Function to update dock border color
    function updateDockBorderColor() {
        currentDockBorderColor = Qt.rgba(
            dockBorderRedSlider.value / 255,
            dockBorderGreenSlider.value / 255,
            dockBorderBlueSlider.value / 255,
            1.0
        ).toString()
        dockBorderChangeTimer.restart()
    }
    
    // Function to initialize sliders from color
    function initializeDockBorderSlidersFromColor(color) {
        if (color) {
            // Convert string color to QML color object if needed
            let colorObj = color
            if (typeof color === 'string') {
                colorObj = Qt.color(color)
            }
            
            if (colorObj && colorObj.r !== undefined) {
                dockBorderRedSlider.value = Math.round(colorObj.r * 255)
                dockBorderGreenSlider.value = Math.round(colorObj.g * 255)
                dockBorderBlueSlider.value = Math.round(colorObj.b * 255)
                currentDockBorderColor = color
            }
        }
    }
    
    // Initialize sliders with current dock border color
    Component.onCompleted: {
        initializeDockBorderSlidersFromColor(ConfigOptions.dock.borderColor || "#ffffff")
    }
} 