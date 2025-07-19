import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import "./quickToggles/"
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
import Quickshell.Services.UPower

Scope {
    readonly property bool upowerReady: typeof PowerProfiles !== 'undefined' && PowerProfiles
    readonly property int currentProfile: upowerReady ? PowerProfiles.profile : 0
    
    // Independent sizing properties for right sidebar
    property int sidebarWidth: {
        // Base width scales with screen size - increased by 1.1x (10% wider)
        let baseWidth = Math.max(400, Screen.width * 0.22) // 22% of screen width, minimum 400px
        
        // Adjust based on screen resolution
        if (Screen.width >= 3840) { // 4K
            return Math.max(550, Screen.width * 0.20) // 20% for 4K (was 18%)
        } else if (Screen.width >= 2560) { // 2K
            return Math.max(495, Screen.width * 0.22) // 22% for 2K (was 20%)
        } else if (Screen.width >= 1920) { // 1080p
            return Math.max(418, Screen.width * 0.22) // 22% for 1080p (was 20%)
        } else if (Screen.width >= 1366) { // 720p
            return Math.max(418, Screen.width * 0.275) // 27.5% for 720p (was 25%)
        } else { // Small screens
            return Math.max(385, Screen.width * 0.308) // 30.8% for small screens (was 28%)
        }
    }
    
    property int sidebarWidthExtended: {
        // Extended width for content-heavy sidebars - increased by 1.1x (10% wider)
        let baseWidth = Math.max(600, Screen.width * 0.28) // 28% of screen width, minimum 600px
        
        // Adjust based on screen resolution
        if (Screen.width >= 3840) { // 4K
            return Math.max(770, Screen.width * 0.242) // 24.2% for 4K (was 22%)
        } else if (Screen.width >= 2560) { // 2K
            return Math.max(715, Screen.width * 0.275) // 27.5% for 2K (was 25%)
        } else if (Screen.width >= 1920) { // 1080p
            return Math.max(572, Screen.width * 0.275) // 27.5% for 1080p (was 25%)
        } else if (Screen.width >= 1366) { // 720p
            return Math.max(605, Screen.width * 0.352) // 35.2% for 720p (was 32%)
        } else { // Small screens
            return Math.max(550, Screen.width * 0.385) // 38.5% for small screens (was 35%)
        }
    }
    
    property int sidebarWidthWeather: {
        // Weather-optimized width - increased by 1.1x (10% wider)
        let baseWidth = Math.max(520, Screen.width * 0.24) // 24% of screen width, minimum 520px
        
        // Adjust based on screen resolution
        if (Screen.width >= 3840) { // 4K
            return Math.max(660, Screen.width * 0.211) // 21.1% for 4K (was 19.2%)
        } else if (Screen.width >= 2560) { // 2K
            return Math.max(616, Screen.width * 0.238) // 23.8% for 2K (was 21.6%)
        } else if (Screen.width >= 1920) { // 1080p
            return Math.max(528, Screen.width * 0.264) // 26.4% for 1080p (was 24%)
        } else if (Screen.width >= 1366) { // 720p
            return Math.max(528, Screen.width * 0.299) // 29.9% for 720p (was 27.2%)
        } else { // Small screens
            return Math.max(484, Screen.width * 0.326) // 32.6% for small screens (was 29.6%)
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
    
    property string currentSystemProfile: ""
    property bool showBluetoothDialog: false
    property bool pinned: false
    property real slideOffset: 0
    property bool isAnimating: false
    // Fix undefined QUrl assignments with default values
    property url wallpaperUrl: ConfigOptions.appearance?.wallpaper ?? ""
    
    // Content-aware width calculation
    property real contentAwareWidth: {
        // Base width from responsive sizing
        let baseWidth = sidebarWidth
        
        // Adjust based on content complexity and screen resolution
        if (centerWidgetGroup) {
            switch (centerWidgetGroup.selectedTab) {
                case 0: // Notifications - needs more space for notification content and tab text
                    if (Screen.width >= 1920) return Math.max(450, Screen.width * 0.24) // 24% for 1080p - increased for better tab spacing
                    else if (Screen.width >= 2560) return Math.max(500, Screen.width * 0.21) // 21% for 2K - increased
                    else if (Screen.width >= 3840) return Math.max(550, Screen.width * 0.19) // 19% for 4K - increased
                    else return Math.max(420, Screen.width * 0.25) // 25% for smaller screens - increased
                    
                case 1: // Volume mixer - needs more space for device list and volume controls
                    if (Screen.width >= 1920) return Math.max(460, Screen.width * 0.24) // 24% for 1080p - increased for better device display
                    else if (Screen.width >= 2560) return Math.max(520, Screen.width * 0.22) // 22% for 2K - increased
                    else if (Screen.width >= 3840) return Math.max(570, Screen.width * 0.20) // 20% for 4K - increased
                    else return Math.max(440, Screen.width * 0.26) // 26% for smaller screens - increased
                    
                case 2: // Weather - needs more space for 10-day forecast and weather details
                    if (Screen.width >= 1920) return Math.max(580, Screen.width * 0.30) // 30% for 1080p - increased for better forecast display
                    else if (Screen.width >= 2560) return Math.max(640, Screen.width * 0.28) // 28% for 2K
                    else if (Screen.width >= 3840) return Math.max(700, Screen.width * 0.25) // 25% for 4K
                    else return Math.max(540, Screen.width * 0.32) // 32% for smaller screens
                    
                case 3: // Calendar - needs space for calendar grid and todo list
                    if (Screen.width >= 1920) return Math.max(520, Screen.width * 0.27) // 27% for 1080p
                    else if (Screen.width >= 2560) return Math.max(580, Screen.width * 0.25) // 25% for 2K
                    else if (Screen.width >= 3840) return Math.max(640, Screen.width * 0.22) // 22% for 4K
                    else return Math.max(500, Screen.width * 0.29) // 29% for smaller screens
                    
                default:
                    return baseWidth
            }
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

    // Refresh system profile from powerprofilesctl
    function refreshSystemProfile() {
        getProfileProcess.running = true
    }

    Process {
        id: getProfileProcess
        command: ["powerprofilesctl", "get"]
        onExited: {
            if (getProfileProcess.stdout) {
                currentSystemProfile = getProfileProcess.stdout.trim()
            }
        }
    }

    Component.onCompleted: {
// console.log("[Sidebar] PowerProfiles.profile on load:", PowerProfiles.profile)
        refreshSystemProfile()
    }

    Connections {
        target: PowerProfiles
        function onProfileChanged() {
// console.log("[Sidebar] PowerProfiles.profile changed:", PowerProfiles.profile)
            refreshSystemProfile()
        }
    }

    Loader {
        id: sidebarLoader
        active: false
        onActiveChanged: {
            GlobalStates.sidebarRightOpen = sidebarLoader.active
        }

        PanelWindow {
            id: sidebarRoot
            visible: sidebarLoader.active

            function hide() {
                if (!pinned) {
                    sidebarLoader.active = false
                }
            }

            function show() {
                sidebarLoader.active = true
            }

            exclusiveZone: 0
            implicitWidth: contentAwareWidth
            WlrLayershell.namespace: "quickshell:sidebarRight"
            // Hyprland 0.49: Focus is always exclusive and setting this breaks mouse focus grab
            // WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            anchors {
                top: true
                right: true
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
                id: sidebarRightBackground
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
                    source: sidebarRightBackground
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

                    // Header with logo, uptime, and action buttons
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
                        
                        // Left side - Logo and uptime
                        RowLayout {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Math.max(12, parent.width * 0.02) // Responsive margins
                            spacing: Math.max(10, parent.width * 0.015) // Responsive spacing

                            Item {
                                implicitWidth: Math.max(25, parent.height * 0.35) // Responsive logo size
                                implicitHeight: Math.max(25, parent.height * 0.35)
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
                            }
                        }

                        // Right side - Buttons
                        RowLayout {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: Math.max(6, contentAwareWidth * 0.015) // Dynamic margins based on sidebar width
                            spacing: Math.max(2, contentAwareWidth * 0.005) // Dynamic spacing based on sidebar width

                            BatteryToggle {
                                visible: Battery.available
                                // Dynamic button size based on sidebar width
                                implicitWidth: Math.max(24, contentAwareWidth * 0.06)
                                implicitHeight: Math.max(24, contentAwareWidth * 0.06)
                            }

                            QuickToggleButton {
                                toggled: pinned
                                buttonIcon: "push_pin"
                                onClicked: pinned = !pinned
                                // Dynamic button size based on sidebar width
                                implicitWidth: Math.max(24, contentAwareWidth * 0.06)
                                implicitHeight: Math.max(24, contentAwareWidth * 0.06)
                                StyledToolTip {
                                    content: pinned ? qsTr("Unpin sidebar (auto-close)") : qsTr("Pin sidebar (keep open)")
                                }
                            }
                            
                            QuickToggleButton {
                                toggled: false
                                buttonIcon: "restart_alt"
                                onClicked: {
                                    Hyprland.dispatch("reload")
                                    Quickshell.reload(true)
                                }
                                // Dynamic button size based on sidebar width
                                implicitWidth: Math.max(24, contentAwareWidth * 0.06)
                                implicitHeight: Math.max(24, contentAwareWidth * 0.06)
                                StyledToolTip {
                                    content: qsTr("Reload Hyprland & Quickshell")
                                }
                            }
                            
                            QuickToggleButton {
                                toggled: false
                                buttonIcon: "settings"
                                onClicked: {
                                    Hyprland.dispatch("global quickshell:settingsOpen")
                                }
                                // Dynamic button size based on sidebar width
                                implicitWidth: Math.max(24, contentAwareWidth * 0.06)
                                implicitHeight: Math.max(24, contentAwareWidth * 0.06)
                                StyledToolTip {
                                    content: qsTr("Settings")
                                }
                            }
                            
                            QuickToggleButton {
                                toggled: false
                                buttonIcon: "power_settings_new"
                                onClicked: {
                                    Hyprland.dispatch("global quickshell:sessionOpen")
                                }
                                // Dynamic button size based on sidebar width
                                implicitWidth: Math.max(24, contentAwareWidth * 0.06)
                                implicitHeight: Math.max(24, contentAwareWidth * 0.06)
                                StyledToolTip {
                                    content: qsTr("Session")
                                }
                            }
                        }
                    }

                    // Quick toggle controls
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        radius: Appearance.rounding.full
                        color: Qt.rgba(
                            Appearance.colors.colLayer1.r,
                            Appearance.colors.colLayer1.g,
                            Appearance.colors.colLayer1.b,
                            0.55
                        )
                        border.color: Qt.rgba(1, 1, 1, 0.12)
                        border.width: 1
                        implicitHeight: sidebarQuickControlsRow.implicitHeight + Math.max(10, parent.height * 0.012) // Responsive height
                        
                        RowLayout {
                            id: sidebarQuickControlsRow
                            anchors.centerIn: parent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: Math.max(3, contentAwareWidth * 0.006) // Dynamic margins based on sidebar width
                            spacing: Math.max(6, contentAwareWidth * 0.012) // Dynamic spacing based on sidebar width
                            
                            Item { Layout.fillWidth: true }
                            
                            RowLayout {
                                spacing: Math.max(6, contentAwareWidth * 0.012) // Dynamic spacing based on sidebar width
                                Layout.alignment: Qt.AlignVCenter

                                NetworkToggle {
                                    Layout.alignment: Qt.AlignVCenter
                                    // Dynamic button size based on sidebar width
                                    implicitWidth: Math.max(26, contentAwareWidth * 0.065)
                                    implicitHeight: Math.max(26, contentAwareWidth * 0.065)
                                }
                                BluetoothToggle {
                                    id: bluetoothToggle
                                    Layout.alignment: Qt.AlignVCenter
                                    // Dynamic button size based on sidebar width
                                    implicitWidth: Math.max(26, contentAwareWidth * 0.065)
                                    implicitHeight: Math.max(26, contentAwareWidth * 0.065)
                                }
                                NightLight {
                                    Layout.alignment: Qt.AlignVCenter
                                    // Dynamic button size based on sidebar width
                                    implicitWidth: Math.max(26, contentAwareWidth * 0.065)
                                    implicitHeight: Math.max(26, contentAwareWidth * 0.065)
                                }
                                GameMode {
                                    Layout.alignment: Qt.AlignVCenter
                                    // Dynamic button size based on sidebar width
                                    implicitWidth: Math.max(26, contentAwareWidth * 0.065)
                                    implicitHeight: Math.max(26, contentAwareWidth * 0.065)
                                }
                                IdleInhibitor {
                                    Layout.alignment: Qt.AlignVCenter
                                    // Dynamic button size based on sidebar width
                                    implicitWidth: Math.max(26, contentAwareWidth * 0.065)
                                    implicitHeight: Math.max(26, contentAwareWidth * 0.065)
                                }
                                QuickToggleButton {
                                    id: perfProfilePerformance
                                    buttonIcon: "speed"
                                    toggled: PowerProfiles.profile === PowerProfile.Performance
                                    onClicked: PowerProfiles.profile = PowerProfile.Performance
                                    Layout.alignment: Qt.AlignVCenter
                                    // Dynamic button size based on sidebar width
                                    implicitWidth: Math.max(26, contentAwareWidth * 0.065)
                                    implicitHeight: Math.max(26, contentAwareWidth * 0.065)
                                    StyledToolTip { content: qsTr("Performance Mode") }
                                }
                                QuickToggleButton {
                                    id: perfProfileBalanced
                                    buttonIcon: "balance"
                                    toggled: PowerProfiles.profile === PowerProfile.Balanced
                                    onClicked: PowerProfiles.profile = PowerProfile.Balanced
                                    Layout.alignment: Qt.AlignVCenter
                                    // Dynamic button size based on sidebar width
                                    implicitWidth: Math.max(26, contentAwareWidth * 0.065)
                                    implicitHeight: Math.max(26, contentAwareWidth * 0.065)
                                    StyledToolTip { content: qsTr("Balanced Mode") }
                                }
                                QuickToggleButton {
                                    id: perfProfileSaver
                                    buttonIcon: "battery_saver"
                                    toggled: PowerProfiles.profile === PowerProfile.PowerSaver
                                    onClicked: PowerProfiles.profile = PowerProfile.PowerSaver
                                    Layout.alignment: Qt.AlignVCenter
                                    // Dynamic button size based on sidebar width
                                    implicitWidth: Math.max(26, contentAwareWidth * 0.065)
                                    implicitHeight: Math.max(26, contentAwareWidth * 0.065)
                                    StyledToolTip { content: qsTr("Power Saver Mode") }
                                }
                            }
                            
                            Item { Layout.fillWidth: true }
                        }
                    }

                    // Main content (tabs: notifications, volume, weather, calendar)
                    CenterWidgetGroup {
                        id: centerWidgetGroup
                        focus: sidebarRoot.visible
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "sidebarRight"

        function toggle(): void {
            if (sidebarLoader.active) {
                sidebarRoot.hide();
            } else {
                sidebarLoader.active = true;
                sidebarRoot.show();
                Notifications.timeoutAll();
            }
        }

        function close(): void {
            sidebarRoot.hide();
        }

        function open(): void {
            sidebarLoader.active = true;
            sidebarRoot.show();
            Notifications.timeoutAll();
        }
    }

    GlobalShortcut {
        name: "sidebarRightToggle"
        description: qsTr("Toggles right sidebar on press")

        onPressed: {
            if (sidebarLoader.active) {
                sidebarRoot.hide();
            } else {
                sidebarLoader.active = true;
                sidebarRoot.show();
                Notifications.timeoutAll();
            }
        }
    }
    GlobalShortcut {
        name: "sidebarRightOpen"
        description: qsTr("Opens right sidebar on press")

        onPressed: {
            sidebarLoader.active = true;
            sidebarRoot.show();
            Notifications.timeoutAll();
        }
    }
    GlobalShortcut {
        name: "sidebarRightClose"
        description: qsTr("Closes right sidebar on press")

        onPressed: {
            sidebarRoot.hide();
        }
    }

    // Process to set profile and refresh after
    Process {
        id: setProfileProcess
        command: ["true"]
        onExited: refreshSystemProfile()
    }

    Loader {
        id: bluetoothDialogLoader
        active: showBluetoothDialog
        visible: showBluetoothDialog
        z: 9999
        source: showBluetoothDialog ? "quickToggles/BluetoothConnectModule.qml" : ""
        onStatusChanged: {
            if (status === Loader.Error) {
// console.log("Bluetooth dialog failed to load:", errorString);
            }
        }
    }
}
