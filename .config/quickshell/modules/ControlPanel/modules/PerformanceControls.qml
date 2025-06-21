import QtQuick
import QtQuick.Controls
import Quickshell.Services.UPower

// Power profile controls
Column {
    id: root
    required property var shell
    
    spacing: 8
    signal performanceActionRequested(string action)
    signal mouseChanged(bool containsMouse)
    
    readonly property bool containsMouse: performanceButton.containsMouse || 
                                         balancedButton.containsMouse || 
                                         powerSaverButton.containsMouse
    
    // Safe UPower service access with fallback checks
    readonly property bool upowerReady: typeof PowerProfiles !== 'undefined' && PowerProfiles
    readonly property int currentProfile: upowerReady ? PowerProfiles.profile : 0
    
    onContainsMouseChanged: root.mouseChanged(containsMouse)
    
    opacity: visible ? 1 : 0
    
    Behavior on opacity {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    Row {
        spacing: 8
        width: parent.width

        // Performance mode button
        SystemButton {
            id: performanceButton
            width: (parent.width - parent.spacing * 2) / 3
            height: 52
            
            shell: root.shell
            iconText: "speed"
            
            isActive: root.upowerReady && (typeof PowerProfile !== 'undefined') ? 
                      root.currentProfile === PowerProfile.Performance : false
            
            onClicked: {
                if (root.upowerReady && typeof PowerProfile !== 'undefined') {
                    PowerProfiles.profile = PowerProfile.Performance
                    root.performanceActionRequested("performance")
                } else {
                    console.warn("PowerProfiles not available")
                }
            }
            onMouseChanged: function(containsMouse) {
                if (!containsMouse && !root.containsMouse) {
                    root.mouseChanged(false)
                }
            }
        }
        
        // Balanced mode button
        SystemButton {
            id: balancedButton
            width: (parent.width - parent.spacing * 2) / 3
            height: 52
            
            shell: root.shell
            iconText: "balance"
            
            isActive: root.upowerReady && (typeof PowerProfile !== 'undefined') ? 
                      root.currentProfile === PowerProfile.Balanced : false
            
            onClicked: {
                if (root.upowerReady && typeof PowerProfile !== 'undefined') {
                    PowerProfiles.profile = PowerProfile.Balanced
                    root.performanceActionRequested("balanced")
                } else {
                    console.warn("PowerProfiles not available")
                }
            }
            onMouseChanged: function(containsMouse) {
                if (!containsMouse && !root.containsMouse) {
                    root.mouseChanged(false)
                }
            }
        }
        
        // Power saver mode button
        SystemButton {
            id: powerSaverButton
            width: (parent.width - parent.spacing * 2) / 3
            height: 52
            
            shell: root.shell
            iconText: "battery_saver"
            
            isActive: root.upowerReady && (typeof PowerProfile !== 'undefined') ? 
                      root.currentProfile === PowerProfile.PowerSaver : false
            
            onClicked: {
                if (root.upowerReady && typeof PowerProfile !== 'undefined') {
                    PowerProfiles.profile = PowerProfile.PowerSaver
                    root.performanceActionRequested("powersaver")
                } else {
                    console.warn("PowerProfiles not available")
                }
            }
            onMouseChanged: function(containsMouse) {
                if (!containsMouse && !root.containsMouse) {
                    root.mouseChanged(false)
                }
            }
        }
    }
    
    // Ensure UPower service initialization
    Component.onCompleted: {
        Qt.callLater(function() {
            if (!root.upowerReady) {
                console.warn("UPower service not ready - performance controls may not work correctly")
            }
        })
    }
}