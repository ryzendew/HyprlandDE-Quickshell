import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Hyprland
import "root:/services/"
import "root:/modules/common/"
import "root:/modules/common/widgets/"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import "root:/modules/common/functions/file_utils.js" as FileUtils

ColumnLayout {
    spacing: 24

    Process {
        id: konachanWallProc
        property string status: ""
        command: ["bash", "-c", FileUtils.trimFileProtocol(`${Directories.config}/quickshell/scripts/colors/random_konachan_wall.sh`)]
        stdout: SplitParser {
            onRead: data => {
// console.log(`Konachan wall proc output: ${data}`);
                konachanWallProc.status = data.trim();
            }
        }
    }

    Timer {
        id: themeRegenerationTimer
        interval: 2000 // Wait 2 seconds after wallpaper change
        repeat: false
        onTriggered: {
            MaterialThemeLoader.reapplyTheme();
        }
    }

    // Colors & Theme Section
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
                        text: "Colors & Theme"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer1
                    }

                    StyledText {
                        text: "Customize the visual appearance and color scheme"
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            // Theme mode selection
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                StyledText {
                    text: "Theme Mode"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }

                RowLayout {
            Layout.fillWidth: true
                    spacing: 8

            LightDarkPreferenceButton {
                dark: false
                        Layout.fillWidth: true
            }
            LightDarkPreferenceButton {
                dark: true
                        Layout.fillWidth: true
                    }
            }
        }

        // Material palette selection
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        text: "Material Palette"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        radius: 8
                        color: Appearance.colors.colPrimary
                    }
                }

            ConfigSelectionArray {
                    Layout.fillWidth: true
                currentValue: Config.options.appearance.palette.type
                configOptionName: "appearance.palette.type"
                onSelected: (newValue) => {
                        ConfigLoader.setConfigValue("appearance.palette.type", newValue);
                        // Trigger theme regeneration when palette type changes
                        MaterialThemeLoader.reapplyTheme();
                }
                options: [
                    {"value": "auto", "displayName": "Auto"},
                    {"value": "scheme-content", "displayName": "Content"},
                    {"value": "scheme-expressive", "displayName": "Expressive"},
                    {"value": "scheme-fidelity", "displayName": "Fidelity"},
                    {"value": "scheme-fruit-salad", "displayName": "Fruit Salad"},
                    {"value": "scheme-monochrome", "displayName": "Monochrome"},
                    {"value": "scheme-neutral", "displayName": "Neutral"},
                    {"value": "scheme-rainbow", "displayName": "Rainbow"},
                    {"value": "scheme-tonal-spot", "displayName": "Tonal Spot"}
                ]
            }
        }

            // Transparency setting
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        text: "Transparency Effects"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }

                    Item { Layout.fillWidth: true }

                    ConfigSwitch {
                        text: ""
                        checked: Config.options.appearance.transparency
                        onCheckedChanged: {
                            ConfigLoader.setConfigValue("appearance.transparency", checked);
                        }
                    }
                }

                StyledText {
                    text: "Enable transparency effects for windows and panels. May affect performance."
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }

    // Wallpaper Section
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
                        text: "wallpaper"
                        iconSize: 18
                        color: Appearance.colors.colPrimary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        text: "Wallpaper"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer1
                    }

                    StyledText {
                        text: "Set your desktop background image"
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            // Wallpaper options
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    radius: Appearance.rounding.normal
                    color: rndWallMouseArea.containsMouse ? 
                           Appearance.colors.colLayer2Hover : 
                           Appearance.colors.colLayer2
                    border.width: 1
                    border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)

                    MouseArea {
                        id: rndWallMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                    onClicked: {
// console.log(konachanWallProc.command.join(" "))
                        konachanWallProc.running = true;
                    }
                    }

                    RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 16
                        spacing: 12

                        MaterialSymbol {
                            text: "shuffle"
                            iconSize: 20
                            color: Appearance.colors.colPrimary
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                text: konachanWallProc.running ? "Downloading..." : "Random Wallpaper"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer2
                            }

                            StyledText {
                                text: "Get a random anime wallpaper from Konachan"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                    }
                }

                        Rectangle {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            radius: 8
                            color: "transparent"
                            border.width: 2
                            border.color: Appearance.colors.colPrimary
                            visible: konachanWallProc.running

                            RotationAnimation {
                                target: parent
                                property: "rotation"
                                from: 0
                                to: 360
                                duration: 1000
                                loops: Animation.Infinite
                                running: konachanWallProc.running
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    radius: Appearance.rounding.normal
                    color: chooseWallMouseArea.containsMouse ? 
                           Appearance.colors.colLayer2Hover : 
                           Appearance.colors.colLayer2
                    border.width: 1
                    border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)

                    MouseArea {
                        id: chooseWallMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                    onClicked: {
                        Quickshell.execDetached(`${Directories.wallpaperSwitchScriptPath}`)
                            // Note: Theme regeneration will be handled by the wallpaper script
                        }
                    }

                        RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 16
                        spacing: 12

                        MaterialSymbol {
                            text: "folder_open"
                            iconSize: 20
                            color: Appearance.colors.colPrimary
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                text: "Choose File"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer2
                            }

                            StyledText {
                                text: "Select an image from your computer"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }

                            RowLayout {
                            spacing: 4
                                KeyboardKey {
                                    key: "Ctrl"
                                }
                                StyledText {
                                    text: "+"
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.small
                                }
                                KeyboardKey {
                                    key: "T"
                                }
                            }
                        }
                    }
                }

            // Quick tip
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: Appearance.rounding.small
                color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.05)
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.2)

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 12
                    spacing: 8

                    MaterialSymbol {
                        text: "lightbulb"
                        iconSize: 16
                        color: Appearance.colors.colPrimary
                    }

                    StyledText {
                        text: "Pro tip: Use /dark, /light, or /img commands in the launcher for quick theme changes"
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colPrimary
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }

    // Visual Effects Section
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
                        text: "auto_fix_high"
                        iconSize: 18
                        color: Appearance.colors.colPrimary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        text: "Visual Effects"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer1
                    }

                    StyledText {
                        text: "Configure visual enhancements and window decorations"
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            // Screen rounding
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                StyledText {
                    text: "Screen Rounding"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                property int selectedPolicy: Config.options.appearance.fakeScreenRounding

                SelectionGroupButton {
                    property int value: 0
                        Layout.fillWidth: true
                    leftmost: true
                        buttonText: "Disabled"
                        toggled: (parent.selectedPolicy === value)
                    onClicked: {
                            ConfigLoader.setConfigValue("appearance.fakeScreenRounding", value);
                    }
                }
                SelectionGroupButton {
                    property int value: 1
                        Layout.fillWidth: true
                        buttonText: "Always"
                        toggled: (parent.selectedPolicy === value)
                    onClicked: {
                            ConfigLoader.setConfigValue("appearance.fakeScreenRounding", value);
                    }
                }
                SelectionGroupButton {
                    property int value: 2
                        Layout.fillWidth: true
                    rightmost: true
                        buttonText: "When Windowed"
                        toggled: (parent.selectedPolicy === value)
                    onClicked: {
                            ConfigLoader.setConfigValue("appearance.fakeScreenRounding", value);
                    }
                }
            }

                StyledText {
                    text: "Add rounded corners to your screen edges for a modern look"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            // Window decorations
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                StyledText {
                    text: "Window Decorations"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                ConfigSwitch {
                            text: ""
                    checked: Config.options.windows.showTitlebar
                    onCheckedChanged: {
                                ConfigLoader.setConfigValue("windows.showTitlebar", checked);
                    }
                }

                        StyledText {
                            text: "Show title bars"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                ConfigSwitch {
                            text: ""
                    checked: Config.options.windows.centerTitle
                    onCheckedChanged: {
                                ConfigLoader.setConfigValue("windows.centerTitle", checked);
                    }
                }

                        StyledText {
                            text: "Center titles"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
            }
        }
                }

                StyledText {
                    text: "Control how window title bars appear in shell applications"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }

    // Spacer at bottom
    Item {
        Layout.fillHeight: true
        Layout.minimumHeight: 20
    }
}