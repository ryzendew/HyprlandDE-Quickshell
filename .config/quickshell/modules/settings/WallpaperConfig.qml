import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore
import Qt.labs.platform
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/file_utils.js" as FileUtils

import "root:/services/"

ColumnLayout {
    id: wallpaperConfig
    spacing: 24 * (root.scaleFactor ?? 1.0)
    
    // Responsive scaling properties
    property real scaleFactor: root.scaleFactor ?? 1.0
    property int baseIconSize: 18
    property int baseSpacing: 12
    
    // Wallpaper directory - simple path
    property string wallpaperDir: "~/Pictures/Wallpapers/"
    property var wallpaperFiles: []
    property string currentWallpaper: ""
    
    // Cache properties
    property var cachedWallpapers: []
    property bool cacheValid: false
    property string lastScanTime: ""
    
    // Current wallpaper storage
    property string currentWallpaperFile: "~/.local/state/Quickshell/Wallpapers/current_wallpaper.txt"
    
    // Supported image formats
    property var supportedFormats: ["jpg", "jpeg", "png", "bmp", "webp", "svg"]
    

    
    // Function to set wallpaper using swww
    function setWallpaper(path) {
        if (!path) return
        
        console.log("Setting wallpaper to:", path)
        Hyprland.dispatch(`exec swww img "${path}"`)
        currentWallpaper = path
        
        // Save current wallpaper to file
        saveCurrentWallpaper(path)
    }
    
    // Function to save current wallpaper to file
    function saveCurrentWallpaper(path) {
        const expandedPath = path.replace("~", SystemPaths.homeDir)
        Hyprland.dispatch(`exec bash -c 'echo "${expandedPath}" > ${currentWallpaperFile.replace("~", SystemPaths.homeDir)}'`)
        console.log("Saved current wallpaper to:", currentWallpaperFile)
    }
    
    // Function to load current wallpaper from file
    function loadCurrentWallpaper() {
        const expandedPath = currentWallpaperFile.replace("~", SystemPaths.homeDir)
        Hyprland.dispatch(`exec bash -c 'if [ -f "${expandedPath}" ]; then cat "${expandedPath}"; else echo ""; fi'`)
        
        // Use a timer to read the result
        currentWallpaperTimer.start()
    }
    

    
    // Function to load wallpapers from config file
    function loadWallpapers(forceRefresh = false) {
        console.log("Loading wallpapers from config file, forceRefresh:", forceRefresh)
        
        // If cache is valid and not forcing refresh, use cached data
        if (cacheValid && !forceRefresh && cachedWallpapers.length > 0) {
            console.log("Using cached wallpapers:", cachedWallpapers.length)
            wallpaperFiles = cachedWallpapers
            return
        }
        
        // Clear cache and regenerate config file
        wallpaperFiles = []
        cacheValid = false
        
        // Regenerate the config file to ensure it's up to date
        Hyprland.dispatch(`exec python3 ${SystemPaths.quickshellConfigDir}/scripts/generate_wallpapers_conf.py`)
        
        // Reload the FileView to read the updated config file
        wallpapersFileView.reload()
    }
    

    
    // Function to get current wallpaper from swww
    function getCurrentWallpaper() {
        // Load current wallpaper from saved file
        loadCurrentWallpaper()
    }
    
    // Initialize
    Component.onCompleted: {
        console.log("Initializing wallpaper config...")
        
        // Ensure the wallpaper state directory exists
        Hyprland.dispatch(`exec mkdir -p ~/.local/state/Quickshell/Wallpapers/`)
        
        // Generate the config file if it doesn't exist
        Hyprland.dispatch(`exec python3 ${SystemPaths.quickshellConfigDir}/scripts/generate_wallpapers_conf.py`)
        
        // Load current wallpaper and wallpapers list
        getCurrentWallpaper()
    }
    
    // Timer to read current wallpaper file
    Timer {
        id: currentWallpaperTimer
        interval: 300
        repeat: false
        onTriggered: {
            const expandedPath = currentWallpaperFile.replace("~", SystemPaths.homeDir)
            const fileView = Qt.createQmlObject(`
                import QtQuick
                import Quickshell.Io
                
                FileView { }
            `, wallpaperConfig)
            
            fileView.path = expandedPath
            
            if (fileView) {
                const content = fileView.text()
                if (content && content.trim() !== "") {
                    const wallpaperPath = content.trim()
                    console.log("Loaded current wallpaper from file:", wallpaperPath)
                    currentWallpaper = wallpaperPath
                } else {
                    console.log("No current wallpaper found in file")
                    currentWallpaper = ""
                }
            } else {
                console.log("Failed to read current wallpaper file")
                currentWallpaper = ""
            }
        }
    }
    
    // FileView to read wallpapers config file
    FileView {
        id: wallpapersFileView
        path: "/home/matt/.local/state/Quickshell/Wallpapers/wallpapers.conf"
        
        onLoaded: {
            console.log("Wallpapers config file loaded successfully")
            try {
                const content = text()
                console.log("Config file content length:", content ? content.length : 0)
                
                if (content && content.trim() !== "") {
                    // Parse the config file, skip comment lines
                    const lines = content.trim().split("\n")
                    const files = lines.filter(line => line.trim() !== "" && !line.trim().startsWith("#"))
                    console.log("Found wallpapers:", files.length)
                    
                    // Update cache
                    cachedWallpapers = files
                    cacheValid = true
                    lastScanTime = new Date().toLocaleTimeString()
                    
                    // Update display
                    wallpaperFiles = files
                } else {
                    console.log("No wallpapers found in config file")
                    wallpaperFiles = []
                    cacheValid = false
                }
            } catch (e) {
                console.log("Error parsing wallpapers config file:", e)
                wallpaperFiles = []
                cacheValid = false
            }
        }
        
        onLoadFailed: {
            console.log("Failed to load wallpapers config file, regenerating...")
            // Regenerate the config file and reload
            Hyprland.dispatch(`exec python3 ${SystemPaths.quickshellConfigDir}/scripts/generate_wallpapers_conf.py`)
            cacheValid = false
            reload()
        }
    }
    
    // Header section with current wallpaper
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 140
        radius: 12
        color: "#2a2a2a"
        border.width: 1
        border.color: "#404040"
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16
            
            // Current wallpaper preview
            Rectangle {
                Layout.preferredWidth: 100
                Layout.preferredHeight: 100
                radius: 12
                color: "#1a1a1a"
                border.width: 2
                border.color: "#505050"
                clip: true
                
                Image {
                    id: currentWallpaperImage
                    anchors.fill: parent
                    anchors.margins: 4
                    source: currentWallpaper ? "file://" + currentWallpaper : ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    mipmap: true
                }
                
                // Fallback icon if no wallpaper
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "wallpaper"
                    iconSize: 32
                    color: "#666666"
                    visible: !currentWallpaperImage.source || currentWallpaperImage.status !== Image.Ready
                }
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Text {
                    text: "Current Wallpaper"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: "#ffffff"
                }
                
                Text {
                    text: currentWallpaper ? currentWallpaper.split("/").pop() : "No wallpaper set"
                    font.pixelSize: 14
                    color: "#cccccc"
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
                
                Item { Layout.fillWidth: true }
            }
        }
    }
    
    // Wallpaper grid section
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 12
        color: "#2a2a2a"
        border.width: 1
        border.color: "#404040"
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16
            
            // Grid header with count
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 8
                    color: Appearance.colors.colPrimary
                    
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "grid_view"
                        iconSize: 18
                        color: "#ffffff"
                    }
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    
                    Text {
                        text: "Wallpaper Gallery"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        color: "#ffffff"
                    }
                    
                    Text {
                        text: wallpaperFiles.length > 0 ? `${wallpaperFiles.length} wallpapers available` : "No wallpapers found"
                        font.pixelSize: 12
                        color: "#cccccc"
                    }
                    
                    Text {
                        text: cacheValid ? `Last updated: ${lastScanTime}` : "Scanning..."
                        font.pixelSize: 10
                        color: "#999999"
                        visible: wallpaperFiles.length > 0
                    }
                }
                
                // Refresh button
                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 8
                    color: parent.pressed ? "#3a3a3a" : parent.hovered ? "#4a4a4a" : "#5a5a5a"
                    border.width: 1
                    border.color: "#666666"
                    
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "refresh"
                        iconSize: 18
                        color: "#ffffff"
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: parent.color = "#3a3a3a"
                        onReleased: parent.color = parent.hovered ? "#4a4a4a" : "#5a5a5a"
                        onClicked: loadWallpapers(true)
                    }
                }
            }
            
            // Wallpaper grid
            ScrollView {
                id: gridView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                GridLayout {
                    width: gridView.width
                    columns: Math.floor(gridView.width / 120)
                    rowSpacing: 12
                    columnSpacing: 12
                    
                    Repeater {
                        model: wallpaperFiles
                        
                        // Empty state when no wallpapers
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 100
                            radius: 8
                            color: "#3a3a3a"
                            border.width: 1
                            border.color: "#505050"
                            visible: wallpaperFiles.length === 0
                            
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                
                                MaterialSymbol {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "folder_open"
                                    iconSize: 24
                                    color: "#666666"
                                }
                                
                                Text {
                                    text: "No wallpapers found"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: "#ffffff"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                
                                Text {
                                    text: "Add images to ~/Pictures/Wallpapers/"
                                    font.pixelSize: 11
                                    color: "#cccccc"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                        
                        delegate: Rectangle {
                            Layout.fillWidth: false
                            Layout.preferredWidth: 100
                            Layout.preferredHeight: 100
                            radius: 8
                            color: modelData === currentWallpaper ? "#4a4a4a" : "#3a3a3a"
                            border.width: modelData === currentWallpaper ? 2 : 1
                            border.color: modelData === currentWallpaper ? "#4CAF50" : "#505050"
                            clip: true
                            
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                
                                onEntered: {
                                    if (modelData !== currentWallpaper) {
                                        parent.color = "#454545"
                                    }
                                }
                                
                                onExited: {
                                    if (modelData !== currentWallpaper) {
                                        parent.color = "#3a3a3a"
                                    }
                                }
                                
                                onClicked: {
                                    setWallpaper(modelData)
                                }
                            }
                            
                            // Wallpaper thumbnail (fills entire square)
                            Image {
                                anchors.fill: parent
                                anchors.margins: 2
                                source: "file://" + modelData
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                                mipmap: true
                                
                                // Loading indicator
                                BusyIndicator {
                                    anchors.centerIn: parent
                                    running: parent.status === Image.Loading
                                    width: 20
                                    height: 20
                                }
                                
                                // Current indicator overlay
                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 4
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: modelData === currentWallpaper ? "#4CAF50" : "transparent"
                                    visible: modelData === currentWallpaper
                                    
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "check"
                                        iconSize: 12
                                        color: "#ffffff"
                                    }
                                }
                                
                                // Filename overlay at bottom
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    height: 20
                                    color: Qt.rgba(0, 0, 0, 0.7)
                                    visible: modelData === currentWallpaper
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.split("/").pop().replace(/\.[^/.]+$/, "")
                                        font.pixelSize: 10
                                        color: "#ffffff"
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideMiddle
                                        font.weight: Font.Medium
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
} 