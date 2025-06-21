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

Scope {
    property int sidebarWidth: Appearance.sizes.sidebarWidth
    property int sidebarPadding: 15

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
                    Appearance.colors.colLayer0.r,
                    Appearance.colors.colLayer0.g,
                    Appearance.colors.colLayer0.b,
                    1 - AppearanceSettingsState.sidebarTransparency
                )
                radius: Appearance.rounding.screenRounding - Appearance.sizes.elevationMargin + 1

                // Add border
                Rectangle {
                    id: border
                    anchors.fill: parent
                    color: "transparent"
                    radius: parent.radius
                    border.width: 2
                    border.color: Qt.rgba(1, 1, 1, 0.2)
                }

                layer.enabled: true
                layer.effect: MultiEffect {
                    source: sidebarRightBackground
                    anchors.fill: sidebarRightBackground
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
                        Layout.alignment: Qt.AlignVCenter

                        Item {
                            implicitWidth: distroIcon.width
                            implicitHeight: distroIcon.height
                            Layout.alignment: Qt.AlignVCenter
                            CustomIcon {
                                id: distroIcon
                                width: 25
                                height: 25
                                source: SystemInfo.distroIcon
                            }
                            ColorOverlay {
                                anchors.fill: distroIcon
                                source: distroIcon
                                color: Appearance.colors.colOnLayer0
                            }
                        }

                        StyledText {
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer0
                            text: StringUtils.format(qsTr("Uptime: {0}"), DateTime.uptime)
                            textFormat: Text.MarkdownText
                            Layout.alignment: Qt.AlignVCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        StyledText {
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnLayer0
                            text: DateTime.time
                            Layout.leftMargin: 10
                            Layout.rightMargin: 0
                            Layout.topMargin: 2
                            Layout.bottomMargin: 2
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                            Layout.alignment: Qt.AlignVCenter
                            elide: Text.ElideRight
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
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
                            Layout.alignment: Qt.AlignVCenter
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
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillHeight: false
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colLayer1
                        implicitWidth: sidebarQuickControlsRow.implicitWidth + 10
                        implicitHeight: sidebarQuickControlsRow.implicitHeight + 10
                        
                        
                        RowLayout {
                            id: sidebarQuickControlsRow
                            anchors.fill: parent
                            anchors.margins: 5
                            spacing: 5

                            NetworkToggle {}
                            BluetoothToggle {}
                            NightLight {}
                            GameMode {}
                            IdleInhibitor {}
                            
                        }
                    }

                    // Center widget group
                    CenterWidgetGroup {
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

}
