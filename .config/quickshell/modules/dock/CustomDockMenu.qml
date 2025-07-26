pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "root:/modules/common"

PopupWindow {
    id: dockMenu
    implicitWidth: 180
    implicitHeight: Math.max(40, listView.contentHeight + 12)
    visible: false
    color: "transparent"

    property var contextAppInfo: null
    property bool contextIsPinned: false
    property var contextDockItem: null
    property var anchorItem: null
    property real anchorX
    property real anchorY
    property var dock: null
    property bool workspaceExpanded: false

    anchor.item: anchorItem ? anchorItem : null
    anchor.rect.x: anchorX
    anchor.rect.y: anchorY - 4

    function showAt(item, x, y) {
        if (!item) {
            console.warn("CustomDockMenu: anchorItem is undefined, not showing menu.");
            return;
        }
        
        // If menu is already visible and same item, just hide it
        if (visible && anchorItem === item) {
            hideMenu()
            return
        }
        
        anchorItem = item
        anchorX = x
        anchorY = y
        populateMenu()
        visible = true
        forceActiveFocus()
        Qt.callLater(() => dockMenu.anchor.updateAnchor())
        
        // No global MouseArea needed - PopupWindow handles outside clicks automatically
    }

    function hideMenu() {
        visible = false
        workspaceExpanded = false
    }
    
    function expandWorkspaceSubmenu() {
        if (!workspaceExpanded) {
            workspaceExpanded = true
            // Find the workspace submenu item and insert workspace options after it
            var insertIndex = -1
            for (var i = 0; i < menuModel.count; i++) {
                if (menuModel.get(i).action === "workspace_submenu") {
                    insertIndex = i + 1
                    break
                }
            }
            
            if (insertIndex !== -1) {
                // Insert workspace options 1-10
                for (var j = 1; j <= 10; j++) {
                    menuModel.insert(insertIndex + j - 1, {
                        text: "  " + qsTr("Workspace ") + j,
                        enabled: true,
                        isSeparator: false,
                        action: "workspace_" + j
                    })
                }
            }
        }
    }
    
    function collapseWorkspaceSubmenu() {
        if (workspaceExpanded) {
            workspaceExpanded = false
            // Remove workspace options 1-10
            var removeCount = 0
            for (var i = menuModel.count - 1; i >= 0; i--) {
                if (menuModel.get(i).action && menuModel.get(i).action.startsWith("workspace_") && menuModel.get(i).action !== "workspace_submenu") {
                    menuModel.remove(i)
                    removeCount++
                }
                if (removeCount >= 10) break
            }
        }
    }

    function populateMenu() {
        menuModel.clear()
        
        // Debug logging
        console.log("[CustomDockMenu] populateMenu called with contextAppInfo:", JSON.stringify(contextAppInfo))
        console.log("[CustomDockMenu] contextAppInfo.address:", contextAppInfo ? contextAppInfo.address : "null")
        console.log("[CustomDockMenu] contextAppInfo.class:", contextAppInfo ? contextAppInfo.class : "null")
        
        // Pin/Unpin item
        menuModel.append({
            text: contextIsPinned ? qsTr("Unpin from dock") : qsTr("Pin to dock"),
            enabled: true,
            isSeparator: false,
            action: "pin"
        })
        
        // Launch new instance
        menuModel.append({
            text: qsTr("Launch new instance"),
            enabled: true,
            isSeparator: false,
            action: "launch"
        })
        
        // Separator
        menuModel.append({
            text: "",
            enabled: false,
            isSeparator: true,
            action: ""
        })
        
                            // Move to workspace (collapsible) - always show but enable/disable based on address
                    menuModel.append({
                        text: qsTr("Move to workspace"),
                        enabled: contextAppInfo && contextAppInfo.address !== undefined,
                        isSeparator: false,
                        action: "workspace_submenu",
                        hasSubmenu: true,
                        isExpanded: false
                    })
        
        // Toggle floating - always show but enable/disable based on address
        menuModel.append({
            text: qsTr("Toggle floating"),
            enabled: contextAppInfo && contextAppInfo.address !== undefined,
            isSeparator: false,
            action: "toggle_floating"
        })
        
        // Separator
        menuModel.append({
            text: "",
            enabled: false,
            isSeparator: true,
            action: ""
        })
        
        // Close
        menuModel.append({
            text: qsTr("Close"),
            enabled: true,
            isSeparator: false,
            action: "close"
        })
        
        // Close All
        if (contextAppInfo && contextAppInfo.class) {
            menuModel.append({
                text: qsTr("Close All"),
                enabled: true,
                isSeparator: false,
                action: "close_all"
            })
        }
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        color: "#1a1a1a"
        border.color: "#333333"
        border.width: 1
        radius: 12
        z: 0
        
        // Close menu when clicking outside
        MouseArea {
            anchors.fill: parent
            enabled: dockMenu.visible
            onClicked: {
                dockMenu.hideMenu()
            }
        }
    }

    ListView {
        id: listView
        anchors.fill: parent
        anchors.margins: 6
        spacing: 2
        interactive: false
        enabled: dockMenu.visible
        clip: true
        z: 1

        model: ListModel {
            id: menuModel
        }

        delegate: Rectangle {
            id: entry
            required property var modelData

            width: listView.width
            height: (modelData?.isSeparator) ? 8 : 32
            color: "transparent"
            radius: 12

            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 20
                height: 1
                color: Qt.darker(Appearance.colors.colLayer1, 1.4)
                visible: modelData?.isSeparator ?? false
            }

            Rectangle {
                id: bg
                anchors.fill: parent
                color: mouseArea.containsMouse ? "#404040" : "transparent"
                radius: 8
                visible: !(modelData?.isSeparator ?? false)
                property color hoverTextColor: mouseArea.containsMouse ? "#ffffff" : "#ffffff"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        color: (modelData?.enabled ?? true) ? bg.hoverTextColor : "#666666"
                        text: modelData?.text ?? ""
                        font.family: Appearance.font.family
                        font.pixelSize: Appearance.font.pixelSize.small
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    Image {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        source: modelData?.icon ?? ""
                        visible: (modelData?.icon ?? "") !== ""
                        fillMode: Image.PreserveAspectFit
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: (modelData?.enabled ?? true) && !(modelData?.isSeparator ?? false) && dockMenu.visible

                    onClicked: {
                        if (modelData && !modelData.isSeparator && modelData.enabled) {
                            if (modelData.hasSubmenu) {
                                // Toggle workspace submenu expansion
                                if (dockMenu.workspaceExpanded) {
                                    dockMenu.collapseWorkspaceSubmenu()
                                } else {
                                    dockMenu.expandWorkspaceSubmenu()
                                }
                            } else {
                                handleMenuAction(modelData.action)
                                dockMenu.hideMenu()
                            }
                        }
                    }

                }
            }
        }
    }

    function handleMenuAction(action) {
        switch (action) {
            case "pin":
                if (contextIsPinned) {
                    dock.removePinnedApp(contextAppInfo.class)
                } else {
                    dock.addPinnedApp(contextAppInfo.class)
                }
                break
            case "launch":
                if (contextAppInfo && contextAppInfo.class) {
                    dock.launchApp(contextAppInfo.class)
                }
                break
            case "toggle_floating":
                if (contextAppInfo && contextAppInfo.address) {
                    Hyprland.dispatch(`togglefloating address:${contextAppInfo.address}`)
                }
                break
            case "close":
                if (contextAppInfo && contextAppInfo.address) {
                    Hyprland.dispatch(`closewindow address:${contextAppInfo.address}`)
                } else if (contextAppInfo && contextAppInfo.pid) {
                    Hyprland.dispatch(`closewindow pid:${contextAppInfo.pid}`)
                } else if (contextAppInfo && contextAppInfo.class) {
                    Hyprland.dispatch(`closewindow class:${contextAppInfo.class}`)
                }
                if (contextDockItem && contextDockItem.closeApp) contextDockItem.closeApp()
                break
            case "workspace_submenu":
                // This is just a submenu header, no action needed
                break

            case "close_all":
                if (contextAppInfo && contextAppInfo.class) {
                    var className = contextAppInfo.class;
                    
                    // Build mapping for .desktop files to possible window classes
                    var mapping = {
                        'AffinityPhoto.desktop': ['photo.exe', 'Photo.exe', 'affinityphoto', 'AffinityPhoto'],
                        'AffinityDesigner.desktop': ['designer.exe', 'Designer.exe', 'affinitydesigner', 'AffinityDesigner'],
                        'microsoft-edge-dev': ['microsoft-edge-dev', 'Microsoft-edge-dev', 'msedge', 'edge'],
                        'vesktop': ['vesktop', 'discord', 'Vesktop', 'Discord'],
                        'steam-native': ['steam', 'steam.exe', 'Steam', 'Steam.exe'],
                        'org.gnome.Nautilus': ['nautilus', 'org.gnome.nautilus', 'org.gnome.Nautilus', 'Nautilus'],
                        'org.gnome.nautilus': ['nautilus', 'org.gnome.nautilus', 'org.gnome.Nautilus', 'Nautilus'],
                        'org.gnome.Nautilus.desktop': ['nautilus', 'org.gnome.Nautilus'],
                        'lutris': ['lutris', 'net.lutris.lutris', 'net.lutris.Lutris', 'Lutris'],
                        'heroic': ['heroic', 'heroicgameslauncher', 'Heroic', 'HeroicGamesLauncher'],
                        'obs': ['obs', 'OBS', 'com.obsproject.studio', 'com.obsproject.Studio'],
                        'com.obsproject.Studio.desktop': ['obs', 'OBS', 'com.obsproject.studio', 'com.obsproject.Studio'],
                        'cursor-cursor': ['cursor', 'Cursor', 'cursor-cursor'],
                        'ptyxis': ['ptyxis', 'org.gnome.ptyxis', 'Ptyxis', 'Org.gnome.ptyxis'],
                        'com.blackmagicdesign.resolve.desktop': ['davinci-resolve-studio-20', 'DaVinci Resolve Studio 20', 'resolve', 'com.blackmagicdesign.resolve']
                    };
                    
                    // Get possible window classes for this app
                    var classes = [className];
                    
                    // Remove .desktop extension for mapping lookup
                    var baseClassName = className.replace(/\.desktop$/i, "");
                    
                    if (mapping[className]) {
                        classes = classes.concat(mapping[className]);
                    } else if (mapping[baseClassName]) {
                        classes = classes.concat(mapping[baseClassName]);
                    }
                    
                    // Also try the base name without .desktop extension
                    if (className !== baseClassName) {
                        classes.push(baseClassName);
                    }
                    
                    // Close all windows with these classes
                    for (var i = 0; i < classes.length; i++) {
                        try {
                            Hyprland.dispatch(`closewindow class:${classes[i]}`);
                        } catch (error) {
                            // Ignore errors for non-existent windows
                        }
                    }
                }
                if (contextDockItem && contextDockItem.closeApp) contextDockItem.closeApp()
                break
            default:
                if (action.startsWith("workspace_")) {
                    var workspaceNum = action.replace("workspace_", "")
                    if (contextAppInfo && contextAppInfo.address) {
                        Hyprland.dispatch(`movetoworkspace ${workspaceNum},address:${contextAppInfo.address}`)
                    }
                }
                break
        }
    }
    

} 