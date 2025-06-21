import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import "root:/Data" as Data

// System tray with icon caching
Row {
    property var bar
    property var shell
    property var trayMenu
    spacing: 8
    Layout.alignment: Qt.AlignVCenter
    
    property bool containsMouse: false
    property var systemTray: SystemTray
    
    // Custom icon cache to reduce memory usage
    property var iconCache: ({})
    property var iconCacheCount: ({})
    
    // Aggressive cache cleanup to prevent memory leaks
    Timer {
        interval: 120000
        repeat: true
        running: systemTray.items.length > 0
        onTriggered: {
            // Decrement counters and remove unused icons
            for (let icon in iconCacheCount) {
                iconCacheCount[icon]--
                if (iconCacheCount[icon] <= 0) {
                    delete iconCache[icon]
                    delete iconCacheCount[icon]
                }
            }
            
            // Enforce maximum cache size
            const maxCacheSize = 10;
            const cacheKeys = Object.keys(iconCache);
            if (cacheKeys.length > maxCacheSize) {
                const toRemove = cacheKeys.slice(0, cacheKeys.length - maxCacheSize);
                toRemove.forEach(key => {
                    delete iconCache[key];
                    delete iconCacheCount[key];
                });
            }
        }
    }
    
    Repeater {
        model: systemTray.items
        delegate: Item {
            width: 24
            height: 24
            property bool isHovered: trayMouseArea.containsMouse
            
            onIsHoveredChanged: updateParentHoverState()
            Component.onCompleted: updateParentHoverState()
            
            // Update parent hover state based on any child being hovered
            function updateParentHoverState() {
                let anyHovered = false
                for (let i = 0; i < parent.children.length; i++) {
                    if (parent.children[i].isHovered) {
                        anyHovered = true
                        break
                    }
                }
                parent.containsMouse = anyHovered
            }
            
            // Hover animations
            scale: isHovered ? 1.15 : 1.0
            Behavior on scale {
                enabled: isHovered
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
            
            rotation: isHovered ? 5 : 0
            Behavior on rotation {
                enabled: isHovered
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
            
            Image {
                id: trayIcon
                anchors.centerIn: parent
                width: 18
                height: 18
                sourceSize.width: 18
                sourceSize.height: 18
                smooth: false      // Memory savings
                asynchronous: true
                cache: false       // Use custom cache instead
                source: {
                    let icon = modelData?.icon || "";
                    if (!icon) return "";
                    
                    // Return cached icon if available
                    if (iconCache[icon]) {
                        iconCacheCount[icon] = 2
                        return iconCache[icon];
                    }
                    
                    // Process icon path
                    let finalPath = icon;
                    if (icon.includes("?path=")) {
                        const [name, path] = icon.split("?path=");
                        const fileName = name.substring(name.lastIndexOf("/") + 1);
                        finalPath = `file://${path}/${fileName}`;
                    }
                    
                    // Cache the processed path
                    iconCache[icon] = finalPath;
                    iconCacheCount[icon] = 2;
                    return finalPath;
                }
                opacity: status === Image.Ready ? 1 : 0
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }
            }
            
            // Clean up cache entry
            Component.onDestruction: {
                let icon = modelData?.icon || "";
                if (icon) {
                    delete iconCache[icon];
                    delete iconCacheCount[icon];
                }
            }
            
            // Handle tray item interactions
            MouseArea {
                id: trayMouseArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: (mouse) => {
                    if (!modelData) return;
                    
                    if (mouse.button === Qt.LeftButton) {
                        if (trayMenu && trayMenu.visible) {
                            trayMenu.hide()
                        }
                        if (!modelData.onlyMenu) {
                            modelData.activate()
                        }
                    } else if (mouse.button === Qt.MiddleButton) {
                        if (trayMenu && trayMenu.visible) {
                            trayMenu.hide()
                        }
                        modelData.secondaryActivate && modelData.secondaryActivate()
                    } else if (mouse.button === Qt.RightButton) {
                        if (trayMenu && trayMenu.visible) {
                            trayMenu.hide()
                            return
                        }
                        // Show context menu if available
                        if (modelData.hasMenu && modelData.menu && trayMenu) {
                            trayMenu.menu = modelData.menu
                            const iconCenter = Qt.point(width / 2, height)
                            const iconPos = mapToItem(trayMenu.parent, 0, 0)
                            const menuX = iconPos.x - (trayMenu.width / 2) + (width / 2)
                            const menuY = iconPos.y + height + 15
                            trayMenu.show(Qt.point(menuX, menuY), trayMenu.parent)
                        }
                    }
                }
            }
        }
    }
}