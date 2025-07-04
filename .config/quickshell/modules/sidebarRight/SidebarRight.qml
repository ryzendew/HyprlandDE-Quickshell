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
    property int sidebarPadding: 15
    property string currentSystemProfile: ""
    property bool showBluetoothDialog: false

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
                sidebarLoader.active = false
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
                    if (!active) sidebarRoot.hide()
                }
            }

            // Background
            Rectangle {
                id: sidebarRightBackground
                anchors.centerIn: parent
                width: parent.width - Appearance.sizes.hyprlandGapsOut * 2
                height: parent.height - Appearance.sizes.hyprlandGapsOut * 2
                color: Qt.rgba(
                    Appearance.colors.colLayer1.r,
                    Appearance.colors.colLayer1.g,
                    Appearance.colors.colLayer1.b,
                    0.55
                )
                radius: Appearance.rounding.screenRounding - Appearance.sizes.elevationMargin + 1
                border.width: 2
                border.color: Appearance.colors.colOutline
                layer.enabled: true
                layer.effect: MultiEffect {
                    source: sidebarRightBackground
                    shadowEnabled: true
                    shadowColor: Appearance.colors.colShadow
                    shadowVerticalOffset: 1
                    shadowBlur: 0.5
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                    }
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        sidebarRoot.hide();
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: sidebarPadding
                    
                    spacing: sidebarPadding

                    RowLayout {
                        Layout.fillHeight: false
                        spacing: 10
                        Layout.margins: 10
                        Layout.topMargin: 5
                        Layout.bottomMargin: 0

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
                                color: "#00ffcc"  // CachyOS brand teal color
                            }
                        }

                        StyledText {
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer0
                            text: StringUtils.format(qsTr("Uptime: {0}"), DateTime.uptime)
                            textFormat: Text.MarkdownText
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        QuickToggleButton {
                            toggled: false
                            buttonIcon: "refresh"
                            onClicked: {
                                Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
                            }
                            StyledToolTip {
                                content: qsTr("Reload Quickshell")
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
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillHeight: false
                        radius: Appearance.rounding.full
                        color: Qt.rgba(
                            Appearance.colors.colLayer1.r,
                            Appearance.colors.colLayer1.g,
                            Appearance.colors.colLayer1.b,
                            0.55
                        )
                        implicitWidth: sidebarQuickControlsRow.implicitWidth + 10
                        implicitHeight: sidebarQuickControlsRow.implicitHeight + 10
                        
                        
                        RowLayout {
                            id: sidebarQuickControlsRow
                            anchors.fill: parent
                            anchors.margins: 5
                            spacing: 5

                            NetworkToggle {}
                            BluetoothToggle {
                                id: bluetoothToggle
                            }
                            NightLight {}
                            GameMode {}
                            IdleInhibitor {}
                            QuickToggleButton {
                                id: perfProfilePerformance
                                buttonIcon: "speed"
                                toggled: PowerProfiles.profile === PowerProfile.Performance
                                onClicked: PowerProfiles.profile = PowerProfile.Performance
                                StyledToolTip { content: qsTr("Performance Mode") }
                            }
                            QuickToggleButton {
                                id: perfProfileBalanced
                                buttonIcon: "balance"
                                toggled: PowerProfiles.profile === PowerProfile.Balanced
                                onClicked: PowerProfiles.profile = PowerProfile.Balanced
                                StyledToolTip { content: qsTr("Balanced Mode") }
                            }
                            QuickToggleButton {
                                id: perfProfileSaver
                                buttonIcon: "battery_saver"
                                toggled: PowerProfiles.profile === PowerProfile.PowerSaver
                                onClicked: PowerProfiles.profile = PowerProfile.PowerSaver
                                StyledToolTip { content: qsTr("Power Saver Mode") }
                            }
                        }
                    }

                    // Center widget group
                    CenterWidgetGroup {
                        id: centerWidgetGroup
                        focus: sidebarRoot.visible
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                    }

                    BottomWidgetGroup {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillHeight: false
                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight
                        hideCalendar: centerWidgetGroup.selectedTab === 3
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
