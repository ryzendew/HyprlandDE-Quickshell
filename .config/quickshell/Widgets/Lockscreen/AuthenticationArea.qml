import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "root:/Data" as Data

// Authentication area
Column {
    id: authColumn
    anchors.centerIn: parent
    anchors.verticalCenterOffset: 80
    spacing: 20
    width: 300
    
    required property bool isVisible
    required property string errorMessage
    required property bool isAuthenticating
    required property bool authSuccess
    required property string usernameText
    
    signal passwordEntered(string password)
    
    // Expose password field
    readonly property alias passwordField: passwordField
    
    // Subtle slide up animation (after main slide)
    transform: Translate {
        id: authTransform
        y: isVisible ? 0 : 50
        Behavior on y {
            SequentialAnimation {
                PauseAnimation { duration: 600 }  // Wait for main slide and time
                NumberAnimation {
                    duration: 600
                    easing.type: Easing.OutBack
                }
            }
        }
    }
    
    opacity: isVisible ? 1.0 : 0.0
    Behavior on opacity {
        SequentialAnimation {
            PauseAnimation { duration: 700 }  // Wait for time to appear
            NumberAnimation {
                duration: 600
                easing.type: Easing.OutCubic
            }
        }
    }
    
    // User avatar with circular masking
    Rectangle {
        id: avatarContainer
        width: 100
        height: 100
        radius: 50
        anchors.horizontalCenter: parent.horizontalCenter
        color: "transparent"
        border.color: Data.Colors.accentColor
        border.width: 4
        clip: true
        
        // Scale animation for avatar
        scale: isVisible ? 1.0 : 0.0
        Behavior on scale {
            SequentialAnimation {
                PauseAnimation { duration: 1000 }  // Wait for auth area to appear
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutBack
                }
            }
        }
        
        Image {
            id: avatarImage
            anchors.fill: parent
            anchors.margins: 4
            source: Data.Settings.avatarSource
            fillMode: Image.PreserveAspectCrop
            cache: false
            visible: false  // Hidden for masking
            asynchronous: true
            sourceSize.width: 92
            sourceSize.height: 92
        }

        // Apply circular mask to avatar
        OpacityMask {
            anchors.fill: avatarImage
            source: avatarImage
            maskSource: Rectangle {
                width: avatarImage.width
                height: avatarImage.height
                radius: 46
                visible: false
            }
        }
        
        // Fallback icon if avatar fails to load
        Text {
            anchors.centerIn: parent
            text: "person"
            font.family: "Material Symbols Outlined"
            font.pixelSize: 48
            color: Data.Colors.accentColor
            visible: avatarImage.status !== Image.Ready
        }
    }
    
    // Username display
    Text {
        id: usernameDisplay
        anchors.horizontalCenter: parent.horizontalCenter
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 18
        color: Data.Colors.primaryText
        text: usernameText
    }
    
    // Password input field
    Rectangle {
        width: parent.width
        height: 50
        radius: 25
        color: Data.Colors.withOpacity(Data.Colors.bgLighter, 0.4)
        border.color: passwordField.activeFocus ? Data.Colors.accentColor : Data.Colors.withOpacity(Data.Colors.border, 0.6)
        border.width: 2
        
        TextInput {
            id: passwordField
            anchors.fill: parent
            anchors.margins: 15
            echoMode: TextInput.Normal
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 16
            color: "transparent"  // Hide the actual text
            selectionColor: Data.Colors.accentColor
            selectByMouse: true
            focus: isVisible
            
            onAccepted: {
                if (text.length > 0) {
                    passwordEntered(text)
                }
            }
            
            // Password mask with better spaced dots
            Row {
                id: passwordDotsRow
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                spacing: 8
                visible: passwordField.text.length > 0
                
                property int previousLength: 0
                
                Repeater {
                    id: passwordRepeater
                    model: passwordField.text.length
                    delegate: Rectangle {
                        id: passwordDot
                        width: 8
                        height: 8
                        radius: 4
                        color: Data.Colors.primaryText
                        
                        property bool isNewDot: index >= passwordDotsRow.previousLength
                        
                        // Only animate new dots, existing ones stay visible
                        scale: isNewDot ? 0 : 1.0
                        opacity: isNewDot ? 0 : 1.0
                        
                        ParallelAnimation {
                            running: passwordDot.isNewDot
                            
                            NumberAnimation {
                                target: passwordDot
                                property: "scale"
                                from: 0
                                to: 1.0
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                            
                            NumberAnimation {
                                target: passwordDot
                                property: "opacity"
                                from: 0
                                to: 1.0
                                duration: 150
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                }
                
                // Track length changes to identify new dots
                Connections {
                    target: passwordField
                    function onTextChanged() {
                        // Update previous length after a short delay to allow new dots to be marked as new
                        Qt.callLater(function() {
                            passwordDotsRow.previousLength = passwordField.text.length
                        })
                    }
                }
            }
            
            // Placeholder text
            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                text: "Password"
                font.family: passwordField.font.family
                font.pixelSize: passwordField.font.pixelSize
                color: Data.Colors.withOpacity(Data.Colors.secondaryText, 0.7)
                visible: passwordField.text.length === 0 && !passwordField.activeFocus
            }
        }
    }
    
    // Error message
    Text {
        id: errorText
        anchors.horizontalCenter: parent.horizontalCenter
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 14
        color: Data.Colors.errorColor
        text: errorMessage
        visible: errorMessage !== ""
        wrapMode: Text.WordWrap
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
    }
    
    // Authentication status
    Text {
        id: statusText
        anchors.horizontalCenter: parent.horizontalCenter
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 14
        color: authSuccess ? Data.Colors.success : Data.Colors.accentColorBright
        text: {
            if (authSuccess) return "Authentication successful!"
            if (isAuthenticating) return "Authenticating..."
            return ""
        }
        visible: isAuthenticating || authSuccess
    }
    
    // Public function to clear password
    function clearPassword() {
        passwordField.text = ""
        passwordField.focus = true
    }
    
    // Public function to focus password field
    function focusPassword() {
        passwordField.focus = true
    }
} 