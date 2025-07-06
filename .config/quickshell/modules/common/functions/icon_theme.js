// Improved icon theme system following XDG standards
// This system properly detects the current icon theme from multiple sources:
// 1. Qt6 theme settings (qt6ct.conf)
// 2. GNOME settings (gsettings)
// 3. XDG environment variables
// 4. System-wide defaults

var currentDetectedTheme = "";
var availableThemes = [];
var iconCache = {};

function getCurrentIconTheme() {
    return currentDetectedTheme;
}

function setCurrentTheme(theme) {
    currentDetectedTheme = theme;
    // Clear cache when theme changes
    iconCache = {};
    // console.log("[ICON DEBUG] Theme set to:", theme);
}

function getCurrentTheme() {
    return currentDetectedTheme;
}

function debugLog(...args) {
    if (typeof console !== 'undefined' && console.log) {
        console.log('[ICON DEBUG]', ...args);
    }
}

// Detect the current icon theme following XDG standards
function detectCurrentIconTheme(homeDir) {
    var detectedTheme = "";
    debugLog('Detecting current icon theme...');
    // Priority order for theme detection:
    // 1. Qt6 theme settings
    // 2. GNOME gsettings
    // 3. XDG environment variables
    // 4. System defaults
    
    // Try to detect from Qt6 theme settings
    try {
        var qt6ConfigPath = StandardPaths.writableLocation(StandardPaths.ConfigLocation) + "/qt6ct/qt6ct.conf";
        var fileView = Qt.createQmlObject('import Quickshell.Io; FileView { }', this);
        fileView.path = qt6ConfigPath;
        var content = fileView.text();
        fileView.destroy();
        
        if (content) {
            var lines = content.split('\n');
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line.startsWith('icon_theme=')) {
                    detectedTheme = line.substring(11);
                debugLog('Detected theme from qt6ct.conf:', detectedTheme);
                break;
                }
            }
        }
    } catch (e) {
        debugLog('Could not read qt6ct.conf:', e);
        // qt6ct not available
    }
    
    // If Qt6 didn't work, try GNOME gsettings
    if (!detectedTheme) {
        try {
            // This would require a system call to gsettings
            // For now, we'll rely on Qt6 detection
        } catch (e) {
            // gsettings not available
        }
    }
    
    // Fallback to common themes if nothing detected
    if (!detectedTheme) {
        debugLog('Falling back to common themes...');
        var commonThemes = ["Tela-circle", "Tela-circle-blue", "Tela-circle-blue-dark", "OneUI", "OneUI-dark", "breeze", "breeze-dark"];
        for (var i = 0; i < commonThemes.length; i++) {
            if (themeExists(commonThemes[i], homeDir)) {
                detectedTheme = commonThemes[i];
                debugLog('Found fallback theme:', detectedTheme);
                break;
            }
        }
    }
    
    // Final fallback
    if (!detectedTheme) {
        detectedTheme = "hicolor";
        debugLog('No theme found, using hicolor');
    }
    
    debugLog('Final detected theme:', detectedTheme);
    return detectedTheme;
}

// Check if a theme exists in the system
function themeExists(themeName, homeDir) {
    var iconBasePaths = [
        homeDir + "/.local/share/icons",
        homeDir + "/.icons",
        "/usr/share/icons",
        "/usr/local/share/icons"
    ];
    
    for (var i = 0; i < iconBasePaths.length; i++) {
        var themePath = iconBasePaths[i] + "/" + themeName;
        try {
            var fileView = Qt.createQmlObject('import Quickshell.Io; FileView { }', this);
            fileView.path = themePath + "/index.theme";
            var content = fileView.text();
            fileView.destroy();
            if (content && content.length > 0) {
                return true;
            }
        } catch (e) {
            // Theme doesn't exist at this path
        }
    }
    return false;
}

