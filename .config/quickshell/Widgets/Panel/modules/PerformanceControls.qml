import QtQuick
import QtQuick.Controls
import Quickshell.Services.UPower

Column {
    id: root
    required property var shell
    
    spacing: 8
    signal performanceActionRequested(string action)
    signal mouseChanged(bool containsMouse)
    
    readonly property bool containsMouse: performanceButton.containsMouse || 
                                         balancedButton.containsMouse || 
                                         powerSaverButton.containsMouse
    
    // Safe property access with fallbacks
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

        // Performance Profile Button
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
        
        // Balanced Profile Button
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
        
        // Power Saver Profile Button
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
    
    // Optional: Add a small delay to ensure services are ready
    Component.onCompleted: {
        // Small delay to ensure UPower service is fully initialized
        Qt.callLater(function() {
            if (!root.upowerReady) {
                console.warn("UPower service not ready - performance controls may not work correctly")
            }
        })
    }
}