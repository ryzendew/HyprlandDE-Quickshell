import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import "root:/modules/common"
import "root:/modules/common/widgets"

Item {
    id: barModule
    
    // --- Properties ---
    property string moduleId: ""
    property string moduleType: ""
    property var moduleComponent: null
    property bool isDraggable: true
    property int moduleIndex: 0
    property string section: "left" // "left", "right", "center"
    
    // Drag state
    property bool isDragging: false
    property bool isDropTarget: false
    property real dragStartX: 0
    property real dragStartY: 0
    property int dragThreshold: 10
    
    // Visual feedback
    property color dragColor: Qt.rgba(Appearance.colors.colLayer1Active.r, Appearance.colors.colLayer1Active.g, Appearance.colors.colLayer1Active.b, 0.3)
    property color dropTargetColor: Qt.rgba(Appearance.colors.colAccent.r, Appearance.colors.colAccent.g, Appearance.colors.colAccent.b, 0.2)
    
    // --- Signals ---
    signal dragStarted(string moduleId, int index)
    signal dragEnded()
    signal moduleDropped(string fromId, string toId, int fromIndex, int toIndex)
    signal requestReorder(string moduleId, int fromIndex, int toIndex)
    
    // --- Layout ---
    Layout.fillHeight: true
    implicitWidth: moduleContent.implicitWidth
    implicitHeight: moduleContent.implicitHeight
    
    // --- Visual State ---
    opacity: isDragging ? 0.7 : 1.0
    scale: isDragging ? 1.05 : (isDropTarget ? 1.02 : 1.0)
    z: isDragging ? 100 : 1
    
    Behavior on opacity {
        NumberAnimation {
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Appearance.animation.elementMoveFast.type
        }
    }
    
    Behavior on scale {
        NumberAnimation {
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Appearance.animation.elementMoveFast.type
        }
    }
    
    // --- Drop Target Visual ---
    Rectangle {
        id: dropIndicator
        anchors.fill: parent
        color: isDropTarget ? dropTargetColor : "transparent"
        radius: Appearance.rounding.small
        border.width: isDropTarget ? 2 : 0
        border.color: Appearance.colors.colAccent
        
        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
            }
        }
    }
    
    // --- Module Content ---
    Item {
        id: moduleContent
        anchors.fill: parent
        
        // This will hold the actual module component
        Loader {
            id: moduleLoader
            anchors.fill: parent
            sourceComponent: moduleComponent
        }
    }
    
    // --- Drag Background ---
    Rectangle {
        id: dragBackground
        anchors.fill: parent
        color: isDragging ? dragColor : "transparent"
        radius: Appearance.rounding.small
        visible: isDragging
        
        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
            }
        }
    }
    
    // --- Mouse Handling ---
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        propagateComposedEvents: true
        
        property bool dragActive: false
        property bool dragStarted: false
        
        onPressed: (mouse) => {
            if (mouse.button === Qt.LeftButton && isDraggable) {
                dragActive = true
                dragStarted = false
                dragStartX = mouse.x
                dragStartY = mouse.y
                mouse.accepted = false // Allow child components to receive the event
            }
        }
        
        onPositionChanged: (mouse) => {
            if (dragActive && isDraggable && (mouse.buttons & Qt.LeftButton)) {
                var distance = Math.sqrt(Math.pow(mouse.x - dragStartX, 2) + Math.pow(mouse.y - dragStartY, 2))
                
                if (!dragStarted && distance > dragThreshold) {
                    // Start dragging
                    dragStarted = true
                    isDragging = true
                    dragStarted(moduleId, moduleIndex)
                }
                
                if (isDragging) {
                    // Find other modules in the same section to check for drop targets
                    var parentLayout = barModule.parent
                    if (parentLayout && parentLayout.children) {
                        var globalMousePos = barModule.mapToItem(null, mouse.x, mouse.y)
                        
                        for (var i = 0; i < parentLayout.children.length; i++) {
                            var item = parentLayout.children[i]
                            if (item && item !== barModule && item.moduleId !== undefined) {
                                var itemMousePos = item.mapFromItem(null, globalMousePos.x, globalMousePos.y)
                                var isOver = (itemMousePos.x >= 0 && itemMousePos.x <= item.width && 
                                            itemMousePos.y >= 0 && itemMousePos.y <= item.height)
                                
                                if (isOver && !item.isDropTarget) {
                                    item.isDropTarget = true
                                } else if (!isOver && item.isDropTarget) {
                                    item.isDropTarget = false
                                }
                            }
                        }
                    }
                }
            }
        }
        
        onReleased: (mouse) => {
            if (mouse.button === Qt.LeftButton && isDragging) {
                // Find drop target
                var parentLayout = barModule.parent
                var dropTargetId = ""
                var dropTargetIndex = -1
                
                if (parentLayout && parentLayout.children) {
                    for (var i = 0; i < parentLayout.children.length; i++) {
                        var item = parentLayout.children[i]
                        if (item && item !== barModule && item.moduleId !== undefined && item.isDropTarget) {
                            dropTargetId = item.moduleId
                            dropTargetIndex = i
                            item.isDropTarget = false
                            break
                        } else if (item && item.isDropTarget !== undefined) {
                            item.isDropTarget = false
                        }
                    }
                }
                
                // Perform reorder if valid drop target found
                if (dropTargetId && dropTargetIndex >= 0 && dropTargetIndex !== moduleIndex) {
                    requestReorder(moduleId, moduleIndex, dropTargetIndex)
                }
                
                // End dragging
                isDragging = false
                dragStarted = false
                dragEnded()
            }
            
            dragActive = false
            mouse.accepted = false // Allow child components to receive the event
        }
        
        onClicked: (mouse) => {
            // Let child components handle clicks
            mouse.accepted = false
        }
    }
    
    // --- Drop Area ---
    DropArea {
        anchors.fill: parent
        
        onEntered: (drag) => {
            if (drag.source && drag.source.moduleId && drag.source.moduleId !== moduleId) {
                isDropTarget = true
            }
        }
        
        onExited: {
            isDropTarget = false
        }
        
        onDropped: (drop) => {
            if (drop.source && drop.source.moduleId) {
                moduleDropped(drop.source.moduleId, moduleId, drop.source.moduleIndex, moduleIndex)
                isDropTarget = false
            }
        }
    }
} 