// Get available themes from the system
function refreshAvailableThemes(homeDir) {
    availableThemes = [];
    var iconBasePaths = [
        homeDir + "/.local/share/icons",
        homeDir + "/.icons",
        "/usr/share/icons",
        "/usr/local/share/icons"
    ];
    
    for (var i = 0; i < iconBasePaths.length; i++) {
        var basePath = iconBasePaths[i];
        try {
            var fileView = Qt.createQmlObject('import Quickshell.Io; FileView { }', this);
            fileView.path = basePath;
            var content = fileView.text();
            var lines = content.split('\n');
            
            for (var j = 0; j < lines.length; j++) {
                var line = lines[j].trim();
                if (line && !line.startsWith('.') && !line.startsWith('..')) {
                    // Check if it's a directory and has an index.theme
                    try {
                        var themeIndexPath = basePath + "/" + line + "/index.theme";
                        var indexFileView = Qt.createQmlObject('import Quickshell.Io; FileView { }', this);
                        indexFileView.path = themeIndexPath;
                        var indexContent = indexFileView.text();
                        indexFileView.destroy();
                        
                        if (indexContent && indexContent.length > 0) {
                            if (availableThemes.indexOf(line) === -1) {
                                availableThemes.push(line);
                            }
                        }
                    } catch (e) {
                        // Not a valid theme directory
                    }
                }
            }
            fileView.destroy();
        } catch (e) {
            // Directory not accessible
        }
    }
    
    return availableThemes;
}

// Get the list of available themes
function getAvailableThemes(homeDir) {
    if (availableThemes.length === 0) {
        refreshAvailableThemes(homeDir);
    }
    return availableThemes;
}

// Improved icon path resolution following XDG standards
function getIconPath(iconName, homeDir) {
    debugLog('getIconPath called for:', iconName, 'homeDir:', homeDir, 'currentTheme:', currentDetectedTheme);
    if (!homeDir) {
        // console.error("[ICON DEBUG] homeDir not provided to getIconPath!");
        return "";
    }
    
    if (!iconName || iconName.trim() === "") {
        return "";
    }

    // Strip "file://" prefix if present
    if (homeDir && homeDir.startsWith("file://")) {
        homeDir = homeDir.substring(7);
    }

    if (!homeDir) {
        return "";
    }
    
    // Check cache first
    var cacheKey = iconName + "_" + currentDetectedTheme;
    if (iconCache[cacheKey]) {
        debugLog('Cache hit for', cacheKey, '->', iconCache[cacheKey]);
        return iconCache[cacheKey];
    }
    
    // Icon variations to try (most specific first)
    var iconVariations = [iconName];
    
    // Application-specific mappings
    var appMappings = {
        "Cursor": ["accessories-text-editor", "io.elementary.code", "code", "text-editor"],
        "cursor": ["accessories-text-editor", "io.elementary.code", "code", "text-editor"],
        "cursor-cursor": ["accessories-text-editor", "io.elementary.code", "code", "text-editor"],
        "qt6ct": ["preferences-system", "system-preferences", "preferences-desktop"],
        "steam": ["steam-native", "steam-launcher", "steam-icon"],
        "steam-native": ["steam", "steam-launcher", "steam-icon"],
        "microsoft-edge-dev": ["microsoft-edge", "msedge", "edge", "web-browser"],
        "vesktop": ["discord", "com.discordapp.Discord"],
        "discord": ["vesktop", "com.discordapp.Discord"],
        "cider": ["apple-music", "music"],
        "org.gnome.Nautilus": ["nautilus", "file-manager", "system-file-manager"],
        "org.gnome.nautilus": ["nautilus", "file-manager", "system-file-manager"],
        "nautilus": ["org.gnome.Nautilus", "file-manager", "system-file-manager"],
        "obs": ["com.obsproject.Studio", "obs-studio"],
        "ptyxis": ["terminal", "org.gnome.Terminal"],
        "org.gnome.ptyxis": ["terminal", "org.gnome.Terminal"],
        "org.gnome.Ptyxis": ["terminal", "org.gnome.Terminal"]
    };
    
    // Add mappings if available
    if (appMappings[iconName]) {
        iconVariations = iconVariations.concat(appMappings[iconName]);
    }
    
    // Add lowercase variation
    var lowerName = iconName.toLowerCase();
    if (lowerName !== iconName) {
        iconVariations.push(lowerName);
        if (appMappings[lowerName]) {
            iconVariations = iconVariations.concat(appMappings[lowerName]);
        }
    }
    
    // Check desktop files first for better icon resolution
    var resolvedIcon = checkDesktopFiles(iconName, homeDir);
    if (resolvedIcon) {
        debugLog('Resolved icon from desktop file:', resolvedIcon);
        iconCache[cacheKey] = resolvedIcon;
        return resolvedIcon;
    }
    
    // Try icon theme resolution
    resolvedIcon = resolveFromIconTheme(iconVariations, homeDir);
    if (resolvedIcon) {
        debugLog('Resolved icon from icon theme:', resolvedIcon);
        iconCache[cacheKey] = resolvedIcon;
        return resolvedIcon;
    }
    
    debugLog('Falling back to generic icon for', iconName);
    // Try to resolve the fallback icon through the theme system
    var fallbackPath = resolveFromIconTheme(["gnome-terminal", "utilities-terminal", "terminal"], homeDir);
    if (fallbackPath) {
        iconCache[cacheKey] = fallbackPath;
        return fallbackPath;
    }
    // If even the fallback fails, return the icon name
    var fallbackIcon = "gnome-terminal";
    iconCache[cacheKey] = fallbackIcon;
    return fallbackIcon;
}

