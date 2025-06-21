var currentDetectedTheme = "Tela-circle";

function getCurrentIconTheme() {
    return currentDetectedTheme;
}

function setCurrentTheme(theme) {
    currentDetectedTheme = theme;
    // console.log("[ICON DEBUG] Theme set to:", theme);
}

function getCurrentTheme() {
    return currentDetectedTheme;
}

function getIconPath(iconName, homeDir) {
    if (!homeDir) {
        // console.error("[ICON DEBUG] homeDir not provided to getIconPath!");
        return "";
    }
    
    // console.log("[ICON DEBUG] Getting icon for:", iconName, "with homeDir:", homeDir);
    
    if (!iconName || iconName.trim() === "") {
        return "";
    }

    // Strip "file://" prefix if present
    if (homeDir && homeDir.startsWith("file://")) {
        homeDir = homeDir.substring(7);
    }

    if (!homeDir) {
        // console.error("[ICON DEBUG] homeDir not provided to getIconPath!");
        return ""; // Cannot proceed without homeDir
    }
    
    // console.log("[ICON DEBUG] Getting icon for:", iconName, "with homeDir:", homeDir);
    
    // Icon variations to try (most specific first)
    var iconVariations = [iconName];
    var appMappings = {
        "Cursor": ["accessories-text-editor", "io.elementary.code", "code", "text-editor"],
        "cursor": ["accessories-text-editor", "io.elementary.code", "code", "text-editor"],
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
    
    // Application-specific resource paths
    var appResourcePaths = {
        "Cursor": "/opt/Cursor/resources/app/resources/linux",
        "cursor": "/opt/Cursor/resources/app/resources/linux"
    };
    
    // Check application-specific resource paths first
    for (var v = 0; v < iconVariations.length; v++) {
        var iconVar = iconVariations[v];
        if (appResourcePaths[iconVar]) {
            var resourcePath = appResourcePaths[iconVar];
            // Try both .png and .svg extensions
            var pngPath = resourcePath + "/" + iconVar.toLowerCase() + ".png";
            var svgPath = resourcePath + "/" + iconVar.toLowerCase() + ".svg";
            // Return the first path found
            return pngPath;
        }
    }
    
    if (appMappings[iconName]) {
        iconVariations = iconVariations.concat(appMappings[iconName]);
    }
    var lowerName = iconName.toLowerCase();
    if (lowerName !== iconName) {
        iconVariations.push(lowerName);
        if (appMappings[lowerName]) {
            iconVariations = iconVariations.concat(appMappings[lowerName]);
        }
    }
    
    // Check AppImage desktop files first
    var appImageDesktopPaths = [
        homeDir + "/.local/share/applications",
        "/usr/share/applications",
        "/usr/local/share/applications"
    ];
    
    for (var v = 0; v < iconVariations.length; v++) {
        var iconVar = iconVariations[v];
        for (var p = 0; p < appImageDesktopPaths.length; p++) {
            var desktopPath = appImageDesktopPaths[p] + "/" + iconVar + ".desktop";
            try {
                var fileView = Qt.createQmlObject('import Quickshell.Io; FileView { }', this);
                fileView.path = desktopPath;
                var content = fileView.text();
                var lines = content.split('\n');
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.startsWith('Icon=')) {
                        var iconValue = line.substring(5).trim();
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
                    }
                }
            } catch (e) {
                // Desktop file not found or error reading it, continue to next path
                continue;
            }
        }
    }
    
    var themes = [
        "Tela-circle", "Tela-circle-blue", "Tela-circle-grey", "Tela-circle-manjaro",
        "Tela-circle-nord", "Tela-circle-black", "breeze-plus", "breeze-plus-dark", "breeze", "breeze-dark", "hicolor", "Adwaita"
    ];
    var iconBasePaths = [
        "/usr/share/icons",
        homeDir + "/.local/share/icons",
        homeDir + "/.icons",
        "/usr/share/icons",
        "/usr/local/share/icons"
    ];
    var sizeDirs = ["scalable/apps", "48x48/apps", "64x64/apps", "apps/48", "128x128/apps"];
    var extensions = [".svg", ".png"];

    // First try with the current theme
    var currentTheme = getCurrentTheme();
    if (currentTheme) {
        for (var b = 0; b < iconBasePaths.length; b++) {
            var basePath = iconBasePaths[b];
            for (var v = 0; v < iconVariations.length; v++) {
                var iconVar = iconVariations[v];
                for (var s = 0; s < sizeDirs.length; s++) {
                    var sizeDir = sizeDirs[s];
                    for (var e = 0; e < extensions.length; e++) {
                        var ext = extensions[e];
                        var fullPath = basePath + "/" + currentTheme + "/" + sizeDir + "/" + iconVar + ext;
                        // Let QML handle file existence check via Image.status
                        // console.log("[ICON DEBUG] Trying current theme path:", fullPath);
                        return fullPath;
                    }
                }
            }
        }
    }

    // If current theme didn't work, try all themes
    for (var t = 0; t < themes.length; t++) {
        var theme = themes[t];
        if (theme === currentTheme) continue; // Skip current theme as we already tried it
        
        for (var b = 0; b < iconBasePaths.length; b++) {
            var basePath = iconBasePaths[b];
            for (var v = 0; v < iconVariations.length; v++) {
                var iconVar = iconVariations[v];
                for (var s = 0; s < sizeDirs.length; s++) {
                    var sizeDir = sizeDirs[s];
                    for (var e = 0; e < extensions.length; e++) {
                        var ext = extensions[e];
                        var fullPath = basePath + "/" + theme + "/" + sizeDir + "/" + iconVar + ext;
                        // Let QML handle file existence check via Image.status
                        // console.log("[ICON DEBUG] Trying theme path:", fullPath);
                        return fullPath;
                    }
                }
            }
        }
    }
    
    // console.log("[ICON DEBUG] No specific icon found for:", iconName, ", trying generic fallback.");
    return "/usr/share/icons/breeze/apps/48/applications-other.svg";
}

function refreshThemes() {
    // console.log("[ICON DEBUG] Theme refresh requested (currently no-op)");
} 
