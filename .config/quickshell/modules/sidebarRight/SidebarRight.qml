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
    property int sidebarWidth: Appearance.sizes.sidebarWidth
    property int sidebarPadding: 8
    property string currentSystemProfile: ""
    property bool showBluetoothDialog: false
    property bool pinned: false
    property real slideOffset: 0
    property bool isAnimating: false
    // Fix undefined QUrl assignments with default values
    property url wallpaperUrl: ConfigOptions.appearance?.wallpaper ?? ""

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
        console.log("[Sidebar] PowerProfiles.profile on load:", PowerProfiles.profile)
        refreshSystemProfile()
    }

    Connections {
        target: PowerProfiles
        function onProfileChanged() {
            console.log("[Sidebar] PowerProfiles.profile changed:", PowerProfiles.profile)
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

            // Animation properties for slide effect
            property real slideOffset: 0
            property bool isAnimating: false

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
                    to: slideOffset
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
                    sidebarLoader.active = false
                    isAnimating = false
                    sidebarRoot.opacity = 1.0  // Reset opacity for next time
                }
            }

            // Slide in animation (opening)
            SequentialAnimation {
                id: slideInAnimation
                ScriptAction {
                    script: {
                        sidebarRoot.x = slideOffset
                        sidebarRoot.opacity = 0.0  // Start transparent
                    }
                }
                ParallelAnimation {
                    NumberAnimation {
                        target: sidebarRoot
                        property: "x"
                        from: slideOffset
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
            implicitWidth: sidebarWidth
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
                width: parent.width - Appearance.sizes.hyprlandGapsOut * 2
                height: parent.height - Appearance.sizes.hyprlandGapsOut * 2
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
                    spacing: 6

                    // Header with logo, uptime, and action buttons
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
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
                            anchors.leftMargin: 12
                            spacing: 10

                            Item {
                                implicitWidth: 25
                                implicitHeight: 25
                                antialiasing: true
                                Image {
                                    id: nobaraLogo
                                    width: 25
                                    height: 25
                                    source: "root:/assets/icons/Nobara-linux-logo.svg"
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    antialiasing: true
                                    sourceSize.width: 25
                                    sourceSize.height: 25
                                    layer.enabled: true
                                    layer.smooth: true
                                }
                                ColorOverlay {
                                    anchors.fill: nobaraLogo
                                    source: nobaraLogo
                                    color: "white"
                                }
                            }

                            StyledText {
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer0
                                text: StringUtils.format(qsTr("Uptime: {0}"), DateTime.uptime)
                                textFormat: Text.MarkdownText
                            }
                        }

                        // Right side - Buttons
                        RowLayout {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: 12
                            spacing: 4

                            BatteryToggle {
                                visible: Battery.available
                            }

                            QuickToggleButton {
                                toggled: pinned
                                buttonIcon: "push_pin"
                                onClicked: pinned = !pinned
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
                        implicitHeight: sidebarQuickControlsRow.implicitHeight + 10
                        
                        RowLayout {
                            id: sidebarQuickControlsRow
                            anchors.centerIn: parent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 5
                            spacing: 14
                            
                            Item { Layout.fillWidth: true }
                            
                            RowLayout {
                                spacing: 14
                                Layout.alignment: Qt.AlignVCenter

                                NetworkToggle {
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                BluetoothToggle {
                                    id: bluetoothToggle
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                NightLight {
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                GameMode {
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                IdleInhibitor {
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                QuickToggleButton {
                                    id: perfProfilePerformance
                                    buttonIcon: "speed"
                                    toggled: PowerProfiles.profile === PowerProfile.Performance
                                    onClicked: PowerProfiles.profile = PowerProfile.Performance
                                    Layout.alignment: Qt.AlignVCenter
                                    StyledToolTip { content: qsTr("Performance Mode") }
                                }
                                QuickToggleButton {
                                    id: perfProfileBalanced
                                    buttonIcon: "balance"
                                    toggled: PowerProfiles.profile === PowerProfile.Balanced
                                    onClicked: PowerProfiles.profile = PowerProfile.Balanced
                                    Layout.alignment: Qt.AlignVCenter
                                    StyledToolTip { content: qsTr("Balanced Mode") }
                                }
                                QuickToggleButton {
                                    id: perfProfileSaver
                                    buttonIcon: "battery_saver"
                                    toggled: PowerProfiles.profile === PowerProfile.PowerSaver
                                    onClicked: PowerProfiles.profile = PowerProfile.PowerSaver
                                    Layout.alignment: Qt.AlignVCenter
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
                console.log("Bluetooth dialog failed to load:", errorString);
            }
        }
    }
}
