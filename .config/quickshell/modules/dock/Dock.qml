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
import "root:/modules/common/functions/icon_theme.js" as IconTheme
import "root:/Data" as Data

Scope {
    id: dock

    // Dock dimensions and appearance
    readonly property int dockHeight: Appearance.sizes.barHeight * 1.5
    readonly property int dockWidth: Appearance.sizes.barHeight * 1.5
    readonly property int dockSpacing: Appearance.sizes.elevationMargin
    
    // Color properties that update when Appearance changes
    readonly property color backgroundColor: Qt.rgba(
        Appearance.colors.colLayer0.r,
        Appearance.colors.colLayer0.g,
        Appearance.colors.colLayer0.b,
        AppearanceSettingsState.dockTransparency
    )
    
    // Auto-hide properties
    property bool autoHide: false
    property int hideDelay: 200 // Hide timer interval
    property int showDelay: 50 // Show timer interval
    property int animationDuration: Appearance.animation.elementMoveFast.duration // Animation speed for dock sliding
    property int approachRegionHeight: 18 // Height of the approach region in pixels
    
    // Property to track if mouse is over any dock item
    property bool mouseOverDockItem: false
    
    // Menu properties
    property bool showDockMenu: false
    property var menuAppInfo: ({})
    property rect menuTargetRect: Qt.rect(0, 0, 0, 0)  // Store position and size of target item
    property var activeMenuItem: null  // Track which item triggered the menu
    
    // Preview properties
    property bool showDockPreviews: false
    property var previewAppClass: ""
    property point previewPosition: Qt.point(0, 0)
    property int previewItemWidth: 0
    
    // Default pinned apps to use if no saved settings exist
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
            "net.lutris.davinci-resolve-studio-20-1.desktop",
            "AffinityPhoto.desktop",
            "ptyxis"
    ]
    
    // Pinned apps list - will be loaded from file
    property var pinnedApps: []
    
    // Debug pinnedApps changes
    onPinnedAppsChanged: {
        // console.log("[DOCK DEBUG] pinnedApps changed to:", JSON.stringify(pinnedApps))
    }
    
    // Settings file path
    property string configFilePath: `${Quickshell.configDir}/dock_config.json`
    
    // Map desktop IDs to executable commands
    readonly property var desktopIdToCommand: ({
        // Nautilus variations
        "org.gnome.Nautilus": "nautilus --new-window",
        "org.gnome.nautilus": "nautilus --new-window",
        "nautilus": "nautilus --new-window",
        "Nautilus": "nautilus --new-window",
        
        // Ptyxis variations
        "org.gnome.Ptyxis.desktop": "ptyxis",
        "org.gnome.Ptyxis": "ptyxis",
        "ptyxis": "ptyxis",
        
        // Other apps
        "vesktop": "vesktop --new-window",
        "microsoft-edge-dev": "microsoft-edge-dev --new-window",
        "steam-native": "steam-native -newbigpicture",
        "lutris": "lutris",
        "heroic": "heroic",
        "obs": "obs",
        "com.blackmagicdesign.resolve": "resolve",
        "net.lutris.davinci-resolve-studio-20-1.desktop": "gtk-launch net.lutris.davinci-resolve-studio-20-1.desktop",
        "AffinityPhoto": "AffinityPhoto",
        "AffinityPhoto.desktop": "gtk-launch AffinityPhoto.desktop",
        "AffinityDesigner": "AffinityDesigner",
        "AffinityDesigner.desktop": "gtk-launch AffinityDesigner.desktop"
    })
    
    // Watch for changes in blur settings
    Connections {
        target: AppearanceSettingsState
        function onDockBlurAmountChanged() {
            // Update Hyprland blur rules for dock
            if (AppearanceSettingsState.blurEnabled) {
                Hyprland.dispatch(`setvar decoration:blur:size ${AppearanceSettingsState.dockBlurAmount}`)
            }
            // Reload Quickshell - this might be for other theming aspects tied to blur amount
            Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
        }
        function onDockBlurPassesChanged() {
            if (AppearanceSettingsState.blurEnabled) {
                Hyprland.dispatch(`setvar decoration:blur:passes ${AppearanceSettingsState.dockBlurPasses}`)
            }
            // Reload Quickshell - this might be for other theming aspects
            Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
        }
        function onDockTransparencyChanged() {
            // Reload Quickshell
            Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
        }
        // Add onBlurEnabledChanged if needed to unset layerrule or disable blur
        function onBlurEnabledChanged() {
            if (!AppearanceSettingsState.blurEnabled) {
                // This will remove the blur rule for the dock if blur is globally disabled
                Hyprland.dispatch(`layerrule unset,^(quickshell:dock:blur)$`)
            } else {
                // This will re-apply blur rules if blur is re-enabled
                // AppearanceSettingsState.updateDockBlurSettings() should handle this if called
                // For now, just ensure size and passes are set if blur is on
                Hyprland.dispatch(`setvar decoration:blur:size ${AppearanceSettingsState.dockBlurAmount}`)
                Hyprland.dispatch(`setvar decoration:blur:passes ${AppearanceSettingsState.dockBlurPasses}`)
                Hyprland.dispatch(`layerrule blur,^(quickshell:dock:blur)$`)
            }
             Hyprland.dispatch("exec killall -SIGUSR2 quickshell")
        }
    }
    
    // Watch for changes in icon theme
    Connections {
        target: IconTheme
        function onIconThemeChanged() {
            console.log("[DOCK DEBUG] Icon theme changed, reloading dock");
            // Force a reload of the dock by toggling visibility
            dockRoot.visible = false;
            Qt.callLater(function() {
                dockRoot.visible = true;
            });
        }
    }
    
    // FileView to monitor Qt6 theme settings changes
    FileView {
        id: qt6SettingsView
        path: Qt.binding(() => Qt.getenv("HOME") + "/.config/qt6ct/qt6ct.conf")
        
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
                    // Refresh themes when we first load
                    IconTheme.refreshThemes();
                } else if (lastTheme !== currentTheme) {
                    // console.log("[DOCK DEBUG] Qt6 theme changed from", lastTheme, "to", currentTheme);
                    lastTheme = currentTheme;
                    
                    // Update the theme in the icon system
                    IconTheme.setCurrentTheme(currentTheme);
                    
                    // Refresh the available themes
                    IconTheme.refreshThemes();
                    
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
        id: qt6ThemeCheckTimer
        interval: 2000 // Check every 2 seconds for theme changes
        repeat: true
        running: true
        
        onTriggered: {
            // Reload the Qt6 settings file to check for changes
            try {
                qt6SettingsView.reload();
            } catch (e) {
                // console.log("[DOCK DEBUG] Error reloading Qt6 settings:", e);
            }
        }
    }
    
    function saveConfig() {
        var config = {
            pinnedApps: pinnedApps,
            autoHide: autoHide
        }
        dockConfigView.setText(JSON.stringify(config, null, 2))
    }
    
    function savePinnedApps() {
        saveConfig()
    }
    
    // Toggle dock auto-hide (exclusive mode)
    function toggleDockExclusive() {
        // Toggle auto-hide state
        autoHide = !autoHide
        
        // If we're toggling to pinned mode (auto-hide off), ensure the dock is visible
        if (!autoHide) {
            // Force show the dock
            if (dockContainer) {
                dockContainer.y = dockRoot.height - dockHeight
                // Stop any hide timers
                hideTimer.stop()
            }
        }
        
        // Save the configuration
        saveConfig()
    }
    
    // Add a new app to pinned apps
    function addPinnedApp(appClass) {
        // Map window class to desktop file if known
        var windowClassToDesktopFile = {
            "photo.exe": "AffinityPhoto.desktop",
            "Photo.exe": "AffinityPhoto.desktop",
            "designer.exe": "AffinityDesigner.desktop",
            "Designer.exe": "AffinityDesigner.desktop"
            // Add more mappings as needed
        };
        var toPin = windowClassToDesktopFile[appClass] || appClass;
        // Check if app is already pinned
        if (!pinnedApps.includes(toPin)) {
            // Create a new array to trigger QML reactivity
            var newPinnedApps = pinnedApps.slice()
            newPinnedApps.push(toPin)
            pinnedApps = newPinnedApps
            savePinnedApps()
        }
    }
    
    // Remove an app from pinned apps
    function removePinnedApp(appClass) {
        var index = pinnedApps.indexOf(appClass)
        if (index !== -1) {
            var newPinnedApps = pinnedApps.slice()
            newPinnedApps.splice(index, 1)
            pinnedApps = newPinnedApps
            savePinnedApps()
        }
    }
    
    // Reorder pinned apps (for drag and drop)
    function reorderPinnedApp(fromIndex, toIndex) {
        console.log("reorderPinnedApp called with fromIndex:", fromIndex, "toIndex:", toIndex)
        console.log("Current pinnedApps:", JSON.stringify(pinnedApps))
        
        if (fromIndex === toIndex || fromIndex < 0 || toIndex < 0 || 
            fromIndex >= pinnedApps.length || toIndex >= pinnedApps.length) {
            console.log("Invalid indices, aborting reorder")
            return
        }
        
        var newPinnedApps = pinnedApps.slice()
        var item = newPinnedApps.splice(fromIndex, 1)[0]
        newPinnedApps.splice(toIndex, 0, item)
        pinnedApps = newPinnedApps
        
        console.log("New pinnedApps:", JSON.stringify(pinnedApps))
        savePinnedApps()
    }
    
    // FileView for persistence
    FileView {
        id: dockConfigView
        path: configFilePath
        
        onLoaded: {
            try {
                const fileContents = dockConfigView.text()
                // console.log("[DOCK DEBUG] Raw config file contents:", fileContents)
                const config = JSON.parse(fileContents)
                // console.log("[DOCK DEBUG] Parsed config:", JSON.stringify(config))
                if (config) {
                    // Load pinned apps
                    if (config.pinnedApps) {
                        // Migrate any known window class to desktop file name
                        var windowClassToDesktopFile = {
                            "photo.exe": "AffinityPhoto.desktop",
                            "Photo.exe": "AffinityPhoto.desktop",
                            "designer.exe": "AffinityDesigner.desktop",
                            "Designer.exe": "AffinityDesigner.desktop"
                            // Add more mappings as needed
                        };
                        var migratedPinnedApps = config.pinnedApps.map(function(app) {
                            return windowClassToDesktopFile[app] || app;
                        });
                        // console.log("[DOCK DEBUG] Migrated pinnedApps:", JSON.stringify(migratedPinnedApps))
                        dock.pinnedApps = migratedPinnedApps
                        // console.log("[DOCK DEBUG] pinnedApps after setting:", JSON.stringify(dock.pinnedApps))
                    }
                    
                    // Load auto-hide setting if available
                    if (config.autoHide !== undefined) {
                        dock.autoHide = config.autoHide
                    }
                }
                console.log("[Dock] Config loaded")
            } catch (e) {
                console.log("[Dock] Error parsing config: " + e)
                // Initialize with defaults on parsing error
                dock.pinnedApps = defaultPinnedApps
                savePinnedApps()
            }
        }
        
        onLoadFailed: (error) => {
            console.log("[Dock] Config load failed: " + error)
            // Initialize with defaults if file doesn't exist
            dock.pinnedApps = defaultPinnedApps
            savePinnedApps()
        }
    }
    
    Component.onCompleted: {
        // Load config when component is ready
        dockConfigView.reload()
        
        // Apply initial blur settings
        Hyprland.dispatch(`keyword decoration:blur:passes ${AppearanceSettingsState.dockBlurPasses}`)
        Hyprland.dispatch(`keyword decoration:blur:size ${AppearanceSettingsState.dockBlurAmount}`)
        
        // Debug: Show what's in pinnedApps
        // console.log("[DOCK DEBUG] Dock component completed")
        // console.log("[DOCK DEBUG] pinnedApps:", JSON.stringify(pinnedApps))
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
                bottom: 2
                left: 0
                right: 0
            }
            property ShellScreen modelData
            
            screen: modelData
            WlrLayershell.namespace: "quickshell:dock:blur"
            implicitHeight: dockHeight
            implicitWidth: dockContainer.implicitWidth
            color: "transparent"

            // Basic configuration
            WlrLayershell.layer: WlrLayer.Top
            exclusiveZone: dockHeight
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            mask: Region {
                item: Rectangle {
                    width: dockContent.width
                    height: dockContent.height
                    x: dockContent.x + (dockRoot.width - dockContent.width) / 2
                    y: dockContent.y
                }
            }

            // Track active windows
            property var activeWindows: []
            
            // Helper function for controlled logging
            function log(level, message) {
                if (!ConfigOptions?.logging?.enabled) return
                if (level === "debug" && !ConfigOptions?.logging?.debug) return
                if (level === "info" && !ConfigOptions?.logging?.info) return
                if (level === "warning" && !ConfigOptions?.logging?.warning) return
                if (level === "error" && !ConfigOptions?.logging?.error) return
                console.log(`[Dock][${level.toUpperCase()}] ${message}`)
            }
            
            // Update when window list changes
            Connections {
                target: HyprlandData
                function onWindowListChanged() { 
                    // console.log("[DOCK DEBUG] Window list changed event received")
                    // console.log("[DOCK DEBUG] Current window list:", JSON.stringify(HyprlandData.windowList.map(w => w.class)))
                    log("debug", "Window list changed, updating active windows")
                    updateActiveWindows() 
                }
            }
            
            Component.onCompleted: {
                // console.log("[DOCK DEBUG] Dock component completed, initializing...")
                // console.log("[DOCK DEBUG] Initial window list:", JSON.stringify(HyprlandData.windowList.map(w => w.class)))
                log("info", "Dock component completed, initializing...")
                updateActiveWindows()
            }
            
            function updateActiveWindows() {
                // console.log("[DOCK DEBUG] updateActiveWindows called")
                // console.log("[DOCK DEBUG] Current monitor:", modelData.name)
                // console.log("[DOCK DEBUG] All windows:", JSON.stringify(HyprlandData.windowList.map(w => ({class: w.class, monitor: w.monitor}))))
                
                // Show apps from ALL monitors/workspaces instead of filtering by current monitor
                const windows = HyprlandData.windowList.filter(window => 
                    window.class && window.class.length > 0  // Only filter out windows without a valid class
                )
                
                // console.log("[DOCK DEBUG] All windows across all monitors:", JSON.stringify(windows.map(w => w.class)))
                
                if (JSON.stringify(windows) !== JSON.stringify(activeWindows)) {
                    log("debug", `Updating active windows: ${windows.length} windows found`)
                    log("debug", `Window list: ${JSON.stringify(windows.map(w => w.class))}`)
                    activeWindows = windows
                }
            }
            
            function getIconForClass(windowClass) {
                // Special handling for Affinity Designer and Affinity Photo
                if (windowClass === 'designer.exe' || windowClass === 'Designer.exe') {
                    windowClass = 'AffinityDesigner.desktop';
                }
                if (windowClass === 'photo.exe' || windowClass === 'Photo.exe') {
                    windowClass = 'AffinityPhoto.desktop';
                }
                if (windowClass.endsWith('.desktop')) {
                    // Try user applications first, then system applications
                    var userPath = Qt.getenv("HOME") + "/.local/share/applications/" + windowClass
                    var systemPath = "/usr/share/applications/" + windowClass
                    var fileView = Qt.createQmlObject('import Quickshell.Io; FileView { }', dock)
                    var content = ""
                    try {
                        fileView.path = userPath
                        content = fileView.text()
                    } catch (e) {
                        try {
                            fileView.path = systemPath
                            content = fileView.text()
                        } catch (e2) {
                            fileView.destroy()
                            return windowClass.toLowerCase()
                        }
                    }
                    // Parse the desktop file to find Icon line
                    var lines = content.split('\n')
                    for (var i = 0; i < lines.length; i++) {
                        var line = lines[i].trim()
                        if (line.startsWith('Icon=')) {
                            var iconName = line.substring(5)
                            fileView.destroy()
                            var resolvedIcon = IconTheme.getIconPath(iconName) || iconName
                            // console.log('[DOCK DEBUG] getIconForClass:', windowClass, 'Icon entry:', iconName, 'Resolved icon:', resolvedIcon)
                            return resolvedIcon
                        }
                    }
                    fileView.destroy()
                    return windowClass.toLowerCase()
                }
                var resolvedIcon = IconTheme.getIconPath(windowClass) || windowClass.toLowerCase()
                // console.log('[DOCK DEBUG] getIconForClass:', windowClass, 'Resolved icon:', resolvedIcon)
                return resolvedIcon
            }
            
            function isWindowActive(windowClass) {
                // Map .desktop files to possible window classes and vice versa
                var mapping = {
                    'AffinityPhoto.desktop': ['photo.exe', 'Photo.exe', 'affinityphoto', 'AffinityPhoto'],
                    'AffinityDesigner.desktop': ['designer.exe', 'Designer.exe', 'affinitydesigner', 'AffinityDesigner'],
                        'microsoft-edge-dev': ['microsoft-edge-dev', 'msedge', 'edge'],
                        'vesktop': ['vesktop', 'discord'],
                        'steam-native': ['steam', 'steam.exe'],
                        'org.gnome.nautilus': ['nautilus', 'org.gnome.nautilus'],
                        'lutris': ['lutris', 'net.lutris.lutris'],
                        'heroic': ['heroic', 'heroicgameslauncher'],
                        'obs': ['obs', 'com.obsproject.studio'],
                        'ptyxis': ['ptyxis', 'org.gnome.ptyxis'],
                        'net.lutris.davinci-resolve-studio-20-1.desktop': ['davinci-resolve-studio-20', 'DaVinci Resolve Studio 20', 'resolve', 'com.blackmagicdesign.resolve']
                    };
                var targetClass = windowClass.toLowerCase();
                var possibleClasses = [targetClass];
                // If the pinned app is a .desktop file and has a mapping, add those classes
                if (mapping[windowClass]) {
                    possibleClasses = possibleClasses.concat(mapping[windowClass].map(c => c.toLowerCase()));
                }
                // If the pinned app is a window class and is mapped from a .desktop, add that .desktop
                for (var key in mapping) {
                    if (mapping[key].map(c => c.toLowerCase()).includes(targetClass)) {
                        possibleClasses.push(key.toLowerCase());
                    }
                }
                return activeWindows.some(w => possibleClasses.includes(w.class.toLowerCase()));
            }
            
            function focusOrLaunchApp(appInfo) {
                if (isWindowActive(appInfo.class)) {
                    Hyprland.dispatch(`focuswindow class:${appInfo.class}`)
                } else {
                    let cmd;
                    if (appInfo.class.endsWith('.desktop')) {
                        // For .desktop files, extract the actual Exec command
                        cmd = dock.getDesktopFileExecCommand(appInfo.class);
                        if (!cmd) {
                            // Fallback to gio launch if we can't parse the desktop file
                            cmd = `gio launch ${Qt.getenv("HOME")}/.local/share/applications/${appInfo.class} || gio launch /usr/share/applications/${appInfo.class}`;
                        }
                    } else {
                        // For regular apps, use mapping or fallback
                        cmd = desktopIdToCommand[appInfo.class] || appInfo.class.toLowerCase();
                    }
                    Hyprland.dispatch(`exec ${cmd}`)
                }
            }

            anchors.left: false
            anchors.right: false
            anchors.top: false
            anchors.bottom: true

            Item {
                id: fullContainer
                anchors.fill: parent

                Item {
                    id: dockContainer
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    implicitWidth: dockContent.width
                    height: dockHeight

                    Rectangle {
                        id: dockContent
                        width: dockItemsLayout.width + (dockHeight * 0.5)
                        height: parent.height
                        anchors.centerIn: parent
                        radius: 30
                        color: Qt.rgba(
                            Appearance.colors.colLayer0.r,
                            Appearance.colors.colLayer0.g,
                            Appearance.colors.colLayer0.b,
                            1 - AppearanceSettingsState.dockTransparency
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

                        // Border
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: "black"
                            border.width: 2.5
                            radius: parent.radius
                        }

                        // Main dock layout
                        GridLayout {
                            id: dockItemsLayout
                            anchors.centerIn: dockContent
                            rowSpacing: 0
                            columnSpacing: 4
                            flow: GridLayout.LeftToRight
                            columns: -1
                            rows: 1

                            // Arch menu button (replacing the pin/unpin button)
                            Item {
                                Layout.preferredWidth: dock.dockWidth - 10
                                Layout.preferredHeight: dock.dockWidth - 10
                                Layout.leftMargin: 0 // Remove left margin completely
                                
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
                                    Image {
                                        anchors.centerIn: parent
                                        source : StandardPaths.writableLocation(StandardPaths.ConfigLocation) + "/quickshell/logo/Arch-linux-logo.png"
                                        width: parent.width * 0.65
                                        height: parent.height * 0.65
                                        fillMode: Image.PreserveAspectFit
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
                                    icon: modelData  // Pass raw class name to SystemIcon
                                    tooltip: modelData  // Use the app class name for pinned apps
                                    isActive: dockRoot.isWindowActive(modelData)
                                    isPinned: true
                                    appInfo: ({
                                        class: modelData,
                                        command: modelData.toLowerCase()
                                    })
                                    onClicked: {
                                        // console.log("[DOCK DEBUG] Clicked pinned app:", modelData);
                                        
                                        // Build mapping for .desktop files to possible window classes
                                        var mapping = {
                                            'AffinityPhoto.desktop': ['photo.exe', 'Photo.exe', 'affinityphoto', 'AffinityPhoto'],
                                            'AffinityDesigner.desktop': ['designer.exe', 'Designer.exe', 'affinitydesigner', 'AffinityDesigner'],
                                            'microsoft-edge-dev': ['microsoft-edge-dev', 'msedge', 'edge'],
                                            'vesktop': ['vesktop', 'discord'],
                                            'steam-native': ['steam', 'steam.exe'],
                                            'org.gnome.Nautilus': ['nautilus', 'org.gnome.nautilus'],
                                            'lutris': ['lutris', 'net.lutris.lutris'],
                                            'heroic': ['heroic', 'heroicgameslauncher'],
                                            'obs': ['obs', 'com.obsproject.studio'],
                                            'ptyxis': ['ptyxis', 'org.gnome.ptyxis'],
                                            'net.lutris.davinci-resolve-studio-20-1.desktop': ['davinci-resolve-studio-20', 'DaVinci Resolve Studio 20', 'resolve', 'com.blackmagicdesign.resolve']
                                        };
                                        
                                        // Build list of possible window classes for this pinned app
                                        var possibleClasses = [modelData.toLowerCase()];
                                        if (mapping[modelData]) {
                                            possibleClasses = possibleClasses.concat(mapping[modelData].map(c => c.toLowerCase()));
                                        }
                                        
                                        // Find the window for this pinned app across all monitors/workspaces
                                        var targetWindow = HyprlandData.windowList.find(w => 
                                            possibleClasses.includes(w.class.toLowerCase()) ||
                                            possibleClasses.includes(w.initialClass.toLowerCase())
                                        )
                                        // console.log("[DOCK DEBUG] Found target window:", targetWindow ? targetWindow.class : "none");
                                        
                                        if (targetWindow) {
                                            // console.log("[DOCK DEBUG] Window exists, focusing it");
                                            // If window exists, focus it and switch to its workspace
                                            if (targetWindow.address) {
                                                Hyprland.dispatch(`focuswindow address:${targetWindow.address}`)
                                                
                                                // Switch to the workspace containing the window
                                                if (targetWindow.workspace && targetWindow.workspace.id) {
                                                    Hyprland.dispatch(`workspace ${targetWindow.workspace.id}`)
                                                }
                                            } else {
                                                // Fallback to focusing by class
                                                Hyprland.dispatch(`focuswindow class:${targetWindow.class}`)
                                            }
                                        } else {
                                            // console.log("[DOCK DEBUG] No window exists, launching app");
                                            // If no window exists, launch the app
                                            if (modelData.endsWith('.desktop')) {
                                                let entry = DesktopEntries.applications[modelData];
                                                if (!entry) {
                                                    // console.log('[DOCK DEBUG] DesktopEntries.applications keys:', Object.keys(DesktopEntries.applications));
                                                }
                                                if (entry && entry.execute) {
                                                    entry.execute();
                                                } else {
                                                    Hyprland.dispatch(`exec gio launch ${Qt.getenv("HOME")}/.local/share/applications/${modelData} || gio launch /usr/share/applications/${modelData}`);
                                                }
                                            } else {
                                                let cmd = dock.desktopIdToCommand[modelData] || modelData.toLowerCase();
                                                // console.log("[DOCK DEBUG] Launching app:", modelData);
                                                // console.log("[DOCK DEBUG] Command:", cmd);
                                                Hyprland.dispatch(`exec ${cmd}`)
                                            }
                                        }
                                    }
                                    onUnpinApp: {
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
                                    var nonPinnedApps = []
                                    // console.log("[DOCK DEBUG] Active windows count:", dockRoot.activeWindows.length)
                                    // console.log("[DOCK DEBUG] Active windows:", JSON.stringify(dockRoot.activeWindows.map(w => w.class)))
                                    // console.log("[DOCK DEBUG] Pinned apps:", JSON.stringify(dock.pinnedApps))
                                    // Build a mapping for .desktop files to possible window classes
                                    var mapping = {
                                        'AffinityPhoto.desktop': ['photo.exe', 'Photo.exe', 'affinityphoto', 'AffinityPhoto'],
                                        'AffinityDesigner.desktop': ['designer.exe', 'Designer.exe', 'affinitydesigner', 'AffinityDesigner'],
                                        'microsoft-edge-dev': ['microsoft-edge-dev', 'msedge', 'edge'],
                                        'vesktop': ['vesktop', 'discord'],
                                        'steam-native': ['steam', 'steam.exe'],
                                        'org.gnome.nautilus': ['nautilus', 'org.gnome.nautilus'],
                                        'lutris': ['lutris', 'net.lutris.lutris'],
                                        'heroic': ['heroic', 'heroicgameslauncher'],
                                        'obs': ['obs', 'com.obsproject.studio'],
                                        'ptyxis': ['ptyxis', 'org.gnome.ptyxis'],
                                        'net.lutris.davinci-resolve-studio-20-1.desktop': ['davinci-resolve-studio-20', 'DaVinci Resolve Studio 20', 'resolve', 'com.blackmagicdesign.resolve']
                                    };
                                    // Build a set of all window classes covered by pinned apps
                                    var pinnedClasses = new Set()
                                    for (var i = 0; i < dock.pinnedApps.length; i++) {
                                        var pin = dock.pinnedApps[i]
                                        pinnedClasses.add(pin.toLowerCase())
                                        if (mapping[pin]) {
                                            mapping[pin].forEach(function(cls) {
                                                pinnedClasses.add(cls.toLowerCase())
                                            })
                                        }
                                    }
                                    for (var i = 0; i < dockRoot.activeWindows.length; i++) {
                                        var activeWindow = dockRoot.activeWindows[i]
                                        if (!pinnedClasses.has(activeWindow.class.toLowerCase())) {
                                            nonPinnedApps.push(activeWindow)
                                        }
                                    }
                                    // console.log("[DOCK DEBUG] Non-pinned apps found:", JSON.stringify(nonPinnedApps.map(w => w.class)))
                                    return nonPinnedApps
                                }
                                
                                DockItem {
                                    icon: modelData.class  // Pass raw class name to SystemIcon
                                    tooltip: modelData.title || modelData.class
                                    isActive: true
                                    isPinned: false
                                    appInfo: modelData
                                    Component.onCompleted: {
                                        // console.log("[DOCK DEBUG] Unpinned DockItem created for class:", modelData.class, "icon property set to:", icon);
                                    }
                                    
                                    onClicked: {
                                        // console.log("[DOCK DEBUG] Clicked unpinned app:", modelData.class);
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
                                Layout.preferredWidth: mediaComponent.implicitWidth + 40 // Add extra space for album art
                                Layout.preferredHeight: dockHeight * 0.65
                                Layout.rightMargin: dockHeight * 0.25

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

    // Function to extract Exec command from desktop file
    function getDesktopFileExecCommand(desktopFileName) {
        try {
            // Try user applications first, then system applications
            var userPath = Qt.getenv("HOME") + "/.local/share/applications/" + desktopFileName
            var systemPath = "/usr/share/applications/" + desktopFileName
            
            var fileView = Qt.createQmlObject('import Quickshell.Io; FileView { }', dock)
            
            // Try user path first
            fileView.path = userPath
            var content = ""
            try {
                content = fileView.text()
            } catch (e) {
                // Try system path if user path fails
                fileView.path = systemPath
                content = fileView.text()
            }
            
            // Parse the desktop file to find Exec line
            var lines = content.split('\n')
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim()
                if (line.startsWith('Exec=')) {
                    var execCommand = line.substring(5) // Remove 'Exec=' prefix
                    // console.log("[DOCK DEBUG] Found Exec command for", desktopFileName + ":", execCommand)
                    fileView.destroy()
                    return execCommand
                }
            }
            
            fileView.destroy()
            // console.log("[DOCK DEBUG] No Exec command found in", desktopFileName)
            return ""
        } catch (e) {
            // console.log("[DOCK DEBUG] Error reading desktop file", desktopFileName + ":", e)
            return ""
        }
    }

    // Manual function to force refresh all icons (useful for testing)
    function forceRefreshIcons() {
        // console.log("[DOCK DEBUG] Manually forcing icon refresh");
        
        // Refresh the theme discovery system
        IconTheme.refreshThemes();
        
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

    // Background blur system - static blur approach inspired by Blur My Shell
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
            radius: 30
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
            
            // Border to cover blur edge artifacts
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.width: 2.5
                border.color: "black" // Or use Qt.rgba(0,0,0,0.5) for a softer look
                radius: parent.radius
                z: 2
            }
        }
        
        // Mask to match dock shape
        mask: Region {
            item: Rectangle {
                width: dockContent.width
                height: dockContent.height
                x: dockContent.x + (dockRoot.width - dockContent.width) / 2
                y: dockContent.y
                radius: 30
            }
        }
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
                if (dockContextMenu.contextIsPinned) dock.removePinnedApp(dockContextMenu.contextAppInfo.class)
                else dock.addPinnedApp(dockContextMenu.contextAppInfo.class)
            }
        }
        MenuItem {
            text: qsTr("Launch new instance")
            onTriggered: {
                var command = ""
                if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.class) {
                    if (dockContextMenu.contextAppInfo.class.endsWith('.desktop')) {
                        command = `gio launch ${Qt.getenv("HOME")}/.local/share/applications/${dockContextMenu.contextAppInfo.class} || gio launch /usr/share/applications/${dockContextMenu.contextAppInfo.class}`;
                    } else {
                        var classLower = dockContextMenu.contextAppInfo.class.toLowerCase()
                        var classWithDesktop = dockContextMenu.contextAppInfo.class + ".desktop"
                        if (dock.desktopIdToCommand[dockContextMenu.contextAppInfo.class]) {
                            command = dock.desktopIdToCommand[dockContextMenu.contextAppInfo.class]
                        } else if (dock.desktopIdToCommand[classLower]) {
                            command = dock.desktopIdToCommand[classLower]
                        } else if (dock.desktopIdToCommand[classWithDesktop]) {
                            command = dock.desktopIdToCommand[classWithDesktop]
                        } else {
                            command = dockContextMenu.contextAppInfo.command || dockContextMenu.contextAppInfo.class.toLowerCase()
                        }
                    }
                }
                Hyprland.dispatch(`exec ${command}`)
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
                        console.log("[DOCK MENU DEBUG] Moving window to workspace 1, address:", dockContextMenu.contextAppInfo.address)
                        Hyprland.dispatch(`movetoworkspace 1,address:${dockContextMenu.contextAppInfo.address}`)
                    } else {
                        console.log("[DOCK MENU DEBUG] Cannot move to workspace 1 - missing address:", dockContextMenu.contextAppInfo)
                    }
                }
            }
            MenuItem {
                text: qsTr("Workspace 2")
                enabled: dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address !== undefined
                onTriggered: {
                    if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address) {
                        console.log("[DOCK MENU DEBUG] Moving window to workspace 2, address:", dockContextMenu.contextAppInfo.address)
                        Hyprland.dispatch(`movetoworkspace 2,address:${dockContextMenu.contextAppInfo.address}`)
                    } else {
                        console.log("[DOCK MENU DEBUG] Cannot move to workspace 2 - missing address:", dockContextMenu.contextAppInfo)
                    }
                }
            }
            MenuItem {
                text: qsTr("Workspace 3")
                enabled: dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address !== undefined
                onTriggered: {
                    if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address) {
                        console.log("[DOCK MENU DEBUG] Moving window to workspace 3, address:", dockContextMenu.contextAppInfo.address)
                        Hyprland.dispatch(`movetoworkspace 3,address:${dockContextMenu.contextAppInfo.address}`)
                    } else {
                        console.log("[DOCK MENU DEBUG] Cannot move to workspace 3 - missing address:", dockContextMenu.contextAppInfo)
                    }
                }
            }
            MenuItem {
                text: qsTr("Workspace 4")
                enabled: dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address !== undefined
                onTriggered: {
                    if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address) {
                        console.log("[DOCK MENU DEBUG] Moving window to workspace 4, address:", dockContextMenu.contextAppInfo.address)
                        Hyprland.dispatch(`movetoworkspace 4,address:${dockContextMenu.contextAppInfo.address}`)
                    } else {
                        console.log("[DOCK MENU DEBUG] Cannot move to workspace 4 - missing address:", dockContextMenu.contextAppInfo)
                    }
                }
            }
            MenuItem {
                text: qsTr("Workspace 5")
                enabled: dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address !== undefined
                onTriggered: {
                    if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address) {
                        console.log("[DOCK MENU DEBUG] Moving window to workspace 5, address:", dockContextMenu.contextAppInfo.address)
                        Hyprland.dispatch(`movetoworkspace 5,address:${dockContextMenu.contextAppInfo.address}`)
                    } else {
                        console.log("[DOCK MENU DEBUG] Cannot move to workspace 5 - missing address:", dockContextMenu.contextAppInfo)
                    }
                }
            }
            MenuItem {
                text: qsTr("Workspace 6")
                enabled: dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address !== undefined
                onTriggered: {
                    if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address) {
                        console.log("[DOCK MENU DEBUG] Moving window to workspace 6, address:", dockContextMenu.contextAppInfo.address)
                        Hyprland.dispatch(`movetoworkspace 6,address:${dockContextMenu.contextAppInfo.address}`)
                    } else {
                        console.log("[DOCK MENU DEBUG] Cannot move to workspace 6 - missing address:", dockContextMenu.contextAppInfo)
                    }
                }
            }
            MenuItem {
                text: qsTr("Workspace 7")
                enabled: dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address !== undefined
                onTriggered: {
                    if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address) {
                        console.log("[DOCK MENU DEBUG] Moving window to workspace 7, address:", dockContextMenu.contextAppInfo.address)
                        Hyprland.dispatch(`movetoworkspace 7,address:${dockContextMenu.contextAppInfo.address}`)
                    } else {
                        console.log("[DOCK MENU DEBUG] Cannot move to workspace 7 - missing address:", dockContextMenu.contextAppInfo)
                    }
                }
            }
            MenuItem {
                text: qsTr("Workspace 8")
                enabled: dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address !== undefined
                onTriggered: {
                    if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address) {
                        console.log("[DOCK MENU DEBUG] Moving window to workspace 8, address:", dockContextMenu.contextAppInfo.address)
                        Hyprland.dispatch(`movetoworkspace 8,address:${dockContextMenu.contextAppInfo.address}`)
                    } else {
                        console.log("[DOCK MENU DEBUG] Cannot move to workspace 8 - missing address:", dockContextMenu.contextAppInfo)
                    }
                }
            }
            MenuItem {
                text: qsTr("Workspace 9")
                enabled: dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address !== undefined
                onTriggered: {
                    if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address) {
                        console.log("[DOCK MENU DEBUG] Moving window to workspace 9, address:", dockContextMenu.contextAppInfo.address)
                        Hyprland.dispatch(`movetoworkspace 9,address:${dockContextMenu.contextAppInfo.address}`)
                    } else {
                        console.log("[DOCK MENU DEBUG] Cannot move to workspace 9 - missing address:", dockContextMenu.contextAppInfo)
                    }
                }
            }
            MenuItem {
                text: qsTr("Workspace 10")
                enabled: dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address !== undefined
                onTriggered: {
                    if (dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address) {
                        console.log("[DOCK MENU DEBUG] Moving window to workspace 10, address:", dockContextMenu.contextAppInfo.address)
                        Hyprland.dispatch(`movetoworkspace 10,address:${dockContextMenu.contextAppInfo.address}`)
                    } else {
                        console.log("[DOCK MENU DEBUG] Cannot move to workspace 10 - missing address:", dockContextMenu.contextAppInfo)
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
    }

    function openDockContextMenu(appInfo, isPinned, dockItem, mouse) {
        var finalAppInfo = appInfo
        
        
        // For pinned apps, we need to find the actual window to get the address
        if (isPinned && appInfo && appInfo.class) {
            // Build mapping for .desktop files to possible window classes
            var mapping = {
                'AffinityPhoto.desktop': ['photo.exe', 'Photo.exe', 'affinityphoto', 'AffinityPhoto'],
                'AffinityDesigner.desktop': ['designer.exe', 'Designer.exe', 'affinitydesigner', 'AffinityDesigner'],
                'microsoft-edge-dev': ['microsoft-edge-dev', 'msedge', 'edge'],
                'vesktop': ['vesktop', 'discord'],
                'steam-native': ['steam', 'steam.exe'],
                'org.gnome.Nautilus': ['nautilus', 'org.gnome.nautilus'],
                'lutris': ['lutris', 'net.lutris.lutris'],
                'heroic': ['heroic', 'heroicgameslauncher'],
                'obs': ['obs', 'com.obsproject.studio'],
                'ptyxis': ['ptyxis', 'org.gnome.ptyxis'],
                'net.lutris.davinci-resolve-studio-20-1.desktop': ['davinci-resolve-studio-20', 'DaVinci Resolve Studio 20', 'resolve', 'com.blackmagicdesign.resolve']
            };
            
            // Build list of possible window classes for this pinned app
            var possibleClasses = [appInfo.class.toLowerCase()];
            if (mapping[appInfo.class]) {
                possibleClasses = possibleClasses.concat(mapping[appInfo.class].map(c => c.toLowerCase()));
            }
            
            // Find the window for this pinned app
            var targetWindow = HyprlandData.windowList.find(w => 
                possibleClasses.includes(w.class.toLowerCase()) ||
                possibleClasses.includes(w.initialClass.toLowerCase())
            )
            
            if (targetWindow) {
                // Use the actual window data instead of the simple appInfo
                finalAppInfo = targetWindow
                console.log("[DOCK MENU DEBUG] Found window for pinned app:", targetWindow.class, "address:", targetWindow.address)
            } else {
                console.log("[DOCK MENU DEBUG] No window found for pinned app:", appInfo.class)
            }
        }
        
        // Now set the context with the final app info
        dockContextMenu.contextAppInfo = finalAppInfo
        dockContextMenu.contextIsPinned = isPinned
        dockContextMenu.contextDockItem = dockItem
        
        console.log("[DOCK MENU DEBUG] Opening context menu for app:", dockContextMenu.contextAppInfo ? dockContextMenu.contextAppInfo.class : "null")
        console.log("[DOCK MENU DEBUG] App info:", JSON.stringify(dockContextMenu.contextAppInfo, null, 2))
        console.log("[DOCK MENU DEBUG] Has address:", dockContextMenu.contextAppInfo && dockContextMenu.contextAppInfo.address ? "yes" : "no")
        console.log("[DOCK MENU DEBUG] Address value:", dockContextMenu.contextAppInfo ? dockContextMenu.contextAppInfo.address : "undefined")
        
        // Just open the menu at default position for now
        dockContextMenu.open()
    }

    // --- DOCK APP LIST AND PREVIEW (End4 1:1 port) ---
    DockApps { id: dockApps }
    // --- END DOCK APP LIST AND PREVIEW ---
}
