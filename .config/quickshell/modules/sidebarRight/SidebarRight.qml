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

    // Refresh system profile from powerprofilesctl
    function refreshSystemProfile() {
        getProfileProcess.start()
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
        onProfileChanged: {
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

            function hide() {
                if (!pinned) sidebarLoader.active = false
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
                                Image {
                                    id: cachyosLogo
                                    width: 25
                                    height: 25
                                    source: "root:/assets/icons/cachyos-symbolic.svg"
                                    fillMode: Image.PreserveAspectFit
                                }
                                ColorOverlay {
                                    anchors.fill: cachyosLogo
                                    source: cachyosLogo
                                    color: "#00ffcc"
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
                            spacing: 0

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
            sidebarLoader.active = !sidebarLoader.active;
            if(sidebarLoader.active) Notifications.timeoutAll();
        }

        function close(): void {
            sidebarLoader.active = false;
        }

        function open(): void {
            sidebarLoader.active = true;
            Notifications.timeoutAll();
        }
    }

    GlobalShortcut {
        name: "sidebarRightToggle"
        description: qsTr("Toggles right sidebar on press")

        onPressed: {
            sidebarLoader.active = !sidebarLoader.active;
            if(sidebarLoader.active) Notifications.timeoutAll();
        }
    }
    GlobalShortcut {
        name: "sidebarRightOpen"
        description: qsTr("Opens right sidebar on press")

        onPressed: {
            sidebarLoader.active = true;
            Notifications.timeoutAll();
        }
    }
    GlobalShortcut {
        name: "sidebarRightClose"
        description: qsTr("Closes right sidebar on press")

        onPressed: {
            sidebarLoader.active = false;
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
        source: showBluetoothDialog ? "quickToggles/BluetoothConnectModule.qml" : undefined
        onStatusChanged: {
            if (status === Loader.Error) {
                console.log("Bluetooth dialog failed to load:", errorString);
            }
        }
    }
    Connections {
        target: bluetoothToggle
        onRequestBluetoothDialog: showBluetoothDialog = true
    }
}
