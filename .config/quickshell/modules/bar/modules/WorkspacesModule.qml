import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "root:/modules/common"
import "../"

Item {
    Layout.alignment: Qt.AlignCenter | Qt.AlignVCenter
    implicitWidth: workspaces.implicitWidth
    implicitHeight: workspaces.implicitHeight
    
    property var bar: null // Will be set by parent
    
    Workspaces {
        id: workspaces
        bar: parent.bar
        anchors.fill: parent
        
        MouseArea { // Right-click to toggle overview
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onPressed: (event) => {
                if (event.button === Qt.RightButton) {
                    Hyprland.dispatch('global quickshell:overviewToggle')
                }
            }
        }
    }
} 