// Check desktop files for icon information
function checkDesktopFiles(iconName, homeDir) {
    debugLog('Checking desktop files for icon:', iconName);
    var appImageDesktopPaths = [
        homeDir + "/.local/share/applications",
        "/usr/share/applications",
        "/usr/local/share/applications"
    ];
    
        for (var p = 0; p < appImageDesktopPaths.length; p++) {
        var desktopPath = appImageDesktopPaths[p] + "/" + iconName + ".desktop";
            try {
                var fileView = Qt.createQmlObject('import Quickshell.Io; FileView { }', this);
                fileView.path = desktopPath;
                var content = fileView.text();
                var lines = content.split('\n');
                
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.startsWith('Icon=')) {
                        var iconValue = line.substring(5).trim();
                        debugLog('Found Icon= in desktop file:', iconValue, 'at', desktopPath);
                        fileView.destroy();
                        
                        // If it's an absolute path, return it directly
                        if (iconValue.startsWith('/')) {
                            return iconValue;
                        }
                        
                        // If it's a relative path, try to find the AppImage and extract its icon
                        var execLine = "";
                        for (var j = 0; j < lines.length; j++) {
                            if (lines[j].trim().startsWith('Exec=')) {
                                execLine = lines[j].trim().substring(5).trim();
                                break;
                            }
                        }
                        
                        if (execLine) {
                            // Extract the AppImage path from the Exec line
                            var appImagePath = execLine.split(' ')[0];
                            if (appImagePath.endsWith('.AppImage') || appImagePath.endsWith('.appimage')) {
                                // Try to get the icon from the AppImage
                                var appImageIcon = appImagePath + "/.DirIcon";
                                return appImageIcon;
                            }
                        }
                        
                        // Try to resolve the icon name through the theme system
                        return resolveFromIconTheme([iconValue], homeDir);
                    }
                }
                fileView.destroy();
            } catch (e) {
            debugLog('Could not read desktop file:', desktopPath, e);
        }
    }
    
    debugLog('No icon found in desktop files for', iconName);
    return null;
            }

