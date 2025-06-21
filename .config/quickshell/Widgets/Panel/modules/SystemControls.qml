import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

RowLayout {
    id: root
    required property var shell
    
    spacing: 8
    signal systemActionRequested(string action)
    signal mouseChanged(bool containsMouse)
    
    readonly property bool containsMouse: lockButton.containsMouse || 
                                        rebootButton.containsMouse || 
                                        shutdownButton.containsMouse
    
    onContainsMouseChanged: root.mouseChanged(containsMouse)
    
    opacity: visible ? 1 : 0
    
    Behavior on opacity {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    // Lock Button
    SystemButton {
        id: lockButton
        Layout.fillHeight: true
        Layout.fillWidth: true
        
        shell: root.shell
        iconText: "lock"
        
        onClicked: {
            console.log("Lock button clicked")
            console.log("root.shell:", root.shell)
            console.log("root.shell.lockscreen:", root.shell ? root.shell.lockscreen : "shell is null")
            
            // Directly trigger custom lockscreen
            if (root.shell && root.shell.lockscreen) {
                console.log("Calling root.shell.lockscreen.lock()")
                root.shell.lockscreen.lock()
            } else {
                console.log("Fallback to systemActionRequested")
                // Fallback to system action for compatibility
                root.systemActionRequested("lock")
            }
        }
        onMouseChanged: function(containsMouse) {
            if (!containsMouse && !root.containsMouse) {
                root.mouseChanged(false)
            }
        }
    }

    // Reboot Button
    SystemButton {
        id: rebootButton
        Layout.fillHeight: true
        Layout.fillWidth: true
        
        shell: root.shell
        iconText: "restart_alt"
        
        onClicked: root.systemActionRequested("reboot")
        onMouseChanged: function(containsMouse) {
            if (!containsMouse && !root.containsMouse) {
                root.mouseChanged(false)
            }
        }
    }

    // Shutdown Button
    SystemButton {
        id: shutdownButton
        Layout.fillHeight: true
        Layout.fillWidth: true
        
        shell: root.shell
        iconText: "power_settings_new"
        
        onClicked: root.systemActionRequested("shutdown")
        onMouseChanged: function(containsMouse) {
            if (!containsMouse && !root.containsMouse) {
                root.mouseChanged(false)
            }
        }
    }
}