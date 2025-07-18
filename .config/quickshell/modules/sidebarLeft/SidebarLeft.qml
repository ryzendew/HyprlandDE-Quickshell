import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import "../sidebarRight/quickToggles"

Scope {
    // Independent sizing properties for left sidebar
    property int sidebarWidth: {
        // Base width scales with screen size
        let baseWidth = Math.max(400, Screen.width * 0.22) // 22% of screen width, minimum 400px
        
        // Adjust based on screen resolution
        if (Screen.width >= 3840) { // 4K
            return Math.max(500, Screen.width * 0.18) // 18% for 4K
        } else if (Screen.width >= 2560) { // 2K
            return Math.max(450, Screen.width * 0.20) // 20% for 2K
        } else if (Screen.width >= 1920) { // 1080p
            return Math.max(420, Screen.width * 0.22) // 22% for 1080p
        } else if (Screen.width >= 1366) { // 720p
            return Math.max(380, Screen.width * 0.25) // 25% for 720p
        } else { // Small screens
            return Math.max(350, Screen.width * 0.28) // 28% for small screens
        }
    }
    
    property int sidebarWidthExtended: {
        // Extended width for content-heavy tabs
        let baseWidth = Math.max(600, Screen.width * 0.28) // 28% of screen width, minimum 600px
        
        // Adjust based on screen resolution
        if (Screen.width >= 3840) { // 4K
            return Math.max(700, Screen.width * 0.22) // 22% for 4K
        } else if (Screen.width >= 2560) { // 2K
            return Math.max(650, Screen.width * 0.25) // 25% for 2K
        } else if (Screen.width >= 1920) { // 1080p
            return Math.max(600, Screen.width * 0.28) // 28% for 1080p
        } else if (Screen.width >= 1366) { // 720p
            return Math.max(550, Screen.width * 0.32) // 32% for 720p
        } else { // Small screens
            return Math.max(500, Screen.width * 0.35) // 35% for small screens
        }
    }
    
    property int sidebarPadding: {
        if (Screen.width >= 3840) return Math.max(16, Screen.height * 0.012) // 4K
        else if (Screen.width >= 2560) return Math.max(14, Screen.height * 0.014) // 2K
        else if (Screen.width >= 1920) return Math.max(12, Screen.height * 0.016) // 1080p
        else if (Screen.width >= 1366) return Math.max(10, Screen.height * 0.018) // 720p
        else return Math.max(8, Screen.height * 0.02) // Small screens
    }
    
    property int sidebarSpacing: {
        if (Screen.width >= 3840) return Math.max(8, Screen.height * 0.006) // 4K
        else if (Screen.width >= 2560) return Math.max(7, Screen.height * 0.007) // 2K
        else if (Screen.width >= 1920) return Math.max(6, Screen.height * 0.008) // 1080p
        else if (Screen.width >= 1366) return Math.max(5, Screen.height * 0.01) // 720p
        else return Math.max(4, Screen.height * 0.012) // Small screens
    }
    
    property int sidebarHeaderHeight: {
        if (Screen.width >= 3840) return Math.max(70, Screen.height * 0.04) // 4K
        else if (Screen.width >= 2560) return Math.max(65, Screen.height * 0.045) // 2K
        else if (Screen.width >= 1920) return Math.max(60, Screen.height * 0.05) // 1080p
        else if (Screen.width >= 1366) return Math.max(55, Screen.height * 0.055) // 720p
        else return Math.max(50, Screen.height * 0.06) // Small screens
    }
    
    property int hyprlandGapsOut: 5
    
    property bool pinned: false
    property real slideOffset: 0
    property bool isAnimating: false
    
    // Content-aware width calculation
    property real contentAwareWidth: {
        // Base width from responsive sizing
        let baseWidth = sidebarWidth
        
        // Adjust based on content complexity
        if (centerWidgetGroup && centerWidgetGroup.selectedTab === 2) { // System Status tab
            // System status has more complex content, use extended width
            return sidebarWidthExtended
        }
        
        return baseWidth
    }
    
    // Dynamic width adjustment with animation
    property real currentWidth: contentAwareWidth
    
    // Timer to smoothly adjust width when content changes
    Timer {
        id: widthAdjustmentTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (Math.abs(currentWidth - contentAwareWidth) > 5) { // Only animate if difference is significant
                widthAnimation.start()
            }
        }
    }
    
    // Width animation
    NumberAnimation {
        id: widthAnimation
        target: sidebarRoot
        property: "implicitWidth"
        from: currentWidth
        to: contentAwareWidth
        duration: 300
        easing.type: Easing.OutCubic
        onFinished: {
            currentWidth = contentAwareWidth
        }
    }
    
    // Monitor content changes
    Connections {
        target: centerWidgetGroup
        function onSelectedTabChanged() {
            widthAdjustmentTimer.start()
        }
    }
    
    // Monitor screen size changes
    Connections {
        target: Screen
        function onWidthChanged() {
            // Adjust sidebar width when screen size changes
            widthAdjustmentTimer.start()
        }
        function onHeightChanged() {
            // Adjust sidebar width when screen size changes
            widthAdjustmentTimer.start()
        }
    }

    Loader {
        id: sidebarLoader
        active: GlobalStates.sidebarLeftOpen

        Connections {
            target: GlobalStates
            function onSidebarLeftOpenChanged() {
                if (GlobalStates.sidebarLeftOpen && sidebarLoader.active) {
                    sidebarRoot.show()
                } else if (!GlobalStates.sidebarLeftOpen && sidebarRoot.visible) {
                    sidebarRoot.hide()
                }
            }
        }

        PanelWindow {
            id: sidebarRoot
            visible: sidebarLoader.active

            // Animation properties for slide effect
            property real slideOffset: 0
            property bool isAnimating: false
            property real x: 0
            property real opacity: 1.0

            function hide() {
                if (!pinned) {
                    isAnimating = true
                    slideOutAnimation.start()
                }
            }

            function show() {
                isAnimating = true
                slideInAnimation.start()
            }

            // Slide out animation (closing)
            ParallelAnimation {
                id: slideOutAnimation
                NumberAnimation {
                    target: sidebarRoot
                    property: "x"
                    from: 0
                    to: -slideOffset
                    duration: 200
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: sidebarRoot
                    property: "opacity"
                    from: 1.0
                    to: 0.0
                    duration: 200
                    easing.type: Easing.OutCubic
                }
                onFinished: {
                    GlobalStates.sidebarLeftOpen = false
                    isAnimating = false
                    sidebarRoot.opacity = 1.0  // Reset opacity for next time
                }
            }

            // Slide in animation (opening)
            SequentialAnimation {
                id: slideInAnimation
                ScriptAction {
                    script: {
                        sidebarRoot.x = -slideOffset
                        sidebarRoot.opacity = 0.0  // Start transparent
                    }
                }
                ParallelAnimation {
                    NumberAnimation {
                        target: sidebarRoot
                        property: "x"
                        from: -slideOffset
                        to: 0
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: sidebarRoot
                        property: "opacity"
                        from: 0.0
                        to: 1.0
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
                ScriptAction {
                    script: {
                        isAnimating = false
                    }
                }
            }

            // Initialize position when component is created
            Component.onCompleted: {
                x = 0
                opacity = 1.0
            }

            exclusiveZone: 0
            implicitWidth: contentAwareWidth
            WlrLayershell.namespace: "quickshell:sidebarLeft"
            color: "transparent"

            anchors {
                top: true
                left: true
                bottom: true
            }

            HyprlandFocusGrab {
                id: grab
                windows: [ sidebarRoot ]
                active: sidebarRoot.visible
                onCleared: () => {
                    if (!active && !pinned) sidebarRoot.hide()
                }
            }

            // Modern Background
            Rectangle {
                id: sidebarLeftBackground
                anchors.centerIn: parent
                width: parent.width - hyprlandGapsOut * 2
                height: parent.height - hyprlandGapsOut * 2
                radius: Appearance.rounding.verylarge
                
                gradient: Gradient {
                    GradientStop { 
                        position: 0.0
                        color: Qt.rgba(
                            Appearance.colors.colLayer1.r,
                            Appearance.colors.colLayer1.g,
                            Appearance.colors.colLayer1.b,
                            0.75
                        )
                    }
                    GradientStop { 
                        position: 1.0
                        color: Qt.rgba(
                            Appearance.colors.colLayer1.r,
                            Appearance.colors.colLayer1.g,
                            Appearance.colors.colLayer1.b,
                            0.65
                        )
                    }
                }
                
                border.width: 1
                border.color: Qt.rgba(
                    Appearance.colors.colOutline.r,
                    Appearance.colors.colOutline.g,
                    Appearance.colors.colOutline.b,
                    0.3
                )
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    source: sidebarLeftBackground
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.15)
                    shadowVerticalOffset: 8
                    shadowHorizontalOffset: 0
                    shadowBlur: 24
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: parent.radius - 1
                    color: "transparent"
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                    }
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape && !pinned) {
                        sidebarRoot.hide();
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: sidebarPadding
                    spacing: sidebarSpacing

                    // Header with logo and uptime
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: sidebarHeaderHeight
                        radius: Appearance.rounding.large
                        color: Qt.rgba(
                            Appearance.colors.colLayer1.r,
                            Appearance.colors.colLayer1.g,
                            Appearance.colors.colLayer1.b,
                            0.3
                        )
                        border.color: Qt.rgba(1, 1, 1, 0.15)
                        border.width: 1
                        
                        // Logo and uptime
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Math.max(12, parent.width * 0.02) // Responsive margins
                            spacing: Math.max(16, parent.width * 0.025) // Responsive spacing

                            Item {
                                implicitWidth: Math.max(25, parent.height * 0.35) // Responsive logo size
                                implicitHeight: Math.max(25, parent.height * 0.35)
                                Layout.alignment: Qt.AlignVCenter
                                antialiasing: true
                                Image {
                                    id: nobaraLogo
                                    width: parent.width
                                    height: parent.height
                                    source: "root:/assets/icons/" + (ConfigOptions.appearance.logo || "distro-nobara-symbolic.svg")
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    antialiasing: true
                                    sourceSize.width: parent.width
                                    sourceSize.height: parent.height
                                    layer.enabled: true
                                    layer.smooth: true
                                }
                                ColorOverlay {
                                    anchors.fill: nobaraLogo
                                    source: nobaraLogo
                                    color: ConfigOptions.appearance.logoColor || "#ffffff"
                                }
                            }

                            StyledText {
                                font.pixelSize: Math.max(Appearance.font.pixelSize.normal, parent.height * 0.25) // Responsive font size
                                color: Appearance.colors.colOnLayer0
                                text: StringUtils.format(qsTr("Uptime: {0}"), DateTime.uptime)
                                textFormat: Text.MarkdownText
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Item { Layout.fillWidth: true }

                            QuickToggleButton {
                                buttonIcon: "push_pin"
                                toggled: pinned
                                onClicked: pinned = !pinned
                                Layout.alignment: Qt.AlignVCenter
                                // Scale button size with sidebar width
                                implicitWidth: Math.max(32, parent.height * 0.4)
                                implicitHeight: Math.max(32, parent.height * 0.4)
                                StyledToolTip {
                                    content: pinned ? qsTr("Unpin sidebar (auto-close)") : qsTr("Pin sidebar (keep open)")
                                }
                            }
                        }
                    }

                    // Main content area with tabs
                    CenterWidgetGroup {
                        id: centerWidgetGroup
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "sidebarLeft"

        function toggle(): void {
            if (sidebarLoader.active) {
                sidebarRoot.hide();
            } else {
                sidebarLoader.active = true;
                sidebarRoot.show();
            }
        }

        function close(): void {
            sidebarRoot.hide();
        }

        function open(): void {
            sidebarLoader.active = true;
            sidebarRoot.show();
        }
    }

    GlobalShortcut {
        name: "sidebarLeftToggle"
        description: qsTr("Toggles left sidebar on press")

        onPressed: {
            if (sidebarLoader.active) {
                sidebarRoot.hide();
            } else {
                sidebarLoader.active = true;
                sidebarRoot.show();
            }
        }
    }

    GlobalShortcut {
        name: "sidebarLeftOpen"
        description: qsTr("Opens left sidebar on press")

        onPressed: {
            sidebarLoader.active = true;
            sidebarRoot.show();
        }
    }

    GlobalShortcut {
        name: "sidebarLeftClose"
        description: qsTr("Closes left sidebar on press")

        onPressed: {
            sidebarRoot.hide();
        }
    }
} 