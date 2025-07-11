import QtQuick 2.15
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import QtCore
import "../functions/icon_theme.js" as IconTheme

Item {
    id: root
    
    property string iconName: ""
    property real iconSize: 24
    property color iconColor: "transparent"
    property string fallbackIcon: "gnome-terminal"
    property string resolvedIconPath: ""
    
    // Get user's home directory from QML context using StandardPaths
    readonly property string homeDirectory: {
        var path = StandardPaths.writableLocation(StandardPaths.HomeLocation);
        // console.log("[SYSTEMICON DEBUG] Initialized homeDirectory:", path);
        return path;
    }
    
    width: iconSize
    height: iconSize
    
    // Desktop file reader
    FileView {
        id: desktopFileReader
        onLoaded: {
            parseDesktopFile()
        }
        onLoadFailed: {
            // console.log("[SYSTEMICON DEBUG] Failed to load desktop file:", path)
            updateIconSource() // Try normal resolution if .desktop fails
        }
    }
    
    // Parse desktop file and extract icon
    function parseDesktopFile() {
        try {
            var content = desktopFileReader.text()
            var lines = content.split('\n')
            
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim()
                if (line.startsWith('Icon=')) {
                    var iconValue = line.substring(5).trim()
                    // console.log("[SYSTEMICON DEBUG] Found icon in desktop file:", iconValue)
                    
                    // Check if we have a mapping for this .desktop file
                    var mappedIcon = iconMappings[iconName]
                    if (mappedIcon) {
                        // console.log("[SYSTEMICON DEBUG] Using mapped icon:", mappedIcon, "for:", iconName)
                        resolvedIconPath = IconTheme.getIconPath(mappedIcon, homeDirectory)
                    } else if (iconValue.startsWith('/')) { // Absolute path
                        resolvedIconPath = iconValue
                    } else { // Icon name, resolve it
                        resolvedIconPath = IconTheme.getIconPath(iconValue, homeDirectory)
                    }
                    updateIconSource()
                    return
                }
            }
            
            // console.log("[SYSTEMICON DEBUG] No Icon= line found in desktop file:", desktopFileReader.path)
            resolvedIconPath = "" // Clear if no icon found
            updateIconSource() // Proceed to normal icon resolution
        } catch (e) {
            // console.log("[SYSTEMICON DEBUG] Error parsing desktop file:", e, "Path:", desktopFileReader.path)
            resolvedIconPath = ""
            updateIconSource()
        }
    }
    
    // Simple icon mapping for common cases (fallback)
    property var iconMappings: {
        "cider": "cider", "Cider": "cider", "spotify": "spotify", "obs": "com.obsproject.Studio",
        "vlc": "vlc", "mpv": "mpv", "code": "visual-studio-code", "cursor": "cursor", "Cursor": "cursor", "cursor-cursor": "cursor",
        "firefox": "firefox", "google-chrome": "google-chrome", "chromium": "chromium",
        "microsoft-edge-dev": "microsoft-edge-dev", "microsoft-edge": "microsoft-edge-dev",
        "discord": "discord", "Discord": "discord", "vesktop": "discord", 
        "org.gnome.Nautilus": "system-file-manager", "nautilus": "system-file-manager",
        "org.gnome.Ptyxis": "terminal", "ptyxis": "terminal",
        "net.lutris.davinci-resolve-studio-20-1.desktop": "davinci-resolve",
        "davinci-resolve-studio-20": "davinci-resolve",
        "DaVinci Resolve Studio 20": "davinci-resolve",
        "resolve": "davinci-resolve",
        "com.blackmagicdesign.resolve": "davinci-resolve",
        "better-control": "settings",
        "better_control.py": "settings"
    }
    
    // Map window classes to their corresponding desktop files
    property var windowClassToDesktopFile: {
        "photo.exe": "AffinityPhoto.desktop", "Photo.exe": "AffinityPhoto.desktop",
        "davinci-resolve-studio-20": "net.lutris.davinci-resolve-studio-20-1.desktop",
        "DaVinci Resolve Studio 20": "net.lutris.davinci-resolve-studio-20-1.desktop",
        "resolve": "net.lutris.davinci-resolve-studio-20-1.desktop",
        "com.blackmagicdesign.resolve": "net.lutris.davinci-resolve-studio-20-1.desktop",
        "better_control.py": "better-control.desktop"
    }
    
    // Get the best icon name to use for resolution
    function getBestIconNameToResolve() {
        if (!iconName) return fallbackIcon
        var name = iconName.toString().trim()
        if (!name) return fallbackIcon
        if (iconMappings[name]) return iconMappings[name]
        
        var cleanName = name.replace(/\.desktop$/, "").replace(/\.exe$/, "")
        var variations = [cleanName, cleanName.toLowerCase(), cleanName.charAt(0).toUpperCase() + cleanName.slice(1).toLowerCase()]
        if (name.startsWith("org.")) {
            var parts = name.split(".")
            if (parts.length > 1) { // Use last part for org.xxx.Yyy names
                var lastPart = parts[parts.length - 1]
                variations.push(lastPart)
                variations.push(lastPart.toLowerCase())
            }
        }
        return variations[0]; // Return the primary clean name for IconTheme.js
    }
    
    // Helper to format path for Image.source
    function formatPathForImageSource(rawPath) {
        if (!rawPath || rawPath === "") {
            return "";
        }
        
        if (rawPath.startsWith("/")) {
            // It's an absolute path, ensure it becomes file:///abs/path
            // Triple slash is important for absolute paths.
            return "file://" + rawPath;
        }
        
        if (rawPath.startsWith("file://") || rawPath.startsWith("http://") || rawPath.startsWith("qrc://")) {
            // It already has a scheme, return as is
            return rawPath;
        }
        
        // If it's just an icon name (no path separators), try to resolve it through the icon theme
        if (!rawPath.includes("/") && !rawPath.includes("\\")) {
            var resolvedPath = IconTheme.getIconPath(rawPath, homeDirectory);
            if (resolvedPath && resolvedPath !== "" && resolvedPath !== rawPath) {
                // The icon theme returned a different path, format it
                return formatPathForImageSource(resolvedPath);
            }
        }
        
        // For any other case, return as is
        return rawPath;
    }
    
    // Update icon source based on current state
    function updateIconSource() {
        var sourcePath = "";
        if (resolvedIconPath && resolvedIconPath !== "") {
            sourcePath = resolvedIconPath;
        } else {
            var bestName = getBestIconNameToResolve();
            sourcePath = IconTheme.getIconPath(bestName, homeDirectory);
        }
        if (sourcePath && sourcePath !== "") {
            var formatted = formatPathForImageSource(sourcePath);
            mainIcon.source = formatted;
        } else {
            var fallbackPath = IconTheme.getIconPath(fallbackIcon, homeDirectory);
            var formattedFallback = formatPathForImageSource(fallbackPath);
            mainIcon.source = formattedFallback; // Fallback icon
        }
    }
    
    // Watch for iconName changes
    onIconNameChanged: {
        // console.log("[SYSTEMICON DEBUG] iconName changed to:", iconName)
        resolvedIconPath = "" // Reset resolved path
        
        if (!iconName || iconName.trim() === "") {
            // console.log("[SYSTEMICON DEBUG] iconName is empty, using fallback directly.")
            mainIcon.source = formatPathForImageSource(IconTheme.getIconPath(fallbackIcon, homeDirectory));
            return
        }
        
        var nameToProcess = iconName.toString().trim()
        if (windowClassToDesktopFile[nameToProcess]) {
            nameToProcess = windowClassToDesktopFile[nameToProcess]
            // console.log("[SYSTEMICON DEBUG] Mapped window class", iconName, "to desktop file", nameToProcess)
        }
        
        if (nameToProcess.endsWith('.desktop')) {
            var desktopBasePaths = [
                homeDirectory + "/.local/share/applications",
                "/usr/share/applications",
                "/usr/local/share/applications"
            ];
            var foundDesktopFile = false;
            for (var i = 0; i < desktopBasePaths.length; i++) {
                var potentialPath = desktopBasePaths[i] + "/" + nameToProcess;
                // Check if file exists before attempting to load with FileView
                // This requires a way to check file existence from QML/JS, which is tricky
                // For now, let FileView attempt and handle onLoadFailed
                // console.log("[SYSTEMICON DEBUG] Attempting to load .desktop file:", potentialPath);
                desktopFileReader.path = potentialPath;
                // desktopFileReader.reload(); // This might be problematic if called too rapidly or if path is bad
                // Instead of reload, FileView should auto-load on path change if designed so, or load explicitly if needed.
                // Forcing a reload here without checking existence first could lead to errors if path is invalid.
                // It's safer to let the onLoaded/onLoadFailed handlers manage the next steps.
                // For now, we'll rely on a single attempt or a more robust existence check if available.
                // If FileView doesn't auto-reload, then a manual trigger is needed here.
                // Let's assume FileView is set up to load on path change or use a method if it exists.
                // If not, this logic might need a direct load call or a timer to avoid race conditions.
                // For now, we'll rely on a single attempt or a more robust existence check if available.
                return; // Exit and let FileView callbacks handle it.
            }
             if (!foundDesktopFile) {
                // console.log("[SYSTEMICON DEBUG] No .desktop file found in standard paths for:", nameToProcess);
                updateIconSource(); // Proceed to normal icon resolution if .desktop file not found
            }
        } else {
            updateIconSource() // Not a .desktop file, proceed to normal resolution
        }
    }
    
    Component.onCompleted: {
        // console.log("[SYSTEMICON DEBUG] Component.onCompleted for iconName:", iconName, "homeDirectory is:", homeDirectory);
        // mainIcon.source = "file:///usr/share/icons/hicolor/48x48/apps/utilities-terminal.png"; // REVERTED HARDCODED TEST
        
        // Initialize icon theme system if not already done
        if (!IconTheme.getCurrentTheme()) {
            IconTheme.initializeIconTheme(homeDirectory);
        }
        
        if (iconName && iconName.trim() !== "") {
            iconNameChanged() // Trigger initial icon load
        } else {
             mainIcon.source = formatPathForImageSource(IconTheme.getIconPath(fallbackIcon, homeDirectory)); // Fallback if no iconName
        }
    }
    
    // Main icon image
    Image {
        id: mainIcon
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        smooth: false
        mipmap: true
        sourceSize.width: iconSize * 2
        sourceSize.height: iconSize * 2
        onStatusChanged: {
            // Image status changed
        }
    }
    
    // Color overlay if specified
    ColorOverlay {
        anchors.fill: mainIcon
        source: mainIcon
        color: iconColor
        visible: iconColor !== "transparent"
    }
} 