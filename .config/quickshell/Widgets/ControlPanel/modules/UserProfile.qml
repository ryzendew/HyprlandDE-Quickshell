import Quickshell.Io
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "root:/Data/" as Data

// User profile card
Rectangle {
    id: root
    required property var shell
    property url avatarSource: Data.Settings.avatarSource
    property string userName: ""        // will be set by process output
    property string userInfo: ""        // will hold uptime string

    property bool isActive: false
    property bool isHovered: false      // track hover state

    radius: 20
    width: 220
    height: 80

    // Dynamic color based on hover and active states
    color: {
        if (isActive) {
            return isHovered ?
                   Qt.lighter(Data.Colors.accentColor, 1.1) :
                   Qt.rgba(Data.Colors.accentColor.r, Data.Colors.accentColor.g, Data.Colors.accentColor.b, 0.3)
        } else {
            return isHovered ?
                   Qt.lighter(Data.Colors.accentColor, 1.2) :
                   Qt.darker(Data.Colors.bgColor, 1.05)
        }
    }

    border.width: isActive ? 2 : 1
    border.color: isActive ? Data.Colors.accentColor : Qt.darker(Data.Colors.bgColor, 1.1)

    Row {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12
        anchors.verticalCenter: parent.verticalCenter

        // Avatar
        Rectangle {
            id: avatarCircle
            width: 52
            height: 52
            radius: 20
            clip: true
            border.color: Data.Colors.accentColor
            border.width: 3
            color: "transparent"

            Image {
                id: avatarImage
                anchors.fill: parent
                anchors.margins: 2
                source: Data.Settings.avatarSource
                fillMode: Image.PreserveAspectCrop
                cache: false
                visible: false  // Hidden for masking
                asynchronous: true
                sourceSize.width: 48  // Memory optimization
                sourceSize.height: 48
            }

            // Apply circular mask to avatar
            OpacityMask {
                anchors.fill: avatarImage
                source: avatarImage
                maskSource: Rectangle {
                    width: avatarImage.width
                    height: avatarImage.height
                    radius: 18  // Proportional to parent radius
                    visible: false
                }
            }
        }

        // User information text
        Column {
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - avatarCircle.width - gifContainer.width - parent.spacing * 2

            Text {
                width: parent.width
                text: root.userName === "" ? "Loading..." : root.userName
                font.pixelSize: 16
                font.bold: true
                color: isHovered || root.isActive ? "#ffffff" : Data.Colors.accentColor
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                width: parent.width
                text: root.userInfo === "" ? "Loading uptime..." : root.userInfo
                font.pixelSize: 11
                font.bold: true
                color: isHovered || root.isActive ? "#cccccc" : Qt.lighter(Data.Colors.accentColor, 1.6)
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        // Animated GIF with rounded corners
        Rectangle {
            id: gifContainer
            width: 80
            height: 80
            radius: 12
            color: "transparent"
            anchors.verticalCenter: parent.verticalCenter

            AnimatedImage {
                id: animatedImage
                source: "root:/Assets/tardis.gif"
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                playing: true
                cache: false
                speed: 1.0
                asynchronous: true
            }

            // Apply rounded corner mask to GIF
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: gifContainer.width
                    height: gifContainer.height
                    radius: gifContainer.radius
                    visible: false
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.isHovered = true
        onExited: root.isHovered = false
    }

    // Get current username
    Process {
        id: usernameProcess
        running: true  // Always run to get username
        command: ["sh", "-c", "whoami"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                const line = data.trim();
                if (line.length > 0) {
                    root.userName = line.charAt(0).toUpperCase() + line.slice(1);
                }
            }
        }
    }

    // Get system uptime with parsing for readable format
    Process {
        id: uptimeProcess
        running: false
        command: ["sh", "-c", "uptime"]  // Use basic uptime command

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                const line = data.trim();
                if (line.length > 0) {
                    // Parse uptime output: " 10:30:00 up  1:23,  2 users,  load average: 0.08, 0.02, 0.01"
                    const match = line.match(/up\s+(.+?),\s+\d+\s+user/);
                    if (match && match[1]) {
                        root.userInfo = "Up: " + match[1].trim();
                    } else {
                        // Fallback parsing for different uptime formats
                        const upIndex = line.indexOf("up ");
                        if (upIndex !== -1) {
                            const afterUp = line.substring(upIndex + 3);
                            const commaIndex = afterUp.indexOf(",");
                            if (commaIndex !== -1) {
                                root.userInfo = "Up: " + afterUp.substring(0, commaIndex).trim();
                            } else {
                                root.userInfo = "Up: " + afterUp.trim();
                            }
                        } else {
                            root.userInfo = "Uptime unknown";
                        }
                    }
                } else {
                    root.userInfo = "Uptime unknown";
                }
            }
        }

        stderr: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                console.log("Uptime error:", data);
                root.userInfo = "Uptime error";
            }
        }
    }

    // Update uptime every 5 minutes
    Timer {
        id: uptimeTimer
        interval: 300000   // Update every 5 minutes
        running: true      // Always run the uptime timer
        repeat: true
        onTriggered: {
            uptimeProcess.running = false
            uptimeProcess.running = true
        }
    }

    Component.onCompleted: {
        uptimeProcess.running = true  // Start uptime process on component load
    }

    Component.onDestruction: {
        if (usernameProcess.running) {
            usernameProcess.running = false
        }
        if (uptimeProcess.running) {
            uptimeProcess.running = false
        }
        if (uptimeTimer.running) {
            uptimeTimer.running = false
        }
    }
} 