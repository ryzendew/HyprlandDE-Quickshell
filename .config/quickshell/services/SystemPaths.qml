import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    id: systemPaths
    
    // Base directories using XDG standards
    readonly property string homeDir: StandardPaths.writableLocation(StandardPaths.HomeLocation)
    readonly property string configDir: StandardPaths.writableLocation(StandardPaths.ConfigLocation)
    readonly property string cacheDir: StandardPaths.writableLocation(StandardPaths.CacheLocation)
    readonly property string dataDir: StandardPaths.writableLocation(StandardPaths.GenericDataLocation)
    readonly property string localDataDir: homeDir + "/.local/share"
    
    // Application-specific paths
    readonly property string quickshellConfigDir: configDir + "/quickshell"
    readonly property string quickshellCacheDir: cacheDir + "/quickshell"
    readonly property string quickshellAssetsDir: quickshellConfigDir + "/assets"
    readonly property string quickshellLogoDir: quickshellConfigDir + "/logo"
    
    // Hyprland paths
    readonly property string hyprlandConfigDir: configDir + "/hypr"
    readonly property string hyprlandConfigFile: hyprlandConfigDir + "/hyprland.conf"
    readonly property string hyprlandKeybindsFile: hyprlandConfigDir + "/keybinds.conf"
    
    // Icon theme paths
    readonly property string userIconsDir: localDataDir + "/icons"
    readonly property string systemIconsDir: "/usr/share/icons"
    readonly property list<string> iconSearchPaths: [
        userIconsDir,
        homeDir + "/.icons",
        systemIconsDir,
        "/usr/local/share/icons"
    ]
    
    // Qt6 configuration
    readonly property string qt6ConfigFile: configDir + "/qt6ct/qt6ct.conf"
    
    // Desktop files
    readonly property string userDesktopDir: localDataDir + "/applications"
    readonly property string systemDesktopDir: "/usr/share/applications"
    readonly property list<string> desktopSearchPaths: [
        userDesktopDir,
        systemDesktopDir
    ]
    
    // Network interface detection
    property string detectedWirelessInterface: "wlan0"
    property string detectedEthernetInterface: "eth0"
    
    // Current icon theme
    property string currentIconTheme: ""
    
    // Initialization
    Component.onCompleted: {
        detectNetworkInterfaces()
        detectIconTheme()
    }
    
    // Network interface detection
    function detectNetworkInterfaces() {
        // Detect wireless interface
        const wirelessCmd = "ls /sys/class/net/ | grep -E '^(wlan|wlp|wlx)' | head -1"
        Io.shellCommand(wirelessCmd, (exitCode, stdout) => {
            if (exitCode === 0 && stdout.trim()) {
                detectedWirelessInterface = stdout.trim()
            }
        })
        
        // Detect ethernet interface
        const ethernetCmd = "ls /sys/class/net/ | grep -E '^(eth|enp|ens)' | head -1"
        Io.shellCommand(ethernetCmd, (exitCode, stdout) => {
            if (exitCode === 0 && stdout.trim()) {
                detectedEthernetInterface = stdout.trim()
            }
        })
    }
    
    // Icon theme detection
    function detectIconTheme() {
        // Try to read from Qt6 config first
        try {
            const fileView = Qt.createQmlObject('import Quickshell.Io; FileView { }', this)
            fileView.path = qt6ConfigFile
            const content = fileView.text()
            fileView.destroy()
            
            if (content) {
                const lines = content.split('\n')
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim()
                    if (line.startsWith('icon_theme=')) {
                        currentIconTheme = line.substring(11)
                        return
                    }
                }
            }
        } catch (e) {
            // Qt6 config not available
        }
        
        // Fallback to common themes
        const commonThemes = ["Tela-circle", "Tela-circle-blue", "Tela-circle-blue-dark", "OneUI", "OneUI-dark", "breeze", "breeze-dark"]
        for (const theme of commonThemes) {
            if (iconThemeExists(theme)) {
                currentIconTheme = theme
                return
            }
        }
        
        // Final fallback
        currentIconTheme = "hicolor"
    }
    
    // Check if an icon theme exists
    function iconThemeExists(themeName) {
        for (const basePath of iconSearchPaths) {
            const themePath = basePath + "/" + themeName
            try {
                const fileView = Qt.createQmlObject('import Quickshell.Io; FileView { }', this)
                fileView.path = themePath + "/index.theme"
                const content = fileView.text()
                fileView.destroy()
                if (content && content.length > 0) {
                    return true
                }
            } catch (e) {
                // Theme doesn't exist at this path
            }
        }
        return false
    }
    
    // Get icon path for current theme
    function getIconPath(iconName, size = "scalable") {
        const themePath = userIconsDir + "/" + currentIconTheme + "/" + size + "/apps/" + iconName
        return themePath
    }
    
    // Get application icon path
    function getAppIconPath(appName) {
        // Check if it's a hardcoded path first
        if (appName.startsWith("/") || appName.startsWith("file://")) {
            return appName
        }
        
        // Use current icon theme
        return getIconPath(appName + ".svg")
    }
    
    // Logo path
    function getLogoPath(logoName = "Arch-linux-logo.png") {
        return "file://" + quickshellLogoDir + "/" + logoName
    }
    
    // Asset path
    function getAssetPath(assetName) {
        return "file://" + quickshellAssetsDir + "/" + assetName
    }
} 