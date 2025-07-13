import QtQuick 2.15
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"


Rectangle {
    id: dockItem
    
    // --- Properties ---
    // The desktop entry or app info for this dock item
    property var appData: null
    // Tooltip text for this item (shows app class or title)
    property string tooltip: isPinned ? (appData?.name || appData?.desktopId || "") : (appData?.title || appData?.class || appData?.name || "")
    // Whether this item is currently active (focused window)
    property bool isActive: false
    // Whether the right-click menu is shown for this item
    property bool showMenu: false
    // Whether this app is pinned to the dock
    property bool isPinned: false
    // The index of this item in the layout (for ordering)
    property int layoutIndex: parent ? parent.children.indexOf(dockItem) : 0
    // The index in the model (if using a model)
    property int modelIndex: typeof index !== "undefined" ? index : 0  // Use the index from Repeater
    // The class of the app that was last clicked
    property string clickedAppClass: ""
    // The index of this item in the parent (for ordering)
    property int itemIndex: parent ? parent.children.indexOf(this) : 0
    // Whether this menu is the currently active menu
    property bool isActiveMenu: false
    // The last position where the item was hovered (for tooltips, etc)
    property point lastHoverPos: Qt.point(0, 0)  // Add this property to track hover position
    // The last click position for menu positioning
    property point lastClickPos: Qt.point(0, 0)
    
    // Drag and drop properties
    property bool isDragging: false
    property bool isDropTarget: false
    property real dragStartX: 0
    property real dragStartY: 0
    property int dragThreshold: 10
    
    // --- Signals ---
    // Emitted when the item is clicked (left click)
    signal clicked()
    // Emitted when the user wants to pin the app
    signal pinApp()
    // Emitted when the user wants to unpin the app
    signal unpinApp()
    // Emitted when the user wants to close the app
    signal closeApp()
    // Emitted when drag starts
    signal dragStarted()
    // Emitted when drag ends
    signal dragEnded()
    // Emitted when item is dropped on another item
    signal itemDropped(int fromIndex, int toIndex)
    
    // --- Appearance ---
    // Set the size and shape of the dock item
    implicitWidth: dock.dockWidth - 6
    implicitHeight: dock.dockWidth - 6
    radius: Appearance.rounding.full
    // Set the color based on state (active, hovered, pressed)
    color: mouseArea.pressed ? Appearance.colors.colLayer1Active : 
           mouseArea.containsMouse ? Appearance.colors.colLayer1Hover : 
           "transparent"
    
    // Visual feedback for drag and drop
    opacity: isDragging ? 0.7 : 1.0
    scale: isDragging ? 1.1 : (isDropTarget ? 1.05 : 1.0)
    z: isDragging ? 100 : 1
    
    // Animate color changes for smooth transitions
    Behavior on color {
        ColorAnimation {
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Appearance.animation.elementMoveFast.type
        }
    }
    
    // Animate drag feedback
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

    // --- Icon ---
    // The app icon, centered in the item using proper Quickshell icon handling
    Item {
        id: iconContainer
        anchors.centerIn: parent
        width: ConfigOptions.dock.iconSize
        height: ConfigOptions.dock.iconSize

        // Use proper icon source resolution according to Quickshell docs
        Image {
            id: appIcon
            anchors.fill: parent
            property string resolvedSource: (function() {
                if (!appData) {
                    console.log('[DOCK DEBUG] appData is null/undefined for DockItem');
                    return "image://icon/application-x-executable";
                }
                // For desktop entries, use iconUrl or fallback to icon name
                if (appData.iconUrl) {
                    console.log('[DOCK DEBUG] appData:', JSON.stringify(appData), 'icon source:', appData.iconUrl);
                    return appData.iconUrl;
                }
                if (appData.icon) {
                    console.log('[DOCK DEBUG] appData:', JSON.stringify(appData), 'icon source:', "image://icon/" + appData.icon);
                    return "image://icon/" + appData.icon;
                }
                // Final fallback - same for both pinned and unpinned
                console.log('[DOCK DEBUG] No icon found, using fallback for appData:', JSON.stringify(appData));
                return "image://icon/application-x-executable";
            })()
            source: resolvedSource
            smooth: true
            mipmap: true
        }
    }

    // --- Tooltip (disabled) ---
    // Loader for tooltips (currently disabled by setting active: false)
    Loader {
        id: tooltipLoader
        active: false  // Disable tooltips
        sourceComponent: PanelWindow {
            id: tooltipPanel
            visible: tooltipLoader.active
            color: Qt.rgba(0, 0, 0, 0)
            implicitWidth: tooltipContent.implicitWidth
            implicitHeight: tooltipContent.implicitHeight

            // Set up as a popup window
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:docktooltip"

            // Let the window float freely
            anchors.left: true
            anchors.right: false
            anchors.top: false
            anchors.bottom: true
            
            margins {
                left: 655  // Hard-coded position that works well
                bottom: 65
                top: 0
                right: 0
            }

            Item {
                width: tooltipContent.implicitWidth
                height: tooltipContent.implicitHeight

                MultiEffect {
                    anchors.fill: tooltipContent
                    source: tooltipContent
                    shadowEnabled: true
                    shadowColor: Appearance.colors.colShadow
                    shadowVerticalOffset: 1
                    shadowBlur: 0.5
            }

            Rectangle {
                id: tooltipContent
                anchors.fill: parent
                color: Qt.rgba(
                    Appearance.colors.colLayer0.r,
                    Appearance.colors.colLayer0.g,
                    Appearance.colors.colLayer0.b,
                    1.0
                )
                radius: Appearance.rounding.small
                implicitWidth: tooltipText.implicitWidth + 30
                implicitHeight: tooltipText.implicitHeight + 16

                Text {
                    id: tooltipText
                    anchors.centerIn: parent
                    text: dockItem.tooltip
                    color: Appearance.colors.colOnLayer0
                    font: dockItem.font
                    }
                }
            }
        }
    }
    
    // --- Right-Click Context Menu ---
    // Menu moved to global level in Dock.qml to avoid constraints
    
    // --- Mouse Interaction ---
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        
        property bool dragActive: false
        property bool dragStarted: false
        
        // Track hover position for possible tooltip use
        onPositionChanged: (mouse) => {
            lastHoverPos = dockItem.mapToItem(null, mouse.x, mouse.y)
            
            // Handle dragging for pinned items only
            if (dragActive && dockItem.isPinned && (mouse.buttons & Qt.LeftButton)) {
                var distance = Math.sqrt(Math.pow(mouse.x - dragStartX, 2) + Math.pow(mouse.y - dragStartY, 2))
                
                if (!dragStarted && distance > dragThreshold) {
                    // Start dragging
                    dragStarted = true
                    dockItem.isDragging = true
                    dockItem.dragStarted()
                    // console.log("Started dragging item at model index:", dockItem.modelIndex)
                }
                
                if (dockItem.isDragging) {
                    // Update drop targets - use the direct repeater reference
                    var repeater = dockItem.parentRepeater
                    
                    if (repeater && repeater.count !== undefined) {
                        for (var i = 0; i < repeater.count; i++) {
                            var item = repeater.itemAt(i)
                            if (item && item !== dockItem && item.isPinned) {
                                // Get the global mouse position
                                var globalMousePos = dockItem.mapToItem(null, mouse.x, mouse.y)
                                // Map to the target item's coordinate system
                                var itemMousePos = item.mapFromItem(null, globalMousePos.x, globalMousePos.y)
                                
                                // Check if mouse is over this item
                                var isOver = (itemMousePos.x >= 0 && itemMousePos.x <= item.width && 
                                            itemMousePos.y >= 0 && itemMousePos.y <= item.height)
                                
                                if (isOver && !item.isDropTarget) {
                                    // console.log("Setting drop target for item at index:", i)
                                    item.isDropTarget = true
                                } else if (!isOver && item.isDropTarget) {
                                    // console.log("Clearing drop target for item at index:", i)
                                    item.isDropTarget = false
                                }
                            }
                        }
                    }
                }
            }
        }
        
        onPressed: (mouse) => {
            if (mouse.button === Qt.LeftButton && dockItem.isPinned) {
                dragActive = true
                dragStarted = false
                dragStartX = mouse.x
                dragStartY = mouse.y
                // console.log("Press detected on pinned item at model index:", dockItem.modelIndex)
            }
        }
        
        onReleased: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                if (dockItem.isDragging) {
                    // console.log("Drop detected")
                    // Handle drop - use the direct repeater reference
                    var repeater = dockItem.parentRepeater
                    var dropTargetIndex = -1
                    var currentIndex = dockItem.modelIndex
                    
                    // console.log("Current item index:", currentIndex)
                    // console.log("Repeater count:", repeater ? repeater.count : "no repeater")
                    
                    if (repeater && repeater.count !== undefined) {
                        for (var i = 0; i < repeater.count; i++) {
                            var item = repeater.itemAt(i)
                            // console.log("Checking item", i, "isPinned:", item ? item.isPinned : "no item", "isDropTarget:", item ? item.isDropTarget : "no item")
                            if (item && item !== dockItem && item.isPinned && item.isDropTarget) {
                                dropTargetIndex = i
                                item.isDropTarget = false
                                // console.log("Found drop target at index:", dropTargetIndex)
                                break
                            } else if (item && item.isDropTarget !== undefined) {
                                item.isDropTarget = false
                            }
                        }
                    }
                    
                    // console.log("Final drop target index:", dropTargetIndex)
                    // console.log("Current index:", currentIndex)
                    
                    // Perform reorder if valid drop target found
                    if (dropTargetIndex >= 0 && currentIndex >= 0 && dropTargetIndex !== currentIndex) {
                        // console.log("Calling reorderPinnedApp from", currentIndex, "to", dropTargetIndex)
                        dock.reorderPinnedApp(currentIndex, dropTargetIndex)
                    } else {
                        // console.log("No reorder: dropTargetIndex =", dropTargetIndex, "currentIndex =", currentIndex)
                    }
                    
                    // End dragging
                    dockItem.isDragging = false
                    dragStarted = false
                    dockItem.dragEnded()
                }
                
                dragActive = false
            }
        }
        
        // Handle left and right clicks
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton && !dockItem.isDragging) {
                dockItem.clicked()
            } else if (mouse.button === Qt.RightButton) {
                // Use the existing dock context menu function
                if (dock && dock.openDockContextMenu) {
                    dock.openDockContextMenu(dockItem.appData, dockItem.isPinned, dockItem, mouse)
                }
            }
        }
        
        // Track mouse over state for dock hover logic
        onEntered: {
            // console.log("[DOCK ITEM DEBUG] Mouse entered dock item for:", appData?.class || "unknown");
            dock.mouseOverDockItem = true
            
            // DISABLED: Show window previews if this app has multiple windows
            // if (appData && appData.class && !showMenu) {
            //     console.log("[DOCK ITEM DEBUG] Calling showWindowPreviews for:", appData.class);
            //     const position = dockItem.mapToItem(null, dockItem.width / 2, 0);
            //     dock.showWindowPreviews(appData.class, position, dockItem.width);
            // } else {
            //     console.log("[DOCK ITEM DEBUG] Not calling showWindowPreviews - appInfo:", !!appData, "class:", appData?.class, "showMenu:", showMenu);
            // }
        }
        
        onExited: {
            dock.mouseOverDockItem = false
            
            // DISABLED: Hide window previews
            // dock.hideWindowPreviews();
        }
    }
    
    // --- Active Indicator ---
    // A small dot centered at the bottom to show if the app is active
    Rectangle {
        id: activeIndicator
        visible: isActive
        width: 6
        height: 6
        radius: 3
        color: Appearance.colors.colOnLayer1
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -2
    }
    
    // --- Drop Indicator ---
    // Visual indicator when this item is a drop target
    Rectangle {
        id: dropIndicator
        visible: isDropTarget
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.color: Appearance.m3colors.m3primary
        border.width: 2
        
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.8
            height: parent.height * 0.8
            radius: parent.radius
            color: Qt.rgba(Appearance.m3colors.m3primary.r, 
                          Appearance.m3colors.m3primary.g, 
                          Appearance.m3colors.m3primary.b, 0.2)
        }
    }
}

// --- Footnotes ---
// [1] Right-click triggers the context menu for this dock item.
// [2] Ensures only one menu is open at a time by closing others.
// [3] Toggles the menu: closes if already open, opens if closed.
// [4] Stores the mouse position so the menu can be placed near the click.
// [5] Setting showMenu to true triggers the Loader below to create the menu.
// [6] The Loader creates the menu window (Popup) when showMenu is true.
// [7] The menu's UI and actions (Pin/Unpin, Launch, Move, Toggle, Close) are defined in DockItemMenuPanel.qml.
