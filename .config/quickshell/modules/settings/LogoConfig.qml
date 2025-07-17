import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Qt.labs.platform
import Quickshell
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services/"

ColumnLayout {
    spacing: 24
    
    // Property to track current slider color
    property color currentSliderColor: "#ffffff"
    
    // Timer to debounce slider changes
    Timer {
        id: sliderChangeTimer
        interval: 100 // 100ms delay
        repeat: false
        onTriggered: {
            ConfigLoader.setConfigValueAndSave("appearance.logoColor", currentSliderColor)
            MaterialThemeLoader.reapplyTheme()
        }
    }
    
    // Function to update slider color
    function updateSliderColor() {
        currentSliderColor = Qt.rgba(redSlider.value / 255, greenSlider.value / 255, blueSlider.value / 255, 1.0)
        sliderChangeTimer.restart()
    }
    
    // Function to initialize sliders from color
    function initializeSlidersFromColor(color) {
        if (color) {
            // Convert string color to QML color object if needed
            let colorObj = color
            if (typeof color === 'string') {
                colorObj = Qt.color(color)
            }
            
            if (colorObj && colorObj.r !== undefined) {
                redSlider.value = Math.round(colorObj.r * 255)
                greenSlider.value = Math.round(colorObj.g * 255)
                blueSlider.value = Math.round(colorObj.b * 255)
                currentSliderColor = colorObj
            }
        }
    }
    
    // Header section
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: childrenRect.height + 32
        radius: 12
        color: "#2a2a2a"
        border.width: 1
        border.color: "#404040"
        
        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 24
            spacing: 20
            
            // Section header
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 8
                    color: "#4a4a4a"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "🖼️"
                        font.pixelSize: 18
                        color: "#ffffff"
                    }
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    
                    Text {
                        text: "System Logo"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        color: "#ffffff"
                    }
                    
                    Text {
                        text: "Customize the system logo displayed in the top bar and sidebars"
                        font.pixelSize: 12
                        color: "#cccccc"
                    }
                }
            }
            
            // Description
            Text {
                text: "The selected logo will be used throughout the interface. You can choose from various Linux distribution logos, generic icons, or custom images available in the assets/icons directory."
                font.pixelSize: 12
                color: "#cccccc"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            // Current logo display
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                radius: 8
                color: "#232323"
                border.width: 1
                border.color: "#505050"
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12
                    
                    Text {
                        text: "Current:"
                        font.pixelSize: 12
                        color: "#cccccc"
                    }
                    
                    Item {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        
                        Image {
                            id: currentLogoImage
                            anchors.fill: parent
                            source: "root:/assets/icons/" + (ConfigOptions.appearance.logo || "distro-nobara-symbolic.svg")
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                        }
                        
                        ColorOverlay {
                            anchors.fill: parent
                            source: currentLogoImage
                            color: currentSliderColor
                        }
                    }
                    
                    Text {
                        text: (ConfigOptions.appearance.logo || "distro-nobara-symbolic.svg").replace(/\.(svg|png|jpg|jpeg|gif)$/i, '').replace(/[-_]/g, ' ')
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: "#ffffff"
                        Layout.fillWidth: true
                    }
                }
            }
            
            // Logo color picker
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
                    
                    Text {
                        text: "Logo Color"
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: "#ffffff"
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        
                        // Color preview
                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            radius: 8
                            color: currentSliderColor
                            border.width: 2
                            border.color: "#505050"
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: colorDialog.open()
                            }
                        }
                        
                        // Color picker button
                        Button {
                            text: "Choose Color"
                            onClicked: colorDialog.open()
                        }
                        
                        // Reset button
                        Button {
                            text: "Reset to White"
                            onClicked: {
                                initializeSlidersFromColor("#ffffff")
                                ConfigLoader.setConfigValueAndSave("appearance.logoColor", "#ffffff")
                                MaterialThemeLoader.reapplyTheme()
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                    }
                }
            }
            
            // Color picker dialog
            ColorDialog {
                id: colorDialog
                title: "Choose Logo Color"
                onAccepted: {
                    initializeSlidersFromColor(colorDialog.color)
                    ConfigLoader.setConfigValueAndSave("appearance.logoColor", colorDialog.color)
                    MaterialThemeLoader.reapplyTheme()
                }
            }
        }
    }
    
    // Color sliders section
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: childrenRect.height + 32
        radius: 12
        color: "#2a2a2a"
        border.width: 1
        border.color: "#404040"
        
        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 24
            spacing: 20
            
            // Section header
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 8
                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)
                    
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "palette"
                        iconSize: 18
                        color: Appearance.colors.colPrimary
                    }
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    
                    Text {
                        text: "Color Customization"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        color: "#ffffff"
                    }
                    
                    Text {
                        text: "Fine-tune the logo color using RGB sliders"
                        font.pixelSize: 12
                        color: "#cccccc"
                    }
                }
            }
            
            // RGB Sliders
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 16
                
                // Red slider
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    RowLayout {
                        Layout.fillWidth: true
                        
                        Text {
                            text: "Red"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: "#ffffff"
                            Layout.preferredWidth: 60
                        }
                        
                        StyledSlider {
                            id: redSlider
                            Layout.fillWidth: true
                            from: 0
                            to: 255
                            value: 255
                            onValueChanged: {
                                updateSliderColor()
                            }
                            highlightColor: Appearance.colors.colPrimary
                            trackColor: Appearance.colors.colPrimaryContainer
                        }
                        
                        Text {
                            text: Math.round(redSlider.value)
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
                    spacing: 8
                    
                    RowLayout {
                        Layout.fillWidth: true
                        
                        Text {
                            text: "Green"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: "#ffffff"
                            Layout.preferredWidth: 60
                        }
                        
                        StyledSlider {
                            id: greenSlider
                            Layout.fillWidth: true
                            from: 0
                            to: 255
                            value: 255
                            onValueChanged: {
                                updateSliderColor()
                            }
                            highlightColor: Appearance.colors.colPrimaryHover
                            trackColor: Appearance.colors.colPrimaryContainerHover
                        }
                        
                        Text {
                            text: Math.round(greenSlider.value)
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
                    spacing: 8
                    
                    RowLayout {
                        Layout.fillWidth: true
                        
                        Text {
                            text: "Blue"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: "#ffffff"
                            Layout.preferredWidth: 60
                        }
                        
                        StyledSlider {
                            id: blueSlider
                            Layout.fillWidth: true
                            from: 0
                            to: 255
                            value: 255
                            onValueChanged: {
                                updateSliderColor()
                            }
                            highlightColor: Appearance.colors.colPrimaryActive
                            trackColor: Appearance.colors.colPrimaryContainerActive
                        }
                        
                        Text {
                            text: Math.round(blueSlider.value)
                            font.pixelSize: 12
                            color: "#cccccc"
                            Layout.preferredWidth: 30
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }
            
            // Color preview with sliders
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                radius: 8
                color: "#232323"
                border.width: 1
                border.color: "#505050"
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12
                    
                    Text {
                        text: "Preview:"
                        font.pixelSize: 12
                        color: "#cccccc"
                    }
                    
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 8
                        color: currentSliderColor
                        border.width: 2
                        border.color: "#505050"
                    }
                    
                    Text {
                        text: `RGB(${Math.round(redSlider.value)}, ${Math.round(greenSlider.value)}, ${Math.round(blueSlider.value)})`
                        font.pixelSize: 12
                        font.family: "monospace"
                        color: "#cccccc"
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
    
    // Logo selector
    LogoSelector {
        Layout.fillWidth: true
        Layout.fillHeight: true
        
        onLogoSelected: (logoName) => {
            // Save the selected logo to configuration
            ConfigLoader.setConfigValue("appearance.logo", logoName)
        }
    }
    
    // Initialize sliders with current logo color
    Component.onCompleted: {
        initializeSlidersFromColor(ConfigOptions.appearance.logoColor || "#ffffff")
    }
} 