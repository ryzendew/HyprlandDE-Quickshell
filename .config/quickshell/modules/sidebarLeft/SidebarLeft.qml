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
    property int sidebarWidth: Appearance.sizes.sidebarWidth
    property int sidebarPadding: 8
    property bool pinned: false
    property real slideOffset: 0
    property bool isAnimating: false

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
            implicitWidth: sidebarWidth
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
                    spacing: 6

                    // Header with logo and uptime
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
                        
                        // Logo and uptime
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 16

                            Item {
                                implicitWidth: 25
                                implicitHeight: 25
                                Layout.alignment: Qt.AlignVCenter
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
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Item { Layout.fillWidth: true }

                            QuickToggleButton {
                                buttonIcon: "push_pin"
                                toggled: pinned
                                onClicked: pinned = !pinned
                                Layout.alignment: Qt.AlignVCenter
                                StyledToolTip {
                                    content: pinned ? qsTr("Unpin sidebar (auto-close)") : qsTr("Pin sidebar (keep open)")
                                }
                            }
                        }
                    }

                    // Main content area with tabs
                    CenterWidgetGroup {
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