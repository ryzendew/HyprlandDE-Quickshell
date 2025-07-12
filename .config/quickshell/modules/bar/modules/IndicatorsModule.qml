import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"

Rectangle {
    id: indicatorsContainer
    Layout.margins: 4
    Layout.rightMargin: 2
    Layout.fillHeight: true
    implicitWidth: indicatorsRowLayout.implicitWidth + 20
    radius: Appearance.rounding.full
    color: (indicatorsMouseArea.pressed || GlobalStates.sidebarRightOpen) ? 
        Qt.rgba(Appearance.colors.colLayer1Active.r, Appearance.colors.colLayer1Active.g, Appearance.colors.colLayer1Active.b, 0.8) : 
        indicatorsMouseArea.hovered ? 
        Qt.rgba(Appearance.colors.colLayer1Hover.r, Appearance.colors.colLayer1Hover.g, Appearance.colors.colLayer1Hover.b, 0.8) : 
        "transparent"
    
    property bool hyprlandAvailable: true

    // Helper function to safely dispatch Hyprland commands
    function safeDispatch(command) {
        if (!hyprlandAvailable) return;
        
        try {
            Hyprland.dispatch(command);
        } catch (e) {
            hyprlandAvailable = false;
        }
    }

    Component.onCompleted: {
        // Skip Hyprland availability test since it causes warnings
        // Assume Hyprland is available since config is set up
        hyprlandAvailable = true;
    }
    
    // Mouse area only for the indicators section
    MouseArea {
        id: indicatorsMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        
        onPressed: (event) => {
            if (event.button === Qt.LeftButton) {
                safeDispatch('global quickshell:sidebarRightOpen')
            }
        }
    }
    
    RowLayout {
        id: indicatorsRowLayout
        anchors.centerIn: parent
        property real realSpacing: 15
        spacing: 0
        
        Revealer {
            reveal: Audio.sink?.audio?.muted ?? false
            Layout.fillHeight: true
            Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
            Behavior on Layout.rightMargin {
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }
            MaterialSymbol {
                text: "volume_off"
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnLayer0
            }
        }
        Revealer {
            reveal: Audio.source?.audio?.muted ?? false
            Layout.fillHeight: true
            Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
            Behavior on Layout.rightMargin {
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }
            MaterialSymbol {
                text: "mic_off"
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnLayer0
            }
        }
        // Network icons
        Item {
            width: Appearance.font.pixelSize.larger
            height: Appearance.font.pixelSize.larger
            Layout.rightMargin: indicatorsRowLayout.realSpacing - 1.5
            
            RowLayout {
                anchors.fill: parent
                spacing: 4

                // Ethernet icon
                Rectangle {
                    Layout.preferredWidth: Appearance.font.pixelSize.larger * 0.85
                    Layout.preferredHeight: Appearance.font.pixelSize.larger * 0.85
                    color: "transparent"
                    visible: Network.networkType === "ethernet"

                    AnimatedEthernetIcon {
                        anchors.fill: parent
                        iconSize: parent.width
                        iconColor: Appearance.colors.colOnLayer0
                    }
                }

                // WiFi icon
                Rectangle {
                    id: wifiIconRect
                    Layout.preferredWidth: Appearance.font.pixelSize.larger * 0.85
                    Layout.preferredHeight: Appearance.font.pixelSize.larger * 0.85
                    color: "transparent"
                    visible: Network.networkType === "wifi"

                    Image {
                        id: wifiIcon
                        anchors.fill: parent
                        source: "image://icon/" + (Network.wifiEnabled ? (
                            Network.networkStrength >= 90 ? "network-wireless-signal-excellent" :
                            Network.networkStrength >= 80 ? "network-wireless-signal-good" :
                            Network.networkStrength >= 65 ? "network-wireless-signal-ok" :
                            Network.networkStrength >= 45 ? "network-wireless-signal-weak" :
                            Network.networkStrength >= 25 ? "network-wireless-signal-none" :
                            Network.networkStrength >= 10 ? "network-wireless-signal-none" :
                            "network-wireless-signal-none"
                        ) : "network-wireless-offline") || "network-wireless"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        opacity: Network.wifiEnabled ? 1.0 : 0.5
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: false
                    }
                }
            }
        }
        MaterialSymbol {
            text: Bluetooth.bluetoothConnected ? "bluetooth_connected" : Bluetooth.bluetoothEnabled ? "bluetooth" : "bluetooth_disabled"
            iconSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colOnLayer0
        }
    }
} 