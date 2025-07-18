import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/modules/common/"
import "root:/modules/common/widgets/"
import "root:/modules/common/functions/color_utils.js" as ColorUtils

ColumnLayout {
    spacing: 24 * (root.scaleFactor ?? 1.0)
    anchors.left: parent ? parent.left : undefined
    anchors.leftMargin: 40 * (root.scaleFactor ?? 1.0)

    // Responsive scaling properties
    property real scaleFactor: root.scaleFactor ?? 1.0
    property int baseIconSize: 20
    property int baseSpacing: 12

    // Header
    RowLayout {
        spacing: 16 * scaleFactor
        Rectangle {
            width: 40 * scaleFactor; height: 40 * scaleFactor
            radius: Appearance.rounding.normal * scaleFactor
            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)
            MaterialSymbol {
                anchors.centerIn: parent
                text: "keyboard"
                iconSize: baseIconSize * scaleFactor
                color: "#000"
            }
        }
        ColumnLayout {
            spacing: 4 * scaleFactor
            StyledText {
                text: "Keyboard"
                font.pixelSize: (Appearance.font.pixelSize.large * scaleFactor)
                font.weight: Font.Bold
                color: "#fff"
            }
            StyledText {
                text: "Configure keyboard layout, repeat rate, accessibility, and more."
                font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                color: "#fff"
                opacity: 0.9
            }
        }
    }

    // Key Repeat Rate
    ColumnLayout {
        spacing: baseSpacing * scaleFactor
        StyledText {
            text: "Key Repeat Rate"
            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
            font.weight: Font.Medium
            color: "#fff"
        }
        RowLayout {
            spacing: 24 * scaleFactor
            RowLayout {
                spacing: 8 * scaleFactor
                StyledText { text: "Delay (ms)"; color: "#fff"; font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor) }
                ConfigSpinBox {
                    value: ConfigOptions.keyboard.repeatDelay
                    from: 100; to: 2000; stepSize: 10
                    onValueChanged: ConfigLoader.setConfigValue("keyboard.repeatDelay", value)
                }
            }
            RowLayout {
                spacing: 8 * scaleFactor
                StyledText { text: "Rate (per sec)"; color: "#fff"; font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor) }
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
        spacing: baseSpacing * scaleFactor
        StyledText {
            text: "Cursor Blink Rate"
            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
            font.weight: Font.Medium
            color: "#fff"
        }
        RowLayout {
            spacing: 8 * scaleFactor
            StyledText { text: "Blink interval (ms)"; color: "#fff"; font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor) }
            ConfigSpinBox {
                value: ConfigOptions.keyboard.cursorBlinkInterval
                from: 100; to: 2000; stepSize: 10
                onValueChanged: ConfigLoader.setConfigValue("keyboard.cursorBlinkInterval", value)
            }
        }
    }

    // Keyboard Layouts
    ColumnLayout {
        spacing: baseSpacing * scaleFactor
        StyledText {
            text: "Keyboard Layouts"
            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
            font.weight: Font.Medium
            color: "#fff"
        }
        RowLayout {
            spacing: 8 * scaleFactor
            ComboBox {
                id: layoutComboBox
                model: ConfigOptions.keyboard.availableLayouts
                textRole: "display"
                valueRole: "value"
                currentIndex: ConfigOptions.keyboard.availableLayouts.indexOf(ConfigOptions.keyboard.currentLayout)
                onActivated: {
                    ConfigLoader.setConfigValue("keyboard.currentLayout", model[currentIndex].value)
                }
                Layout.preferredWidth: 200 * scaleFactor
                background: Rectangle { color: Appearance.colors.colLayer2; radius: Appearance.rounding.normal * scaleFactor }
                contentItem: StyledText { text: root.displayText; color: "#fff"; font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor) }
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
                font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                opacity: 0.7
            }
        }
        StyledText {
            text: "Preview: " + ConfigOptions.keyboard.currentLayoutPreview
            color: "#fff"
            font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
            opacity: 0.7
        }
    }

    // Caps Lock/Num Lock
    ColumnLayout {
        spacing: baseSpacing * scaleFactor
        StyledText {
            text: "Lock Keys"
            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
            font.weight: Font.Medium
            color: "#fff"
        }
        RowLayout {
            spacing: 16 * scaleFactor
            ConfigSwitch {
                checked: ConfigOptions.keyboard.capsLockToggles
                onCheckedChanged: ConfigLoader.setConfigValue("keyboard.capsLockToggles", checked)
            }
            StyledText { text: "Caps Lock toggles case"; color: "#fff"; font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor) }
            ConfigSwitch {
                checked: ConfigOptions.keyboard.numLockOnStartup
                onCheckedChanged: ConfigLoader.setConfigValue("keyboard.numLockOnStartup", checked)
            }
            StyledText { text: "Num Lock on startup"; color: "#fff"; font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor) }
        }
    }

    // Compose Key
    ColumnLayout {
        spacing: baseSpacing * scaleFactor
        StyledText {
            text: "Compose Key"
            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
            font.weight: Font.Medium
            color: "#fff"
        }
        RowLayout {
            spacing: 8 * scaleFactor
            ComboBox {
                id: composeComboBox
                model: ConfigOptions.keyboard.composeKeyOptions
                textRole: "display"
                valueRole: "value"
                currentIndex: ConfigOptions.keyboard.composeKeyOptions.indexOf(ConfigOptions.keyboard.composeKey)
                onActivated: {
                    ConfigLoader.setConfigValue("keyboard.composeKey", model[currentIndex].value)
                }
                Layout.preferredWidth: 200 * scaleFactor
                background: Rectangle { color: Appearance.colors.colLayer2; radius: Appearance.rounding.normal * scaleFactor }
                contentItem: StyledText { text: root.displayText; color: "#fff"; font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor) }
            }
        }
    }

    // Input Method (IME) Info
    ColumnLayout {
        spacing: baseSpacing * scaleFactor
        StyledText {
            text: "Input Method (IME)"
            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
            font.weight: Font.Medium
            color: "#fff"
        }
        StyledText {
            text: "Advanced input methods (e.g. for Asian languages) can be configured via IBus, Fcitx, or similar tools."
            color: "#fff"
            font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
            opacity: 0.7
            wrapMode: Text.WordWrap
        }
    }

    // Accessibility
    ColumnLayout {
        spacing: baseSpacing * scaleFactor
        StyledText {
            text: "Accessibility"
            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
            font.weight: Font.Medium
            color: "#fff"
        }
        RowLayout {
            spacing: 16 * scaleFactor
            ConfigSwitch {
                checked: ConfigOptions.keyboard.stickyKeys
                onCheckedChanged: ConfigLoader.setConfigValue("keyboard.stickyKeys", checked)
            }
            StyledText { text: "Sticky Keys"; color: "#fff"; font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor) }
            ConfigSwitch {
                checked: ConfigOptions.keyboard.slowKeys
                onCheckedChanged: ConfigLoader.setConfigValue("keyboard.slowKeys", checked)
            }
            StyledText { text: "Slow Keys"; color: "#fff"; font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor) }
            ConfigSwitch {
                checked: ConfigOptions.keyboard.bounceKeys
                onCheckedChanged: ConfigLoader.setConfigValue("keyboard.bounceKeys", checked)
            }
            StyledText { text: "Bounce Keys"; color: "#fff"; font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor) }
        }
    }

    // Test Area
    ColumnLayout {
        spacing: baseSpacing * scaleFactor
        StyledText {
            text: "Test Area"
            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
            font.weight: Font.Medium
            color: "#fff"
        }
        MaterialTextField {
            placeholderText: "Type here to test your keyboard settings..."
            Layout.fillWidth: true
        }
    }
} 