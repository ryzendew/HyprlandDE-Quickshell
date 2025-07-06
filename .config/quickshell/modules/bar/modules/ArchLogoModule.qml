import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "root:/modules/common"
import "root:/services"

Rectangle {
    id: archLogoContainer
    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
    Layout.leftMargin: 2
    Layout.fillWidth: false
    
    radius: Appearance.rounding.full
    color: archMouseArea.containsMouse ? 
        Qt.rgba(Appearance.colors.colLayer1Active.r, Appearance.colors.colLayer1Active.g, Appearance.colors.colLayer1Active.b, 0.8) : 
        "transparent"
    implicitWidth: archLogo.width + 10
    implicitHeight: archLogo.height + 10

    Image {
        id: archLogo
        anchors.centerIn: parent
        width: 22
        height: 22
        source: SystemPaths.getLogoPath()
        fillMode: Image.PreserveAspectFit
    }
    
    // Mouse area only for the Arch logo
    MouseArea {
        id: archMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        
        onClicked: {
            GlobalStates.hyprMenuOpen = !GlobalStates.hyprMenuOpen
        }
        
        onPressed: (event) => {
            if (event.button === Qt.LeftButton) {
                Hyprland.dispatch('global quickshell:sidebarLeftOpen')
            }
        }
    }
} 