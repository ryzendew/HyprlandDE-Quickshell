import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import "root:/Data" as Data
import "root:/Core" as Core

// Niri workspace indicator
Rectangle {
    id: root
    
    property ListModel workspaces: ListModel {}
    property int currentWorkspace: -1
    property bool isDestroying: false
    
    color: Data.Colors.bgColor
    width: 32
    height: workspaceColumn.implicitHeight + 24
    
    // Smooth height animation
    Behavior on height {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }
    
    // Right-side rounded corners
    topRightRadius: width / 2
    bottomRightRadius: width / 2
    topLeftRadius: 0
    bottomLeftRadius: 0
    
    // Niri event stream listener
    Process {
        id: niriProcess
        command: ["niri", "msg", "event-stream"]
        running: true
        
        stdout: SplitParser {
            onRead: data => {
                const lines = data.split('\n');
                for (const line of lines) {
                    if (line.trim()) {
                        parseNiriEvent(line.trim());
                    }
                }
            }
        }
        
        onExited: {
            // Auto-restart on failure to maintain workspace sync (but not during destruction)
            if (exitCode !== 0 && !root.isDestroying) {
                Qt.callLater(() => running = true);
            }
        }
    }
    
    // Parse Niri event stream messages
    function parseNiriEvent(line) {
        try {
            // Handle workspace focus changes
            if (line.startsWith("Workspace focused: ")) {
                const workspaceId = parseInt(line.replace("Workspace focused: ", ""));
                if (!isNaN(workspaceId)) {
                    root.currentWorkspace = workspaceId;
                    updateWorkspaceFocus(workspaceId);
                }
            }
            // Handle workspace list updates
            else if (line.startsWith("Workspaces changed: ")) {
                const workspaceData = line.replace("Workspaces changed: ", "");
                parseWorkspaceList(workspaceData);
            }
        } catch (e) {
            console.log("Error parsing niri event:", e);
        }
    }
    
    // Update workspace focus states
    function updateWorkspaceFocus(focusedWorkspaceId) {
        for (let i = 0; i < root.workspaces.count; i++) {
            const workspace = root.workspaces.get(i);
            const wasFocused = workspace.isFocused;
            const isFocused = workspace.id === focusedWorkspaceId;
            const isActive = workspace.id === focusedWorkspaceId;
            
            // Only update changed properties to trigger animations
            if (wasFocused !== isFocused) {
                root.workspaces.setProperty(i, "isFocused", isFocused);
                root.workspaces.setProperty(i, "isActive", isActive);
            }
        }
    }
    
    // Parse workspace data from Niri's Rust-style output format
    function parseWorkspaceList(data) {
        try {
            const workspaceMatches = data.match(/Workspace \{[^}]+\}/g);
            if (!workspaceMatches) {
                return;
            }
            
            const newWorkspaces = [];
            
            for (const match of workspaceMatches) {
                const idMatch = match.match(/id: (\d+)/);
                const idxMatch = match.match(/idx: (\d+)/);
                const nameMatch = match.match(/name: Some\("([^"]+)"\)|name: None/);
                const outputMatch = match.match(/output: Some\("([^"]+)"\)/);
                const isActiveMatch = match.match(/is_active: (true|false)/);
                const isFocusedMatch = match.match(/is_focused: (true|false)/);
                const isUrgentMatch = match.match(/is_urgent: (true|false)/);
                
                if (idMatch && idxMatch && outputMatch) {
                    const workspace = {
                        id: parseInt(idMatch[1]),
                        idx: parseInt(idxMatch[1]),
                        name: nameMatch && nameMatch[1] ? nameMatch[1] : "",
                        output: outputMatch[1],
                        isActive: isActiveMatch ? isActiveMatch[1] === "true" : false,
                        isFocused: isFocusedMatch ? isFocusedMatch[1] === "true" : false,
                        isUrgent: isUrgentMatch ? isUrgentMatch[1] === "true" : false
                    };
                    
                    newWorkspaces.push(workspace);
                    
                    if (workspace.isFocused) {
                        root.currentWorkspace = workspace.id;
                    }
                }
            }
            
            // Sort by index and update model
            newWorkspaces.sort((a, b) => a.idx - b.idx);
            root.workspaces.clear();
            root.workspaces.append(newWorkspaces);
        } catch (e) {
            console.log("Error parsing workspace list:", e);
        }
    }
    
    // Vertical workspace indicator pills
    Column {
        id: workspaceColumn
        anchors.centerIn: parent
        spacing: 6
        
        Repeater {
            model: root.workspaces
            
            Rectangle {
                id: workspacePill
                
                // Dynamic sizing based on focus state
                width: model.isFocused ? 18 : 16
                height: model.isFocused ? 36 : 22
                radius: width / 2
                scale: model.isFocused ? 1.0 : 0.9
                
                // Material Design 3 inspired colors
                color: {
                    if (model.isFocused) {
                        return Data.Colors.accent;
                    }
                    if (model.isActive) {
                        return Qt.rgba(Data.Colors.accent.r, Data.Colors.accent.g, Data.Colors.accent.b, 0.5);
                    }
                    if (model.isUrgent) {
                        return Data.Colors.error;
                    }
                    return Qt.rgba(Data.Colors.primaryText.r, Data.Colors.primaryText.g, Data.Colors.primaryText.b, 0.4);
                }
                
                // Elevation shadow
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: model.isFocused ? 1 : 0
                    anchors.leftMargin: model.isFocused ? 0.5 : 0
                    anchors.rightMargin: model.isFocused ? -0.5 : 0
                    anchors.bottomMargin: model.isFocused ? -1 : 0
                    radius: parent.radius
                    color: Qt.rgba(0, 0, 0, model.isFocused ? 0.15 : 0)
                    z: -1
                    visible: model.isFocused
                    
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                
                // Smooth Material Design transitions
                Behavior on width { 
                    NumberAnimation { 
                        duration: 300
                        easing.type: Easing.OutCubic 
                    } 
                }
                Behavior on height { 
                    NumberAnimation { 
                        duration: 300
                        easing.type: Easing.OutCubic 
                    } 
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on color { 
                    ColorAnimation { 
                        duration: 200 
                    } 
                }
                
                // Workspace number text
                Text {
                    anchors.centerIn: parent
                    text: model.idx.toString()
                    color: model.isFocused ? Data.Colors.background : Data.Colors.primaryText
                    font.pixelSize: model.isFocused ? 10 : 8
                    font.bold: model.isFocused
                    font.family: "Roboto, sans-serif"
                    visible: model.isFocused || model.isActive
                    
                    Behavior on font.pixelSize { NumberAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        // Switch workspace via Niri command
                        switchProcess.command = ["niri", "msg", "action", "focus-workspace", model.idx.toString()];
                        switchProcess.running = true;
                    }
                    
                    // Hover feedback
                    onEntered: {
                        if (!model.isFocused) {
                            workspacePill.color = Qt.rgba(Data.Colors.primaryText.r, Data.Colors.primaryText.g, Data.Colors.primaryText.b, 0.6);
                        }
                    }
                    
                    onExited: {
                        // Reset to normal color
                        if (!model.isFocused) {
                            if (model.isActive) {
                                workspacePill.color = Qt.rgba(Data.Colors.accent.r, Data.Colors.accent.g, Data.Colors.accent.b, 0.5);
                            } else if (model.isUrgent) {
                                workspacePill.color = Data.Colors.error;
                            } else {
                                workspacePill.color = Qt.rgba(Data.Colors.primaryText.r, Data.Colors.primaryText.g, Data.Colors.primaryText.b, 0.4);
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Workspace switching command process
    Process {
        id: switchProcess
        running: false
        onExited: {
            running = false
            if (exitCode !== 0) {
                console.log("Failed to switch workspace:", exitCode);
            }
        }
    }
    
    // Border integration corners
    Core.Corners {
        id: topLeftCorner
        position: "topleft"
        size: 1.3
        fillColor: Data.Colors.bgColor 
        offsetX: -41
        offsetY: -25
    }

    Core.Corners {
        id: bottomLeftCorner
        position: "bottomleft"
        size: 1.3
        fillColor: Data.Colors.bgColor
        offsetX: -41
        offsetY: 78
    }

    // Clean up processes on destruction
    Component.onDestruction: {
        // Set flag to prevent auto-restart during destruction
        root.isDestroying = true
        
        if (niriProcess.running) {
            niriProcess.running = false
        }
        if (switchProcess.running) {
            switchProcess.running = false
        }
    }
} 