pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "." as Data

// Wallpaper manager with auto-scan
Item {
    id: manager

    property string wallpaperDirectory: Data.Settings.wallpaperDirectory
    property string currentWallpaper: Data.Settings.lastWallpaperPath
    property var wallpaperList: []

    // Auto-refresh (5 min)
    Timer {
        id: refreshTimer
        interval: 300000
        running: false
        repeat: true
        onTriggered: loadWallpapers()
    }

    // Scan directory for wallpapers
    Process {
        id: findProcessInternal
        property var callback
        property var tempList: []
        running: false
        command: ["find", manager.wallpaperDirectory, "-type", "f", "-name", "*.png", "-o", "-name", "*.jpg", "-o", "-name", "*.jpeg"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                if (line.trim()) {
                    findProcessInternal.tempList.push(line.trim())
                }
            }
        }

        onExited: {
            var newList = findProcessInternal.tempList.slice()
            manager.wallpaperList = newList
            findProcessInternal.tempList = []
            
            // Set first wallpaper if none selected
            if (!currentWallpaper && wallpaperList.length > 0) {
                setWallpaper(wallpaperList[0])
            }
            
            // Start refresh timer after first successful scan
            if (!refreshTimer.running) {
                refreshTimer.running = true
            }
            
            if (callback) callback()
        }
    }

    function loadWallpapers(cb) {
        findProcessInternal.callback = cb
        findProcessInternal.tempList = []
        findProcessInternal.running = true
    }

    function setWallpaper(path) {
        currentWallpaper = path
        Data.Settings.lastWallpaperPath = path
        // Trigger update across all wallpaper components
        currentWallpaperChanged()
    }

    // Ensure wallpapers are loaded before executing callback
    function ensureWallpapersLoaded(callback) {
        if (wallpaperList.length === 0) {
            loadWallpapers(callback)
        } else if (callback) {
            callback()
        }
    }

    Component.onCompleted: {
        if (Data.Settings.lastWallpaperPath) {
            currentWallpaper = Data.Settings.lastWallpaperPath
        }
    }

    Component.onDestruction: {
        if (findProcessInternal.running) {
            findProcessInternal.running = false
        }
        if (refreshTimer.running) {
            refreshTimer.running = false
        }
    }
} 