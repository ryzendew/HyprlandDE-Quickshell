import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import "root:/Data" as Data

// Clipboard history manager
Item {
    id: root
    required property var shell
    property string selectedWidget: "cliphist"
    
    property bool isVisible: false
    property real bgOpacity: 0.0
    
    transformOrigin: Item.Center
    
    function show() { showAnimation.start() }
    function hide() { hideAnimation.start() }
    function toggle() { isVisible ? hide() : show() }

    // Smooth show/hide animations
    ParallelAnimation {
        id: showAnimation
        PropertyAction { target: root; property: "isVisible"; value: true }
        PropertyAnimation { target: root; property: "opacity"; from: 0.0; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
        PropertyAnimation { target: root; property: "scale"; from: 0.9; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
    }
    
    ParallelAnimation {
        id: hideAnimation
        PropertyAnimation { target: root; property: "opacity"; to: 0.0; duration: 150; easing.type: Easing.InCubic }
        PropertyAnimation { target: root; property: "scale"; to: 0.95; duration: 150; easing.type: Easing.InCubic }
        PropertyAction { target: root; property: "isVisible"; value: false }
    }

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        spacing: 12
        
        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            
            Label {
                text: "Clipboard History"
                font.pixelSize: 16
                font.weight: Font.Medium
                color: Data.Colors.fgColor
                Layout.fillWidth: true
            }
            
            Button {
                id: clearButton
                text: "Clear"
                implicitWidth: 60
                implicitHeight: 25
                background: Rectangle {
                    radius: 12
                    color: parent.down ? Qt.darker(Data.Colors.accentColor, 1.2) :
                           parent.hovered ? Qt.lighter(Data.Colors.accentColor, 1.1) : 
                           Qt.rgba(Data.Colors.accentColor.r, Data.Colors.accentColor.g, Data.Colors.accentColor.b, 0.8)
                }
                contentItem: Label {
                    text: parent.text
                    font.pixelSize: 11
                    color: Data.Colors.fgColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    clearClipboardHistory()
                    clickScale.target = clearButton
                    clickScale.start()
                }
            }
        }
        
        // Scrollable clipboard history list
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ScrollView {
                id: scrollView
                anchors.fill: parent
                clip: true
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    interactive: true
                    visible: cliphistList.contentHeight > cliphistList.height
                    contentItem: Rectangle {
                        implicitWidth: 6
                        radius: width / 2
                        color: parent.pressed ? Data.Colors.accentColor 
                             : parent.hovered ? Qt.lighter(Data.Colors.accentColor, 1.2)
                             : Qt.rgba(Data.Colors.accentColor.r, Data.Colors.accentColor.g, Data.Colors.accentColor.b, 0.7)
                    }
                }
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ListView {
                    id: cliphistList
                    model: cliphistModel
                    spacing: 6
                    cacheBuffer: 50  // Memory optimization
                    reuseItems: true
                    boundsBehavior: Flickable.StopAtBounds
                    maximumFlickVelocity: 2500
                    flickDeceleration: 1500

                    // Smooth scrolling behavior
                    property real targetY: contentY
                    Behavior on targetY {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutQuad
                        }
                    }

                    onTargetYChanged: {
                        if (!moving && !dragging) {
                            contentY = targetY
                        }
                    }

                    delegate: Rectangle {
                        width: cliphistList.width
                        height: Math.max(50, contentText.contentHeight + 20)
                        radius: 8
                        color: mouseArea.containsMouse ? Qt.darker(Data.Colors.bgColor, 1.15) : Qt.darker(Data.Colors.bgColor, 1.1)
                        border.color: Data.Colors.accentColor
                        border.width: 1
                        
                        // View optimization - only render visible items
                        visible: y + height > cliphistList.contentY - height && 
                                y < cliphistList.contentY + cliphistList.height + height

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10
                            
                            // Content type icon
                            Label {
                                text: model.type === "image" ? "🖼️" : model.type === "url" ? "🔗" : "📝"
                                font.pixelSize: 16
                                Layout.alignment: Qt.AlignTop
                            }
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 4
                                
                                Label {
                                    id: contentText
                                    text: model.type === "image" ? "[Image Data]" : 
                                          (model.content.length > 100 ? model.content.substring(0, 100) + "..." : model.content)
                                    font.pixelSize: 12
                                    color: Data.Colors.fgColor
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    elide: Text.ElideRight
                                    maximumLineCount: 4
                                }
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    Item { Layout.fillWidth: true }
                                    Label {
                                        text: model.type === "image" ? "Image" : (model.content.length + " chars")
                                        font.pixelSize: 10
                                        color: Qt.darker(Data.Colors.fgColor, 1.5)
                                    }
                                }
                            }
                        }
                        
                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: mouse => {
                                if (mouse.button === Qt.LeftButton) {
                                    copyToClipboard(model.id, model.type)
                                    clickScale.target = parent
                                    clickScale.start()
                                }
                            }
                        }
                    }
                    
                    // Empty state message
                    Label {
                        anchors.centerIn: parent
                        text: "No clipboard history\nCopy something to get started"
                        font.pixelSize: 14
                        color: Qt.darker(Data.Colors.fgColor, 1.5)
                        horizontalAlignment: Text.AlignHCenter
                        visible: cliphistList.count === 0
                        opacity: 0.7
                    }
                }
            }
        }
    }

    // Click feedback animation
    NumberAnimation {
        id: clickScale
        property Item target
        properties: "scale"
        from: 0.95
        to: 1.0
        duration: 150
        easing.type: Easing.OutCubic
    }
    
    ListModel { id: cliphistModel }

    property var currentEntries: []

    // Main cliphist process
    Process {
        id: cliphistProcess
        command: ["cliphist", "list"]
        running: false
        
        property var tempEntries: []
        
        onRunningChanged: {
            if (running) {
                tempEntries = []
            } else {
                // Process completed, apply smart update
                updateModelIfChanged(tempEntries)
            }
        }
        
        stdout: SplitParser {
            onRead: data => {
                try {
                    const line = data.toString().trim()
                    
                    // Skip empty lines and error messages
                    if (line === "" || line.includes("ERROR") || line.includes("WARN") || 
                        line.includes("error:") || line.includes("warning:")) {
                        return
                    }
                    
                    // Parse cliphist output: ID + spaces + content
                    const match = line.match(/^(\d+)\s+(.+)$/)
                    if (match) {
                        const id = match[1]
                        const content = match[2]
                        
                        cliphistProcess.tempEntries.push({
                            id: id,
                            content: content,
                            type: detectContentType(content)
                        })
                    } else {
                        console.log("Failed to parse line:", line)
                    }
                } catch (e) {
                    console.error("Error parsing cliphist line:", e)
                }
            }
        }
    }

    // Clear entire clipboard history
    Process {
        id: clearCliphistProcess
        command: ["cliphist", "wipe"]
        running: false
        
        onRunningChanged: {
            if (!running) {
                cliphistModel.clear()
                currentEntries = []
                console.log("Clipboard history cleared")
            }
        }
        
        stderr: SplitParser {
            onRead: data => {
                console.error("Clear clipboard error:", data.toString())
            }
        }
    }

    // Delete specific clipboard entry
    Process {
        id: deleteEntryProcess
        property string entryId: ""
        command: ["cliphist", "delete-query", entryId]
        running: false
        
        onRunningChanged: {
            if (!running && entryId !== "") {
                // Remove deleted entry from model
                for (let i = 0; i < cliphistModel.count; i++) {
                    if (cliphistModel.get(i).id === entryId) {
                        cliphistModel.remove(i)
                        currentEntries = currentEntries.filter(entry => entry.id !== entryId)
                        break
                    }
                }
                console.log("Deleted entry:", entryId)
                entryId = ""
            }
        }
        
        stderr: SplitParser {
            onRead: data => {
                console.error("Delete entry error:", data.toString())
            }
        }
    }

    // Copy plain text to clipboard
    Process {
        id: copyTextProcess
        property string textToCopy: ""
        command: ["wl-copy", textToCopy]
        running: false
        
        stderr: SplitParser {
            onRead: data => {
                console.error("wl-copy error:", data.toString())
            }
        }
    }

    // Copy from clipboard history
    Process {
        id: copyHistoryProcess
        property string entryId: ""
        command: ["sh", "-c", "printf '%s' '" + entryId + "' | cliphist decode | wl-copy"]
        running: false
        
        stderr: SplitParser {
            onRead: data => {
                console.error("Copy history error:", data.toString())
            }
        }
    }

    // Periodic refresh timer (disabled by default)
    Timer {
        id: refreshTimer
        interval: 30000
        running: false  // Only enable when needed
        repeat: true
        onTriggered: {
            if (!cliphistProcess.running && root.isVisible) {
                refreshClipboardHistory()
            }
        }
    }

    // Smart update
    function updateModelIfChanged(newEntries) {
        // Quick length check
        if (newEntries.length !== currentEntries.length) {
            updateModel(newEntries)
            return
        }
        
        // Compare content for changes
        let hasChanges = false
        for (let i = 0; i < newEntries.length; i++) {
            if (i >= currentEntries.length || 
                newEntries[i].id !== currentEntries[i].id ||
                newEntries[i].content !== currentEntries[i].content) {
                hasChanges = true
                break
            }
        }
        
        if (hasChanges) {
            updateModel(newEntries)
        }
    }
    
    // Efficient model update
    function updateModel(newEntries) {
        const scrollPos = cliphistList.contentY
        
        // Remove obsolete items
        for (let i = cliphistModel.count - 1; i >= 0; i--) {
            const modelItem = cliphistModel.get(i)
            const found = newEntries.some(entry => entry.id === modelItem.id)
            if (!found) {
                cliphistModel.remove(i)
            }
        }
        
        // Add or update items
        for (let i = 0; i < newEntries.length; i++) {
            const newEntry = newEntries[i]
            let found = false
            
            // Check if item exists and update position
            for (let j = 0; j < cliphistModel.count; j++) {
                const modelItem = cliphistModel.get(j)
                if (modelItem.id === newEntry.id) {
                    if (modelItem.content !== newEntry.content) {
                        cliphistModel.set(j, newEntry)
                    }
                    if (j !== i && i < cliphistModel.count) {
                        cliphistModel.move(j, i, 1)
                    }
                    found = true
                    break
                }
            }
            
            // Add new item
            if (!found) {
                if (i < cliphistModel.count) {
                    cliphistModel.insert(i, newEntry)
                } else {
                    cliphistModel.append(newEntry)
                }
            }
        }
        
        // Restore scroll position
        cliphistList.contentY = scrollPos
        currentEntries = newEntries.slice()
    }

    // Content type detection based on patterns
    function detectContentType(content) {
        // Binary/image data detection
        if (content.includes('\x00') || content.startsWith('\x89PNG') || content.startsWith('\xFF\xD8\xFF')) {
            return "image"
        }
        if (content.includes('[[ binary data ') || content.includes('<selection>')) {
            return "image"
        }
        // URL detection
        if (/^https?:\/\/\S+$/.test(content.trim())) return "url"
        // Code detection
        if (content.includes('\n') && (content.includes('{') || content.includes('function') || content.includes('=>'))) return "code"
        // Command detection
        if (content.startsWith('sudo ') || content.startsWith('pacman ') || content.startsWith('apt ')) return "command"
        return "text"
    }

    function formatTimestamp(timestamp) {
        const now = new Date()
        const entryDate = new Date(parseInt(timestamp))
        const diff = (now - entryDate) / 1000
        
        if (diff < 60) return "Just now"
        if (diff < 3600) return Math.floor(diff / 60) + " min ago"
        if (diff < 86400) return Math.floor(diff / 3600) + " hour" + (Math.floor(diff / 3600) === 1 ? "" : "s") + " ago"
        return Qt.formatDateTime(entryDate, "MMM d h:mm AP")
    }

    function clearClipboardHistory() {
        clearCliphistProcess.running = true
    }

    function deleteClipboardEntry(entryId) {
        deleteEntryProcess.entryId = entryId
        deleteEntryProcess.running = true
    }

    function refreshClipboardHistory() {
        cliphistProcess.running = true
    }

    // Copy handler
    function copyToClipboard(entryIdOrText, contentType) {
        if (contentType === "image" || typeof entryIdOrText === "string" && entryIdOrText.match(/^\d+$/)) {
            // Use cliphist decode
            copyHistoryProcess.entryId = entryIdOrText
            copyHistoryProcess.running = true
        } else {
            // Use wl-copy
            copyTextProcess.textToCopy = entryIdOrText
            copyTextProcess.running = true
        }
    }

    // Clean up all processes on destruction
    Component.onDestruction: {
        cliphistProcess.running = false
        clearCliphistProcess.running = false
        deleteEntryProcess.running = false
        copyTextProcess.running = false
        copyHistoryProcess.running = false
    }
}