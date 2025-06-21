pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: colors

    // Dark theme (OLED optimized)
    readonly property var darkTheme: ({
        base00: "#141414",    // Background
        base01: "#1e1e24",    // Panel background
        base02: "#2a2a32",    // Selection background
        base03: "#545466",    // Borders and muted elements
        base04: "#9395a5",    // Secondary text
        base05: "#e2e4ef",    // Primary text
        base06: "#eceef7",    // Bright text
        base07: "#f7f9ff",    // Brightest text
        base08: "#f0707e",    // Red
        base09: "#f5a97f",    // Orange
        base0A: "#f5d767",    // Yellow
        base0B: "#8ccf7e",    // Green
        base0C: "#79dac8",    // Cyan
        base0D: "#86aaec",    // Blue
        base0E: "#c488ec",    // Purple (primary accent)
        base0F: "#f4a4be"     // Pink
    })

    // Light theme
    readonly property var lightTheme: ({
        base00: "#fafafa",    // Background
        base01: "#f0f1f4",    // Panel background
        base02: "#e4e6ed",    // Selection background
        base03: "#9699aa",    // Borders and muted elements
        base04: "#535773",    // Secondary text
        base05: "#2c324a",    // Primary text
        base06: "#1c2033",    // Strong text
        base07: "#0f111a",    // Strongest text
        base08: "#d95468",    // Red
        base09: "#e87c3e",    // Orange
        base0A: "#d98e48",    // Yellow
        base0B: "#34a461",    // Green
        base0C: "#26a6a6",    // Cyan
        base0D: "#4876d6",    // Blue
        base0E: "#8a3fdc",    // Purple (primary accent)
        base0F: "#f4a4be"     // Pink
    })

    // Theme state from Settings
    readonly property bool isDarkTheme: Settings.isDarkTheme

    // Dynamic color properties
    readonly property color base00: isDarkTheme ? darkTheme.base00 : lightTheme.base00
    readonly property color base01: isDarkTheme ? darkTheme.base01 : lightTheme.base01
    readonly property color base02: isDarkTheme ? darkTheme.base02 : lightTheme.base02
    readonly property color base03: isDarkTheme ? darkTheme.base03 : lightTheme.base03
    readonly property color base04: isDarkTheme ? darkTheme.base04 : lightTheme.base04
    readonly property color base05: isDarkTheme ? darkTheme.base05 : lightTheme.base05
    readonly property color base06: isDarkTheme ? darkTheme.base06 : lightTheme.base06
    readonly property color base07: isDarkTheme ? darkTheme.base07 : lightTheme.base07
    readonly property color base08: isDarkTheme ? darkTheme.base08 : lightTheme.base08
    readonly property color base09: isDarkTheme ? darkTheme.base09 : lightTheme.base09
    readonly property color base0A: isDarkTheme ? darkTheme.base0A : lightTheme.base0A
    readonly property color base0B: isDarkTheme ? darkTheme.base0B : lightTheme.base0B
    readonly property color base0C: isDarkTheme ? darkTheme.base0C : lightTheme.base0C
    readonly property color base0D: isDarkTheme ? darkTheme.base0D : lightTheme.base0D
    readonly property color base0E: isDarkTheme ? darkTheme.base0E : lightTheme.base0E
    readonly property color base0F: isDarkTheme ? darkTheme.base0F : lightTheme.base0F

    // Semantic color mappings
    readonly property color bgColor: base00
    readonly property color bgLight: base01
    readonly property color bgLighter: base02
    readonly property color fgColor: base04
    readonly property color fgColorBright: base05
    readonly property color accentColor: base0E
    readonly property color accentColorBright: base0D
    readonly property color highlightBg: Qt.rgba(base0E.r, base0E.g, base0E.b, 0.15)
    readonly property color errorColor: base08
    readonly property color greenColor: base0B
    readonly property color redColor: base08

    // Alternative semantic aliases
    readonly property color background: base00
    readonly property color panelBackground: base01
    readonly property color selection: base02
    readonly property color border: base03
    readonly property color secondaryText: base04
    readonly property color primaryText: base05
    readonly property color brightText: base06
    readonly property color brightestText: base07
    readonly property color error: base08
    readonly property color warning: base09
    readonly property color highlight: base0A
    readonly property color success: base0B
    readonly property color info: base0C
    readonly property color primary: base0D
    readonly property color accent: base0E
    readonly property color special: base0F

    // UI styling constants
    readonly property real borderWidth: 9
    readonly property real cornerRadius: 20

    // Utility functions
    function withOpacity(color, opacity) {
        return Qt.rgba(color.r, color.g, color.b, opacity)
    }

    function withHighlight(color) {
        return Qt.rgba(color.r, color.g, color.b, 0.15)
    }

    // Theme switching function - delegates to Settings
    function toggleTheme() {
        Settings.isDarkTheme = !Settings.isDarkTheme
    }
}
