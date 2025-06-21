import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import "root:/Data" as Data
import "root:/Core" as Core

// Control panel window and trigger
PanelWindow {
    id: controlPanelWindow
    
    // Properties passed from parent ControlPanel
    required property var shell
    required property bool isRecording
    property int currentTab: 0
    property var tabIcons: []
    property bool isShown: false
    
    // Signals to forward to parent
    signal recordingRequested()
    signal stopRecordingRequested()
    signal systemActionRequested(string action)
    signal performanceActionRequested(string action)
    
    screen: Quickshell.primaryScreen || Quickshell.screens[0]
    anchors.top: true
    anchors.left: true
    anchors.right: true
    margins.bottom: 0
    margins.left: (screen ? screen.width / 2 - 400 : 0)  // Centered
    margins.right: (screen ? screen.width / 2 - 400 : 0)
    implicitWidth: 800  // Wide enough
    implicitHeight: isShown ? 400 : 8  // Expand/collapse animation
    
    Behavior on implicitHeight {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }
    exclusiveZone: 0
    color: "transparent"
    visible: true
    
    WlrLayershell.namespace: "quickshell-controlpanel"
    WlrLayershell.layer: WlrLayershell.Overlay
    
    // Hover trigger area at screen top
    MouseArea {
        id: triggerMouseArea
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: 600
        height: 8
        hoverEnabled: true
        onContainsMouseChanged: {
            if (containsMouse) {
                show()
            }
        }
    }

    // Main panel content
    ControlPanelContent {
        id: panelContent
        
        width: 600
        height: 380
        
        anchors.top: parent.top
        anchors.topMargin: 8  // Trigger area space
        anchors.horizontalCenter: parent.horizontalCenter
        visible: isShown
        opacity: isShown ? 1.0 : 0.0
        
        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
        
        // Pass through properties
        shell: controlPanelWindow.shell
        isRecording: controlPanelWindow.isRecording
        currentTab: controlPanelWindow.currentTab
        tabIcons: controlPanelWindow.tabIcons
        triggerMouseArea: triggerMouseArea
        
        // Bind state changes
        onCurrentTabChanged: controlPanelWindow.currentTab = currentTab
        
        // Forward signals
        onRecordingRequested: controlPanelWindow.recordingRequested()
        onStopRecordingRequested: controlPanelWindow.stopRecordingRequested()
        onSystemActionRequested: function(action) { controlPanelWindow.systemActionRequested(action) }
        onPerformanceActionRequested: function(action) { controlPanelWindow.performanceActionRequested(action) }
        
        // Hover state management
        onIsHoveredChanged: {
            if (isHovered) {
                hideTimer.stop()
            } else {
                hideTimer.restart()
            }
        }
    }

    // Border integration corners (positioned to match panel edges)
    Core.Corners {
        id: controlPanelLeftCorner
        position: "bottomright"
        size: 1.3
        fillColor: Data.Colors.bgColor
        offsetX: -661
        offsetY: -313
        visible: isShown
        
        // Disable implicit animations to prevent corner sliding
        Behavior on x { enabled: false }
        Behavior on y { enabled: false }
    }

    Core.Corners {
        id: controlPanelRightCorner
        position: "bottomleft"
        size: 1.3
        fillColor: Data.Colors.bgColor
        offsetX: 661
        offsetY: -313
        visible: isShown
        
        Behavior on x { enabled: false }
        Behavior on y { enabled: false }
    }

    // Auto-hide timer
    Timer {
        id: hideTimer
        interval: 400
        repeat: false
        onTriggered: hide()
    }

    function show() {
        if (isShown) return
        isShown = true
        hideTimer.stop()
    }

    function hide() {
        if (!isShown) return
        // Only hide main tab
        if (currentTab === 0 && !panelContent.isHovered) {
            isShown = false
        }
    }
} 