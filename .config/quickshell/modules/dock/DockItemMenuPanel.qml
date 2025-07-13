import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import "root:/modules/common"
import "root:/modules/common/widgets"

PanelWindow {
    id: menuRoot
    color: "#000000"
    visible: true
    x: clickPos.x // Position at the global mouse x
    y: clickPos.y // Position at the global mouse y
    width: menuWidth
    height: menuContent.implicitHeight
    radius: Appearance.rounding.small
    property var appInfo: ({})
    property bool isPinned: false
    property point clickPos: Qt.point(0, 0)
    property int menuWidth: 200
    
    // Signals
    signal pinApp()
    signal unpinApp()
    signal closeApp()
    
    function show(pos) {
        clickPos = pos
        visible = true
        // Force layout update before positioning
        menuContent.implicitHeight = menuContent.childrenRect.height + menuContent.padding * 2
    }
    
    function hide() {
        visible = false
        destroy()
    }
    
    implicitWidth: menuWidth
    implicitHeight: menuContent.implicitHeight
    
    // Menu content
    Rectangle {
        id: menuContent
        anchors.fill: parent
        color: "#000000" // Solid black background
        radius: Appearance.rounding.small // Keep rounded corners
        property int padding: 4
        // No effects, no shadows
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: menuContent.padding
            spacing: 2
            
            MenuButton {
                Layout.fillWidth: true
                buttonText: isPinned ? qsTr("Unpin from dock") : qsTr("Pin to dock")
                // Force white text
                contentItem: Text {
                    text: isPinned ? qsTr("Unpin from dock") : qsTr("Pin to dock")
                    color: "#ffffff"
                    font: button.font
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    if (isPinned) {
                        menuRoot.unpinApp()
                    } else {
                        menuRoot.pinApp()
                    }
                    menuRoot.hide()
                }
            }
            
            MenuButton {
                Layout.fillWidth: true
                buttonText: qsTr("Launch new instance")
                contentItem: Text {
                    text: qsTr("Launch new instance")
                    color: "#ffffff"
                    font: button.font
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    if (appInfo.class) {
                        dock.launchApp(appInfo.class)
                    }
                    menuRoot.hide()
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#444444" // Solid dark gray separator
            }
            
            MenuButton {
                Layout.fillWidth: true
                buttonText: qsTr("Move to workspace")
                enabled: appInfo.address !== undefined
                contentItem: Text {
                    text: qsTr("Move to workspace")
                    color: "#ffffff"
                    font: button.font
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    if (appInfo.address) {
                        Hyprland.dispatch(`movetoworkspace +1,address:${appInfo.address}`)
                    }
                    menuRoot.hide()
                }
            }
            
            MenuButton {
                Layout.fillWidth: true
                buttonText: qsTr("Toggle floating")
                enabled: appInfo.address !== undefined
                contentItem: Text {
                    text: qsTr("Toggle floating")
                    color: "#ffffff"
                    font: button.font
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    if (appInfo.address) {
                        Hyprland.dispatch(`togglefloating address:${appInfo.address}`)
                    }
                    menuRoot.hide()
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#444444" // Solid dark gray separator
            }
            
            MenuButton {
                Layout.fillWidth: true
                buttonText: qsTr("Close")
                contentItem: Text {
                    text: qsTr("Close")
                    color: "#ffffff"
                    font: button.font
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    if (appInfo.address) {
                        Hyprland.dispatch(`closewindow address:${appInfo.address}`)
                    } else if (appInfo.pid) {
                        Hyprland.dispatch(`closewindow pid:${appInfo.pid}`)
                    } else {
                        Hyprland.dispatch(`closewindow class:${appInfo.class}`)
                    }
                    menuRoot.closeApp()
                    menuRoot.hide()
                }
            }
        }
    }
    
    Component.onCompleted: {
        // Calculate menu position
        var screen = Qt.application.screens[0];
        var menuW = width;
        var menuH = height;
        var xPos = clickPos.x;
        var yPos = clickPos.y;

        // If menu would go off right edge, shift left
        if (xPos + menuW > screen.width) xPos = screen.width - menuW - 5;
        // If menu would go off bottom edge, shift up
        if (yPos + menuH > screen.height) yPos = screen.height - menuH - 5;
        // If menu would go off left edge, shift right
        if (xPos < 0) xPos = 5;
        // If menu would go off top edge, shift down
        if (yPos < 0) yPos = 5;

        x = xPos;
        y = yPos;
    }
} 