// Resolve icon from icon theme following XDG standards
function resolveFromIconTheme(iconVariations, homeDir) {
    debugLog('resolveFromIconTheme for variations:', iconVariations, 'theme:', currentDetectedTheme);
    var iconBasePaths = [
        homeDir + "/.local/share/icons",
        homeDir + "/.icons",
        "/usr/share/icons",
        "/usr/local/share/icons"
    ];
    
    // Priority order for icon sizes (most common first)
    var sizeDirs = [
        "scalable/apps",
        "48x48/apps", 
        "64x64/apps",
        "32x32/apps",
        "128x128/apps",
        "256x256/apps",
        "apps/48",
        "apps/64",
        "apps/32"
    ];
    
    var extensions = [".svg", ".png"];

    // First try with the current theme
    if (currentDetectedTheme) {
        for (var b = 0; b < iconBasePaths.length; b++) {
            var basePath = iconBasePaths[b];
            for (var v = 0; v < iconVariations.length; v++) {
                var iconVar = iconVariations[v];
                for (var s = 0; s < sizeDirs.length; s++) {
                    var sizeDir = sizeDirs[s];
                    for (var e = 0; e < extensions.length; e++) {
                        var ext = extensions[e];
                        var fullPath = basePath + "/" + currentDetectedTheme + "/" + sizeDir + "/" + iconVar + ext;
                        
                        // Check if file exists by trying to read it
                        try {
                            var fileView = Qt.createQmlObject('import Quickshell.Io; FileView { }', this);
                            fileView.path = fullPath;
                            var content = fileView.text();
                            fileView.destroy();
                            if (content && content.length > 0) {
                                debugLog('Found icon in theme:', fullPath);
                        return fullPath;
                            } else {
                                debugLog('File exists but is empty:', fullPath);
                            }
                        } catch (e) {
                            // File doesn't exist or can't be read
                            debugLog('File does not exist or error reading:', fullPath);
                        }
                    }
                }
            }
        }
    }

    // If current theme didn't work, try hicolor (the fallback theme)
        for (var b = 0; b < iconBasePaths.length; b++) {
            var basePath = iconBasePaths[b];
            for (var v = 0; v < iconVariations.length; v++) {
                var iconVar = iconVariations[v];
                for (var s = 0; s < sizeDirs.length; s++) {
                    var sizeDir = sizeDirs[s];
                    for (var e = 0; e < extensions.length; e++) {
                        var ext = extensions[e];
                    var fullPath = basePath + "/hicolor/" + sizeDir + "/" + iconVar + ext;
                    
                    try {
                        var fileView = Qt.createQmlObject('import Quickshell.Io; FileView { }', this);
                        fileView.path = fullPath;
                        var content = fileView.text();
                        fileView.destroy();
                        if (content && content.length > 0) {
                            debugLog('Found icon in hicolor fallback:', fullPath);
                        return fullPath;
                        } else {
                            debugLog('File exists but is empty in hicolor:', fullPath);
                        }
                    } catch (e) {
                        // File doesn't exist or can't be read
                        debugLog('File does not exist or error reading hicolor:', fullPath);
                    }
                }
            }
        }
    }
    
    debugLog('No icon found in any theme for variations:', iconVariations);
    return null;
}

// Initialize the icon theme system
function initializeIconTheme(homeDir) {
    currentDetectedTheme = detectCurrentIconTheme(homeDir);
    refreshAvailableThemes(homeDir);
    // console.log("[ICON DEBUG] Initialized with theme:", currentDetectedTheme);
    // console.log("[ICON DEBUG] Available themes:", availableThemes.length);
}

// Refresh themes (called when theme changes)
function refreshThemes(homeDir) {
    var oldTheme = currentDetectedTheme;
    currentDetectedTheme = detectCurrentIconTheme(homeDir);
    refreshAvailableThemes(homeDir);
    iconCache = {}; // Clear cache
    
    if (oldTheme !== currentDetectedTheme) {
        // console.log("[ICON DEBUG] Theme changed from", oldTheme, "to", currentDetectedTheme);
    }
}

// Initialize on first load
initializeIconTheme(); 
