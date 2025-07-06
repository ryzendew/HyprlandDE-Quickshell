import "root:/services/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property bool showOsdValues: false
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)

    function triggerOsd() {
        showOsdValues = true
        osdTimeout.restart()
    }

    Timer {
        id: osdTimeout
        interval: ConfigOptions.osd.timeout
        repeat: false
        running: false
        onTriggered: {
            root.showOsdValues = false
        }
    }

    Connections {
        target: Brightness
        function onBrightnessChanged() {
            showOsdValues = false
        }
    }

    Connections { // Listen to volume changes to hide microphone OSD
        target: Audio.sink?.audio ?? null
        function onVolumeChanged() {
            if (!Audio.ready) return
            root.showOsdValues = false
        }
    }

    Connections { // Listen to microphone volume changes
        target: Audio.source?.audio ?? null
        function onVolumeChanged() {
            if (!Audio.ready) return
            root.triggerOsd()
        }
        function onMutedChanged() {
            if (!Audio.ready) return
            root.triggerOsd()
        }
    }

    Loader {
        id: osdLoader
        active: showOsdValues

        sourceComponent: PanelWindow {
            id: osdRoot

            Connections {
                target: root
                function onFocusedScreenChanged() {
                    osdRoot.screen = root.focusedScreen
                }
            }

            exclusionMode: ExclusionMode.Normal
            WlrLayershell.namespace: "quickshell:onScreenDisplayMicrophone"
            WlrLayershell.layer: WlrLayer.Overlay
            color: "transparent"

            anchors {
                top: !ConfigOptions.bar.bottom
                bottom: ConfigOptions.bar.bottom
            }
            mask: Region {
                item: osdValuesWrapper
            }

            implicitWidth: columnLayout.implicitWidth
            implicitHeight: columnLayout.implicitHeight
            visible: osdLoader.active

            ColumnLayout {
                id: columnLayout
                anchors.horizontalCenter: parent.horizontalCenter
                Item {
                    id: osdValuesWrapper
                    // Extra space for shadow
                    implicitHeight: contentColumnLayout.implicitHeight + Appearance.sizes.elevationMargin * 2
                    implicitWidth: contentColumnLayout.implicitWidth
                    clip: true

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.showOsdValues = false
                    }

                    ColumnLayout {
                        id: contentColumnLayout
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            leftMargin: Appearance.sizes.elevationMargin
                            rightMargin: Appearance.sizes.elevationMargin
                        }
                        spacing: 0

                        OsdValueIndicator {
                            id: osdValues
                            Layout.fillWidth: true
                            value: Audio.source?.audio.volume ?? 0
                            icon: Audio.source?.audio.muted ? "mic_off" : "mic"
                            name: qsTr("Microphone")
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "osdMicrophone"

        function trigger() {
            root.triggerOsd()
        }

        function hide() {
            showOsdValues = false
        }

        function toggle() {
            showOsdValues = !showOsdValues
        }
    }

    GlobalShortcut {
        name: "osdMicrophoneTrigger"
        description: qsTr("Triggers microphone OSD on press")

        onPressed: {
            root.triggerOsd()
        }
    }
    GlobalShortcut {
        name: "osdMicrophoneHide"
        description: qsTr("Hides microphone OSD on press")

        onPressed: {
            root.showOsdValues = false
        }
    }
} 