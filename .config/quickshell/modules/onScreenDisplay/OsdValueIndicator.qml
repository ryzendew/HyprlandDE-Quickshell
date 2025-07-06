import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

Item {
    id: root
    required property real value
    required property string icon
    required property string name
    property bool rotateIcon: false
    property bool scaleIcon: false

    Layout.margins: Appearance.sizes.elevationMargin
    implicitWidth: 280
    implicitHeight: 80

    // Modern glass effect background
    Rectangle {
        id: backgroundBlur
        anchors.fill: parent
        radius: 20
        color: Qt.rgba(0, 0, 0, 0.6)
        border.color: Qt.rgba(1, 1, 1, 0.2)
        border.width: 1
        
        // Subtle shadow
        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 4
            radius: 16
            samples: 33
            color: Qt.rgba(0, 0, 0, 0.4)
        }
    }

    // Glass overlay effect
    Rectangle {
        anchors.fill: parent
        radius: 20
        color: "transparent"
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1
        
        // Subtle inner glow
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 19
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // Icon section
        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignVCenter
            color: Qt.rgba(1, 1, 1, 0.1)
            radius: 12
            
            MaterialSymbol {
                    anchors.centerIn: parent
                color: "#ffffff"
                    text: root.icon
                iconSize: 24

                    Behavior on iconSize {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }
                }
            }

        // Content section
        ColumnLayout {
            Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            spacing: 8

            // Title and percentage row
            RowLayout {
                        Layout.fillWidth: true
                spacing: 0

                Text {
                        text: root.name
                    color: "#ffffff"
                    font.pixelSize: 16
                    font.weight: Font.Medium
                }
                
                Item {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 12
                }

                Text {
                    text: Math.round(root.value * 100) + "%"
                    color: "#ffffff"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignRight
                }
            }

            // Modern progress bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                color: Qt.rgba(1, 1, 1, 0.2)
                radius: 3

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * root.value
                    height: parent.height
                    color: "#ffffff"
                    radius: 3
                    
                    Behavior on width {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutQuad
                }
            }
        }
            }
        }
    }
    
    // Entrance animation
    NumberAnimation on opacity {
        id: entranceAnimation
        running: false
        from: 0
        to: 1
        duration: 250
        easing.type: Easing.OutQuad
    }
    
    NumberAnimation on scale {
        id: scaleAnimation
        running: false
        from: 0.8
        to: 1.0
        duration: 250
        easing.type: Easing.OutBack
    }
    
    Component.onCompleted: {
        entranceAnimation.start()
        scaleAnimation.start()
    }
}