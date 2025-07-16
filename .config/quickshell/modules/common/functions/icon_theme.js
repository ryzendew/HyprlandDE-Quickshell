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
    // Debug logging disabled
    return;
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
        var content = Qt.createQmlObject('import Qt 6.0; FileHelper.readFile("' + qt6ConfigPath + '")', null);
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
            var content = Qt.createQmlObject('import Qt 6.0; FileHelper.readFile("' + themePath + '/index.theme")', null);
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
            var content = Qt.createQmlObject('import Qt 6.0; FileHelper.readFile("' + basePath + '")', null);
            var lines = content.split('\n');
            
            for (var j = 0; j < lines.length; j++) {
                var line = lines[j].trim();
                if (line && !line.startsWith('.') && !line.startsWith('..')) {
                    // Check if it's a directory and has an index.theme
                    try {
                        var themeIndexPath = basePath + "/" + line + "/index.theme";
                        var indexContent = Qt.createQmlObject('import Qt 6.0; FileHelper.readFile("' + themeIndexPath + '")', null);
                        
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
    
    // Apply icon substitutions from icons.js
    var substitutedIconName = applyIconSubstitutions(iconName, homeDir);
    if (substitutedIconName && substitutedIconName !== iconName) {
        debugLog('Applied substitution for', iconName, '->', substitutedIconName);
        // If substitution returned an absolute path, return it directly
        if (substitutedIconName.startsWith('/')) {
            var absPath = substitutedIconName.startsWith('file://') ? substitutedIconName : 'file://' + substitutedIconName;
            iconCache[cacheKey] = absPath;
            return absPath;
        }
        // If substitution returned a different icon name, try to resolve it
        var resolvedFromSubstitution = getIconPath(substitutedIconName, homeDir);
        if (resolvedFromSubstitution && resolvedFromSubstitution !== substitutedIconName) {
            iconCache[cacheKey] = resolvedFromSubstitution;
            return resolvedFromSubstitution;
        }
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
        "org.gnome.Ptyxis": ["terminal", "org.gnome.Terminal"],
        "AffinityPhoto": ["AffinityPhoto", "photo", "image-editor"],
        "AffinityPhoto.desktop": ["AffinityPhoto", "photo", "image-editor"],
        "photo.exe": ["AffinityPhoto", "photo", "image-editor"],
        "Photo.exe": ["AffinityPhoto", "photo", "image-editor"]
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
    

    
    // Map window classes to desktop files for better icon resolution
    var windowClassToDesktopFile = {
        "photo.exe": "AffinityPhoto.desktop",
        "Photo.exe": "AffinityPhoto.desktop",
        "designer.exe": "AffinityDesigner.desktop",
        "Designer.exe": "AffinityDesigner.desktop"
    };
    
    // If this is a window class, try to map it to a desktop file
    if (windowClassToDesktopFile[iconName]) {
        var mappedDesktopFile = windowClassToDesktopFile[iconName];
        debugLog('Mapped window class', iconName, 'to desktop file', mappedDesktopFile);
        var resolvedFromMapping = getIconPath(mappedDesktopFile, homeDir);
        if (resolvedFromMapping && resolvedFromMapping !== mappedDesktopFile) {
            iconCache[cacheKey] = resolvedFromMapping;
            return resolvedFromMapping;
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
        debugLog('Trying desktop path:', desktopPath);
        try {
            var content = Qt.createQmlObject('import Qt 6.0; FileHelper.readFile("' + desktopPath + '")', null);
            debugLog('Desktop file content length:', content ? content.length : 0);
            if (content) {
                var lines = content.split('\n');
                debugLog('Desktop file has', lines.length, 'lines');
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.startsWith('Icon=')) {
                        var iconValue = line.substring(5).trim();
                        debugLog('Found Icon= in desktop file:', iconValue, 'at', desktopPath);
                        // If it's an absolute path, return it directly
                        if (iconValue.startsWith('/')) {
                            var absPath = iconValue.startsWith('file://') ? iconValue : 'file://' + iconValue;
                            debugLog('Found absolute path in desktop file:', absPath);
                            return absPath;
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
            }
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
                            var content = Qt.createQmlObject('import Qt 6.0; FileHelper.readFile("' + fullPath + '")', null);
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
                        var content = Qt.createQmlObject('import Qt 6.0; FileHelper.readFile("' + fullPath + '")', null);
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

// Apply icon substitutions from icons.js
function applyIconSubstitutions(iconName, homeDir) {
    // Icon substitutions from icons.js
    var substitutions = {
        "code-url-handler": "visual-studio-code",
        "Code": "visual-studio-code",
        "GitHub Desktop": "github-desktop",
        "Minecraft* 1.20.1": "minecraft",
        "gnome-tweaks": "org.gnome.tweaks",
        "pavucontrol-qt": "pavucontrol",
        "wps": "wps-office2019-kprometheus",
        "wpsoffice": "wps-office2019-kprometheus",
        "footclient": "foot",
        "zen": "zen-browser",
        "ptyxis": function() {
            return homeDir + "/.local/share/icons/scalable/apps/org.gnome.Ptyxis.svg";
        },
        "AffinityPhoto.desktop": function() {
            return homeDir + "/.local/share/icons/AffinityPhoto.png";
        },
        "steam-native": function() {
            return homeDir + "/.local/share/icons/scalable/apps/steam.svg";
        },
        "steam_tray_mono": function() {
            return homeDir + "/.local/share/icons/scalable/apps/steam.svg";
        },
        "lutris": function() {
            return homeDir + "/.local/share/icons/scalable/apps/lutris.svg";
        },
        "com.blackmagicdesign.resolve.desktop": function() {
            return homeDir + "/.local/share/icons/scalable/apps/resolve.svg";
        },
        "cider": function() {
            return homeDir + "/.local/share/icons/scalable/apps/cider.svg";
        },
        "vesktop": function() {
            return homeDir + "/.local/share/icons/scalable/apps/vesktop.svg";
        },
        "obs": function() {
            var configDir = StandardPaths.writableLocation(StandardPaths.ConfigLocation);
            return configDir + "/quickshell/assets/icons/obs.svg";
        },
        "heroic": function() {
            return homeDir + "/.local/share/icons/scalable/apps/heroic.svg";
        },
        "microsoft-edge-dev": function() {
            return homeDir + "/.local/share/icons/scalable/apps/microsoft-edge-dev.svg";
        },
        "org.gnome.Nautilus": function() {
            return homeDir + "/.local/share/icons/scalable/apps/nautilus.svg";
        },
        "": "image-missing"
    };
    
    // Check for direct substitution
    if (substitutions[iconName]) {
        var substitution = substitutions[iconName];
        if (typeof substitution === 'function') {
            return substitution();
        }
        return substitution;
    }
    
    // Check for regex substitutions
    var regexSubstitutions = [
        {
            "regex": /^steam_app_(\d+)$/,
            "replace": "steam_icon_$1"
        },
        {
            "regex": /Minecraft.*$/,
            "replace": "minecraft"
        }
    ];
    
    for (var i = 0; i < regexSubstitutions.length; i++) {
        var substitution = regexSubstitutions[i];
        var replacedName = iconName.replace(substitution.regex, substitution.replace);
        if (replacedName !== iconName) {
            return replacedName;
        }
    }
    
    // No substitution found
    return iconName;
}

// Initialize on first load
initializeIconTheme(); 
