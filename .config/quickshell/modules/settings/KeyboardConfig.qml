import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/modules/common/"
import "root:/modules/common/widgets/"
import "root:/modules/common/functions/color_utils.js" as ColorUtils

ColumnLayout {
    spacing: 24
    anchors.left: parent ? parent.left : undefined
    anchors.leftMargin: 40

    // Header
    RowLayout {
        spacing: 16
        Rectangle {
            width: 40; height: 40
            radius: Appearance.rounding.normal
            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)
            MaterialSymbol {
                anchors.centerIn: parent
                text: "keyboard"
                iconSize: 20
                color: "#000"
            }
        }
        ColumnLayout {
            spacing: 4
            StyledText {
                text: "Keyboard"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Bold
                color: "#fff"
            }
            StyledText {
                text: "Configure keyboard layout, repeat rate, accessibility, and more."
                font.pixelSize: Appearance.font.pixelSize.normal
                color: "#fff"
                opacity: 0.9
            }
        }
    }

    // Key Repeat Rate
    ColumnLayout {
        spacing: 12
        StyledText {
            text: "Key Repeat Rate"
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.Medium
            color: "#fff"
        }
        RowLayout {
            spacing: 24
            RowLayout {
                spacing: 8
                StyledText { text: "Delay (ms)"; color: "#fff" }
                ConfigSpinBox {
                    value: ConfigOptions.keyboard.repeatDelay
                    from: 100; to: 2000; stepSize: 10
                    onValueChanged: ConfigLoader.setConfigValue("keyboard.repeatDelay", value)
                }
            }
            RowLayout {
                spacing: 8
                StyledText { text: "Rate (per sec)"; color: "#fff" }
                ConfigSpinBox {
                    value: ConfigOptions.keyboard.repeatRate
                    from: 1; to: 50; stepSize: 1
                    onValueChanged: ConfigLoader.setConfigValue("keyboard.repeatRate", value)
                }
            }
        }
    }

    // Cursor Blink Rate
    ColumnLayout {
        spacing: 12
        StyledText {
            text: "Cursor Blink Rate"
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.Medium
            color: "#fff"
        }
        RowLayout {
            spacing: 8
            StyledText { text: "Blink interval (ms)"; color: "#fff" }
            ConfigSpinBox {
                value: ConfigOptions.keyboard.cursorBlinkInterval
                from: 100; to: 2000; stepSize: 10
                onValueChanged: ConfigLoader.setConfigValue("keyboard.cursorBlinkInterval", value)
            }
        }
    }

    // Keyboard Layouts
    ColumnLayout {
        spacing: 12
        StyledText {
            text: "Keyboard Layouts"
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.Medium
            color: "#fff"
        }
        RowLayout {
            spacing: 8
            ComboBox {
                id: layoutComboBox
                model: ConfigOptions.keyboard.availableLayouts
                textRole: "display"
                valueRole: "value"
                currentIndex: ConfigOptions.keyboard.availableLayouts.indexOf(ConfigOptions.keyboard.currentLayout)
                onActivated: {
                    ConfigLoader.setConfigValue("keyboard.currentLayout", model[currentIndex].value)
                }
                Layout.preferredWidth: 200
                background: Rectangle { color: Appearance.colors.colLayer2; radius: Appearance.rounding.normal }
                contentItem: StyledText { text: root.displayText; color: "#fff"; font.pixelSize: Appearance.font.pixelSize.normal }
            }
            Button {
                text: "+"
                onClicked: {/* Open add layout dialog */}
            }
            Button {
                text: "-"
                onClicked: {/* Remove selected layout */}
            }
            StyledText {
                text: "Switch shortcut: " + ConfigOptions.keyboard.switchShortcut
                color: "#fff"
                font.pixelSize: Appearance.font.pixelSize.small
                opacity: 0.7
            }
        }
        StyledText {
            text: "Preview: " + ConfigOptions.keyboard.currentLayoutPreview
            color: "#fff"
            font.pixelSize: Appearance.font.pixelSize.small
            opacity: 0.7
        }
    }

    // Caps Lock/Num Lock
    ColumnLayout {
        spacing: 12
        StyledText {
            text: "Lock Keys"
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.Medium
            color: "#fff"
        }
        RowLayout {
            spacing: 16
            ConfigSwitch {
                checked: ConfigOptions.keyboard.capsLockToggles
                onCheckedChanged: ConfigLoader.setConfigValue("keyboard.capsLockToggles", checked)
            }
            StyledText { text: "Caps Lock toggles case"; color: "#fff" }
            ConfigSwitch {
                checked: ConfigOptions.keyboard.numLockOnStartup
                onCheckedChanged: ConfigLoader.setConfigValue("keyboard.numLockOnStartup", checked)
            }
            StyledText { text: "Num Lock on startup"; color: "#fff" }
        }
    }

    // Compose Key
    ColumnLayout {
        spacing: 12
        StyledText {
            text: "Compose Key"
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.Medium
            color: "#fff"
        }
        RowLayout {
            spacing: 8
            ComboBox {
                id: composeComboBox
                model: ConfigOptions.keyboard.composeKeyOptions
                textRole: "display"
                valueRole: "value"
                currentIndex: ConfigOptions.keyboard.composeKeyOptions.indexOf(ConfigOptions.keyboard.composeKey)
                onActivated: {
                    ConfigLoader.setConfigValue("keyboard.composeKey", model[currentIndex].value)
                }
                Layout.preferredWidth: 200
                background: Rectangle { color: Appearance.colors.colLayer2; radius: Appearance.rounding.normal }
                contentItem: StyledText { text: root.displayText; color: "#fff"; font.pixelSize: Appearance.font.pixelSize.normal }
            }
        }
    }

    // Input Method (IME) Info
    ColumnLayout {
        spacing: 12
        StyledText {
            text: "Input Method (IME)"
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.Medium
            color: "#fff"
        }
        StyledText {
            text: "Advanced input methods (e.g. for Asian languages) can be configured via IBus, Fcitx, or similar tools."
            color: "#fff"
            font.pixelSize: Appearance.font.pixelSize.small
            opacity: 0.7
            wrapMode: Text.WordWrap
        }
    }

    // Accessibility
    ColumnLayout {
        spacing: 12
        StyledText {
            text: "Accessibility"
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.Medium
            color: "#fff"
        }
        RowLayout {
            spacing: 16
            ConfigSwitch {
                checked: ConfigOptions.keyboard.stickyKeys
                onCheckedChanged: ConfigLoader.setConfigValue("keyboard.stickyKeys", checked)
            }
            StyledText { text: "Sticky Keys"; color: "#fff" }
            ConfigSwitch {
                checked: ConfigOptions.keyboard.slowKeys
                onCheckedChanged: ConfigLoader.setConfigValue("keyboard.slowKeys", checked)
            }
            StyledText { text: "Slow Keys"; color: "#fff" }
            ConfigSwitch {
                checked: ConfigOptions.keyboard.bounceKeys
                onCheckedChanged: ConfigLoader.setConfigValue("keyboard.bounceKeys", checked)
            }
            StyledText { text: "Bounce Keys"; color: "#fff" }
        }
    }

    // Test Area
    ColumnLayout {
        spacing: 12
        StyledText {
            text: "Test Area"
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.Medium
            color: "#fff"
        }
        MaterialTextField {
            placeholderText: "Type here to test your keyboard settings..."
            Layout.fillWidth: true
        }
    }
} 