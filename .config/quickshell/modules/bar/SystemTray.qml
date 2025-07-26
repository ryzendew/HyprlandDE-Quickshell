import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Qt5Compat.GraphicalEffects 
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "root:/modules/common/widgets"

Row {
    property var bar
    property var shell
    property var trayMenu
    property int iconSize: ConfigOptions.getSystrayIconSize() || 24 // Accept iconSize from parent
    spacing: 8
    Layout.alignment: Qt.AlignVCenter
    Layout.fillHeight: true
    height: parent ? parent.height : implicitHeight
    
    property bool containsMouse: false
    property var systemTray: SystemTray
    property int trayIconSize: iconSize // Use the passed iconSize
    
    // Initialize and listen for configuration changes
    Component.onCompleted: {
        updateIconSize();
    }
    
    // Listen for configuration changes
    Connections {
        target: ConfigOptions.bar
        function onSystrayIconSizeChanged() {
            updateIconSize();
        }
    }
    
    // Also listen for config reloads when settings are saved
    Connections {
        target: ConfigLoader
        function onPendingChangesChanged() {
            // Update when config is reloaded
            updateIconSize();
        }
    }
    
    function updateIconSize() {
        let size = iconSize;
        console.log("[SystemTray] updateIconSize() called - iconSize property:", size);
        if (size > 0) {
            trayIconSize = size;
            console.log("[SystemTray] trayIconSize updated to:", trayIconSize);
        }
    }
    
    Repeater {
        model: systemTray.items
        delegate: Item {
            width: trayIconSize
            height: trayIconSize
            // Hide Spotify icon, or adjust to your liking
            visible: modelData && modelData.id !== "spotify"
            property bool isHovered: trayMouseArea.containsMouse
            
            // Ensure the item is vertically centered within the parent
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            
            // Hover scale animation
            scale: isHovered ? 1.15 : 1.0
            Behavior on scale {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
            
            // Subtle rotation on hover
            rotation: isHovered ? 5 : 0
            Behavior on rotation {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
            
            Rectangle {
                anchors.centerIn: parent
                width: trayIconSize
                height: trayIconSize
                radius: 6
                color: "transparent"
                clip: true

                IconImage {
                    id: trayIcon
                    anchors.centerIn: parent
                    width: trayIconSize
                    height: trayIconSize
                    smooth: false
                    asynchronous: true
                    backer.fillMode: Image.PreserveAspectFit
                    source: {
                        let icon = modelData?.icon || "";
                        if (!icon) return "";
                        // Process icon path
                        if (icon.includes("?path=")) {
                            const [name, path] = icon.split("?path=");
                            const fileName = name.substring(name.lastIndexOf("/") + 1);
                            return `file://${path}/${fileName}`;
                        }
                        return icon;
                    }
                    opacity: status === Image.Ready ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
            
            MouseArea {
                id: trayMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: (mouse) => {
                    if (!modelData) return;
                    
                    if (mouse.button === Qt.LeftButton) {
                        // Close any open menu first
                        if (trayMenu && trayMenu.visible) {
                            trayMenu.hideMenu()
                        }
                        
                        if (!modelData.onlyMenu) {
                            modelData.activate()
                        }
                    } else if (mouse.button === Qt.MiddleButton) {
                        // Close any open menu first
                        if (trayMenu && trayMenu.visible) {
                            trayMenu.hideMenu()
                        }
                        
                        modelData.secondaryActivate && modelData.secondaryActivate()
                    } else if (mouse.button === Qt.RightButton) {
                        console.log("Right click on", modelData.id, "hasMenu:", modelData.hasMenu, "menu:", modelData.menu)
                        // If menu is already visible, close it
                        if (trayMenu && trayMenu.visible) {
                            trayMenu.hideMenu()
                            return
                        }
                        
                        if (modelData.hasMenu && modelData.menu && trayMenu) {
                            // Anchor the menu to the tray icon item (parent) and position it below the icon
                            const menuX = (width / 2) - (trayMenu.width / 2);
                            const menuY = height + 20;
                            trayMenu.menu = modelData.menu;
                            trayMenu.showAt(parent, menuX, menuY);
                        } else {
                            // console.log("No menu available for", modelData.id, "or trayMenu not set")
                        }
                    }
                }
            }
        }
    }
}