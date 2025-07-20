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
    
    // Wallpaper directory - using same approach as PinnedApps
    property string wallpaperDir: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/Pictures/Wallpapers/"
    property var wallpaperFiles: []
    property string currentWallpaper: ""
    
    // Cache properties
    property var cachedWallpapers: []
    property bool cacheValid: false
    property string lastScanTime: ""
    
    // Current wallpaper storage
    property string currentWallpaperFile: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/state/Quickshell/Wallpapers/current_wallpaper.txt"
    property string wallpapersConfFilePath: `${StandardPaths.writableLocation(StandardPaths.HomeLocation)}/.local/state/Quickshell/Wallpapers/wallpapers.conf`
    
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
    
    // Function to save current wallpaper to file - using same approach as PinnedApps
    function saveCurrentWallpaper(path) {
        const expandedPath = path.replace("~", StandardPaths.writableLocation(StandardPaths.HomeLocation))
        Hyprland.dispatch(`exec echo '${expandedPath.replace(/'/g, "'\"'\"'")}' > '${currentWallpaperFile.replace('file://', '')}'`)
        console.log("Saved current wallpaper to:", currentWallpaperFile)
    }
    
    // Function to load current wallpaper from file - using same approach as PinnedApps
    function loadCurrentWallpaper() {
        Hyprland.dispatch(`exec test -f '${currentWallpaperFile.replace('file://', '')}' && cat '${currentWallpaperFile.replace('file://', '')}' || echo ""`)
        
        // Use a timer to read the result
        currentWallpaperTimer.start()
    }
    

    
    // Function to load wallpapers from config file - ROBUST VERSION
    function loadWallpapers(forceRefresh = false) {
        console.log("Loading wallpapers from config file, forceRefresh:", forceRefresh)
        
        // If cache is valid and not forcing refresh, use cached data
        if (cacheValid && !forceRefresh && cachedWallpapers.length > 0) {
            console.log("Using cached wallpapers:", cachedWallpapers.length)
            wallpaperFiles = cachedWallpapers
            return
        }
        
        // Clear cache
        wallpaperFiles = []
        cacheValid = false
        
        // Just reload the FileView directly without triggering scanning
        console.log("Reloading wallpaper FileView directly")
        wallpapersFileView.reload()
    }
    
    // Step 1: Create the wallpapers config file first - using same approach as PinnedApps
    function createWallpapersConfFile() {
        try {
            console.log("[WALLPAPER DEBUG] Step 1: Creating wallpapers config file...")
            
            // Create the directory if it doesn't exist - same as PinnedApps
            var dirPath = wallpapersConfFilePath.replace('file://', '').replace('/wallpapers.conf', '');
            console.log("[WALLPAPER DEBUG] Creating directory:", dirPath);
            Hyprland.dispatch(`exec mkdir -p '${dirPath}'`);
            
            // Create the wallpaper directory if it doesn't exist
            console.log("[WALLPAPER DEBUG] Creating wallpaper directory:", wallpaperDir.replace('file://', ''))
            Hyprland.dispatch(`exec mkdir -p '${wallpaperDir.replace('file://', '')}'`)
            
            // Create the config file with explicit content - same as PinnedApps
            var content = "# Wallpapers configuration file\n";
            Hyprland.dispatch(`exec echo '${content.replace(/'/g, "'\"'\"'")}' > '${wallpapersConfFilePath.replace('file://', '')}'`);
            
            // Create the current wallpaper file if it doesn't exist - same as PinnedApps approach
            Hyprland.dispatch(`exec touch '${currentWallpaperFile.replace('file://', '')}'`);
            
            console.log("[WALLPAPER DEBUG] Step 1: Successfully created wallpapers config file and current wallpaper file")
        } catch (e) {
            console.log("[WALLPAPER DEBUG] Step 1: Error creating wallpapers config file:", e)
        }
    }
    
    // Step 2: Scan for wallpapers and populate the config file - EXACT same approach as PinnedApps
    function scanAndPopulateWallpapers() {
        try {
            console.log("[WALLPAPER DEBUG] Step 2: Scanning for wallpapers and populating config...")
            
            console.log("[WALLPAPER DEBUG] Step 2: Wallpaper directory:", wallpaperDir.replace('file://', ''))
            
            // Check if wallpaper directory exists
            Hyprland.dispatch(`exec ls -la '${wallpaperDir.replace('file://', '')}'`)
            
            // Use find command to get wallpaper list and write to file - EXACT same as PinnedApps approach
            var findCommand = `find '${wallpaperDir.replace('file://', '')}' -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" -o -iname "*.webp" -o -iname "*.svg" \\) 2>/dev/null | sort`
            console.log("[WALLPAPER DEBUG] Step 2: Find command:", findCommand)
            
            // Execute the find command and capture output, then write to file
            Hyprland.dispatch(`exec ${findCommand} > '${wallpapersConfFilePath.replace('file://', '')}'`)
            
            // Debug: check what was actually written to the file
            Hyprland.dispatch(`exec cat '${wallpapersConfFilePath.replace('file://', '')}'`)
            
            console.log("[WALLPAPER DEBUG] Step 2: Successfully scanned and populated wallpapers config file")
            
            // Reload the FileView to read the updated config file
            wallpapersFileView.reload()
        } catch (e) {
            console.log("[WALLPAPER DEBUG] Step 2: Error scanning wallpapers:", e)
            
            // Fallback: ensure file exists with header - same as PinnedApps
            try {
                var content = "# Wallpapers configuration file\n";
                Hyprland.dispatch(`exec echo '${content.replace(/'/g, "'\"'\"'")}' > '${wallpapersConfFilePath.replace('file://', '')}'`);
                console.log("[WALLPAPER DEBUG] Step 2: Created fallback config file")
                wallpapersFileView.reload()
            } catch (fallbackError) {
                console.log("[WALLPAPER DEBUG] Step 2: Fallback also failed:", fallbackError)
            }
        }
    }
    

    
    // Function to check for new wallpapers and update config if needed
    function checkForNewWallpapers() {
        try {
            console.log("[WALLPAPER DEBUG] Checking for new wallpapers...")
            
            // Get current wallpapers from config
            const currentWallpapers = wallpaperFiles || []
            console.log("[WALLPAPER DEBUG] Current wallpapers in config:", currentWallpapers.length)
            
            // Scan directory for actual wallpapers
            const findCommand = `find '${wallpaperDir.replace('file://', '')}' -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" -o -iname "*.webp" -o -iname "*.svg" \\) 2>/dev/null | sort`
            
            // Use a temporary file to capture the find output
            const tempFile = StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/state/Quickshell/Wallpapers/temp_scan.txt"
            Hyprland.dispatch(`exec ${findCommand} > '${tempFile.replace('file://', '')}'`)
            
            // Use a timer to read the temp file and compare
            newWallpapersCheckTimer.start()
        } catch (e) {
            console.log("[WALLPAPER DEBUG] Error checking for new wallpapers:", e)
        }
    }
    
    // Function to get current wallpaper from swww
    function getCurrentWallpaper() {
        // Load current wallpaper from saved file
        loadCurrentWallpaper()
    }
    
    // Initialize
    Component.onCompleted: {
        console.log("Initializing wallpaper config...")
        
        // Load wallpapers (will check for existing config first)
        loadWallpapers(false)
        
        // Load current wallpaper
        getCurrentWallpaper()
        
        // Disable automatic wallpaper checking to prevent overwriting
        wallpaperCheckTimer.running = false
    }
    
    // Timer to read current wallpaper file
    Timer {
        id: currentWallpaperTimer
        interval: 300
        repeat: false
        onTriggered: {
            const fileView = Qt.createQmlObject(`
                import QtQuick
                import Quickshell.Io
                
                FileView { }
            `, wallpaperConfig)
            
            fileView.path = currentWallpaperFile
            
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
    
    // Timer to check if config file exists and decide what to do
    Timer {
        id: configCheckTimer
        interval: 500
        repeat: false
        running: false  // Disabled to prevent overwriting existing wallpapers
        onTriggered: {
            console.log("[WALLPAPER DEBUG] Checking config file status...")
            
            // Create a temporary FileView to check the config file
            const tempFileView = Qt.createQmlObject(`
                import QtQuick
                import Quickshell.Io
                
                FileView { }
            `, wallpaperConfig)
            
            tempFileView.path = wallpapersConfFilePath
            
            if (tempFileView && tempFileView.text() && tempFileView.text().trim() !== "" && tempFileView.text().trim() !== "# Wallpapers configuration file") {
                console.log("[WALLPAPER DEBUG] Config file exists with content, loading existing wallpapers")
                // Config file exists and has content, just reload the FileView
                wallpapersFileView.reload()
            } else {
                console.log("[WALLPAPER DEBUG] Config file missing or empty, creating and scanning")
                // Config file doesn't exist or is empty, create it and scan
                createWallpapersConfFile()
                wallpaperScanTimer.start()
            }
        }
    }
    
    // Timer to scan and populate wallpapers after file creation
    Timer {
        id: wallpaperScanTimer
        interval: 4000
        repeat: false
        running: false  // Disabled to prevent overwriting existing wallpapers
        onTriggered: {
            console.log("[WALLPAPER DEBUG] Timer triggered - scanning for wallpapers")
            scanAndPopulateWallpapers()
        }
    }
    
    // Timer to periodically check for new wallpapers
    Timer {
        id: wallpaperCheckTimer
        interval: 10000 // Check every 10 seconds
        repeat: true
        running: false  // Disabled to prevent overwriting existing wallpapers
        onTriggered: {
            checkForNewWallpapers()
        }
    }
    
    // Timer to read temp scan file and compare wallpapers
    Timer {
        id: newWallpapersCheckTimer
        interval: 500
        repeat: false
        onTriggered: {
            try {
                const tempFile = StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/state/Quickshell/Wallpapers/temp_scan.txt"
                
                // Create a temporary FileView to read the scan results
                const tempFileView = Qt.createQmlObject(`
                    import QtQuick
                    import Quickshell.Io
                    
                    FileView { }
                `, wallpaperConfig)
                
                tempFileView.path = tempFile
                
                if (tempFileView && tempFileView.text()) {
                    const actualWallpapers = tempFileView.text().trim().split('\n').filter(line => line.trim() !== '')
                    const currentWallpapers = wallpaperFiles || []
                    
                    console.log("[WALLPAPER DEBUG] Actual wallpapers in directory:", actualWallpapers.length)
                    console.log("[WALLPAPER DEBUG] Current wallpapers in config:", currentWallpapers.length)
                    
                    // Check if there are new wallpapers
                    const hasNewWallpapers = actualWallpapers.length > currentWallpapers.length
                    const hasRemovedWallpapers = actualWallpapers.length < currentWallpapers.length
                    
                    if (hasNewWallpapers || hasRemovedWallpapers) {
                        console.log("[WALLPAPER DEBUG] Wallpaper count changed! Updating config...")
                        console.log("[WALLPAPER DEBUG] New count:", actualWallpapers.length, "Old count:", currentWallpapers.length)
                        
                        // Update the config file with new wallpapers
                        const content = actualWallpapers.join('\n') + '\n'
                        Hyprland.dispatch(`exec echo '${content.replace(/'/g, "'\"'\"'")}' > '${wallpapersConfFilePath.replace('file://', '')}'`)
                        
                        // Reload the FileView to update the UI
                        wallpapersFileView.reload()
                        
                        // Update cache
                        cachedWallpapers = actualWallpapers
                        cacheValid = true
                        lastScanTime = new Date().toLocaleTimeString()
                    } else {
                        console.log("[WALLPAPER DEBUG] No new wallpapers found")
                    }
                }
                
                // Clean up temp file
                Hyprland.dispatch(`exec rm -f '${tempFile.replace('file://', '')}'`)
            } catch (e) {
                console.log("[WALLPAPER DEBUG] Error comparing wallpapers:", e)
            }
        }
    }
    
    // FileView to read wallpapers config file - EXACT same approach as PinnedApps
    FileView {
        id: wallpapersFileView
        path: wallpapersConfFilePath
        
        onLoaded: {
            console.log("Wallpapers config file loaded successfully")
            try {
                const content = text()
                console.log("Config file content length:", content ? content.length : 0)
                
                if (content && content.trim() !== "") {
                    // Parse the config file, skip comment lines - EXACT same as PinnedApps
                    const lines = content.trim().split("\n")
                    const files = lines.filter(line => line.trim() !== "" && !line.trim().startsWith("#"))
                    console.log("Found wallpapers:", files.length)
                    console.log("Raw wallpaper paths:", files)
                    
                    // Update cache - no cleaning needed if file is written correctly
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
            // Step 1: Create the config file
            createWallpapersConfFile()
            // Step 2: Start timer to scan and populate after 4 seconds
            wallpaperScanTimer.start()
            cacheValid = false
        }
    }

    // Bing wallpaper downloader properties and process
    property string bingSelectedResolution: "1920x1080"
    property string bingDownloadStatus: ""
    
    // Force property change notification
    onBingSelectedResolutionChanged: {
        console.log("Resolution changed to:", bingSelectedResolution)
    }

    Process {
        id: bingDownloadProcess
        property string status: ""
        onStarted: {
            console.log("Bing download process started!")
            bingDownloadStatus = "Starting download..."
        }
        onExited: function(exitCode) {
            console.log("Bing download process exited with code:", exitCode)
            bingDownloadProcess.running = false
            if (exitCode === 0) {
                bingDownloadStatus = "Download completed successfully! Wallpapers saved to Pictures/Wallpapers"
                // Refresh the wallpaper list after successful download
                console.log("Bing download successful, refreshing wallpaper list...")
                // Force reload the FileView without triggering scanning
                wallpapersFileView.reload()
                // Update cache
                cacheValid = false
                lastScanTime = new Date().toLocaleTimeString()
            } else {
                bingDownloadStatus = "Download failed. Please check your internet connection and try again."
            }
        }
        stdout: SplitParser {
            onRead: data => {
                console.log("Bing download stdout:", data)
                bingDownloadStatus = data.trim();
            }
        }
        stderr: SplitParser {
            onRead: data => {
                console.log("Bing download stderr:", data)
                bingDownloadStatus = "Error: " + data.trim();
            }
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
                    source: currentWallpaper ? currentWallpaper : ""
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
    
    // Bing Wallpaper Downloader Section
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: childrenRect.height + 24
        radius: 12
        color: "#2a2a2a"
        border.width: 1
        border.color: "#404040"

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 20
            spacing: 16

            // Header
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
                        text: "download"
                        iconSize: 18
                        color: "#ffffff"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Bing Wallpaper Downloader"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: "#ffffff"
                    }

                    Text {
                        text: "Download daily Bing wallpapers to Pictures/Wallpapers"
                        font.pixelSize: 12
                        color: "#cccccc"
                    }
                }
            }

            // Resolution selector and download button
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Resolution dropdown
                ComboBox {
                    id: bingResolutionComboBox
                    Layout.preferredWidth: 140
                    Layout.preferredHeight: 40
                    model: [
                        { text: "1920x1080 (Full HD)", value: "1920x1080" },
                        { text: "2560x1440 (2K)", value: "2560x1440" },
                        { text: "3840x2160 (4K)", value: "3840x2160" },
                        { text: "1366x768 (HD)", value: "1366x768" }
                    ]
                    textRole: "text"
                    valueRole: "value"
                    
                    background: Rectangle {
                        radius: 8
                        color: bingResolutionComboBox.hovered ? "#4a4a4a" : "#3a3a3a"
                        border.width: 1
                        border.color: "#666666"
                    }
                    
                    contentItem: Text {
                        text: bingResolutionComboBox.displayText
                        font.pixelSize: 12
                        color: "#ffffff"
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 12
                        rightPadding: 12
                    }
                    
                    indicator: MaterialSymbol {
                        x: bingResolutionComboBox.width - width - 12
                        y: bingResolutionComboBox.topPadding + (bingResolutionComboBox.availableHeight - height) / 2
                        text: "expand_more"
                        iconSize: 16
                        color: "#cccccc"
                    }
                    
                    onActivated: function(index) {
                        bingSelectedResolution = bingResolutionComboBox.model[index].value
                        console.log("Resolution selected:", bingSelectedResolution)
                    }
                    
                    Component.onCompleted: {
                        // Set initial value
                        for (let i = 0; i < model.length; i++) {
                            if (model[i].value === bingSelectedResolution) {
                                currentIndex = i
                                break
                            }
                        }
                    }
                }

                // Download button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: 8
                    color: bingDownloadMouseArea.containsMouse ? "#4a4a4a" : "#3a3a3a"
                    border.width: 1
                    border.color: bingDownloadProcess.running ? Appearance.colors.colPrimary : "#666666"

                    MouseArea {
                        id: bingDownloadMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!bingDownloadProcess.running) {
                                console.log("Starting Bing download process...")
                                const scriptPath = FileUtils.trimFileProtocol(StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/quickshell/scripts/download_bing_wallpapers.py")
                                console.log("Script path:", scriptPath)
                                console.log("Resolution:", bingSelectedResolution)
                                bingDownloadProcess.command = ["python3", scriptPath, bingSelectedResolution, "8"]
                                console.log("Command set:", bingDownloadProcess.command)
                                bingDownloadProcess.running = true
                                console.log("Process started, running:", bingDownloadProcess.running)
                            }
                        }
                    }

                    RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 12
                        spacing: 8

                        MaterialSymbol {
                            text: bingDownloadProcess.running ? "hourglass_empty" : "download"
                            iconSize: 16
                            color: bingDownloadProcess.running ? Appearance.colors.colPrimary : "#ffffff"
                        }

                        Text {
                            text: bingDownloadProcess.running ? "Downloading..." : "Download 8 Wallpapers"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: bingDownloadProcess.running ? Appearance.colors.colPrimary : "#ffffff"
                        }

                        // Progress indicator
                        Rectangle {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            radius: 8
                            color: "transparent"
                            border.width: 2
                            border.color: bingDownloadProcess.running ? Appearance.colors.colPrimary : "transparent"
                            visible: bingDownloadProcess.running

                            RotationAnimation {
                                target: parent
                                property: "rotation"
                                from: 0
                                to: 360
                                duration: 1000
                                loops: Animation.Infinite
                                running: bingDownloadProcess.running
                            }
                        }
                    }
                }
            }

            // Status text
            Text {
                text: bingDownloadStatus
                font.pixelSize: 11
                color: bingDownloadProcess.running ? Appearance.colors.colPrimary : "#cccccc"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                visible: bingDownloadStatus !== ""
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
                        onClicked: {
                            console.log("Manual refresh requested")
                            // Force reload the FileView without triggering scanning
                            wallpapersFileView.reload()
                            // Update cache
                            cacheValid = false
                            lastScanTime = new Date().toLocaleTimeString()
                        }
                    }
                }
            }
            
            // Wallpaper grid with right-side scrollbar
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8
                
                // Wallpaper grid
                ScrollView {
                    id: gridView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    
                    ScrollBar.horizontal: ScrollBar {
                        active: true
                        policy: ScrollBar.AsNeeded
                        visible: true
                        width: 12
                        
                        background: Rectangle {
                            color: "#2a2a2a"
                            radius: 6
                        }
                        
                        contentItem: Rectangle {
                            implicitWidth: 12
                            radius: 6
                            color: parent.pressed ? "#666666" : parent.hovered ? "#555555" : "#444444"
                        }
                    }
                    
                    Grid {
                        width: gridView.width
                        columns: Math.floor(gridView.width / 120)
                        rowSpacing: 12
                        columnSpacing: 12
                        
                        Repeater {
                            model: wallpaperFiles
                            
                            // Empty state when no wallpapers
                            Rectangle {
                                width: gridView.width
                                height: 100
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
                                width: 100
                                height: 100
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
                                    source: modelData
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
} 