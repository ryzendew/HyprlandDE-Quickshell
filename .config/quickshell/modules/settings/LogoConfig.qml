import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import "root:/services/"

Rectangle {
    id: logoConfig
    width: parent.width
    height: parent.height
    radius: 12
    color: Appearance.colors.colLayer0
    border.width: 1
    border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)

    // Current logo color
    property string currentSliderColor: ConfigOptions.appearance.logoColor || "#ffffff"
    
    // Caching properties
    property var cachedIcons: []
    property bool cacheValid: false
    property string lastScanTime: ""
    
    // Current logo
    property string currentLogo: ConfigOptions.appearance.logo || "distro-nobara-symbolic.svg"

    // FileView to read icons config
    FileView {
        id: iconsFileView
        path: "/home/matt/.local/state/Quickshell/Icons/icons.conf"
        
        onLoaded: {
            var content = text();
            if (content) {
                var icons = content.split('\n').filter(function(line) {
                    return line.trim() !== '';
                });
                cachedIcons = icons;
                cacheValid = true;
                lastScanTime = new Date().toISOString();
            }
        }
        
        onLoadFailed: {
            console.log("Failed to load icons config, using fallback");
            // Fallback to some basic icons if config file doesn't exist
            cachedIcons = [
                "distro-nobara-symbolic.svg",
                "distro-arch-symbolic.svg",
                "distro-cachyos-symbolic.svg",
                "distro-debian-symbolic.svg",
                "distro-fedora-symbolic.svg",
                "distro-ubuntu-symbolic.svg",
                "icon-app-launcher-symbolic.svg",
                "icon-apps-symbolic.svg",
                "icon-launcher-symbolic.svg"
            ];
            cacheValid = true;
        }
    }

    // Timer to load icons on startup
    Timer {
        interval: 100
        running: true
        repeat: false
        onTriggered: {
            loadIcons();
        }
    }

    function loadIcons(forceRefresh = false) {
        if (!cacheValid || forceRefresh) {
            // Regenerate the config file to ensure it's up to date
            Hyprland.dispatch(`exec python3 ${SystemPaths.quickshellConfigDir}/scripts/generate_icons_conf.py`)
            
            // Reload the FileView to read the updated config file
            iconsFileView.reload()
        }
    }

    function setLogo(iconName) {
        currentLogo = iconName;
        ConfigLoader.setConfigValue("appearance.logo", iconName);
    }

    function initializeSlidersFromColor(color) {
        // Convert hex color to RGB
        var hex = color.replace('#', '');
        var r = parseInt(hex.substr(0, 2), 16);
        var g = parseInt(hex.substr(2, 2), 16);
        var b = parseInt(hex.substr(4, 2), 16);
        
        redSlider.value = r;
        greenSlider.value = g;
        blueSlider.value = b;
        
        updateColor();
    }

    function updateColor() {
        var r = Math.round(redSlider.value);
        var g = Math.round(greenSlider.value);
        var b = Math.round(blueSlider.value);
        
        currentSliderColor = "#" + 
            (r < 16 ? "0" : "") + r.toString(16) +
            (g < 16 ? "0" : "") + g.toString(16) +
            (b < 16 ? "0" : "") + b.toString(16);
        
        ConfigLoader.setConfigValueAndSave("appearance.logoColor", currentSliderColor);
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 24

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: Appearance.rounding.small
                color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "image"
                    iconSize: 18
                    color: Appearance.colors.colPrimary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    text: "System Logo"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer0
                }

                StyledText {
                    text: "Customize the system logo displayed in the top bar and sidebars"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
            }
        }

        // Description
        StyledText {
            text: "The selected logo will be used throughout the interface. Icons are automatically scanned from the assets/icons directory."
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // Current logo display
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1
            border.width: 1
            border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                StyledText {
                    text: "Current Logo"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }

                RowLayout {
                    spacing: 16

                    Image {
                        id: currentLogoImage
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        source: "root:/assets/icons/" + currentLogo
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true

                        ColorOverlay {
                            anchors.fill: currentLogoImage
                            source: currentLogoImage
                            color: currentSliderColor
                        }
                    }

                    StyledText {
                        text: currentLogo.replace(/\.(svg|png|jpg|jpeg|gif)$/i, '').replace(/[-_]/g, ' ')
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                    }
                }
            }
        }

        // Logo Color Controls
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height + 32
            radius: Appearance.rounding.large
            color: Appearance.colors.colLayer1
            border.width: 1
            border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)

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
                        radius: Appearance.rounding.small
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

                        StyledText {
                            text: "Logo Color"
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnLayer1
                        }

                        StyledText {
                            text: "Fine-tune the logo color using RGB sliders"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                }

                // Color preview
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    radius: Appearance.rounding.normal
                    color: currentSliderColor
                    border.width: 2
                    border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.3)

                    StyledText {
                        anchors.centerIn: parent
                        text: currentSliderColor.toUpperCase()
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: (parseInt(currentSliderColor.replace('#', ''), 16) > 0x888888) ? "#000000" : "#ffffff"
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

                            StyledText {
                                text: "Red"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: "#ff6b6b"
                                font.weight: Font.Medium
                            }

                            StyledText {
                                text: Math.round(redSlider.value)
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }

                        Slider {
                            id: redSlider
                            Layout.fillWidth: true
                            from: 0
                            to: 255
                            value: 255
                            stepSize: 1

                            background: Rectangle {
                                x: redSlider.leftPadding
                                y: redSlider.topPadding + redSlider.availableHeight / 2 - height / 2
                                width: redSlider.availableWidth
                                height: 4
                                radius: 2
                                color: "#404040"

                                Rectangle {
                                    width: redSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: "#ff6b6b"
                                    radius: 2
                                }
                            }

                            handle: Rectangle {
                                x: redSlider.leftPadding + redSlider.visualPosition * (redSlider.availableWidth - width)
                                y: redSlider.topPadding + redSlider.availableHeight / 2 - height / 2
                                width: 16
                                height: 16
                                radius: 8
                                color: "#ff6b6b"
                                border.width: 2
                                border.color: "#ffffff"
                            }

                            onValueChanged: updateColor()
                        }
                    }

                    // Green slider
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true

                            StyledText {
                                text: "Green"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: "#51cf66"
                                font.weight: Font.Medium
                            }

                            StyledText {
                                text: Math.round(greenSlider.value)
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }

                        Slider {
                            id: greenSlider
                            Layout.fillWidth: true
                            from: 0
                            to: 255
                            value: 255
                            stepSize: 1

                            background: Rectangle {
                                x: greenSlider.leftPadding
                                y: greenSlider.topPadding + greenSlider.availableHeight / 2 - height / 2
                                width: greenSlider.availableWidth
                                height: 4
                                radius: 2
                                color: "#404040"

                                Rectangle {
                                    width: greenSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: "#51cf66"
                                    radius: 2
                                }
                            }

                            handle: Rectangle {
                                x: greenSlider.leftPadding + greenSlider.visualPosition * (greenSlider.availableWidth - width)
                                y: greenSlider.topPadding + greenSlider.availableHeight / 2 - height / 2
                                width: 16
                                height: 16
                                radius: 8
                                color: "#51cf66"
                                border.width: 2
                                border.color: "#ffffff"
                            }

                            onValueChanged: updateColor()
                        }
                    }

                    // Blue slider
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true

                            StyledText {
                                text: "Blue"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: "#339af0"
                                font.weight: Font.Medium
                            }

                            StyledText {
                                text: Math.round(blueSlider.value)
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }

                        Slider {
                            id: blueSlider
                            Layout.fillWidth: true
                            from: 0
                            to: 255
                            value: 255
                            stepSize: 1

                            background: Rectangle {
                                x: blueSlider.leftPadding
                                y: blueSlider.topPadding + blueSlider.availableHeight / 2 - height / 2
                                width: blueSlider.availableWidth
                                height: 4
                                radius: 2
                                color: "#404040"

                                Rectangle {
                                    width: blueSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: "#339af0"
                                    radius: 2
                                }
                            }

                            handle: Rectangle {
                                x: blueSlider.leftPadding + blueSlider.visualPosition * (blueSlider.availableWidth - width)
                                y: blueSlider.topPadding + blueSlider.availableHeight / 2 - height / 2
                                width: 16
                                height: 16
                                radius: 8
                                color: "#339af0"
                                border.width: 2
                                border.color: "#ffffff"
                            }

                            onValueChanged: updateColor()
                        }
                    }
                }
            }
        }

        // Icon Grid
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Appearance.rounding.large
            color: Appearance.colors.colLayer1
            border.width: 1
            border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 20

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: Appearance.rounding.small
                        color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "grid_view"
                            iconSize: 18
                            color: Appearance.colors.colPrimary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            text: "Available Icons"
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnLayer1
                        }

                        StyledText {
                            text: "Select from " + (cachedIcons.length || 0) + " available icons"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }

                    // Refresh button
                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: Appearance.rounding.small
                        color: refreshMouseArea.containsMouse ? 
                               Appearance.colors.colLayer2Hover : 
                               Appearance.colors.colLayer2
                        border.width: 1
                        border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)

                        MouseArea {
                            id: refreshMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                loadIcons(true);
                            }
                        }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "refresh"
                            iconSize: 16
                            color: Appearance.colors.colPrimary
                        }
                    }
                }

                // Grid
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    GridLayout {
                        width: parent.width
                        columns: Math.floor(parent.width / 100)
                        rowSpacing: 12
                        columnSpacing: 12

                        Repeater {
                            model: cachedIcons

                            delegate: Rectangle {
                                Layout.preferredWidth: 100
                                Layout.preferredHeight: 100
                                radius: Appearance.rounding.normal
                                color: currentLogo === modelData ? 
                                       Appearance.colors.colPrimary : 
                                       (iconMouseArea.containsMouse ? 
                                        Appearance.colors.colLayer2Hover : 
                                        Appearance.colors.colLayer2)
                                border.width: currentLogo === modelData ? 2 : 1
                                border.color: currentLogo === modelData ? 
                                            Appearance.colors.colPrimary : 
                                            ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)
                                clip: true

                                MouseArea {
                                    id: iconMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        setLogo(modelData);
                                    }
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 4

                                    Image {
                                        Layout.preferredWidth: 50
                                        Layout.preferredHeight: 50
                                        Layout.alignment: Qt.AlignHCenter
                                        source: "root:/assets/icons/" + modelData
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        mipmap: true

                                        ColorOverlay {
                                            anchors.fill: parent
                                            source: parent
                                            color: currentLogo === modelData ? 
                                                   (parseInt(Appearance.colors.colPrimary.replace('#', ''), 16) > 0x888888 ? "#000000" : "#ffffff") : 
                                                   currentSliderColor
                                        }
                                    }

                                    StyledText {
                                        text: modelData.replace(/\.(svg|png|jpg|jpeg|gif)$/i, '').replace(/[-_]/g, ' ')
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: currentLogo === modelData ? 
                                               (parseInt(Appearance.colors.colPrimary.replace('#', ''), 16) > 0x888888 ? "#000000" : "#ffffff") : 
                                               Appearance.colors.colOnLayer2
                                        horizontalAlignment: Text.AlignHCenter
                                        Layout.fillWidth: true
                                        elide: Text.ElideMiddle
                                    }
                                }

                                // Selection indicator
                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 4
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: currentLogo === modelData ? 
                                           (parseInt(Appearance.colors.colPrimary.replace('#', ''), 16) > 0x888888 ? "#000000" : "#ffffff") : 
                                           "transparent"
                                    border.width: currentLogo === modelData ? 0 : 1
                                    border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.3)

                                    StyledText {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        font.pixelSize: 10
                                        color: currentLogo === modelData ? 
                                               Appearance.colors.colPrimary : 
                                               "transparent"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Spacer at bottom
        Item {
            Layout.fillHeight: true
        }
    }

    // Initialize sliders with current logo color
    Component.onCompleted: {
        console.log("Initializing logo config...")
        
        // Ensure the icons state directory exists and generate config
        Hyprland.dispatch(`exec mkdir -p ~/.local/state/Quickshell/Icons/`)
        Hyprland.dispatch(`exec python3 ${SystemPaths.quickshellConfigDir}/scripts/generate_icons_conf.py`)
        
        initializeSlidersFromColor(ConfigOptions.appearance.logoColor || "#ffffff");
    }
} 