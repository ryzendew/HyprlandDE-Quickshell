import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "root:/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import Qt.labs.platform
import "root:/modules/bar"
import "root:/modules/dock"


Scope {
    id: dock

    // Dock dimensions and appearance
    readonly property int dockHeight: ConfigOptions.dock.height
    readonly property int dockWidth: ConfigOptions.dock.height // Use height for width to keep it square
    readonly property int dockSpacing: ConfigOptions.dock.spacing
    
    // Color properties that update when Appearance changes
    readonly property color backgroundColor: Qt.rgba(
        Appearance.colors.colLayer0.r,
        Appearance.colors.colLayer0.g,
        Appearance.colors.colLayer0.b,
        ConfigOptions.dock.transparency
    )
    
    // Auto-hide properties - use ConfigOptions as source of truth
    readonly property bool autoHide: ConfigOptions.dock.autoHide
    
    onAutoHideChanged: {
// console.log("[DOCK DEBUG] autoHide property changed to:", autoHide, "ConfigOptions.dock.autoHide:", ConfigOptions.dock.autoHide)
    }
    property int hideDelay: ConfigOptions.dock.hideDelay
    property int showDelay: ConfigOptions.dock.showDelay
    property int animationDuration: Appearance.animation.elementMoveFast.duration
    property int approachRegionHeight: ConfigOptions.dock.hoverRegionHeight // Height of the approach region in pixels
    
    // Property to track if mouse is over any dock item
    property bool mouseOverDockItem: false
    
    // Menu properties
    property bool showDockMenu: false
    property var menuAppInfo: ({})
    property rect menuTargetRect: Qt.rect(0, 0, 0, 0)  // Store position and size of target item
    property var activeMenuItem: null  // Track which item triggered the menu
    
    // Preview properties
    property bool showDockPreviews: ConfigOptions.dock.showPreviews
    property var previewAppClass: ""
    property point previewPosition: Qt.point(0, 0)
    property int previewItemWidth: 0
    
    // Pinned apps list - will be loaded from file
    property var pinnedApps: []
    
    // Active windows list - will be updated by PanelWindow
    property var activeWindows: []
    
    // No longer needed - using DesktopEntries.execute() like HyprMenu
    
    // Debug pinnedApps changes
    onPinnedAppsChanged: {
// console.log("[DOCK DEBUG] pinnedApps changed to:", JSON.stringify(pinnedApps))
    }
    
    // 1. Update pinned apps file path
    property string pinnedAppsFilePath: `${StandardPaths.writableLocation(StandardPaths.HomeLocation)}/.local/state/Quickshell/Dock/PinnedApps.conf`
    property string oldConfigFilePath: `${StandardPaths.writableLocation(StandardPaths.ConfigLocation)}/quickshell/dock_config.json`

    // 2. On startup, initialize pinned apps array
    Component.onCompleted: {
        // Initialize with empty array, FileView will load the data
        dock.pinnedApps = [];
    }

    // 3. Update save logic - using Hyprland.dispatch to write file
    function savePinnedApps() {
        try {
            // console.log("[SAVE PINNED DEBUG] Saving pinned apps to:", pinnedAppsFilePath);
            // console.log("[SAVE PINNED DEBUG] Pinned apps to save:", JSON.stringify(pinnedApps));
            
            // Use Hyprland.dispatch to write the pinned apps file
            // Create the directory if it doesn't exist
            var dirPath = pinnedAppsFilePath.replace('file://', '').replace('/PinnedApps.conf', '');
            // console.log("[SAVE PINNED DEBUG] Creating directory:", dirPath);
            Hyprland.dispatch(`exec mkdir -p '${dirPath}'`);
            
            // Write the JSON content to the file
            var jsonContent = JSON.stringify(pinnedApps, null, 2);
            // console.log("[SAVE PINNED DEBUG] JSON content to write:", jsonContent);
            Hyprland.dispatch(`exec echo '${jsonContent.replace(/'/g, "'\"'\"'")}' > '${pinnedAppsFilePath.replace('file://', '')}'`);
            
            // console.log("[SAVE PINNED DEBUG] Successfully saved pinned apps");
        } catch (e) {
            // console.log("[SAVE PINNED DEBUG] Error saving pinned apps:", e);
        }
    }

    // 4. Remove all fallback/defaults logic
    // Watch for ConfigOptions changes
    Connections {
        target: ConfigOptions.dock
        
        function onHeightChanged() {
            // Dock dimensions will update automatically due to property bindings
        }
        
        function onIconSizeChanged() {
            // Icon sizes will update automatically due to property bindings
        }
        
        function onRadiusChanged() {
            // Radius will update automatically due to property bindings
        }
        
        function onSpacingChanged() {
            // Spacing will update automatically due to property bindings
        }
        
        function onTransparencyChanged() {
            // Transparency will update automatically due to property bindings
        }
        
        function onAutoHideChanged() {
            // Auto-hide behavior will update automatically due to property bindings
        }
        
        function onHideDelayChanged() {
            // Hide delay will update automatically due to property bindings
        }
        
        function onShowDelayChanged() {
            // Show delay will update automatically due to property bindings
        }
        
        function onShowPreviewsChanged() {
            // Preview behavior will update automatically due to property bindings
        }
        
        function onShowLabelsChanged() {
            // Label visibility will update automatically due to property bindings
        }
        
        function onHoverRegionHeightChanged() {
            // Hover region height will update automatically due to property bindings
        }
    }
    
    // Watch for changes in icon theme - removed non-existent signal
    // The icon theme changes are handled by the FileView monitoring qt6ct.conf
    
    // FileView to monitor Qt6 theme settings changes
    FileView {
        id: qt6SettingsView
        path: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/qt6ct/qt6ct.conf"
        
        property string lastTheme: ""
        
        onLoaded: {
            try {
                var content = text();
                var lines = content.split('\n');
                var currentTheme = "";
                
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.startsWith('icon_theme=')) {
                        currentTheme = line.substring('icon_theme='.length);
                        break;
                    }
                }
                
                if (lastTheme === "") {
                    lastTheme = currentTheme;
                    // console.log("[DOCK DEBUG] Initial Qt6 theme detected:", currentTheme);
                    IconTheme.setCurrentTheme(currentTheme);
                    // Initialize the icon theme system with home directory
                    IconTheme.initializeIconTheme(StandardPaths.writableLocation(StandardPaths.HomeLocation));
                } else if (lastTheme !== currentTheme) {
                    // console.log("[DOCK DEBUG] Qt6 theme changed from", lastTheme, "to", currentTheme);
                    lastTheme = currentTheme;
                    
                    // Update the theme in the icon system
                    IconTheme.setCurrentTheme(currentTheme);
                    
                    // Refresh the available themes
                    IconTheme.refreshThemes(StandardPaths.writableLocation(StandardPaths.HomeLocation));
                    
                    // Force complete refresh of all dock items
                    forceRefreshIcons();
                }
            } catch (e) {
                // console.log("[DOCK DEBUG] Error reading Qt6 theme settings:", e);
            }
        }
    }
    
    // Timer to periodically check Qt6 theme changes
    Timer {
        interval: 5000 // Check every 5 seconds
        running: true
        repeat: true
        onTriggered: {
                qt6SettingsView.reload();
        }
    }
    
    // FileView to manage pinned apps storage
    FileView {
        id: pinnedAppsFileView
        path: pinnedAppsFilePath
        
        onLoaded: {
            try {
                var content = text();
                if (content && content.trim() !== '') {
                    var arr = JSON.parse(content);
                    if (Array.isArray(arr)) {
                        dock.pinnedApps = arr;
// console.log("[DOCK DEBUG] Loaded pinned apps:", JSON.stringify(dock.pinnedApps));
                    }
                }
            } catch (e) {
// console.log("[DOCK DEBUG] Error loading pinned apps from file:", e);
                dock.pinnedApps = [];
            }
        }
        
        onLoadFailed: {
// console.log("[DOCK DEBUG] Pinned apps file not found, starting with empty array");
            dock.pinnedApps = [];
        }
    }
    

    
    // Auto-hide is now managed through ConfigOptions.dock.autoHide
    // Use the settings UI to toggle auto-hide
    
    // Add a new app to pinned apps - ROBUST VERSION
    function addPinnedApp(appClass) {
        console.log("[PIN DEBUG] addPinnedApp called with:", appClass);
        
        // Use the same comprehensive mapping as removePinnedApp
        var comprehensiveMapping = {
            // Affinity apps
            "photo.exe": "AffinityPhoto.desktop",
            "Photo.exe": "AffinityPhoto.desktop",
            "affinityphoto": "AffinityPhoto.desktop",
            "AffinityPhoto": "AffinityPhoto.desktop",
            "AffinityPhoto.desktop": "AffinityPhoto.desktop",
            "designer.exe": "AffinityDesigner.desktop",
            "Designer.exe": "AffinityDesigner.desktop",
            "affinitydesigner": "AffinityDesigner.desktop",
            "AffinityDesigner": "AffinityDesigner.desktop",
            "AffinityDesigner.desktop": "AffinityDesigner.desktop",
            
            // Lutris variations
            "net.lutris.lutris": "lutris",
            "net.lutris.Lutris": "lutris",
            "lutris": "lutris",
            "Lutris": "lutris",
            "lutris.desktop": "lutris",
            
            // OBS variations
            "com.obsproject.Studio": "obs",
            "com.obsproject.studio": "obs",
            "com.obsproject.Studio.desktop": "obs",
            "com.obsproject.studio.desktop": "obs",
            "obs": "obs",
            "OBS": "obs",
            "obs-studio": "obs",
            "obs-studio.desktop": "obs",
            
            // Steam variations
            "steam": "steam-native",
            "steam.exe": "steam-native",
            "Steam": "steam-native",
            "Steam.exe": "steam-native",
            "steam-native": "steam-native",
            "steam-native.desktop": "steam-native",
            "com.valvesoftware.Steam": "steam-native",
            "com.valvesoftware.Steam.desktop": "steam-native",
            
            // Nautilus variations
            "nautilus": "org.gnome.Nautilus",
            "org.gnome.nautilus": "org.gnome.Nautilus",
            "org.gnome.Nautilus": "org.gnome.Nautilus",
            "org.gnome.Nautilus.desktop": "org.gnome.Nautilus",
            "files": "org.gnome.Nautilus",
            "gnome-files": "org.gnome.Nautilus",
            
            // Microsoft Edge variations
            "microsoft-edge-dev": "microsoft-edge-dev",
            "microsoft-edge": "microsoft-edge-dev",
            "microsoft-edge.desktop": "microsoft-edge-dev",
            "msedge": "microsoft-edge-dev",
            "edge": "microsoft-edge-dev",
            
            // Vesktop/Discord variations
            "vesktop": "vesktop",
            "discord": "vesktop",
            "discord.desktop": "vesktop",
            "Vesktop": "vesktop",
            "Discord": "vesktop",
            
            // Heroic variations
            "heroic": "heroic",
            "heroicgameslauncher": "heroic",
            "heroic.desktop": "heroic",
            "heroicgameslauncher.desktop": "heroic",
            "Heroic": "heroic",
            "HeroicGamesLauncher": "heroic",
            
            // Ptyxis variations
            "org.gnome.ptyxis": "ptyxis",
            "org.gnome.ptyxis.desktop": "ptyxis",
            "ptyxis": "ptyxis",
            "Ptyxis": "ptyxis",
            "ptyxis.desktop": "ptyxis",
            "Org.gnome.ptyxis": "ptyxis",
            
            // Cider variations
            "cider": "cider",
            "Cider": "cider",
            "Cider.desktop": "cider",
            "cider.desktop": "cider",
            
            // Cursor variations
            "cursor": "cursor-cursor",
            "Cursor": "cursor-cursor",
            "cursor-cursor": "cursor-cursor",
            "cursor-cursor.desktop": "cursor-cursor",
            
            // DaVinci Resolve variations
            "davinci-resolve-studio-20": "net.lutris.davinci-resolve-studio-20-1.desktop",
            "DaVinci Resolve Studio 20": "net.lutris.davinci-resolve-studio-20-1.desktop",
            "resolve": "net.lutris.davinci-resolve-studio-20-1.desktop",
            "com.blackmagicdesign.resolve": "net.lutris.davinci-resolve-studio-20-1.desktop",
            "net.lutris.davinci-resolve-studio-20-1.desktop": "net.lutris.davinci-resolve-studio-20-1.desktop"
        };
        
        // Normalize the input (case-insensitive lookup)
        var normalizedInput = appClass.toLowerCase();
        var toPin = null;
        
        // First, try exact match (case-insensitive)
        for (var key in comprehensiveMapping) {
            if (key.toLowerCase() === normalizedInput) {
                toPin = comprehensiveMapping[key];
                console.log("[PIN DEBUG] Found exact match:", key, "->", toPin);
                break;
            }
        }
        
        // If no exact match, try partial matching
        if (!toPin) {
            for (var key in comprehensiveMapping) {
                if (key.toLowerCase().includes(normalizedInput) || normalizedInput.includes(key.toLowerCase())) {
                    toPin = comprehensiveMapping[key];
                    console.log("[PIN DEBUG] Found partial match:", key, "->", toPin);
                    break;
                }
            }
        }
        
        // If still no match, use the original input
        if (!toPin) {
            toPin = appClass;
            console.log("[PIN DEBUG] No mapping found, using original:", toPin);
        }
        
        // Check if app is already pinned (case-insensitive)
        var alreadyPinned = false;
        for (var i = 0; i < pinnedApps.length; i++) {
            if (pinnedApps[i].toLowerCase() === toPin.toLowerCase()) {
                alreadyPinned = true;
                console.log("[PIN DEBUG] App already pinned:", pinnedApps[i]);
                break;
            }
        }
        
        // Also check with .desktop extension
        if (!alreadyPinned && !toPin.endsWith('.desktop')) {
            var withDesktop = toPin + '.desktop';
            for (var i = 0; i < pinnedApps.length; i++) {
                if (pinnedApps[i].toLowerCase() === withDesktop.toLowerCase()) {
                    alreadyPinned = true;
                    console.log("[PIN DEBUG] App already pinned with .desktop extension:", pinnedApps[i]);
                    break;
                }
            }
        }
        
        // Add the app if not already pinned
        if (!alreadyPinned) {
            var newPinnedApps = pinnedApps.slice();
            newPinnedApps.push(toPin);
            pinnedApps = newPinnedApps;
            console.log("[PIN DEBUG] Successfully added:", toPin);
            savePinnedApps();
            return true; // Success
        } else {
            console.log("[PIN DEBUG] App already pinned, skipping:", toPin);
            return false; // Already pinned
        }
    }
    
    // Remove an app from pinned apps - ROBUST VERSION
    function removePinnedApp(appClass) {
        console.log("[UNPIN DEBUG] removePinnedApp called with:", appClass);
        
        // Comprehensive mapping for all app variations
        var comprehensiveMapping = {
            // Affinity apps
            "photo.exe": "AffinityPhoto.desktop",
            "Photo.exe": "AffinityPhoto.desktop",
            "affinityphoto": "AffinityPhoto.desktop",
            "AffinityPhoto": "AffinityPhoto.desktop",
            "AffinityPhoto.desktop": "AffinityPhoto.desktop",
            "designer.exe": "AffinityDesigner.desktop",
            "Designer.exe": "AffinityDesigner.desktop",
            "affinitydesigner": "AffinityDesigner.desktop",
            "AffinityDesigner": "AffinityDesigner.desktop",
            "AffinityDesigner.desktop": "AffinityDesigner.desktop",
            
            // Lutris variations
            "net.lutris.lutris": "lutris",
            "net.lutris.Lutris": "lutris",
            "lutris": "lutris",
            "Lutris": "lutris",
            "lutris.desktop": "lutris",
            
            // OBS variations
            "com.obsproject.Studio": "obs",
            "com.obsproject.studio": "obs",
            "com.obsproject.Studio.desktop": "obs",
            "com.obsproject.studio.desktop": "obs",
            "obs": "obs",
            "OBS": "obs",
            "obs-studio": "obs",
            "obs-studio.desktop": "obs",
            
            // Steam variations
            "steam": "steam-native",
            "steam.exe": "steam-native",
            "Steam": "steam-native",
            "Steam.exe": "steam-native",
            "steam-native": "steam-native",
            "steam-native.desktop": "steam-native",
            "com.valvesoftware.Steam": "steam-native",
            "com.valvesoftware.Steam.desktop": "steam-native",
            
            // Nautilus variations
            "nautilus": "org.gnome.Nautilus",
            "org.gnome.nautilus": "org.gnome.Nautilus",
            "org.gnome.Nautilus": "org.gnome.Nautilus",
            "org.gnome.Nautilus.desktop": "org.gnome.Nautilus",
            "files": "org.gnome.Nautilus",
            "gnome-files": "org.gnome.Nautilus",
            
            // Microsoft Edge variations
            "microsoft-edge-dev": "microsoft-edge-dev",
            "microsoft-edge": "microsoft-edge-dev",
            "microsoft-edge.desktop": "microsoft-edge-dev",
            "msedge": "microsoft-edge-dev",
            "edge": "microsoft-edge-dev",
            
            // Vesktop/Discord variations
            "vesktop": "vesktop",
            "discord": "vesktop",
            "discord.desktop": "vesktop",
            "Vesktop": "vesktop",
            "Discord": "vesktop",
            
            // Heroic variations
            "heroic": "heroic",
            "heroicgameslauncher": "heroic",
            "heroic.desktop": "heroic",
            "heroicgameslauncher.desktop": "heroic",
            "Heroic": "heroic",
            "HeroicGamesLauncher": "heroic",
            
            // Ptyxis variations
            "org.gnome.ptyxis": "ptyxis",
            "org.gnome.ptyxis.desktop": "ptyxis",
            "ptyxis": "ptyxis",
            "Ptyxis": "ptyxis",
            "ptyxis.desktop": "ptyxis",
            "Org.gnome.ptyxis": "ptyxis",
            
            // Cider variations
            "cider": "cider",
            "Cider": "cider",
            "Cider.desktop": "cider",
            "cider.desktop": "cider",
            
            // Cursor variations
            "cursor": "cursor-cursor",
            "Cursor": "cursor-cursor",
            "cursor-cursor": "cursor-cursor",
            "cursor-cursor.desktop": "cursor-cursor",
            
            // DaVinci Resolve variations
            "davinci-resolve-studio-20": "net.lutris.davinci-resolve-studio-20-1.desktop",
            "DaVinci Resolve Studio 20": "net.lutris.davinci-resolve-studio-20-1.desktop",
            "resolve": "net.lutris.davinci-resolve-studio-20-1.desktop",
            "com.blackmagicdesign.resolve": "net.lutris.davinci-resolve-studio-20-1.desktop",
            "net.lutris.davinci-resolve-studio-20-1.desktop": "net.lutris.davinci-resolve-studio-20-1.desktop"
        };
        
        // Normalize the input (case-insensitive lookup)
        var normalizedInput = appClass.toLowerCase();
        var toRemove = null;
        
        // First, try exact match (case-insensitive)
        for (var key in comprehensiveMapping) {
            if (key.toLowerCase() === normalizedInput) {
                toRemove = comprehensiveMapping[key];
                console.log("[UNPIN DEBUG] Found exact match:", key, "->", toRemove);
                break;
            }
        }
        
        // If no exact match, try partial matching
        if (!toRemove) {
            for (var key in comprehensiveMapping) {
                if (key.toLowerCase().includes(normalizedInput) || normalizedInput.includes(key.toLowerCase())) {
                    toRemove = comprehensiveMapping[key];
                    console.log("[UNPIN DEBUG] Found partial match:", key, "->", toRemove);
                    break;
                }
            }
        }
        
        // If still no match, use the original input
        if (!toRemove) {
            toRemove = appClass;
            console.log("[UNPIN DEBUG] No mapping found, using original:", toRemove);
        }
        
        // Find the app in pinned apps (case-insensitive)
        var index = -1;
        for (var i = 0; i < pinnedApps.length; i++) {
            if (pinnedApps[i].toLowerCase() === toRemove.toLowerCase()) {
                index = i;
                console.log("[UNPIN DEBUG] Found in pinned apps at index:", index, "value:", pinnedApps[i]);
                break;
            }
        }
        
        // Also try with .desktop extension if not found
        if (index === -1 && !toRemove.endsWith('.desktop')) {
            var withDesktop = toRemove + '.desktop';
            for (var i = 0; i < pinnedApps.length; i++) {
                if (pinnedApps[i].toLowerCase() === withDesktop.toLowerCase()) {
                    index = i;
                    console.log("[UNPIN DEBUG] Found with .desktop extension at index:", index, "value:", pinnedApps[i]);
                    break;
                }
            }
        }
        
        // Remove the app if found
        if (index !== -1) {
            var newPinnedApps = pinnedApps.slice();
            var removedApp = newPinnedApps.splice(index, 1)[0];
            pinnedApps = newPinnedApps;
            console.log("[UNPIN DEBUG] Successfully removed:", removedApp);
            savePinnedApps();
            return true; // Success
        } else {
            console.log("[UNPIN DEBUG] App not found in pinned apps:", toRemove);
            console.log("[UNPIN DEBUG] Current pinned apps:", JSON.stringify(pinnedApps));
            return false; // Not found
        }
    }
    
    // Utility function to check if an app is pinned
    function isAppPinned(appClass) {
        console.log("[PIN CHECK DEBUG] isAppPinned called with:", appClass);
        
        // Use the same comprehensive mapping
        var comprehensiveMapping = {
            // Affinity apps
            "photo.exe": "AffinityPhoto.desktop",
            "Photo.exe": "AffinityPhoto.desktop",
            "affinityphoto": "AffinityPhoto.desktop",
            "AffinityPhoto": "AffinityPhoto.desktop",
            "AffinityPhoto.desktop": "AffinityPhoto.desktop",
            "designer.exe": "AffinityDesigner.desktop",
            "Designer.exe": "AffinityDesigner.desktop",
            "affinitydesigner": "AffinityDesigner.desktop",
            "AffinityDesigner": "AffinityDesigner.desktop",
            "AffinityDesigner.desktop": "AffinityDesigner.desktop",
            
            // Lutris variations
            "net.lutris.lutris": "lutris",
            "net.lutris.Lutris": "lutris",
            "lutris": "lutris",
            "Lutris": "lutris",
            "lutris.desktop": "lutris",
            
            // OBS variations
            "com.obsproject.Studio": "obs",
            "com.obsproject.studio": "obs",
            "com.obsproject.Studio.desktop": "obs",
            "com.obsproject.studio.desktop": "obs",
            "obs": "obs",
            "OBS": "obs",
            "obs-studio": "obs",
            "obs-studio.desktop": "obs",
            
            // Steam variations
            "steam": "steam-native",
            "steam.exe": "steam-native",
            "Steam": "steam-native",
            "Steam.exe": "steam-native",
            "steam-native": "steam-native",
            "steam-native.desktop": "steam-native",
            "com.valvesoftware.Steam": "steam-native",
            "com.valvesoftware.Steam.desktop": "steam-native",
            
            // Nautilus variations
            "nautilus": "org.gnome.Nautilus",
            "org.gnome.nautilus": "org.gnome.Nautilus",
            "org.gnome.Nautilus": "org.gnome.Nautilus",
            "org.gnome.Nautilus.desktop": "org.gnome.Nautilus",
            "files": "org.gnome.Nautilus",
            "gnome-files": "org.gnome.Nautilus",
            
            // Microsoft Edge variations
            "microsoft-edge-dev": "microsoft-edge-dev",
            "microsoft-edge": "microsoft-edge-dev",
            "microsoft-edge.desktop": "microsoft-edge-dev",
            "msedge": "microsoft-edge-dev",
            "edge": "microsoft-edge-dev",
            
            // Vesktop/Discord variations
            "vesktop": "vesktop",
            "discord": "vesktop",
            "discord.desktop": "vesktop",
            "Vesktop": "vesktop",
            "Discord": "vesktop",
            
            // Heroic variations
            "heroic": "heroic",
            "heroicgameslauncher": "heroic",
            "heroic.desktop": "heroic",
            "heroicgameslauncher.desktop": "heroic",
            "Heroic": "heroic",
            "HeroicGamesLauncher": "heroic",
            
            // Ptyxis variations
            "org.gnome.ptyxis": "ptyxis",
            "org.gnome.ptyxis.desktop": "ptyxis",
            "ptyxis": "ptyxis",
            "Ptyxis": "ptyxis",
            "ptyxis.desktop": "ptyxis",
            "Org.gnome.ptyxis": "ptyxis",
            
            // Cider variations
            "cider": "cider",
            "Cider": "cider",
            "Cider.desktop": "cider",
            "cider.desktop": "cider",
            
            // Cursor variations
            "cursor": "cursor-cursor",
            "Cursor": "cursor-cursor",
            "cursor-cursor": "cursor-cursor",
            "cursor-cursor.desktop": "cursor-cursor",
            
            // DaVinci Resolve variations
            "davinci-resolve-studio-20": "net.lutris.davinci-resolve-studio-20-1.desktop",
            "DaVinci Resolve Studio 20": "net.lutris.davinci-resolve-studio-20-1.desktop",
            "resolve": "net.lutris.davinci-resolve-studio-20-1.desktop",
            "com.blackmagicdesign.resolve": "net.lutris.davinci-resolve-studio-20-1.desktop",
            "net.lutris.davinci-resolve-studio-20-1.desktop": "net.lutris.davinci-resolve-studio-20-1.desktop"
        };
        
        // Normalize the input (case-insensitive lookup)
        var normalizedInput = appClass.toLowerCase();
        var normalizedApp = null;
        
        // First, try exact match (case-insensitive)
        for (var key in comprehensiveMapping) {
            if (key.toLowerCase() === normalizedInput) {
                normalizedApp = comprehensiveMapping[key];
                console.log("[PIN CHECK DEBUG] Found exact match:", key, "->", normalizedApp);
                break;
            }
        }
        
        // If no exact match, try partial matching
        if (!normalizedApp) {
            for (var key in comprehensiveMapping) {
                if (key.toLowerCase().includes(normalizedInput) || normalizedInput.includes(key.toLowerCase())) {
                    normalizedApp = comprehensiveMapping[key];
                    console.log("[PIN CHECK DEBUG] Found partial match:", key, "->", normalizedApp);
                    break;
                }
            }
        }
        
        // If still no match, use the original input
        if (!normalizedApp) {
            normalizedApp = appClass;
            console.log("[PIN CHECK DEBUG] No mapping found, using original:", normalizedApp);
        }
        
        // Check if app is pinned (case-insensitive)
        for (var i = 0; i < pinnedApps.length; i++) {
            if (pinnedApps[i].toLowerCase() === normalizedApp.toLowerCase()) {
                console.log("[PIN CHECK DEBUG] App is pinned:", pinnedApps[i]);
                return true;
            }
        }
        
        // Also check with .desktop extension
        if (!normalizedApp.endsWith('.desktop')) {
            var withDesktop = normalizedApp + '.desktop';
            for (var i = 0; i < pinnedApps.length; i++) {
                if (pinnedApps[i].toLowerCase() === withDesktop.toLowerCase()) {
                    console.log("[PIN CHECK DEBUG] App is pinned with .desktop extension:", pinnedApps[i]);
                    return true;
                }
            }
        }
        
        console.log("[PIN CHECK DEBUG] App is not pinned:", normalizedApp);
        return false;
    }
    
    // Utility function to get canonical app name
    function getCanonicalAppName(appClass) {
        console.log("[CANONICAL DEBUG] getCanonicalAppName called with:", appClass);
        
        // Use the same comprehensive mapping
        var comprehensiveMapping = {
            // Affinity apps
            "photo.exe": "AffinityPhoto.desktop",
            "Photo.exe": "AffinityPhoto.desktop",
            "affinityphoto": "AffinityPhoto.desktop",
            "AffinityPhoto": "AffinityPhoto.desktop",
            "AffinityPhoto.desktop": "AffinityPhoto.desktop",
            "designer.exe": "AffinityDesigner.desktop",
            "Designer.exe": "AffinityDesigner.desktop",
            "affinitydesigner": "AffinityDesigner.desktop",
            "AffinityDesigner": "AffinityDesigner.desktop",
            "AffinityDesigner.desktop": "AffinityDesigner.desktop",
            
            // Lutris variations
            "net.lutris.lutris": "lutris",
            "net.lutris.Lutris": "lutris",
            "lutris": "lutris",
            "Lutris": "lutris",
            "lutris.desktop": "lutris",
            
            // OBS variations
            "com.obsproject.Studio": "obs",
            "com.obsproject.studio": "obs",
            "com.obsproject.Studio.desktop": "obs",
            "com.obsproject.studio.desktop": "obs",
            "obs": "obs",
            "OBS": "obs",
            "obs-studio": "obs",
            "obs-studio.desktop": "obs",
            
            // Steam variations
            "steam": "steam-native",
            "steam.exe": "steam-native",
            "Steam": "steam-native",
            "Steam.exe": "steam-native",
            "steam-native": "steam-native",
            "steam-native.desktop": "steam-native",
            "com.valvesoftware.Steam": "steam-native",
            "com.valvesoftware.Steam.desktop": "steam-native",
            
            // Nautilus variations
            "nautilus": "org.gnome.Nautilus",
            "org.gnome.nautilus": "org.gnome.Nautilus",
            "org.gnome.Nautilus": "org.gnome.Nautilus",
            "org.gnome.Nautilus.desktop": "org.gnome.Nautilus",
            "files": "org.gnome.Nautilus",
            "gnome-files": "org.gnome.Nautilus",
            
            // Microsoft Edge variations
            "microsoft-edge-dev": "microsoft-edge-dev",
            "microsoft-edge": "microsoft-edge-dev",
            "microsoft-edge.desktop": "microsoft-edge-dev",
            "msedge": "microsoft-edge-dev",
            "edge": "microsoft-edge-dev",
            
            // Vesktop/Discord variations
            "vesktop": "vesktop",
            "discord": "vesktop",
            "discord.desktop": "vesktop",
            "Vesktop": "vesktop",
            "Discord": "vesktop",
            
            // Heroic variations
            "heroic": "heroic",
            "heroicgameslauncher": "heroic",
            "heroic.desktop": "heroic",
            "heroicgameslauncher.desktop": "heroic",
            "Heroic": "heroic",
            "HeroicGamesLauncher": "heroic",
            
            // Ptyxis variations
            "org.gnome.ptyxis": "ptyxis",
            "org.gnome.ptyxis.desktop": "ptyxis",
            "ptyxis": "ptyxis",
            "Ptyxis": "ptyxis",
            "ptyxis.desktop": "ptyxis",
            "Org.gnome.ptyxis": "ptyxis",
            
            // Cider variations
            "cider": "cider",
            "Cider": "cider",
            "Cider.desktop": "cider",
            "cider.desktop": "cider",
            
            // Cursor variations
            "cursor": "cursor-cursor",
            "Cursor": "cursor-cursor",
            "cursor-cursor": "cursor-cursor",
            "cursor-cursor.desktop": "cursor-cursor",
            
            // DaVinci Resolve variations
            "davinci-resolve-studio-20": "net.lutris.davinci-resolve-studio-20-1.desktop",
            "DaVinci Resolve Studio 20": "net.lutris.davinci-resolve-studio-20-1.desktop",
            "resolve": "net.lutris.davinci-resolve-studio-20-1.desktop",
            "com.blackmagicdesign.resolve": "net.lutris.davinci-resolve-studio-20-1.desktop",
            "net.lutris.davinci-resolve-studio-20-1.desktop": "net.lutris.davinci-resolve-studio-20-1.desktop"
        };
        
        // Normalize the input (case-insensitive lookup)
        var normalizedInput = appClass.toLowerCase();
        var canonicalName = null;
        
        // First, try exact match (case-insensitive)
        for (var key in comprehensiveMapping) {
            if (key.toLowerCase() === normalizedInput) {
                canonicalName = comprehensiveMapping[key];
                console.log("[CANONICAL DEBUG] Found exact match:", key, "->", canonicalName);
                break;
            }
        }
        
        // If no exact match, try partial matching
        if (!canonicalName) {
            for (var key in comprehensiveMapping) {
                if (key.toLowerCase().includes(normalizedInput) || normalizedInput.includes(key.toLowerCase())) {
                    canonicalName = comprehensiveMapping[key];
                    console.log("[CANONICAL DEBUG] Found partial match:", key, "->", canonicalName);
                    break;
                }
            }
        }
        
        // If still no match, use the original input
        if (!canonicalName) {
            canonicalName = appClass;
            console.log("[CANONICAL DEBUG] No mapping found, using original:", canonicalName);
        }
        
        console.log("[CANONICAL DEBUG] Returning canonical name:", canonicalName);
        return canonicalName;
    }
    
    // Universal app launching function
    function launchApp(appIdentifier) {
        // Write to file to test if function is called
        Hyprland.dispatch(`exec echo "$(date): ===== STARTING APP LAUNCH =====" >> /tmp/dock_debug.log`);
        Hyprland.dispatch(`exec echo "$(date): Launching app: ${appIdentifier}" >> /tmp/dock_debug.log`);
        
        // STEP 1: Handle Affinity apps - use direct Wine commands (keep existing special handling)
        if (appIdentifier.toLowerCase().includes("affinity") || appIdentifier.toLowerCase().includes("photo") || appIdentifier.toLowerCase().includes("designer")) {
            Hyprland.dispatch(`exec echo "$(date): === STEP 1: Affinity app detection ===" >> /tmp/dock_debug.log`);
            
            // Handle specific Affinity app names - use direct Wine commands (check these first)
            if (appIdentifier === "AffinityPhoto" || appIdentifier === "AffinityPhoto.desktop") {
                let cmd = `exec env WINEPREFIX=/home/matt/.AffinityLinux /home/matt/.AffinityLinux/ElementalWarriorWine/bin/wine "/home/matt/.AffinityLinux/drive_c/Program Files/Affinity/Photo 2/Photo.exe"`;
                Hyprland.dispatch(`exec echo "$(date): Dispatching: ${cmd}" >> /tmp/dock_debug.log`);
                Hyprland.dispatch(cmd);
                return;
            }
            
            if (appIdentifier === "AffinityDesigner" || appIdentifier === "AffinityDesigner.desktop") {
                let cmd = `exec env WINEPREFIX=/home/matt/.AffinityLinux /home/matt/.AffinityLinux/ElementalWarriorWine/bin/wine "/home/matt/.AffinityLinux/drive_c/Program Files/Affinity/Designer 2/Designer.exe"`;
                Hyprland.dispatch(`exec echo "$(date): Dispatching: ${cmd}" >> /tmp/dock_debug.log`);
                Hyprland.dispatch(cmd);
                return;
            }
            
            // Try to find Affinity desktop files in DesktopEntries
            let affinityEntries = [];
            for (let k in DesktopEntries.applications) {
                let e = DesktopEntries.applications[k];
                if (e && (k.toLowerCase().includes('affinity') || (e.name && e.name.toLowerCase().includes('affinity')))) {
                    affinityEntries.push(k);
                }
            }
            Hyprland.dispatch(`exec echo "$(date): Found Affinity entries: ${affinityEntries.join(', ')}" >> /tmp/dock_debug.log`);
            
            // Try to execute the first matching Affinity entry
            for (let entryKey of affinityEntries) {
                let entry = DesktopEntries.applications[entryKey];
            if (entry && entry.execute) {
                    Hyprland.dispatch(`exec echo "$(date): SUCCESS: Using DesktopEntries.execute() for: ${entryKey}" >> /tmp/dock_debug.log`);
                    try {
                entry.execute();
                        Hyprland.dispatch(`exec echo "$(date): Execute() called successfully" >> /tmp/dock_debug.log`);
                return;
                    } catch (e) {
                        Hyprland.dispatch(`exec echo "$(date): ERROR in execute(): ${e}" >> /tmp/dock_debug.log`);
                    }
                }
            }
            
            // If no desktop entry found, try gio launch with common Affinity names
            let affinityNames = ['AffinityPhoto', 'AffinityDesigner', 'AffinityPublisher'];
            for (let name of affinityNames) {
                let cmd = `exec gio launch ${name}`;
                Hyprland.dispatch(`exec echo "$(date): Dispatching: ${cmd}" >> /tmp/dock_debug.log`);
                Hyprland.dispatch(cmd);
                return;
            }
        }

        // STEP 2: Try DesktopEntries first (most reliable for desktop files)
        Hyprland.dispatch(`exec echo "$(date): === STEP 2: DesktopEntries ===" >> /tmp/dock_debug.log`);
        let entry = DesktopEntries.applications[appIdentifier];
        if (entry && entry.execute) {
                Hyprland.dispatch(`exec echo "$(date): SUCCESS: Using DesktopEntries.execute() for: ${appIdentifier}" >> /tmp/dock_debug.log`);
                try {
                    entry.execute();
                    Hyprland.dispatch(`exec echo "$(date): Execute() called successfully" >> /tmp/dock_debug.log`);
                return;
                } catch (e) {
                    Hyprland.dispatch(`exec echo "$(date): ERROR in execute(): ${e}" >> /tmp/dock_debug.log`);
            }
        }

        // STEP 3: Try DesktopEntries with .desktop extension
        if (!appIdentifier.endsWith('.desktop')) {
            let desktopId = appIdentifier + '.desktop';
        let entry2 = DesktopEntries.applications[desktopId];
            if (entry2 && entry2.execute) {
                Hyprland.dispatch(`exec echo "$(date): SUCCESS: Using DesktopEntries.execute() for: ${desktopId}" >> /tmp/dock_debug.log`);
                try {
                    entry2.execute();
                    Hyprland.dispatch(`exec echo "$(date): Execute() called successfully" >> /tmp/dock_debug.log`);
            return;
                } catch (e) {
                    Hyprland.dispatch(`exec echo "$(date): ERROR in execute(): ${e}" >> /tmp/dock_debug.log`);
                }
            }
        }

        // STEP 4: Try common app-specific fallbacks
        Hyprland.dispatch(`exec echo "$(date): === STEP 4: App-specific fallbacks ===" >> /tmp/dock_debug.log`);
        
        // Common app name mappings for fallback
        let appFallbacks = {
            'obs': ['com.obsproject.Studio', 'com.obsproject.Studio.desktop', 'obs-studio'],
            'lutris': ['net.lutris.lutris', 'net.lutris.lutris.desktop'],
            'steam': ['steam-native', 'steam-native.desktop', 'com.valvesoftware.Steam'],
            'nautilus': ['org.gnome.Nautilus', 'org.gnome.Nautilus.desktop', 'files'],
            'microsoft-edge-dev': ['microsoft-edge', 'microsoft-edge.desktop'],
            'vesktop': ['discord', 'discord.desktop'],
            'heroic': ['heroicgameslauncher', 'heroicgameslauncher.desktop'],
            'ptyxis': ['org.gnome.ptyxis', 'org.gnome.ptyxis.desktop'],
            'cider': ['Cider', 'Cider.desktop']
        };
        
        // Try fallback names for the current app
        if (appFallbacks[appIdentifier]) {
            for (let fallback of appFallbacks[appIdentifier]) {
                let fallbackCmd = `exec gio launch ${fallback}`;
                Hyprland.dispatch(`exec echo "$(date): Trying app-specific fallback: ${fallbackCmd}" >> /tmp/dock_debug.log`);
                Hyprland.dispatch(fallbackCmd);
            }
        }

        // STEP 5: Try different launcher strategies based on app type
        Hyprland.dispatch(`exec echo "$(date): === STEP 5: Launcher strategies ===" >> /tmp/dock_debug.log`);
        
        // For .desktop files, try gio first, then gtk-launch
        if (appIdentifier.endsWith('.desktop')) {
            // Try gio launch first
            let gioCmd = `exec gio launch ${appIdentifier}`;
            Hyprland.dispatch(`exec echo "$(date): Trying gio launch: ${gioCmd}" >> /tmp/dock_debug.log`);
            Hyprland.dispatch(gioCmd);
            
            // Try gtk-launch as fallback
            let gtkCmd = `exec gtk-launch ${appIdentifier}`;
            Hyprland.dispatch(`exec echo "$(date): Trying gtk-launch fallback: ${gtkCmd}" >> /tmp/dock_debug.log`);
            Hyprland.dispatch(gtkCmd);
            
            // Try with full path as additional fallback
            let desktopPath = `~/.local/share/applications/${appIdentifier}`;
            let pathCmd = `exec gio launch "${desktopPath}"`;
            Hyprland.dispatch(`exec echo "$(date): Trying full path fallback: ${pathCmd}" >> /tmp/dock_debug.log`);
            Hyprland.dispatch(pathCmd);
        } else {
            // For non-desktop files, try gio first, then direct command
            let gioCmd = `exec gio launch ${appIdentifier}`;
            Hyprland.dispatch(`exec echo "$(date): Trying gio launch: ${gioCmd}" >> /tmp/dock_debug.log`);
            Hyprland.dispatch(gioCmd);
            
            // Try direct command execution as fallback
            let directCmd = `exec ${appIdentifier}`;
            Hyprland.dispatch(`exec echo "$(date): Trying direct command fallback: ${directCmd}" >> /tmp/dock_debug.log`);
            Hyprland.dispatch(directCmd);
            
            // Try with .desktop extension as additional fallback
            let desktopCmd = `exec gio launch ${appIdentifier}.desktop`;
            Hyprland.dispatch(`exec echo "$(date): Trying .desktop extension fallback: ${desktopCmd}" >> /tmp/dock_debug.log`);
            Hyprland.dispatch(desktopCmd);
        }

        // STEP 6: Try comprehensive system fallbacks
        Hyprland.dispatch(`exec echo "$(date): === STEP 6: System fallbacks ===" >> /tmp/dock_debug.log`);
        
        // Try to find the app in system PATH and launch it
        let whichCmd = `exec which ${appIdentifier} && exec ${appIdentifier}`;
        Hyprland.dispatch(`exec echo "$(date): Trying system PATH fallback: ${whichCmd}" >> /tmp/dock_debug.log`);
        Hyprland.dispatch(whichCmd);

        // FINAL: Log failure
        Hyprland.dispatch(`exec echo "$(date): FAILED TO LAUNCH: ${appIdentifier}" >> /tmp/dock_debug.log`);
    }
    
    // Universal function to find a window for a given app
    function findWindowForApp(appIdentifier) {
        // Normalize appIdentifier for special cases
        var normalizedIdentifier = appIdentifier;
        if (appIdentifier === "lutris" || appIdentifier === "net.lutris.lutris" || 
            appIdentifier === "net.lutris.Lutris" || appIdentifier === "Lutris") {
            normalizedIdentifier = "lutris";
        }
        if (appIdentifier === "obs" || appIdentifier === "com.obsproject.Studio" || 
            appIdentifier === "com.obsproject.studio" || appIdentifier === "OBS") {
            normalizedIdentifier = "obs";
        }
        if (appIdentifier === "steam" || appIdentifier === "steam.exe" || 
            appIdentifier === "Steam" || appIdentifier === "Steam.exe") {
            normalizedIdentifier = "steam-native";
        }
        if (appIdentifier === "ptyxis" || appIdentifier === "org.gnome.ptyxis" || 
            appIdentifier === "Ptyxis" || appIdentifier === "Org.gnome.ptyxis") {
            normalizedIdentifier = "ptyxis";
        }
        
        // Build mapping for .desktop files to possible window classes
        var mapping = {
            'AffinityPhoto.desktop': ['photo.exe', 'Photo.exe', 'affinityphoto', 'AffinityPhoto'],
            'AffinityDesigner.desktop': ['designer.exe', 'Designer.exe', 'affinitydesigner', 'AffinityDesigner'],
            'microsoft-edge-dev': ['microsoft-edge-dev', 'msedge', 'edge'],
            'vesktop': ['vesktop', 'discord'],
            'steam-native': ['steam', 'steam.exe', 'Steam', 'Steam.exe'],
            'org.gnome.Nautilus': ['nautilus', 'org.gnome.nautilus'],
            'org.gnome.nautilus': ['nautilus', 'org.gnome.nautilus'],
            'lutris': ['lutris', 'net.lutris.lutris'],
            'heroic': ['heroic', 'heroicgameslauncher'],
            'obs': ['obs', 'com.obsproject.studio'],
            'com.obsproject.Studio.desktop': ['obs', 'com.obsproject.studio'],
            'cursor-cursor': ['cursor', 'Cursor'],
            'ptyxis': ['ptyxis', 'org.gnome.ptyxis'],
            'net.lutris.davinci-resolve-studio-20-1.desktop': ['davinci-resolve-studio-20', 'DaVinci Resolve Studio 20', 'resolve', 'com.blackmagicdesign.resolve']
        };
        
        // Build list of possible window classes for this app
        var possibleClasses = [normalizedIdentifier.toLowerCase()];
        if (mapping[normalizedIdentifier]) {
            possibleClasses = possibleClasses.concat(mapping[normalizedIdentifier].map(c => c.toLowerCase()));
        }
        
        // Find the window for this app across all monitors/workspaces
        return HyprlandData.windowList.find(w => 
            possibleClasses.includes(w.class.toLowerCase()) ||
            possibleClasses.includes(w.initialClass.toLowerCase())
        );
    }
    
    // Reorder pinned apps (for drag and drop)
    function reorderPinnedApp(fromIndex, toIndex) {
        // console.log("reorderPinnedApp called with fromIndex:", fromIndex, "toIndex:", toIndex)
        // console.log("Current pinnedApps:", JSON.stringify(pinnedApps))
        
        if (fromIndex === toIndex || fromIndex < 0 || toIndex < 0 || 
            fromIndex >= pinnedApps.length || toIndex >= pinnedApps.length) {
            // console.log("Invalid indices, aborting reorder")
            return
        }
        
        var newPinnedApps = pinnedApps.slice()
        var item = newPinnedApps.splice(fromIndex, 1)[0]
        newPinnedApps.splice(toIndex, 0, item)
        pinnedApps = newPinnedApps
        
        // console.log("New pinnedApps:", JSON.stringify(pinnedApps))
        savePinnedApps()
        // Initialize icon theme system
        IconTheme.initializeIconTheme(StandardPaths.writableLocation(StandardPaths.HomeLocation));
        
        // Auto-hide is now managed by ConfigOptions.dock.autoHide
        // pinnedOnStartup behavior is handled in the settings UI
        
        // Auto-hide initialization is now handled in PanelWindow.onCompleted
// console.log("[DOCK DEBUG] Component completed, autoHide value:", autoHide)
        
        // Debug: Show what's in pinnedApps
    }
    
    function showMenuForApp(appInfo) {
        menuAppInfo = appInfo
        showDockMenu = true
    }
    
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: dockRoot
            margins {
                top: 0
                bottom: 0
                left: 0
                right: 0
            }
            property ShellScreen modelData
            
            screen: modelData
            WlrLayershell.namespace: "quickshell:dock:blur"
            implicitHeight: dockHeight
            implicitWidth: dockContainer.implicitWidth
            color: "transparent"
            
            // Reveal logic based on end-4's approach - moved inside PanelWindow
            property bool reveal: !dock.autoHide || dockMouseArea.containsMouse
            
            onRevealChanged: {
// console.log("[DOCK DEBUG] Reveal changed to:", reveal, "autoHide:", dock.autoHide, "dockMouseArea.containsMouse:", dockMouseArea.containsMouse)
            }

            // Basic configuration
            WlrLayershell.layer: WlrLayer.Top
            exclusiveZone: dock.autoHide ? 0 : dockHeight
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            
            onExclusiveZoneChanged: {
// console.log("[DOCK DEBUG] Exclusive zone changed to:", exclusiveZone, "autoHide:", dock.autoHide, "implicitHeight:", implicitHeight)
            }



            // Track active windows
            // property var activeWindows: [] // This line is removed
            
            // Helper function for controlled logging
            function log(level, message) {
                if (!ConfigOptions?.logging?.enabled) return
                if (level === "debug" && !ConfigOptions?.logging?.debug) return
                if (level === "info" && !ConfigOptions?.logging?.info) return
                if (level === "warning" && !ConfigOptions?.logging?.warning) return
                if (level === "error" && !ConfigOptions?.logging?.error) return
                // console.log(`[Dock][${level.toUpperCase()}] ${message}`)
            }
            
            // Update when window list changes
            Connections {
                target: HyprlandData
                function onWindowListChanged() { 
                    // log("debug", "Window list changed, updating active windows")
                    updateActiveWindows() 
                }
            }
            
            Component.onCompleted: {
                // log("info", "Dock component completed, initializing...")
                updateActiveWindows()
            }
            
            function updateActiveWindows() {
                // Show apps from ALL monitors/workspaces instead of filtering by current monitor
                const windows = HyprlandData.windowList.filter((window, idx, arr) => {
                    // log("debug", `[FILTER] Checking window: class='${window.class}', title='${window.title}'`);
                    // Skip windows without a valid class
                    if (!window.class || window.class.trim() === '') {
                        // log("debug", `[FILTER] Excluded: missing or empty class`);
                        return false;
                    }
                    // Skip windows with very short class names that might be temporary/placeholder
                    if (window.class.length < 2) {
                        // log("debug", `[FILTER] Excluded: class too short`);
                        return false;
                    }
                    // Skip windows with generic class names that don't represent real apps
                    const genericClasses = ['window', 'x11', 'xwayland', 'wayland', 'unknown', 'null', 'undefined'];
                    if (genericClasses.includes(window.class.toLowerCase())) {
                        // log("debug", `[FILTER] Excluded: generic class '${window.class}'`);
                        return false;
                    }
                    // Skip windows that don't have a proper title (optional additional check)
                    if (!window.title || window.title.trim() === '') {
                        // log("debug", `[FILTER] Excluded: missing or empty title`);
                        return false;
                    }
                    // Icon resolution is now handled in DockItem.qml, so we don't need to filter by icon here
                    // log("debug", `[FILTER] Included: valid window`);
                    return true;
                })
                
                if (JSON.stringify(windows) !== JSON.stringify(dock.activeWindows)) {
                    // log("debug", `Updating active windows: ${windows.length} windows found`)
                    // log("debug", `Window list: ${JSON.stringify(windows.map(w => w.class))}`)
                    dock.activeWindows = windows
                }
            }
            

            
            function isWindowActive(windowClass) {
                // Normalize windowClass for special cases
                var normalizedWindowClass = windowClass;
                if (windowClass === "lutris" || windowClass === "net.lutris.lutris" || 
                    windowClass === "net.lutris.Lutris" || windowClass === "Lutris") {
                    normalizedWindowClass = "lutris";
                }
                if (windowClass === "obs" || windowClass === "com.obsproject.Studio" || 
                    windowClass === "com.obsproject.studio" || windowClass === "OBS") {
                    normalizedWindowClass = "obs";
                }
                
                // Map .desktop files to possible window classes and vice versa
                var mapping = {
                    'AffinityPhoto.desktop': ['photo.exe', 'Photo.exe', 'affinityphoto', 'AffinityPhoto'],
                    'AffinityDesigner.desktop': ['designer.exe', 'Designer.exe', 'affinitydesigner', 'AffinityDesigner'],
                        'microsoft-edge-dev': ['microsoft-edge-dev', 'msedge', 'edge'],
                        'vesktop': ['vesktop', 'discord'],
                        'steam-native': ['steam', 'steam.exe', 'Steam', 'Steam.exe'],
                        'org.gnome.nautilus': ['nautilus', 'org.gnome.nautilus'],
                        'lutris': ['lutris', 'net.lutris.lutris'],
                        'heroic': ['heroic', 'heroicgameslauncher'],
                        'obs': ['obs', 'com.obsproject.studio'],
                        'com.obsproject.Studio.desktop': ['obs', 'com.obsproject.studio'],
                        'cursor-cursor': ['cursor', 'Cursor'],
                        'ptyxis': ['ptyxis', 'org.gnome.ptyxis'],
                        'net.lutris.davinci-resolve-studio-20-1.desktop': ['davinci-resolve-studio-20', 'DaVinci Resolve Studio 20', 'resolve', 'com.blackmagicdesign.resolve'],
                        'Cider.desktop': ['cider', 'Cider', 'Cider.exe']
                    };
                var targetClass = normalizedWindowClass.toLowerCase();
                var possibleClasses = [targetClass];
                // If the pinned app is a .desktop file and has a mapping, add those classes
                if (mapping[normalizedWindowClass]) {
                    possibleClasses = possibleClasses.concat(mapping[normalizedWindowClass].map(c => c.toLowerCase()));
                }
                // If the pinned app is a window class and is mapped from a .desktop, add that .desktop
                for (var key in mapping) {
                    if (mapping[key].map(c => c.toLowerCase()).includes(targetClass)) {
                        possibleClasses.push(key.toLowerCase());
                    }
                }
                // log("debug", `[ISWINDOWACTIVE] Checking ${normalizedWindowClass}, possible classes: ${JSON.stringify(possibleClasses)}`);
                // log("debug", `[ISWINDOWACTIVE] Active windows: ${JSON.stringify(dock.activeWindows.map(w => w.class))}`);
                var result = dock.activeWindows.some(w => possibleClasses.includes(w.class.toLowerCase()));
                // log("debug", `[ISWINDOWACTIVE] Result for ${normalizedWindowClass}: ${result}`);
                return result;
            }
            
            function focusOrLaunchApp(appInfo) {
                // log("debug", `[FOCUSORLAUNCH] Called with appInfo: ${JSON.stringify(appInfo)}`);
                var isActive = isWindowActive(appInfo.class);
                // log("debug", `[FOCUSORLAUNCH] isWindowActive(${appInfo.class}) = ${isActive}`);
                if (isActive) {
                    // log("debug", `[FOCUSORLAUNCH] Focusing window class: ${appInfo.class}`);
                    Hyprland.dispatch(`focuswindow class:${appInfo.class}`)
                } else {
                    // log("debug", `[FOCUSORLAUNCH] Launching new instance`);
                    dock.launchApp(appInfo.class);
                }
            }

            anchors.left: true
            anchors.right: true
            anchors.bottom: true

            MouseArea {
                id: dockMouseArea
                anchors.top: parent.top
                height: parent.height
                anchors.topMargin: {
                    var margin = dockRoot.reveal ? 0 : 
                        dock.autoHide ? (dockRoot.implicitHeight - dock.approachRegionHeight) :
                        (dockRoot.implicitHeight + 1)
// console.log("[DOCK DEBUG] topMargin calculated:", margin, "reveal:", dockRoot.reveal, "autoHide:", dock.autoHide, "implicitHeight:", dockRoot.implicitHeight, "approachRegionHeight:", dock.approachRegionHeight)
                    return margin
                }
                    
                anchors.left: parent.left
                anchors.right: parent.right
                hoverEnabled: true

                onEntered: {
// console.log("[DOCK DEBUG] Mouse area entered, autoHide:", dock.autoHide, "reveal:", dockRoot.reveal)
                }
                
                onExited: {
// console.log("[DOCK DEBUG] Mouse area exited, autoHide:", dock.autoHide, "reveal:", dockRoot.reveal)
                }

                Behavior on anchors.topMargin {
                    NumberAnimation {
                        duration: animationDuration
                        easing.type: Easing.OutCubic
                    }
                }
                


                Item {
                    id: dockContainer
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    implicitWidth: dockItemsLayout.width + 8
                    height: dockHeight

                    Rectangle {
                        id: dockContent
                        width: parent.width
                        height: parent.height
                        anchors.centerIn: parent
                        radius: ConfigOptions.dock.radius
                        color: Qt.rgba(
                            Appearance.colors.colLayer0.r,
                            Appearance.colors.colLayer0.g,
                            Appearance.colors.colLayer0.b,
                            1 - ConfigOptions.dock.transparency
                        )



                        // Enable layer for effects
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            source: dockContent
                            shadowEnabled: true
                            shadowColor: Qt.rgba(0, 0, 0, 0.3)
                            shadowVerticalOffset: 4
                            shadowHorizontalOffset: 0
                            shadowBlur: 12
                            blurEnabled: true
                            blurMultiplier: 0.7
                            blurMax: 64
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Appearance.animation.elementMoveFast.duration
                                easing.type: Appearance.animation.elementMoveFast.type
                            }
                        }

                        // Smooth border - matching sidebar style
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: Qt.rgba(
                                Qt.color(ConfigOptions.dock.borderColor || "#ffffff").r,
                                Qt.color(ConfigOptions.dock.borderColor || "#ffffff").g,
                                Qt.color(ConfigOptions.dock.borderColor || "#ffffff").b,
                                ConfigOptions.dock.borderOpacity || 0.15
                            )
                            border.width: 1
                            radius: parent.radius
                            antialiasing: true
                        }
                        
                        // Inner highlight for smooth depth
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            color: "transparent"
                            border.color: Qt.rgba(
                                Qt.color(ConfigOptions.dock.innerBorderColor || "#ffffff").r,
                                Qt.color(ConfigOptions.dock.innerBorderColor || "#ffffff").g,
                                Qt.color(ConfigOptions.dock.innerBorderColor || "#ffffff").b,
                                ConfigOptions.dock.innerBorderOpacity || 0.05
                            )
                            border.width: 1
                            radius: parent.radius - 1
                            antialiasing: true
                        }

                        // Main dock layout
                        GridLayout {
                            id: dockItemsLayout
                            anchors.centerIn: dockContent
                            rowSpacing: 0
                            columnSpacing: dock.dockSpacing
                            flow: GridLayout.LeftToRight
                            columns: -1
                            rows: 1

                            // Arch menu button (replacing the pin/unpin button)
                            Item {
                                Layout.preferredWidth: dock.dockWidth - 6
                                Layout.preferredHeight: dock.dockWidth - 6
                                Layout.leftMargin: dock.dockSpacing // Use configurable spacing
                                antialiasing: true
                                Rectangle {
                                    id: archButton
                                    anchors.fill: parent
                                    radius: Appearance.rounding.full
                                    color: archMouseArea.pressed ? Appearance.colors.colLayer1Active : 
                                           archMouseArea.containsMouse ? Appearance.colors.colLayer1Hover : 
                                           "transparent"
                                    
                                    Behavior on color {
                                        ColorAnimation { 
                                            duration: Appearance.animation.elementMoveFast.duration
                                            easing.type: Appearance.animation.elementMoveFast.type
                                        }
                                    }
                                    
                                    // Arch Linux logo
                                    Item {
                                        anchors.centerIn: parent
                                        width: parent.width * 0.75
                                        height: parent.height * 0.75
                                        
                                        Image {
                                            id: dockLogo
                                            anchors.fill: parent
                                            source: "root:/assets/icons/" + (ConfigOptions.appearance.logo || "distro-nobara-symbolic.svg")
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        antialiasing: true
                                        sourceSize.width: parent.width * 0.75
                                        sourceSize.height: parent.height * 0.75
                                        layer.enabled: true
                                        layer.smooth: true
                                        }
                                        
                                        ColorOverlay {
                                            anchors.fill: dockLogo
                                            source: dockLogo
                                            color: ConfigOptions.appearance.logoColor || "#ffffff"
                                        }
                                    }
                                    
                                    MouseArea {
                                        id: archMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        
                                        onClicked: {
                                            GlobalStates.hyprMenuOpen = !GlobalStates.hyprMenuOpen
                                        }
                                    }
                                }
                            }
                            
                            // Pinned apps
                            Repeater {
                                id: pinnedAppsRepeater
                                model: {
                                    // console.log("[DOCK DEBUG] Repeater model - pinnedApps:", JSON.stringify(dock.pinnedApps))
                                    return dock.pinnedApps
                                }
                                
                                DockItem {
                                    property var parentRepeater: pinnedAppsRepeater  // Add reference to the repeater
                                    appData: {
                                        var pinnedId = modelData;
                                        var lowerPinnedId = pinnedId.toLowerCase();
                                        var base = pinnedId.replace(/\.desktop$/i, "");
                                        var lowerBase = base.toLowerCase();
                                        var found = null;
                                        
                                        // 1. Try exact desktopId (case-insensitive, with and without .desktop)
                                        for (var i = 0; i < AppSearch.list.length; i++) {
                                            var app = AppSearch.list[i];
                                            if (app.desktopId && (
                                                app.desktopId.toLowerCase() === lowerPinnedId ||
                                                app.desktopId.toLowerCase() === lowerBase + ".desktop" ||
                                                app.desktopId.toLowerCase() === lowerBase
                                            )) {
                                                found = app;
                                                break;
                                            }
                                        }
                                        // 2. Try name (case-insensitive)
                                        if (!found) {
                                            for (var i = 0; i < AppSearch.list.length; i++) {
                                                var app = AppSearch.list[i];
                                                if (app.name && app.name.toLowerCase() === lowerBase) {
                                                    found = app;
                                                    break;
                                                }
                                            }
                                        }
                                        // 3. Try exec (contains, case-insensitive)
                                        if (!found) {
                                            for (var i = 0; i < AppSearch.list.length; i++) {
                                                var app = AppSearch.list[i];
                                                if (app.exec && app.exec.toLowerCase().indexOf(lowerBase) !== -1) {
                                                    found = app;
                                                    break;
                                                }
                                            }
                                        }
                                        // 4. Try fuzzy name matching
                                        if (!found) {
                                            for (var i = 0; i < AppSearch.list.length; i++) {
                                                var app = AppSearch.list[i];
                                                if (app.name && (
                                                    app.name.toLowerCase().indexOf(lowerBase) !== -1 ||
                                                    app.name.toLowerCase().replace(/\s+/g, '') === lowerBase ||
                                                    (app.id && app.id.toLowerCase() === lowerBase)
                                                )) {
                                                    found = app;
                                                    break;
                                                }
                                            }
                                        }
                                        // 5. If found, ensure icon is valid
                                        if (found) {
                                            if (!found.icon || found.icon === "") {
                                                found.icon = AppSearch.guessIcon(pinnedId);
                                            }
                                            if (!found.iconUrl) {
                                                found.iconUrl = null;
                                            }
                                            // --- Merge real window data if running ---
                                            var mapping = {
                                                'AffinityPhoto.desktop': ['photo.exe', 'Photo.exe', 'affinityphoto', 'AffinityPhoto'],
                                                'AffinityDesigner.desktop': ['designer.exe', 'Designer.exe', 'affinitydesigner', 'AffinityDesigner'],
                                                'microsoft-edge-dev': ['microsoft-edge-dev', 'msedge', 'edge', 'Microsoft-edge-dev'],
                                                'vesktop': ['vesktop', 'discord', 'Vesktop', 'Discord'],
                                                'steam-native': ['steam', 'steam.exe', 'Steam', 'Steam.exe'],
                                                'org.gnome.Nautilus': ['nautilus', 'org.gnome.nautilus', 'org.gnome.Nautilus', 'Nautilus'],
                                                'org.gnome.nautilus': ['nautilus', 'org.gnome.nautilus', 'org.gnome.Nautilus', 'Nautilus'],
                                                'lutris': ['lutris', 'net.lutris.lutris', 'net.lutris.Lutris', 'Lutris'],
                                                'heroic': ['heroic', 'heroicgameslauncher', 'Heroic', 'HeroicGamesLauncher'],
                                                'obs': ['obs', 'OBS', 'com.obsproject.studio', 'com.obsproject.Studio'],
                                                'com.obsproject.Studio.desktop': ['obs', 'OBS', 'com.obsproject.studio', 'com.obsproject.Studio'],
                                                'cursor-cursor': ['cursor', 'Cursor', 'cursor-cursor'],
                                                'ptyxis': ['ptyxis', 'org.gnome.ptyxis', 'Ptyxis', 'Org.gnome.ptyxis'],
                                                'net.lutris.davinci-resolve-studio-20-1.desktop': ['davinci-resolve-studio-20', 'DaVinci Resolve Studio 20', 'resolve', 'com.blackmagicdesign.resolve']
                                            };
                                            var pinnedClassLower = pinnedId.toLowerCase();
                                            var possibleClasses = [pinnedClassLower];
                                            if (mapping[pinnedId]) {
                                                possibleClasses = possibleClasses.concat(mapping[pinnedId].map(c => c.toLowerCase()));
                                            }
                                            if (mapping[pinnedClassLower]) {
                                                possibleClasses = possibleClasses.concat(mapping[pinnedClassLower].map(c => c.toLowerCase()));
                                            }
                                            if (!pinnedClassLower.endsWith('.desktop')) {
                                                possibleClasses.push(pinnedClassLower + '.desktop');
                                            }
                                            possibleClasses = Array.from(new Set(possibleClasses));
                                            var runningWindow = HyprlandData.windowList.find(w => 
                                                possibleClasses.includes((w.class || '').toLowerCase()) ||
                                                possibleClasses.includes((w.initialClass || '').toLowerCase())
                                            );
                                            if (runningWindow) {
                                                // Merge address, workspace, etc. into found
                                                found.address = runningWindow.address;
                                                found.workspace = runningWindow.workspace;
                                                found.pid = runningWindow.pid;
                                                found.title = runningWindow.title;
                                            }
                                            return found;
                                        }
                                        // 6. Final fallback
                                        var fallback = {
                                            desktopId: pinnedId,
                                            name: pinnedId,
                                            icon: AppSearch.guessIcon(pinnedId),
                                            iconUrl: null
                                        };
                                        return fallback;
                                    }
                                    tooltip: modelData  // Use the app class name for pinned apps
                                    isActive: dockRoot.isWindowActive(modelData)
                                    isPinned: true
                                    onClicked: {
                                        // Write to a file to test if click is detected
                                        Hyprland.dispatch(`exec echo "$(date): Pinned app clicked: ${modelData}" >> /tmp/dock_debug.log`);
                                        console.log("[DOCK CLICK DEBUG] Pinned app clicked:", modelData);
                                        // Universal approach: try to focus existing window first, then launch if not found
                                        var targetWindow = dock.findWindowForApp(modelData);
                                        if (targetWindow) {
                                            Hyprland.dispatch(`exec echo "$(date): Found existing window, focusing: ${targetWindow.class}" >> /tmp/dock_debug.log`);
                                            console.log("[DOCK CLICK DEBUG] Found existing window, focusing:", targetWindow.class);
                                            // Focus existing window
                                            if (targetWindow.address) {
                                                Hyprland.dispatch(`focuswindow address:${targetWindow.address}`);
                                                if (targetWindow.workspace && targetWindow.workspace.id) {
                                                    Hyprland.dispatch(`workspace ${targetWindow.workspace.id}`);
                                                }
                                            } else {
                                                Hyprland.dispatch(`focuswindow class:${targetWindow.class}`);
                                            }
                                        } else {
                                            Hyprland.dispatch(`exec echo "$(date): No existing window found, launching new instance: ${modelData}" >> /tmp/dock_debug.log`);
                                            console.log("[DOCK CLICK DEBUG] No existing window found, launching new instance:", modelData);
                                            // Test if function exists
                                            Hyprland.dispatch(`exec echo "$(date): About to call launchApp function" >> /tmp/dock_debug.log`);
                                            if (typeof dock.launchApp === 'function') {
                                                Hyprland.dispatch(`exec echo "$(date): launchApp function exists, calling it" >> /tmp/dock_debug.log`);
                                            // Launch new instance
                                            dock.launchApp(modelData);
                                            } else {
                                                Hyprland.dispatch(`exec echo "$(date): ERROR: launchApp function does not exist!" >> /tmp/dock_debug.log`);
                                            }
                                        }
                                    }
                                    onUnpinApp: {
                                        // Always use the canonical pinned id (modelData) for unpinning
                                        dock.removePinnedApp(modelData)
                                    }
                                }
                            }
                            
                            // Right separator (only visible if there are non-pinned apps)
                            Rectangle {
                                id: rightSeparator
                                visible: nonPinnedAppsRepeater.count > 0
                                Layout.preferredWidth: 1
                                Layout.preferredHeight: dockHeight * 0.5
                                color: Appearance.colors.colOnLayer0
                                opacity: 0.3
                            }
                            
                            // Right side - Active but not pinned apps
                            Repeater {
                                id: nonPinnedAppsRepeater
                                model: {
                                    var nonPinnedApps = [];
                                    var mapping = {
                                        'AffinityPhoto.desktop': ['photo.exe', 'Photo.exe', 'affinityphoto', 'AffinityPhoto'],
                                        'AffinityDesigner.desktop': ['designer.exe', 'Designer.exe', 'affinitydesigner', 'AffinityDesigner'],
                                        'microsoft-edge-dev': ['microsoft-edge-dev', 'msedge', 'edge'],
                                        'vesktop': ['vesktop', 'discord'],
                                        'steam-native': ['steam', 'steam.exe', 'Steam', 'Steam.exe'],
                                        'org.gnome.nautilus': ['nautilus', 'org.gnome.nautilus'],
                                        'lutris': ['lutris', 'net.lutris.lutris'],
                                        'heroic': ['heroic', 'heroicgameslauncher'],
                                        'obs': ['obs', 'com.obsproject.studio'],
                                        'com.obsproject.Studio.desktop': ['obs', 'com.obsproject.studio'],
                                        'cursor-cursor': ['cursor', 'Cursor'],
                                        'ptyxis': ['ptyxis', 'org.gnome.ptyxis'],
                                        'net.lutris.davinci-resolve-studio-20-1.desktop': ['davinci-resolve-studio-20', 'DaVinci Resolve Studio 20', 'resolve', 'com.blackmagicdesign.resolve']
                                    };
                                    var reverseMapping = {
                                        'photo.exe': 'AffinityPhoto.desktop',
                                        'Photo.exe': 'AffinityPhoto.desktop',
                                        'designer.exe': 'AffinityDesigner.desktop',
                                        'Designer.exe': 'AffinityDesigner.desktop',
                                        'microsoft-edge-dev': 'microsoft-edge-dev',
                                        'msedge': 'microsoft-edge-dev',
                                        'edge': 'microsoft-edge-dev',
                                        'vesktop': 'vesktop',
                                        'discord': 'vesktop',
                                        'steam': 'steam-native',
                                        'steam.exe': 'steam-native',
                                        'Steam': 'steam-native',
                                        'Steam.exe': 'steam-native',
                                        'nautilus': 'org.gnome.nautilus',
                                        'org.gnome.nautilus': 'org.gnome.nautilus',
                                        'lutris': 'lutris',
                                        'net.lutris.lutris': 'lutris',
                                        'heroic': 'heroic',
                                        'heroicgameslauncher': 'heroic',
                                        'obs': 'obs',
                                        'com.obsproject.studio': 'obs',
                                        'cursor': 'cursor-cursor',
                                        'Cursor': 'cursor-cursor',
                                        'ptyxis': 'ptyxis',
                                        'org.gnome.ptyxis': 'ptyxis',
                                        'davinci-resolve-studio-20': 'net.lutris.davinci-resolve-studio-20-1.desktop',
                                        'DaVinci Resolve Studio 20': 'net.lutris.davinci-resolve-studio-20-1.desktop',
                                        'resolve': 'net.lutris.davinci-resolve-studio-20-1.desktop',
                                        'com.blackmagicdesign.resolve': 'net.lutris.davinci-resolve-studio-20-1.desktop'
                                    };
                                    var pinnedSet = new Set(dock.pinnedApps.map(a => a.toLowerCase()));
                                    // Normalize pinned set for special cases like Lutris
                                    var normalizedPinnedSet = new Set(pinnedSet);
                                    // Add normalized versions for special cases
                                    if (pinnedSet.has("lutris") || pinnedSet.has("net.lutris.lutris") || 
                                        pinnedSet.has("net.lutris.Lutris") || pinnedSet.has("Lutris")) {
                                        normalizedPinnedSet.add("lutris");
                                        normalizedPinnedSet.add("net.lutris.lutris");
                                        normalizedPinnedSet.add("net.lutris.Lutris");
                                        normalizedPinnedSet.add("Lutris");
                                    }
                                    if (pinnedSet.has("obs") || pinnedSet.has("com.obsproject.Studio") || 
                                        pinnedSet.has("com.obsproject.studio") || pinnedSet.has("OBS")) {
                                        normalizedPinnedSet.add("obs");
                                        normalizedPinnedSet.add("com.obsproject.Studio");
                                        normalizedPinnedSet.add("com.obsproject.studio");
                                        normalizedPinnedSet.add("OBS");
                                    }
                                    // Add normalization for Steam
                                    if (pinnedSet.has("steam-native") || pinnedSet.has("steam") || pinnedSet.has("steam.exe") || pinnedSet.has("Steam") || pinnedSet.has("Steam.exe")) {
                                        normalizedPinnedSet.add("steam-native");
                                        normalizedPinnedSet.add("steam");
                                        normalizedPinnedSet.add("steam.exe");
                                        normalizedPinnedSet.add("Steam");
                                        normalizedPinnedSet.add("Steam.exe");
                                    }
                                    // Add normalization for Ptyxis
                                    if (pinnedSet.has("ptyxis") || pinnedSet.has("org.gnome.ptyxis") || pinnedSet.has("Ptyxis") || pinnedSet.has("Org.gnome.ptyxis")) {
                                        normalizedPinnedSet.add("ptyxis");
                                        normalizedPinnedSet.add("org.gnome.ptyxis");
                                        normalizedPinnedSet.add("Ptyxis");
                                        normalizedPinnedSet.add("Org.gnome.ptyxis");
                                    }
                                    
                                    // Group windows by effective app identity
                                    var groups = {};
                                    for (var i = 0; i < dock.activeWindows.length; i++) {
                                        var w = dock.activeWindows[i];
                                        if (!w.class || w.class.trim() === '' || w.class.length < 2) continue;
                                        var genericClasses = ['window', 'x11', 'xwayland', 'wayland', 'unknown', 'null', 'undefined'];
                                        if (genericClasses.includes(w.class.toLowerCase())) continue;
                                        if (!w.title || w.title.trim() === '') continue;
                                        // Determine grouping key (desktop file if possible, else class)
                                        var rawKey = reverseMapping[w.class] || reverseMapping[w.class.toLowerCase()] || w.class;
                                        var key = rawKey.toLowerCase();
                                        // Normalize OBS variants
                                        if (key === "obs" || key === "com.obsproject.studio" || key === "com.obsproject.studio.desktop") {
                                            key = "obs";
                                        }
                                        // Normalize Lutris variants
                                        if (key === "lutris" || key === "net.lutris.lutris" || key === "net.lutris.lutris.desktop") {
                                            key = "lutris";
                                        }
                                        // Normalize Steam variants
                                        if (key === "steam-native" || key === "steam" || key === "steam.exe" || key === "Steam" || key === "Steam.exe") {
                                            key = "steam-native";
                                        }
                                        // Normalize Ptyxis variants
                                        if (key === "ptyxis" || key === "org.gnome.ptyxis" || key === "Ptyxis" || key === "Org.gnome.ptyxis") {
                                            key = "ptyxis";
                                        }
                                        // Debug log for window class and grouping key
// console.log('[DOCK DEBUG] Window class:', w.class, '| Grouping key:', key, '| Title:', w.title, '| Address:', w.address);
                                        // Skip if this app is pinned (check normalized set)
                                        if (normalizedPinnedSet.has(key)) continue;
                                        if (!groups[key]) groups[key] = [];
                                        groups[key].push(w);
                                    }
                                    // For each group, create a single entry with all windows (toplevels)
                                    for (var key in groups) {
                                        var rep = groups[key][0];
                                        var appObj = null;
                                        // Try to find DesktopEntry for this group (like pinned logic)
                                        appObj = AppSearch.list.find(a =>
                                            (a.desktopId && a.desktopId.toLowerCase() === key.toLowerCase()) ||
                                            (a.exec && a.exec.toLowerCase().includes(key.toLowerCase())) ||
                                            (a.name && a.name.toLowerCase() === key.toLowerCase())
                                        );
                                        if (!appObj) {
                                            // Fallback: minimal object
                                            appObj = {
                                                desktopId: key,
                                                name: key,
                                                icon: AppSearch.guessIcon(key),
                                                iconUrl: null,
                                                pinned: false,
                                                toplevels: []
                                            };
                                        } else {
                                            appObj = Object.assign({}, appObj, { pinned: false, toplevels: [] });
                                        }
                                        appObj.toplevels = groups[key];
                                        // Attach window properties from the first window for focus/activation
                                        appObj.class = rep.class;
                                        appObj.title = rep.title;
                                        appObj.address = rep.address;
                                        appObj.workspace = rep.workspace;
                                        nonPinnedApps.push(appObj);
                                    }
                                    return nonPinnedApps;
                                }
                                
                                DockItem {
                                    appData: {
                                        // 100% port of pinned app logic, adapted for window classes
                                        var windowClass = modelData.class;
                                        var lowerWindowClass = windowClass.toLowerCase();
                                        var base = windowClass.replace(/\.desktop$/i, "");
                                        var lowerBase = base.toLowerCase();
                                        var found = null;
                                        
                                        // Reverse mapping: try to find desktop file from window class
                                        var reverseMapping = {
                                            'photo.exe': 'AffinityPhoto.desktop',
                                            'Photo.exe': 'AffinityPhoto.desktop',
                                            'designer.exe': 'AffinityDesigner.desktop',
                                            'Designer.exe': 'AffinityDesigner.desktop',
                                            'microsoft-edge-dev': 'microsoft-edge-dev',
                                            'msedge': 'microsoft-edge-dev',
                                            'edge': 'microsoft-edge-dev',
                                            'vesktop': 'vesktop',
                                            'discord': 'vesktop',
                                            'steam': 'steam-native',
                                            'steam.exe': 'steam-native',
                                            'Steam': 'steam-native',
                                            'Steam.exe': 'steam-native',
                                            'nautilus': 'org.gnome.nautilus',
                                            'org.gnome.nautilus': 'org.gnome.nautilus',
                                            'lutris': 'lutris',
                                            'net.lutris.lutris': 'lutris',
                                            'heroic': 'heroic',
                                            'heroicgameslauncher': 'heroic',
                                            'obs': 'obs',
                                            'com.obsproject.studio': 'obs',
                                            'cursor': 'cursor-cursor',
                                            'Cursor': 'cursor-cursor',
                                            'ptyxis': 'ptyxis',
                                            'org.gnome.ptyxis': 'ptyxis',
                                            'davinci-resolve-studio-20': 'net.lutris.davinci-resolve-studio-20-1.desktop',
                                            'DaVinci Resolve Studio 20': 'net.lutris.davinci-resolve-studio-20-1.desktop',
                                            'resolve': 'net.lutris.davinci-resolve-studio-20-1.desktop',
                                            'com.blackmagicdesign.resolve': 'net.lutris.davinci-resolve-studio-20-1.desktop'
                                        };
                                        
                                        // Try to get desktop file name from reverse mapping
                                        var mappedDesktopFile = reverseMapping[windowClass] || reverseMapping[lowerWindowClass];
                                        if (mappedDesktopFile) {
                                            // Use the mapped desktop file name for searching
                                            var mappedLower = mappedDesktopFile.toLowerCase();
                                            var mappedBase = mappedDesktopFile.replace(/\.desktop$/i, "");
                                            var mappedLowerBase = mappedBase.toLowerCase();
                                            
// console.log('[REVERSE MAPPING] windowClass:', windowClass, 'mapped to:', mappedDesktopFile);
// console.log('[REVERSE MAPPING] Searching for:', mappedLower, mappedLowerBase + ".desktop", mappedLowerBase);
                                            
                                            // Search using the mapped desktop file name
                                            for (var i = 0; i < AppSearch.list.length; i++) {
                                                var app = AppSearch.list[i];
                                                if (app.desktopId && (
                                                    app.desktopId.toLowerCase() === mappedLower ||
                                                    app.desktopId.toLowerCase() === mappedLowerBase + ".desktop" ||
                                                    app.desktopId.toLowerCase() === mappedLowerBase
                                                )) {
                                                    found = app;
// console.log('[REVERSE MAPPING] Found by mapped desktopId:', app.desktopId, 'icon:', app.icon, 'iconUrl:', app.iconUrl);
                                                    break;
                                                }
                                            }
                                            
                                            // If not found, let's see what's in AppSearch.list for Affinity apps
                                            if (!found && lowerWindowClass.indexOf('affinity') !== -1) {
// console.log('[REVERSE MAPPING] Not found, checking AppSearch.list for Affinity entries...');
                                                for (var j = 0; j < AppSearch.list.length; j++) {
                                                    var searchApp = AppSearch.list[j];
                                                    if ((searchApp.desktopId && searchApp.desktopId.toLowerCase().indexOf('affinity') !== -1) ||
                                                        (searchApp.name && searchApp.name.toLowerCase().indexOf('affinity') !== -1)) {
// console.log('[REVERSE MAPPING] Found Affinity entry:', JSON.stringify(searchApp));
                                                    }
                                                }
                                            }
                                        }
                                        
                                        if (lowerWindowClass.indexOf('affinity') !== -1) {
// console.log('[AFFINITY DEBUG] windowClass:', windowClass, 'base:', base, 'lowerBase:', lowerBase);
// console.log('[AFFINITY DEBUG] Searching AppSearch.list for Affinity entries...');
                                            for (var j = 0; j < AppSearch.list.length; j++) {
                                                var searchApp = AppSearch.list[j];
                                                if ((searchApp.desktopId && searchApp.desktopId.toLowerCase().indexOf('affinity') !== -1) ||
                                                    (searchApp.name && searchApp.name.toLowerCase().indexOf('affinity') !== -1) ||
                                                    (searchApp.exec && searchApp.exec.toLowerCase().indexOf('affinity') !== -1)) {
// console.log('[AFFINITY DEBUG] Found potential match:', JSON.stringify(searchApp));
                                                }
                                            }
                                        }
                                        
                                        // 1. Try exact desktopId (case-insensitive, with and without .desktop)
                                        for (var i = 0; i < AppSearch.list.length; i++) {
                                            var app = AppSearch.list[i];
                                            if (app.desktopId && (
                                                app.desktopId.toLowerCase() === lowerWindowClass ||
                                                app.desktopId.toLowerCase() === lowerBase + ".desktop" ||
                                                app.desktopId.toLowerCase() === lowerBase
                                            )) {
                                                found = app;
                                                                                            if (lowerWindowClass.indexOf('affinity') !== -1) {
// console.log('[AFFINITY DEBUG] [1] Found by desktopId:', app.desktopId, 'icon:', app.icon, 'iconUrl:', app.iconUrl);
                                            }
                                                break;
                                            }
                                        }
                                        
                                        // 2. Try name (case-insensitive)
                                        if (!found) {
                                            for (var i = 0; i < AppSearch.list.length; i++) {
                                                var app = AppSearch.list[i];
                                                if (app.name && app.name.toLowerCase() === lowerBase) {
                                                    found = app;
                                                                                                if (lowerWindowClass.indexOf('affinity') !== -1) {
// console.log('[AFFINITY DEBUG] [2] Found by name:', app.name, 'icon:', app.icon, 'iconUrl:', app.iconUrl);
                                            }
                                                    break;
                                                }
                                            }
                                        }
                                        
                                        // 3. Try exec (contains, case-insensitive)
                                        if (!found) {
                                            for (var i = 0; i < AppSearch.list.length; i++) {
                                                var app = AppSearch.list[i];
                                                if (app.exec && app.exec.toLowerCase().indexOf(lowerBase) !== -1) {
                                                    found = app;
                                                                                                if (lowerWindowClass.indexOf('affinity') !== -1) {
// console.log('[AFFINITY DEBUG] [3] Found by exec:', app.exec, 'icon:', app.icon, 'iconUrl:', app.iconUrl);
                                            }
                                                    break;
                                                }
                                            }
                                        }
                                        
                                        // 4. Try fuzzy name matching (for cases like "AffinityPhoto.desktop" -> "Affinity Photo")
                                        if (!found) {
                                            for (var i = 0; i < AppSearch.list.length; i++) {
                                                var app = AppSearch.list[i];
                                                if (app.name && (
                                                    app.name.toLowerCase().indexOf(lowerBase) !== -1 ||
                                                    app.name.toLowerCase().replace(/\s+/g, '') === lowerBase ||
                                                    (app.id && app.id.toLowerCase() === lowerBase)
                                                )) {
                                                    found = app;
                                                                                                if (lowerWindowClass.indexOf('affinity') !== -1) {
// console.log('[AFFINITY DEBUG] [4] Found by fuzzy name/id:', app.name, 'id:', app.id, 'icon:', app.icon, 'iconUrl:', app.iconUrl);
                                            }
                                                    break;
                                                }
                                            }
                                        }
                                        
                                        // 5. If found, ensure icon is valid and add window properties
                                        if (found) {
                                            // If icon is missing or empty, guess
                                            if (!found.icon || found.icon === "") {
                                                found.icon = AppSearch.guessIcon(windowClass);
                                                                                            if (lowerWindowClass.indexOf('affinity') !== -1) {
// console.log('[AFFINITY DEBUG] [5] Guessed icon:', found.icon);
                                            }
                                            }
                                            if (!found.iconUrl) {
                                                found.iconUrl = null;
                                            }
                                            // Add window properties to the found app data
                                            found.class = windowClass;
                                            found.title = modelData.title;
                                            found.address = modelData.address;
                                            found.workspace = modelData.workspace;
                                            if (lowerWindowClass.indexOf('affinity') !== -1) {
// console.log('[AFFINITY DEBUG] [FINAL] appData:', JSON.stringify(found));
                                            }
                                            return found;
                                        }
                                        
                                        // 6. Final fallback - create minimal object with guessed icon
                                        var fallback = {
                                            desktopId: windowClass,
                                            name: windowClass,
                                            icon: AppSearch.guessIcon(windowClass),
                                            iconUrl: null,
                                            class: windowClass,
                                            title: modelData.title,
                                            address: modelData.address,
                                            workspace: modelData.workspace
                                        };
                                        if (
                                            lowerWindowClass.indexOf('affinity') !== -1 ||
                                            lowerWindowClass === 'designer.exe' ||
                                            lowerWindowClass === 'photo.exe'
                                        ) {
                                            // If we have a mapped desktop file, use its SVG icon path
                                            var mappedDesktopFile = reverseMapping[windowClass] || reverseMapping[lowerWindowClass];
                                            if (mappedDesktopFile) {
                                                var iconPath = "/home/matt/.local/share/icons/" + mappedDesktopFile.replace('.desktop', '.svg');
                                                fallback.iconUrl = "file://" + iconPath;
                                                fallback.icon = mappedDesktopFile.replace('.desktop', '');
// console.log('[AFFINITY FALLBACK] Set iconUrl to', fallback.iconUrl, 'icon:', fallback.icon);
                                            }
                                        }
                                        
                                        return fallback;
                                    }
                                    tooltip: modelData.title || modelData.class
                                    isActive: true
                                    isPinned: false
                                    Component.onCompleted: {
                                        // console.log("[DOCK DEBUG] Unpinned DockItem created for class:", modelData.class);
                                    }
                                    
                                    onClicked: {
                                        // Use the unified launcher for all apps
                                        if (modelData.class) {
                                            dock.launchApp(modelData.class);
                                            return;
                                        }
                                        // For unpinned apps, we already have the specific window
                                        if (modelData.address) {
                                            Hyprland.dispatch(`focuswindow address:${modelData.address}`)
                                            
                                            // Switch to the workspace containing the window
                                            if (modelData.workspace && modelData.workspace.id) {
                                                Hyprland.dispatch(`workspace ${modelData.workspace.id}`)
                                            }
                                        } else {
                                            // Fallback to focusing by class
                                            Hyprland.dispatch(`focuswindow class:${modelData.class}`)
                                        }
                                    }
                                    onPinApp: {
                                                dock.addPinnedApp(modelData.class)
                                    }
                                }
                            }

                            // Left separator for media
                            Rectangle {
                                Layout.preferredWidth: 1
                                Layout.preferredHeight: dockHeight * 0.5
                                color: Appearance.colors.colOnLayer0
                                opacity: 0.3
                            }

                            // Media controls at right edge
                            Item {
                                implicitWidth: mediaComponent.implicitWidth + 40 // Ensure it expands for time display
                                Layout.preferredWidth: mediaComponent.implicitWidth + 40
                                Layout.preferredHeight: dockHeight * 0.65
                                Layout.rightMargin: dockHeight * 0.25
                                Layout.fillWidth: false // Allow natural width expansion
                                Layout.maximumWidth: -1 // Remove maximum width constraint

                                Media {
                                    id: mediaComponent
                                    anchors.fill: parent
                                    anchors.margins: 4
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Background blur system - static blur approach inspired by Blur My Shell
    /*
    PanelWindow {
        id: dockBackgroundBlur
        visible: dockRoot.visible
        screen: dockRoot.screen
        
        // Position behind the dock
        anchors.left: dockRoot.anchors.left
        anchors.right: dockRoot.anchors.right
        anchors.bottom: dockRoot.anchors.bottom
        
        // Set layer to be behind the dock
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:dock:background"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        
        // Match dock dimensions
        implicitWidth: dockRoot.implicitWidth
        implicitHeight: dockRoot.implicitHeight
        color: "transparent"
        
        // Static blur background using wallpaper capture
        Rectangle {
            id: staticBlurBackground
            anchors.centerIn: parent
            width: dockContent.width
            height: dockContent.height
            radius: ConfigOptions.dock.radius
            color: "transparent"
            
            // Wallpaper background for static blur
            Image {
                id: wallpaperForBlur
                anchors.fill: parent
                source: Data.WallpaperManager.currentWallpaper ? "file://" + Data.WallpaperManager.currentWallpaper : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                
                // Apply MultiEffect blur to the wallpaper
                layer.enabled: true
                layer.effect: MultiEffect {
                    source: wallpaperForBlur
                    blurEnabled: true
                    blurMultiplier: 0.7
                    blurMax: 64
                    saturation: 0.8  // Reduce saturation for better blur effect
                }
            }
            
            // Semi-transparent overlay to enhance blur effect
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.3) // Dark overlay to enhance blur
                radius: parent.radius
            }
            
            // Smooth border to cover blur edge artifacts
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.15)
                radius: parent.radius
                antialiasing: true
                z: 2
            }
        }
        

    }
    */

    // No longer needed - using DesktopEntries.execute() like HyprMenu

    // Manual function to force refresh all icons (useful for testing)
    function forceRefreshIcons() {
        // console.log("[DOCK DEBUG] Manually forcing icon refresh");
        
        // Refresh the theme discovery system
        IconTheme.refreshThemes(StandardPaths.writableLocation(StandardPaths.HomeLocation));
        
        // Clear and reload pinned apps with staggered timing
        if (pinnedAppsRepeater) {
            var oldModel = dock.pinnedApps.slice(); // Create a copy
            pinnedAppsRepeater.model = [];
            
            // Wait for the UI to clear, then restore
            Qt.callLater(function() {
                // Force garbage collection
                gc();
                
                // Wait a bit more then restore
                Qt.callLater(function() {
                    pinnedAppsRepeater.model = oldModel;
                    // console.log("[DOCK DEBUG] Pinned apps model restored");
                });
            });
        }
        
        // Refresh active windows which will refresh non-pinned apps
        Qt.callLater(function() {
            updateActiveWindows();
            // console.log("[DOCK DEBUG] Active windows updated");
        });
        
        // console.log("[DOCK DEBUG] Icon refresh initiated");
    }



    // Preview helper functions
    // (Removed showWindowPreviews, hideWindowPreviews, hideWindowPreviewsImmediately, and all windowPreview references)

    Menu {
        id: dockContextMenu
        property var contextAppInfo: null
        property bool contextIsPinned: false
        property var contextDockItem: null

        MenuItem {
            text: dockContextMenu.contextIsPinned ? qsTr("Unpin from dock") : qsTr("Pin to dock")
            onTriggered: {
                // console.log("[CONTEXT MENU DEBUG] Pin/Unpin triggered:", {
                //     isPinned: dockContextMenu.contextIsPinned,
                //     contextClass: dockContextMenu.contextAppInfo ? dockContextMenu.contextAppInfo.class : "no class",
                //     contextAppInfo: dockContextMenu.contextAppInfo
                // });
                
                if (dockContextMenu.contextIsPinned) {
                    // console.log("[CONTEXT MENU DEBUG] Calling removePinnedApp with:", dockContextMenu.contextAppInfo.class);
                    dock.removePinnedApp(dockContextMenu.contextAppInfo.class)
                } else {
                    // console.log("[CONTEXT MENU DEBUG] Calling addPinnedApp with:", dockContextMenu.contextAppInfo.class);
                    dock.addPinnedApp(dockContextMenu.contextAppInfo.class)
                }
            }
        }
        MenuItem {
            text: qsTr("Launch new instance")
            onTriggered: {
                if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.class) {
                    dock.launchApp(dockContextMenu.contextAppInfo.class)
                }
            }
        }
        MenuSeparator {}
        Menu {
            title: qsTr("Move to workspace")
            enabled: dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address !== undefined
            
            MenuItem {
                text: qsTr("Workspace 1")
                enabled: dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address !== undefined
                onTriggered: {
                    if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address) {
                        // console.log("[DOCK MENU DEBUG] Moving window to workspace 1, address:", dockContextMenu.contextAppInfo.address)
                        Hyprland.dispatch(`movetoworkspace 1,address:${dockContextMenu.contextAppInfo.address}`)
                    } else {
                        // console.log("[DOCK MENU DEBUG] Cannot move to workspace 1 - missing address:", dockContextMenu.contextAppInfo)
                    }
                }
            }
            MenuItem {
                text: qsTr("Workspace 2")
                enabled: dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address !== undefined
                onTriggered: {
                    if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address) {
                        // console.log("[DOCK MENU DEBUG] Moving window to workspace 2, address:", dockContextMenu.contextAppInfo.address)
                        Hyprland.dispatch(`movetoworkspace 2,address:${dockContextMenu.contextAppInfo.address}`)
                    } else {
                        // console.log("[DOCK MENU DEBUG] Cannot move to workspace 2 - missing address:", dockContextMenu.contextAppInfo)
                    }
                }
            }
            MenuItem {
                text: qsTr("Workspace 3")
                enabled: dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address !== undefined
                onTriggered: {
                    if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address) {
                        // console.log("[DOCK MENU DEBUG] Moving window to workspace 3, address:", dockContextMenu.contextAppInfo.address)
                        Hyprland.dispatch(`movetoworkspace 3,address:${dockContextMenu.contextAppInfo.address}`)
                    } else {
                        // console.log("[DOCK MENU DEBUG] Cannot move to workspace 3 - missing address:", dockContextMenu.contextAppInfo)
                    }
                }
            }
            MenuItem {
                text: qsTr("Workspace 4")
                enabled: dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address !== undefined
                onTriggered: {
                    if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address) {
                        // console.log("[DOCK MENU DEBUG] Moving window to workspace 4, address:", dockContextMenu.contextAppInfo.address)
                        Hyprland.dispatch(`movetoworkspace 4,address:${dockContextMenu.contextAppInfo.address}`)
                    } else {
                        // console.log("[DOCK MENU DEBUG] Cannot move to workspace 4 - missing address:", dockContextMenu.contextAppInfo)
                    }
                }
            }
            MenuItem {
                text: qsTr("Workspace 5")
                enabled: dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address !== undefined
                onTriggered: {
                    if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address) {
                        // console.log("[DOCK MENU DEBUG] Moving window to workspace 5, address:", dockContextMenu.contextAppInfo.address)
                        Hyprland.dispatch(`movetoworkspace 5,address:${dockContextMenu.contextAppInfo.address}`)
                    } else {
                        // console.log("[DOCK MENU DEBUG] Cannot move to workspace 5 - missing address:", dockContextMenu.contextAppInfo)
                    }
                }
            }
            MenuItem {
                text: qsTr("Workspace 6")
                enabled: dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address !== undefined
                onTriggered: {
                    if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address) {
                        // console.log("[DOCK MENU DEBUG] Moving window to workspace 6, address:", dockContextMenu.contextAppInfo.address)
                        Hyprland.dispatch(`movetoworkspace 6,address:${dockContextMenu.contextAppInfo.address}`)
                    } else {
                        // console.log("[DOCK MENU DEBUG] Cannot move to workspace 6 - missing address:", dockContextMenu.contextAppInfo)
                    }
                }
            }
            MenuItem {
                text: qsTr("Workspace 7")
                enabled: dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address !== undefined
                onTriggered: {
                    if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address) {
                        // console.log("[DOCK MENU DEBUG] Moving window to workspace 7, address:", dockContextMenu.contextAppInfo.address)
                        Hyprland.dispatch(`movetoworkspace 7,address:${dockContextMenu.contextAppInfo.address}`)
                    } else {
                        // console.log("[DOCK MENU DEBUG] Cannot move to workspace 7 - missing address:", dockContextMenu.contextAppInfo)
                    }
                }
            }
            MenuItem {
                text: qsTr("Workspace 8")
                enabled: dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address !== undefined
                onTriggered: {
                    if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address) {
                        // console.log("[DOCK MENU DEBUG] Moving window to workspace 8, address:", dockContextMenu.contextAppInfo.address)
                        Hyprland.dispatch(`movetoworkspace 8,address:${dockContextMenu.contextAppInfo.address}`)
                    } else {
                        // console.log("[DOCK MENU DEBUG] Cannot move to workspace 8 - missing address:", dockContextMenu.contextAppInfo)
                    }
                }
            }
            MenuItem {
                text: qsTr("Workspace 9")
                enabled: dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address !== undefined
                onTriggered: {
                    if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address) {
                        // console.log("[DOCK MENU DEBUG] Moving window to workspace 9, address:", dockContextMenu.contextAppInfo.address)
                        Hyprland.dispatch(`movetoworkspace 9,address:${dockContextMenu.contextAppInfo.address}`)
                    } else {
                        // console.log("[DOCK MENU DEBUG] Cannot move to workspace 9 - missing address:", dockContextMenu.contextAppInfo)
                    }
                }
            }
            MenuItem {
                text: qsTr("Workspace 10")
                enabled: dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address !== undefined
                onTriggered: {
                    if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address) {
                        // console.log("[DOCK MENU DEBUG] Moving window to workspace 10, address:", dockContextMenu.contextAppInfo.address)
                        Hyprland.dispatch(`movetoworkspace 10,address:${dockContextMenu.contextAppInfo.address}`)
                    } else {
                        // console.log("[DOCK MENU DEBUG] Cannot move to workspace 10 - missing address:", dockContextMenu.contextAppInfo)
                    }
                }
            }
        }
        MenuItem {
            text: qsTr("Toggle floating")
            enabled: dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address !== undefined
            onTriggered: {
                if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address) {
                    Hyprland.dispatch(`togglefloating address:${dockContextMenu.contextAppInfo.address}`)
                }
            }
        }
        MenuSeparator {}
        MenuItem {
            text: qsTr("Close")
            onTriggered: {
                if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address) {
                    Hyprland.dispatch(`closewindow address:${dockContextMenu.contextAppInfo.address}`)
                } else if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.pid) {
                    Hyprland.dispatch(`closewindow pid:${dockContextMenu.contextAppInfo.pid}`)
                } else if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.class) {
                    Hyprland.dispatch(`closewindow class:${dockContextMenu.contextAppInfo.class}`)
                }
                if (dockContextMenu.contextDockItem && dockContextMenu.contextDockItem.closeApp) dockContextMenu.contextDockItem.closeApp()
            }
        }
        MenuItem {
            text: qsTr("Close All")
            enabled: dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.class
            property var closeAllTimer: null
            property var currentClassIndex: 0
            property var possibleClasses: []
            property var currentClassAttempts: 0
            
            onTriggered: {
                console.log("[CLOSE ALL DEBUG] Button clicked!");
                console.log("[CLOSE ALL DEBUG] Full contextAppInfo:", JSON.stringify(dockContextMenu.contextAppInfo));
                
                if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.class) {
                    var className = dockContextMenu.contextAppInfo.class;
                    console.log("[CLOSE ALL DEBUG] Original class name:", className);
                    
                    // Build mapping for .desktop files to possible window classes
                    var mapping = {
                        'AffinityPhoto.desktop': ['photo.exe', 'Photo.exe', 'affinityphoto', 'AffinityPhoto'],
                        'AffinityDesigner.desktop': ['designer.exe', 'Designer.exe', 'affinitydesigner', 'AffinityDesigner'],
                        'microsoft-edge-dev': ['microsoft-edge-dev', 'msedge', 'edge', 'Microsoft-edge-dev'],
                        'vesktop': ['vesktop', 'discord', 'Vesktop', 'Discord'],
                        'steam-native': ['steam', 'steam.exe', 'Steam', 'Steam.exe'],
                        'org.gnome.Nautilus': ['nautilus', 'org.gnome.nautilus', 'org.gnome.Nautilus', 'Nautilus'],
                        'org.gnome.nautilus': ['nautilus', 'org.gnome.nautilus', 'org.gnome.Nautilus', 'Nautilus'],
                        'lutris': ['lutris', 'net.lutris.lutris', 'net.lutris.Lutris', 'Lutris'],
                        'heroic': ['heroic', 'heroicgameslauncher', 'Heroic', 'HeroicGamesLauncher'],
                        'obs': ['obs', 'OBS', 'com.obsproject.studio', 'com.obsproject.Studio'],
                        'com.obsproject.Studio.desktop': ['obs', 'OBS', 'com.obsproject.studio', 'com.obsproject.Studio'],
                        'cursor-cursor': ['cursor', 'Cursor', 'cursor-cursor'],
                        'ptyxis': ['ptyxis', 'org.gnome.ptyxis', 'Ptyxis', 'Org.gnome.ptyxis'],
                        'net.lutris.davinci-resolve-studio-20-1.desktop': ['davinci-resolve-studio-20', 'DaVinci Resolve Studio 20', 'resolve', 'com.blackmagicdesign.resolve']
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
                    
                    console.log("[CLOSE ALL DEBUG] Possible classes to try:", classes);
                    
                    // Initialize timer-based closing
                    closeAllTimer = Qt.createQmlObject('import QtQuick; Timer { interval: 10; repeat: true; }', this);
                    possibleClasses = classes;
                    currentClassIndex = 0;
                    currentClassAttempts = 0;
                    
                    closeAllTimer.triggered.connect(function() {
                        if (currentClassIndex >= possibleClasses.length) {
                            console.log("[CLOSE ALL DEBUG] Finished closing all windows");
                            closeAllTimer.stop();
                            closeAllTimer.destroy();
                            return;
                        }
                        
                        var windowClass = possibleClasses[currentClassIndex];
                        
                        if (currentClassAttempts >= 10) {
                            console.log("[CLOSE ALL DEBUG] Max attempts reached for class:", windowClass);
                            currentClassIndex++;
                            currentClassAttempts = 0;
                            return;
                        }
                        
                        try {
                            Hyprland.dispatch(`closewindow class:${windowClass}`);
                            console.log("[CLOSE ALL DEBUG] Closed window for class:", windowClass, "attempt:", currentClassAttempts + 1);
                            currentClassAttempts++;
                        } catch (error) {
                            console.log("[CLOSE ALL DEBUG] No more windows for class:", windowClass, "after", currentClassAttempts, "attempts");
                            currentClassIndex++;
                            currentClassAttempts = 0;
                        }
                    });
                    
                    closeAllTimer.start();
                    
                } else {
                    console.log("[CLOSE ALL DEBUG] No valid class found");
                }
                
                if (dockContextMenu.contextDockItem && dockContextMenu.contextDockItem.closeApp) {
                    dockContextMenu.contextDockItem.closeApp()
                    console.log("[CLOSE ALL DEBUG] Called closeApp signal");
                }
            }
        }
    }

    function openDockContextMenu(appInfo, isPinned, dockItem, mouse) {
        var finalAppInfo = appInfo
        
        // Normalize the app info - desktop entries use 'id', windows use 'class'
        if (appInfo && !appInfo.class && appInfo.id) {
            var classToUse = appInfo.id;
            if (isPinned && !appInfo.id.endsWith('.desktop')) {
                classToUse = appInfo.id + '.desktop';
            }
            finalAppInfo = {
                class: classToUse,
                name: appInfo.name,
                address: appInfo.address,
                pid: appInfo.pid,
                command: appInfo.execString,
                id: appInfo.id,
                genericName: appInfo.genericName,
                noDisplay: appInfo.noDisplay,
                comment: appInfo.comment,
                icon: appInfo.icon,
                execString: appInfo.execString,
                workingDirectory: appInfo.workingDirectory,
                runInTerminal: appInfo.runInTerminal,
                categories: appInfo.categories,
                keywords: appInfo.keywords,
                actions: appInfo.actions,
                iconUrl: appInfo.iconUrl
            }
        }
        
        // Attach all windows for this app as toplevels
        if (isPinned && finalAppInfo && finalAppInfo.class) {
            // Build mapping for .desktop files to possible window classes
            var mapping = {
                'AffinityPhoto.desktop': ['photo.exe', 'Photo.exe', 'affinityphoto', 'AffinityPhoto'],
                'AffinityDesigner.desktop': ['designer.exe', 'Designer.exe', 'affinitydesigner', 'AffinityDesigner'],
                'microsoft-edge-dev': ['microsoft-edge-dev', 'msedge', 'edge', 'Microsoft-edge-dev'],
                'vesktop': ['vesktop', 'discord', 'Vesktop', 'Discord'],
                'steam-native': ['steam', 'steam.exe', 'Steam', 'Steam.exe'],
                'org.gnome.Nautilus': ['nautilus', 'org.gnome.nautilus', 'org.gnome.Nautilus', 'Nautilus'],
                'org.gnome.nautilus': ['nautilus', 'org.gnome.nautilus', 'org.gnome.Nautilus', 'Nautilus'],
                'lutris': ['lutris', 'net.lutris.lutris', 'net.lutris.Lutris', 'Lutris'],
                'heroic': ['heroic', 'heroicgameslauncher', 'Heroic', 'HeroicGamesLauncher'],
                'obs': ['obs', 'OBS', 'com.obsproject.studio', 'com.obsproject.Studio'],
                'com.obsproject.Studio.desktop': ['obs', 'OBS', 'com.obsproject.studio', 'com.obsproject.Studio'],
                'cursor-cursor': ['cursor', 'Cursor', 'cursor-cursor'],
                'ptyxis': ['ptyxis', 'org.gnome.ptyxis', 'Ptyxis', 'Org.gnome.ptyxis'],
                'net.lutris.davinci-resolve-studio-20-1.desktop': ['davinci-resolve-studio-20', 'DaVinci Resolve Studio 20', 'resolve', 'com.blackmagicdesign.resolve']
            };
            var pinnedClassLower = finalAppInfo.class.toLowerCase();
            var possibleClasses = [pinnedClassLower];
            if (mapping[finalAppInfo.class]) {
                possibleClasses = possibleClasses.concat(mapping[finalAppInfo.class].map(c => c.toLowerCase()));
            }
            if (mapping[pinnedClassLower]) {
                possibleClasses = possibleClasses.concat(mapping[pinnedClassLower].map(c => c.toLowerCase()));
            }
            if (!pinnedClassLower.endsWith('.desktop')) {
                possibleClasses.push(pinnedClassLower + '.desktop');
            }
            possibleClasses = Array.from(new Set(possibleClasses));
            // Collect all windows for this app
            var allWindows = HyprlandData.windowList.filter(w => 
                possibleClasses.includes((w.class || '').toLowerCase()) ||
                possibleClasses.includes((w.initialClass || '').toLowerCase())
            );
            finalAppInfo.toplevels = allWindows;
        } else if (appInfo && appInfo.toplevels) {
            finalAppInfo.toplevels = appInfo.toplevels;
            }

        dockContextMenu.contextAppInfo = finalAppInfo
        dockContextMenu.contextIsPinned = isPinned
        dockContextMenu.contextDockItem = dockItem
        dockContextMenu.open()
    }

    // --- DOCK APP LIST AND PREVIEW (End4 1:1 port) ---
    DockApps { id: dockApps }
    // --- END DOCK APP LIST AND PREVIEW ---
}
