import "../"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

QuickToggleButton {
    toggled: Battery.isPluggedIn
    buttonIcon: Battery.isPluggedIn ? (Battery.isFullyCharged ? "power" : "battery_charging_full") :
                Battery.isCritical ? "battery_alert" :
                Battery.isLow ? "battery_low" :
                "battery_6_bar"
    
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton | Qt.LeftButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                // Could open battery settings or show detailed info
                console.log("Battery clicked")
            }
            if (mouse.button === Qt.RightButton) {
                // Could show battery menu or settings
                console.log("Battery right-clicked")
            }
        }
        hoverEnabled: false
        propagateComposedEvents: true
        cursorShape: Qt.PointingHandCursor 
    }
    
    StyledToolTip {
        content: Battery.isFullyCharged
            ? StringUtils.format(qsTr("Fully charged ({0}%)\nHealth: {1}%"), 
                Math.round((Battery.percentage > 1 ? Battery.percentage : Battery.percentage * 100)),
                Battery.batteryHealth.toFixed(1))
            : StringUtils.format(qsTr("Battery: {0}%\n{1}"), 
                Math.round((Battery.percentage > 1 ? Battery.percentage : Battery.percentage * 100)),
                Battery.statusText)
    }
} 