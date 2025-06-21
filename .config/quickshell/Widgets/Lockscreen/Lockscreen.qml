import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "root:/Data" as Data
import "root:/Core" as Core

// Custom lockscreen
PanelWindow {
    id: lockScreen
    
    required property var shell
    property bool isLocked: false
    property bool isAuthenticated: false
    property string errorMessage: ""
    property int failedAttempts: 0
    property bool isAuthenticating: false
    property bool authSuccess: false
    property string usernameText: "Enter Password"
    
    // Animation state - controlled by timer for proper timing
    property bool animateIn: false
    
    // Full screen coverage
    screen: Quickshell.primaryScreen || Quickshell.screens[0]
    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    color: "transparent"
    
    // Top layer to block everything
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-lockscreen"
    
    visible: isLocked
    
    // Timer for slide-in animation - more reliable than Qt.callLater
    Timer {
        id: slideInTimer
        interval: 100  // Short delay to ensure window is fully rendered
        running: false
        onTriggered: {
            console.log("slideInTimer triggered, setting animateIn = true")
            animateIn = true
        }
    }
    
    // Timer for slide-out animation before hiding window
    Timer {
        id: slideOutTimer
        interval: 1000  // Wait for slide animation to complete
        running: false
        onTriggered: {
            isLocked = false
            authArea.clearPassword()
            errorMessage = ""
            failedAttempts = 0
            authSuccess = false
        }
    }
    
    // Timer to show success message before unlocking
    Timer {
        id: successTimer
        interval: 1200  // Show success message for 1.2 seconds
        running: false
        onTriggered: {
            unlock()
        }
    }
    
    // Reset animation state when window becomes invisible
    onVisibleChanged: {
        if (!visible) {
            animateIn = false
            authSuccess = false
            slideInTimer.stop()
            slideOutTimer.stop()
            successTimer.stop()
        }
    }
    
    // Background component
    LockscreenBackground {
        id: background
        isVisible: lockScreen.visible
    }

    // Main lockscreen content with slide-from-top animation
    Item {
        id: mainContent
        anchors.fill: parent
        focus: true  // Enable focus for keyboard handling
        
        // Dramatic slide animation - starts off-screen, slides down when animateIn is true
        transform: Translate {
            id: mainTransform
            y: lockScreen.animateIn ? 0 : -lockScreen.height
            Behavior on y {
                NumberAnimation {
                    duration: 800
                    easing.type: Easing.OutCubic
                }
            }
        }
        
        // Scale animation for extra drama
        scale: lockScreen.animateIn ? 1.0 : 0.98
        Behavior on scale {
            NumberAnimation {
                duration: 800
                easing.type: Easing.OutCubic
            }
        }
        
        // Keyboard shortcuts
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                authArea.clearPassword()
                errorMessage = ""
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (authArea.passwordField.text.length > 0) {
                    authenticate(authArea.passwordField.text)
                }
            }
        }
        
        // Time and date display component
        TimeDisplay {
            id: timeDisplay
            isVisible: lockScreen.animateIn
        }
        
        // Authentication area component
        AuthenticationArea {
            id: authArea
            isVisible: lockScreen.animateIn
            errorMessage: lockScreen.errorMessage
            isAuthenticating: lockScreen.isAuthenticating
            authSuccess: lockScreen.authSuccess
            usernameText: lockScreen.usernameText
            
            onPasswordEntered: function(password) {
                authenticate(password)
            }
        }
        
        // Power buttons component
        PowerButtons {
            id: powerButtons
            isVisible: lockScreen.animateIn
            
            onRebootRequested: rebootProcess.running = true
            onShutdownRequested: shutdownProcess.running = true
        }
    }
    
    // Authentication process using proper PAM authentication
    Process {
        id: authProcess
        property string password: ""
        command: ["sh", "-c", "echo '" + password.replace(/'/g, "'\"'\"'") + "' | sudo -S -k true"]
        running: false
        
        onExited: function(exitCode) {
            isAuthenticating = false
            
            if (exitCode === 0) {
                // Authentication successful
                isAuthenticated = true
                errorMessage = ""
                authSuccess = true
                // Show success message for a brief moment before unlocking
                successTimer.start()
            } else {
                // Authentication failed
                failedAttempts++
                errorMessage = failedAttempts === 1 ? "Incorrect password" : `Incorrect password (${failedAttempts} attempts)`
                authArea.clearPassword()
                
                // Add delay for failed attempts
                if (failedAttempts >= 3) {
                    lockoutTimer.start()
                }
            }
        }
    }
    
    // Lockout timer for failed attempts
    Timer {
        id: lockoutTimer
        interval: 30000 // 30 second lockout
        onTriggered: {
            errorMessage = ""
            authArea.passwordField.enabled = true
            authArea.focusPassword()
        }
    }
    
    // Reboot process
    Process {
        id: rebootProcess
        command: ["systemctl", "reboot"]
        running: false
        onExited: function(exitCode) { console.log("Reboot process completed with exit code:", exitCode) }
    }
    
    // Shutdown process
    Process {
        id: shutdownProcess
        command: ["systemctl", "poweroff"]
        running: false
        onExited: function(exitCode) { console.log("Shutdown process completed with exit code:", exitCode) }
    }
    
    // Get current username
    Process {
        id: usernameProcess
        command: ["whoami"]
        running: lockScreen.isLocked
        
        stdout: SplitParser {
            onRead: function(data) {
                const username = data.trim()
                if (username) {
                    usernameText = username.charAt(0).toUpperCase() + username.slice(1)
                }
            }
        }
    }
    
    // Public functions
    function lock() {
        console.log("Lockscreen.lock() called")
        
        // Reset animation state FIRST, before making window visible
        animateIn = false
        
        isLocked = true
        isAuthenticated = false
        authSuccess = false
        errorMessage = ""
        failedAttempts = 0
        authArea.clearPassword()
        usernameProcess.running = true
        
        // Trigger slide animation after a short delay
        console.log("Starting slideInTimer")
        slideInTimer.start()
    }
    
    function unlock() {
        console.log("Lockscreen.unlock() called")
        
        // Start slide-out animation first
        animateIn = false
        
        // Use timer for reliable timing before completely hiding
        slideOutTimer.start()
    }
    
    function authenticate(password) {
        if (isAuthenticating || password.length === 0) return
        
        console.log("Authenticating...")
        isAuthenticating = true
        authSuccess = false
        errorMessage = ""
        
        // Use sudo authentication
        authProcess.password = password
        authProcess.running = true
    }
    
    // Focus management when locked state changes
    onIsLockedChanged: {
        console.log("isLocked changed to:", isLocked)
        if (isLocked) {
            mainContent.focus = true
            authArea.focusPassword()
        }
    }
    
    // Clean up processes on destruction
    Component.onDestruction: {
        if (authProcess.running) authProcess.running = false
        if (rebootProcess.running) rebootProcess.running = false
        if (shutdownProcess.running) shutdownProcess.running = false
        if (usernameProcess.running) usernameProcess.running = false
        if (lockoutTimer.running) lockoutTimer.running = false
        if (slideInTimer.running) slideInTimer.running = false
        if (slideOutTimer.running) slideOutTimer.running = false
        if (successTimer.running) successTimer.running = false
    }
} 