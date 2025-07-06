# Matt's Quickshell Hyprland Configuration Changelog

![image](https://github.com/user-attachments/assets/49bba28f-776e-454d-a351-a42bba898cd6)

---

A comprehensive documentation of all changes made in converting end-4's AGS-based Hyprland configuration (https://github.com/end-4/dots-hyprland) to Quickshell, with dock implementation based on Pharmaracist's work.

0. Recent Implementation Changes
-----------------------------
File: ~/.config/quickshell/modules/dock/DockItem.qml

A. Right-Click Menu System Overhaul:
```qml
// Previous implementation using standalone Menu
Menu {
    id: contextMenu
    x: parent.width / 2
    y: parent.height
    // Static positioning and basic styling
}

// New implementation using Loader and PanelWindow
Loader {
    id: menuLoader
    active: dockItem.showMenu
    sourceComponent: PanelWindow {
        id: menuPanel
        visible: dockItem.showMenu
        color: Qt.rgba(0, 0, 0, 0)
        implicitWidth: 200
        implicitHeight: menuContent.implicitHeight

        // Enhanced popup window configuration
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:dockmenu"

        // Dynamic positioning based on mouse click
        margins {
            left: dockItem.x + lastClickPos.x + 500
            bottom: 2
        }

        // Improved focus handling
        HyprlandFocusGrab {
            windows: [menuPanel]
            active: menuPanel.visible
            onCleared: () => {
                if (!active) {
                    dockItem.closeMenu()
                }
            }
        }

        // Enhanced menu styling and animations
        Rectangle {
            id: menuContent
            anchors.fill: parent
            radius: Appearance.rounding.small
            color: Appearance.colors.colLayer0
            implicitHeight: menuLayout.implicitHeight + radius * 2

            // Optimized shadow implementation
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 1
                radius: 8.0
                samples: 17
                color: Appearance.colors.colShadow
                source: parent
            }
        }
    }
}
```

B. Performance Optimizations:
File: ~/.config/quickshell/modules/dock/DockItem.qml
```qml
// Previous shadow implementation
MultiEffect {
    source: menuContent
    anchors.fill: menuContent
    shadowEnabled: true
    shadowColor: Appearance.colors.colShadow
    shadowVerticalOffset: 1
    shadowBlur: 0.5
}

// New optimized shadow using DropShadow
layer.enabled: true
layer.effect: DropShadow {
    horizontalOffset: 0
    verticalOffset: 1
    radius: 8.0
    samples: 17
    color: Appearance.colors.colShadow
    source: parent
}
```

C. Window Management Improvements:
File: ~/.config/quickshell/modules/dock/DockItem.qml
```qml
// Enhanced window management logic
MenuButton {
    Layout.fillWidth: true
    buttonText: qsTr("Move to workspace") + " >"
    enabled: {
        // Improved window detection
        var hasActiveWindow = false
        if (dockItem.appInfo.address) {
            hasActiveWindow = HyprlandData.windowByAddress[dockItem.appInfo.address] !== undefined
        } else if (dockItem.appInfo.class) {
            hasActiveWindow = HyprlandData.windowList.some(w => 
                w.class.toLowerCase() === dockItem.appInfo.class.toLowerCase() ||
                w.initialClass.toLowerCase() === dockItem.appInfo.class.toLowerCase()
            )
        }
        return hasActiveWindow
    }
}
```

D. Focus Management:
File: ~/.config/quickshell/modules/dock/DockItem.qml
```qml
// Previous focus handling
MouseArea {
    anchors.fill: parent
    onClicked: menu.popup()
}

// New focus management system
HyprlandFocusGrab {
    windows: [menuPanel]
    active: menuPanel.visible
    onCleared: () => {
        if (!active) {
            dockItem.closeMenu()
        }
    }
}

// Enhanced click handling
MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    
    onPositionChanged: (mouse) => {
        lastHoverPos = dockItem.mapToItem(null, mouse.x, mouse.y)
    }
    
    onClicked: (mouse) => {
        if (mouse.button === Qt.RightButton) {
            // Close other menus first
            var items = parent.children
            for (var i = 0; i < items.length; i++) {
                var item = items[i]
                if (item !== dockItem && item.closeMenu) {
                    item.closeMenu()
                }
            }
            
            lastClickPos = Qt.point(mouse.x, mouse.y)
            dockItem.showMenu = true
            dockItem.isActiveMenu = true
        }
    }
}
```

E. Visual Improvements:
File: ~/.config/quickshell/style/Theme.qml
```qml
// Enhanced menu styling
Rectangle {
    id: menuContent
    anchors.fill: parent
    radius: Appearance.rounding.small
    color: Appearance.colors.colLayer0
    
    // Improved separator styling
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Qt.rgba(
            Appearance.colors.colOnLayer0.r,
            Appearance.colors.colOnLayer0.g,
            Appearance.colors.colOnLayer0.b,
            0.1
        )
    }
}

// Enhanced button interactions
MenuButton {
    background: Rectangle {
        color: button.down ? Qt.rgba(
            Appearance.colors.colPrimary.r,
            Appearance.colors.colPrimary.g,
            Appearance.colors.colPrimary.b,
            0.2
        ) : button.hovered ? Qt.rgba(
            Appearance.colors.colPrimary.r,
            Appearance.colors.colPrimary.g,
            Appearance.colors.colPrimary.b,
            0.1
        ) : "transparent"
        radius: Appearance.rounding.small
        
        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
            }
        }
    }
}
```

F. Hyprland Integration Updates:
File: ~/.config/hypr/hyprland.conf
```conf
# Enhanced window rules
windowrulev2 = float,class:^(quickshell)$
windowrulev2 = noanim,class:^(quickshell)$
windowrulev2 = noblur,class:^(quickshell)$
windowrulev2 = rounding 30,class:^(quickshell)$

# Improved layer rules
layerrule = blur,quickshell:dock:blur
layerrule = ignorezero,quickshell:dock:blur

# Performance optimizations
misc {
    force_default_wallpaper = 0
    disable_splash_rendering = true
    disable_hyprland_logo = true
    no_direct_scanout = false
    disable_autoreload = true
}
```

G. System Service Improvements:
File: ~/.config/quickshell/services/NotificationManager.qml
```qml
// Enhanced notification handling
NotificationManager {
    id: notificationManager
    popupTimeout: 5000
    popupLocation: Qt.TopRight
    
    property var activeNotifications: []
    
    function showNotification(notification) {
        // Improved stacking and positioning
        const yOffset = activeNotifications.length * (notificationHeight + spacing)
        notification.y = baseY + yOffset
        
        // Enhanced animation handling
        notification.opacity = 0
        notification.visible = true
        notification.opacity = 1
        
        activeNotifications.push(notification)
    }
    
    function removeNotification(notification) {
        // Smooth removal animation
        notification.opacity = 0
        activeNotifications = activeNotifications.filter(n => n !== notification)
        repositionNotifications()
    }
}
```

Recent Changes & Improvements
---------------------------
1. **Right-Click Menu System Overhaul**
   - Completely redesigned using a Loader-based approach
   - Custom menu styling with proper borders and transparency
   - Fixed positioning relative to mouse cursor
   - Improved memory management and cleanup
   - Dynamic menu creation and destruction

2. **Performance Optimizations**
   - Removed dependency on MultiEffect for shadow rendering
   - Better error handling and logging
   - Improved component loading efficiency
   - Enhanced focus management
   - Better window tracking and state management

3. **System Integration Enhancements**
   - Improved Hyprland window management
   - Enhanced notification system
   - Better media controls integration
   - Weather module improvements

4. **Visual and UX Improvements**
   - Enhanced dock item styling
   - Improved hover effects and animations
   - Better blur effects and transparency
   - More responsive UI interactions

File Locations Overview
----------------------
Main configuration files changed from AGS to Quickshell:
- ~/.config/quickshell/shell.qml (Replaces ~/.config/ags/main.js)
- ~/.config/quickshell/modules/bar/ (Replaces ~/.config/ags/modules/bar/)
- ~/.config/quickshell/modules/dock/ (Replaces ~/.config/ags/modules/dock/)
- ~/.config/quickshell/style/ (Replaces ~/.config/ags/scss/)
- ~/.config/quickshell/services/ (Replaces ~/.config/ags/services/)
- ~/.config/hypr/hyprland.conf (Modified for Quickshell compatibility)

1. Core Shell Implementation
--------------------------
File: ~/.config/quickshell/shell.qml (Replaces ~/.config/ags/main.js)

Original (AGS):
```javascript
import App from 'resource:///com/github/Aylur/ags/app.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';

export default {
    style: App.configDir + '/style.css',
    windows: [
        // window definitions
    ]
};
```

New (Quickshell):
```qml
import "./modules/bar/"
import "./modules/cheatsheet/"
import "modules/dock"
import "./modules/mediaControls/"
import "./modules/notificationPopup/"
import "./modules/onScreenDisplay/"
import "./modules/overview/"
import "./modules/screenCorners/"
import "./modules/session/"
import "./modules/sidebarLeft/"
import "./modules/sidebarRight/"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import "./services/"

ShellRoot {
    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        ConfigLoader.loadConfig()
        PersistentStateManager.loadStates()
    }

    Bar {}
    Cheatsheet {}
    Dock {}
    MediaControls {}
    NotificationPopup {}
    OnScreenDisplayBrightness {}
    OnScreenDisplayVolume {}
    Overview {}
    ReloadPopup {}
    ScreenCorners {}
    Session {}
    SidebarLeft {}
    SidebarRight {}
}
```

2. Bar Module Conversion
-----------------------
File: ~/.config/quickshell/modules/bar/Bar.qml (Replaces ~/.config/ags/modules/bar/bar.js)

Original (AGS):
```javascript
const Bar = () => Widget.Window({
    name: 'bar',
    anchor: ['top', 'left', 'right'],
    exclusive: true,
    child: Widget.CenterBox({
        startWidget: leftModules,
        centerWidget: centerModules,
        endWidget: rightModules,
    }),
});
```

New (Quickshell):
```qml
Scope {
    id: bar

    readonly property int barHeight: Appearance.sizes.barHeight
    readonly property int barCenterSideModuleWidth: Appearance.sizes.barCenterSideModuleWidth
    readonly property int osdHideMouseMoveThreshold: 20
    property bool showBarBackground: ConfigOptions.bar.showBackground

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barRoot
            screen: modelData
            WlrLayershell.namespace: "quickshell:bar:blur"
            implicitHeight: barHeight
            exclusiveZone: showBarBackground ? barHeight : (barHeight - 4)
            mask: Region {
                item: barContent
            }
            
            // Detailed bar implementation...
        }
    }
}
```

3. Dock Implementation (Based on Pharmaracist's Work)
--------------------------------------------------
File: ~/.config/quickshell/modules/dock/Dock.qml

Original Source: Adapted from [Pharmaracist's Quickshell implementation](https://github.com/Pharmaracist/dots-hyprland/tree/ii-qs/.config/quickshell)

Key Modifications:
```qml
// Added custom dock dimensions
readonly property int dockHeight: Appearance.sizes.barHeight * 1.5
readonly property int dockWidth: Appearance.sizes.barHeight * 1.5
readonly property int dockSpacing: Appearance.sizes.elevationMargin

// Modified background transparency
readonly property color backgroundColor: Qt.rgba(
    Appearance.colors.colLayer0.r,
    Appearance.colors.colLayer0.g,
    Appearance.colors.colLayer0.b,
    0.65  // Adjusted transparency
)

// Added custom pinned apps configuration
readonly property var defaultPinnedApps: [
    "microsoft-edge-dev",
    "org.gnome.Nautilus",
    "vesktop",
    "cider",
    "steam-native",
    "lutris",
    "heroic",
    "obs",
    "com.blackmagicdesign.resolve.desktop",
    "AffinityPhoto.desktop",
    "ptyxis"
]

// Added custom Arch menu button
Rectangle {
    id: archButton
    anchors.fill: parent
    anchors.margins: 4
    radius: Appearance.rounding.full
    color: archMouseArea.containsMouse ? Appearance.colors.colPrimary : "transparent"
    opacity: archMouseArea.containsMouse ? 0.8 : 0.5
    
    Image {
        anchors.centerIn: parent
        source: "/home/matt/.config/quickshell/logo/Arch-linux-logo.png"
        width: parent.width * 0.9
        height: parent.height * 0.9
        fillMode: Image.PreserveAspectFit
    }
}
```

A. Dock Item Modifications (DockItem.qml):
```qml
// Enhanced dock item styling
Rectangle {
    implicitWidth: dock.dockWidth - 10
    implicitHeight: dock.dockWidth - 10
    radius: Appearance.rounding.full
    
    // Modified hover effects
    color: mouseArea.pressed ? Appearance.colors.colLayer1Active : 
           mouseArea.containsMouse ? Appearance.colors.colLayer1Hover : 
           "transparent"
    
    // Added custom icon sizing
    Image {
        width: parent.width * 0.65
        height: parent.height * 0.65
        anchors.bottomMargin: 10
    }
}
```

B. Context Menu Enhancements (DockItemMenu.qml):
```qml
// Added custom menu styling
background: Rectangle {
    implicitWidth: 200
    color: Qt.rgba(
        Appearance.colors.colLayer0.r,
        Appearance.colors.colLayer0.g,
        Appearance.colors.colLayer0.b,
        1.0
    )
    radius: Appearance.rounding.small
    border.width: 1
    border.color: Qt.rgba(
        Appearance.colors.colOnLayer0.r,
        Appearance.colors.colOnLayer0.g,
        Appearance.colors.colOnLayer0.b,
        0.1
    )
}

// Fixed right-click menu positioning
onRightClicked: (mouse) => {
    var component = Qt.createComponent("DockItemMenu.qml")
    if (component.status === Component.Ready) {
        var menu = component.createObject(parent, {
            "appInfo": modelData,
            "isPinned": false
        })
        
        // Position menu at mouse cursor location instead of default position
        menu.popup(Qt.point(mouse.x, mouse.y))
    }
}

// Added new menu items
MenuItem {
    id: floatMenuItem
    text: qsTr("Toggle floating")
    icon.name: "window-float"
    // ... custom styling
}
```

Key Fixes:
1. **Menu Positioning**: Fixed the context menu to appear directly under the mouse cursor instead of at a fixed position relative to the dock item
2. **Mouse Coordinates**: Properly passing mouse event coordinates to ensure accurate menu placement
3. **Dynamic Creation**: Improved menu object creation to ensure proper cleanup and prevent memory leaks

C. Configuration Changes (dock_config.json):
```json
{
  "pinnedApps": [
    "org.gnome.Nautilus",
    "vesktop",
    "cider",
    "steam-native",
    "lutris",
    "heroic.desktop",
    "obs.desktop",
    "com.blackmagicdesign.resolve.desktop",
    "AffinityPhoto.desktop",
    "ptyxis"
  ],
  "autoHide": false
}
```

D. Hyprland Integration (hyprland-rules.conf):
```conf
# Added custom window rules for dock
windowrulev2 = blur,class:^(quickshell)$
windowrulev2 = rounding 30,class:^(quickshell)$
windowrulev2 = nofocus,class:^(quickshell)$

# Added layer rules for proper blur
layerrule = blur,quickshell:dock:blur
layerrule = ignorezero,quickshell:dock:blur
```

4. Theme System Migration
------------------------
Directory: ~/.config/quickshell/style/ (Replaces ~/.config/ags/scss/)

Original (AGS SCSS):
```scss
$bg: #1e1e2e;
$fg: #cdd6f4;

.bar {
    background-color: $bg;
    color: $fg;
}
```

New (Quickshell QML):
```qml
// style/Theme.qml
QtObject {
    readonly property color background: "#1e1e2e"
    readonly property color foreground: "#cdd6f4"
    
    readonly property QtObject bar: QtObject {
        readonly property color background: root.background
        readonly property color foreground: root.foreground
    }
}
```

5. Weather Module Integration (by lysec)
--------------------------------------
File: ~/.config/quickshell/modules/bar/Weather.qml

Implementation:
```qml
// Weather module by lysec
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Weather

WeatherWidget {
    id: weatherWidget
    
    // Weather implementation details...
    // Configuration and display logic
}
```

6. System Services
-----------------
Directory: ~/.config/quickshell/services/

Original (AGS):
```javascript
// services/brightness.js
const Brightness = {
    // AGS implementation
};
```

New (Quickshell):
```qml
// services/Brightness.qml
QtObject {
    id: brightnessService
    
    property var monitors: []
    property real globalBrightness: 1.0
    
    // Quickshell implementation
}
```

7. Hyprland Integration
----------------------
File: ~/.config/hypr/hyprland.conf

Added:
```conf
# Quickshell Integration
exec-once = qs

# Window Rules
windowrulev2 = float,class:^(quickshell)$
windowrulev2 = noanim,class:^(quickshell)$
windowrulev2 = noblur,class:^(quickshell)$

# Performance Optimizations
misc {
    force_default_wallpaper = 0
    disable_splash_rendering = true
    disable_hyprland_logo = true
}
```

8. Additional Components
----------------------
A. Notification System:
```qml
// modules/notificationPopup/NotificationPopup.qml
NotificationManager {
    popupTimeout: 5000
    popupLocation: Qt.TopRight
    
    // Notification handling logic
}
```

B. Media Controls:
```qml
// modules/mediaControls/MediaControls.qml
MediaController {
    players: MprisService.players
    
    // Media control implementation
}
```

A. Media Controls Cover Art Consistency:
File: ~/.config/quickshell/modules/mediaControls/PlayerControl.qml
```qml
// Previous art URL handling
property var artUrl: player?.metadata["xesam:url"] || player?.metadata["mpris:artUrl"] || player?.trackArtUrl

// New robust art URL handling with fallback mechanism
property var artUrl: {
    // Try different metadata sources in order of preference
    const sources = [
        player?.metadata["mpris:artUrl"],
        player?.metadata["xesam:artUrl"],
        player?.trackArtUrl,
        "" // Fallback empty string if no art found
    ];
    // Return first non-empty valid URL
    return sources.find(url => url && url.length > 0) || "";
}

// Enhanced error handling for art loading
Image {
    id: mediaArt
    // ... existing properties ...
    
    onStatusChanged: {
        if (status === Image.Error) {
            playerController.artLoadError = true;
            playerController.artDominantColor = Appearance.m3colors.m3secondaryContainer;
        } else if (status === Image.Ready) {
            playerController.artLoadError = false;
        }
    }
}
```

B. Idle/Suspend Steam Compatibility:
File: ~/.config/quickshell/scripts/wayland-idle-inhibitor.py
```python
# Added Steam process detection
def is_steam_running() -> bool:
    try:
        # Check if steam process is running
        subprocess.run(["pidof", "steam"], check=True, capture_output=True)
        return True
    except subprocess.CalledProcessError:
        return False

# Modified inhibitor destruction logic
def main() -> None:
    # ... existing setup code ...
    
    print("Inhibiting idle...")
    done.wait()
    print("Shutting down...")

    # Only destroy inhibitor if Steam is not running
    if not is_steam_running():
        inhibitor.destroy()

    shutdown()
```