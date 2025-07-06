import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"

PanelWindow {
    id: previewWindow
    
    // Properties
    property var targetWindows: []
    property string appClass: ""
    property bool isVisible: false
    property point targetPosition: Qt.point(0, 0)
    property int itemWidth: 0
    
    // Screen detection - get actual screen width dynamically
    property real screenWidth: {
        // Try to get from the screen property first
        if (screen && screen.geometry) {
            return screen.geometry.width;
        }
        
        // Fallback to getting primary screen from Quickshell.screens
        if (Quickshell.screens && Quickshell.screens.length > 0) {
            // Find the screen this window is on, or use first screen
            for (var i = 0; i < Quickshell.screens.length; i++) {
                var s = Quickshell.screens[i];
                if (s && s.geometry) {
                    return s.geometry.width;
                }
            }
        }
        
        // Final fallback - use a reasonable minimum
        console.warn("[WINDOW PREVIEW] Could not detect screen width, using fallback");
        return 1280; // Minimum reasonable width
    }
    
    // Debug screen info
    QtObject {
        // console.log("[WINDOW PREVIEW DEBUG] Screen changed:", screen ? "defined" : "undefined");
        // console.log("[WINDOW PREVIEW DEBUG] Screen geometry:", screen.geometry.width, "x", screen.geometry.height);
    }
    
    Component.onCompleted: {
        // console.log("[WINDOW PREVIEW DEBUG] Component completed");
        // console.log("[WINDOW PREVIEW DEBUG] Available screens:", Quickshell.screens ? Quickshell.screens.length : "none");
        if (Quickshell.screens) {
            Quickshell.screens.forEach((s, i) => {
                // console.log("[WINDOW PREVIEW DEBUG] Screen", i + ":", s.name, s.geometry.width + "x" + s.geometry.height);
            })
        }
        // console.log("[WINDOW PREVIEW DEBUG] Final screen width:", screenWidth);
    }
    
    // Window properties
    visible: isVisible && targetWindows.length > 0
    color: "transparent"
    
    // Debug: track visibility changes
    Connections {
        target: root
        function onVisibleChanged() {
            // console.log("[WINDOW PREVIEW DEBUG] Visibility changed to:", visible, "isVisible:", isVisible, "targetWindows.length:", targetWindows.length);
        }
    }
    Connections {
        target: repeaterModel
        function onTargetWindowsChanged() {
            // console.log("[WINDOW PREVIEW DEBUG] Target windows changed:", targetWindows.length, "windows");
            if (targetWindows.length > 0) {
                // console.log("[WINDOW PREVIEW DEBUG] First window:", JSON.stringify({class: targetWindows[0].class, title: targetWindows[0].title}));
            }
        }
    }
    
    // Set up as overlay popup
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:dockpreview"
    
    // Positioning - appear above the hovered dock item
    anchors.left: true
    anchors.right: false
    anchors.top: false
    anchors.bottom: true
    
    margins {
        left: Math.max(10, Math.min(targetPosition.x - (implicitWidth / 2), screenWidth - implicitWidth - 10))
        bottom: 120  // Position above the dock (dock height + margin)
    }
    
    // Size based on content
    implicitWidth: Math.max(220, contentItem.implicitWidth + 20)
    implicitHeight: Math.max(140, contentItem.implicitHeight + 20)
    
    // Main content item with scale and opacity animations
    Item {
        id: contentItem
        anchors.fill: parent
        
        // Fade in/out animation
        opacity: isVisible ? 1.0 : 0.0
        scale: isVisible ? 1.0 : 0.8
        
        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        
        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        
        // Background with shadow
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(
                Appearance.colors.colLayer1.r,
                Appearance.colors.colLayer1.g,
                Appearance.colors.colLayer1.b,
                0.95
            )
            radius: Appearance.rounding.medium
            border.color: Qt.rgba(
                Appearance.colors.colLayer2.r,
                Appearance.colors.colLayer2.g,
                Appearance.colors.colLayer2.b,
                0.5
            )
            border.width: 1
            
            // Debug: Add a visible background for testing
            Rectangle {
                anchors.fill: parent
                color: "red"
                opacity: 0.2
                radius: parent.radius
            }
            
            // Shadow effect
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.4)
                shadowVerticalOffset: 4
                shadowHorizontalOffset: 0
                shadowBlur: 16
            }
        }
        
        // Content layout
        ColumnLayout {
            id: previewLayout
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8
            
            // App name header
            Text {
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                text: appClass || "Windows"
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
            
            // Window previews
            Flow {
                id: previewFlow
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 6
                
                Repeater {
                    model: targetWindows
                    
                    Rectangle {
                        id: windowPreviewItem
                        
                        property var windowData: modelData
                        property bool isHovered: previewMouseArea.containsMouse
                        
                        width: Math.min(180, Math.max(120, previewWindow.implicitWidth - 40))
                        height: 100
                        radius: Appearance.rounding.small
                        color: isHovered ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2
                        border.color: windowData.address === (Hyprland.active.window?.address || "") ? 
                            Appearance.m3colors.m3primary : 
                            Qt.rgba(Appearance.colors.colLayer0.r, Appearance.colors.colLayer0.g, Appearance.colors.colLayer0.b, 0.3)
                        border.width: windowData.address === (Hyprland.active.window?.address || "") ? 2 : 1
                        
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                        
                        Behavior on border.color {
                            ColorAnimation { duration: 150 }
                        }
                        
                        // Window content placeholder (since we can't get actual thumbnails easily)
                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4
                            
                            // Debug background (removed anchors.fill to fix Column warning)
                            Rectangle {
                                width: parent.width - 16
                                height: parent.height - 16
                                color: "blue"
                                opacity: 0.1
                                z: -1
                            }
                            
                            // Window icon
                            SystemIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                iconSize: 32
                                iconName: {
                                    if (windowData.class) {
                                        // Use a simple icon mapping instead of AppSearch
                                        return windowData.class.toLowerCase();
                                    }
                                    return "window";
                                }
                                iconColor: "transparent"
                            }
                            
                            // Window title
                            Text {
                                width: parent.width
                                text: windowData.title || windowData.class || "Window"
                                color: Appearance.colors.colOnLayer2
                                font.pixelSize: Math.max(10, Appearance.font.pixelSize.tiny)
                                font.weight: windowData.address === (Hyprland.active.window?.address || "") ? Font.DemiBold : Font.Normal
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                
                                // Debug: make text more visible
                                Rectangle {
                                    anchors.fill: parent
                                    color: "yellow"
                                    opacity: 0.2
                                    z: -1
                                }
                            }
                            
                            // Workspace indicator
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "WS " + (windowData.workspace?.id || "?")
                                color: Qt.rgba(Appearance.colors.colOnLayer2.r, Appearance.colors.colOnLayer2.g, Appearance.colors.colOnLayer2.b, 0.7)
                                font.pixelSize: Math.max(8, Appearance.font.pixelSize.tiny - 2)
                                visible: windowData.workspace && windowData.workspace.id !== (Hyprland.active.workspace?.id || -1)
                            }
                        }
                        
                        // Hover indicator
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: "transparent"
                            border.color: Appearance.m3colors.m3primary
                            border.width: isHovered ? 2 : 0
                            opacity: 0.8
                            
                            Behavior on border.width {
                                NumberAnimation { duration: 150 }
                            }
                        }
                        
                        // Mouse interaction
                        MouseArea {
                            id: previewMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            
                            onClicked: {
                                // Switch to the window's workspace if needed
                                if (windowData.workspace && windowData.workspace.id && 
                                    windowData.workspace.id !== (Hyprland.active.workspace?.id || -1)) {
                                    Hyprland.dispatch(`workspace ${windowData.workspace.id}`);
                                }
                                
                                // Focus the window
                                if (windowData.address) {
                                    Hyprland.dispatch(`focuswindow address:${windowData.address}`);
                                }
                                
                                // Hide the preview
                                previewWindow.isVisible = false;
                            }
                            
                            onEntered: {
                                // Optional: Could add a subtle highlight effect
                            }
                        }
                        
                        // Close button (small X in corner)
                        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            color: closeMouseArea.containsMouse ? Appearance.colors.colError : Qt.rgba(0, 0, 0, 0.5)
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 4
                            visible: isHovered
                            
                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                color: "white"
                                font.pixelSize: 10
                                font.bold: true
                            }
                            
                            MouseArea {
                                id: closeMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                
                                onClicked: {
                                    if (windowData.address) {
                                        Hyprland.dispatch(`closewindow address:${windowData.address}`);
                                    }
                                    mouse.accepted = true; // Prevent parent click
                                }
                            }
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }
                    }
                }
            }
            
            // Footer with window count
            Text {
                Layout.fillWidth: true
                text: targetWindows.length === 1 ? "1 window" : `${targetWindows.length} windows`
                color: Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, 0.7)
                font.pixelSize: Appearance.font.pixelSize.tiny
                horizontalAlignment: Text.AlignHCenter
                visible: targetWindows.length > 1
            }
        }
    }
    
    // Auto-hide timer
    Timer {
        id: hideTimer
        interval: 500
        onTriggered: previewWindow.isVisible = false
    }
    
    // Functions
    function showPreviews(windows, position, itemW, className) {
        hidePreviews()
        // console.log("[WINDOW PREVIEW DEBUG] showPreviews called with:", windows.length, "windows for class:", className);
        // console.log("[WINDOW PREVIEW DEBUG] Position:", position, "ItemWidth:", itemW);
        // console.log("[WINDOW PREVIEW DEBUG] Screen width:", screenWidth);

        if (windows.length > 0) {
            targetClassName = className
            targetWindows = windows;
            // console.log("[WINDOW PREVIEW DEBUG] Setting isVisible to true");
            isVisible = true;
            const targetPosition = previewsContent.mapToItem(root, position.x, position.y);
            // console.log("[WINDOW PREVIEW DEBUG] Calculated left margin:", Math.max(10, Math.min(targetPosition.x - (implicitWidth / 2), screenWidth - implicitWidth - 10)));
            previewsContent.x = Math.max(10, Math.min(targetPosition.x - (implicitWidth / 2), screenWidth - implicitWidth - 10));
            previewsContent.y = targetPosition.y - previewsContent.height - 10; // Position above the dock item
        } else {
            // console.log("[WINDOW PREVIEW DEBUG] No windows to show");
        }
    }
    
    function hidePreviews() {
        hideTimer.start();
    }
    
    function hideImmediately() {
        hideTimer.stop();
        isVisible = false;
    }
} 
