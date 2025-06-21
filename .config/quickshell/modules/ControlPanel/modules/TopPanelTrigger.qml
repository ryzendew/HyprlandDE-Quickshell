import QtQuick

// Top-edge hover trigger
Rectangle {
    id: root
    width: 360
    height: 1
    color: "red"
    anchors.top: parent.top

    signal triggered()

    // Hover detection area at screen top edge
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        
        property bool isHovered: containsMouse
        
        // Timer coordination
        onIsHoveredChanged: {
            if (isHovered) {
                showTimer.start()
                hideTimer.stop()
            } else {
                hideTimer.start()
                showTimer.stop()
            }
        }
        
        onEntered: hideTimer.stop()
    }

    // Delayed show trigger to prevent accidental activation
    Timer {
        id: showTimer
        interval: 200
        onTriggered: root.triggered()
    }

    // Hide delay timer (controlled by parent)
    Timer {
        id: hideTimer
        interval: 500
    }

    // Public interface
    readonly property alias containsMouse: mouseArea.containsMouse
    function stopHideTimer() { hideTimer.stop() }
    function startHideTimer() { hideTimer.start() }
}