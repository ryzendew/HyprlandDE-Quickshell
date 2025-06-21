pragma Singleton
import Quickshell
import QtQuick
import Quickshell.Io

Singleton {
    id: settings

    // Settings file with atomic writes
    FileView {
        id: settingsFile
        path: "settings.json"
        blockWrites: true
        atomicWrites: true
        watchChanges: false

        onLoaded: {
            try {
                var content = JSON.parse(text())
                if (content) {
                    // Load settings with defaults
                    settings.isDarkTheme = content.isDarkTheme ?? true
                    settings.avatarSource = content.avatarSource ?? "https://cdn.discordapp.com/avatars/158005126638993408/de403b05fd7f74bb17e01a9b066a30fa?size=64"
                    settings.weatherLocation = content.weatherLocation ?? "Dinslaken"
                    settings.displayTime = content.displayTime ?? 6000
                    settings.videoPath = content.videoPath ?? "~/Videos/"
                    settings.wallpaperDirectory = content.wallpaperDirectory ?? "/home/lysec/nixos/assets/wallpapers/"
                    settings.lastWallpaperPath = content.lastWallpaperPath ?? ""
                }
            } catch (e) {
                console.log("Error parsing user settings:", e)
            }
        }
    }

    // User customizable settings
    property string avatarSource: "root:/Assets/tardis.gif"
    property bool isDarkTheme: true
    property string weatherLocation: "Halifax, Nova Scotia, Canada"
    property int displayTime: 6000 // Notification display time in ms
    readonly property var ignoredApps: ["some-app", "another-app"]
    property string videoPath: "~/Videos/"
    property string wallpaperDirectory: "/home/lysec/nixos/assets/wallpapers/"
    property string lastWallpaperPath: ""

    // System UI configuration
    readonly property real borderWidth: 9
    readonly property real cornerRadius: 20

    signal settingsChanged()

    // Persist settings to JSON file
    function saveSettings() {
        try {
            var content = {
                isDarkTheme: settings.isDarkTheme,
                avatarSource: settings.avatarSource,
                weatherLocation: settings.weatherLocation,
                displayTime: settings.displayTime,
                videoPath: settings.videoPath,
                wallpaperDirectory: settings.wallpaperDirectory,
                lastWallpaperPath: settings.lastWallpaperPath
            }
            var jsonContent = JSON.stringify(content, null, 4)
            settingsFile.setText(jsonContent)
        } catch (e) {
            console.log("Error saving user settings:", e)
        }
    }

    // Auto-save on property changes
    onIsDarkThemeChanged: {
        settingsChanged()
        saveSettings()
    }
    onAvatarSourceChanged: {
        settingsChanged()
        saveSettings()
    }
    onWeatherLocationChanged: {
        settingsChanged()
        saveSettings()
    }
    onDisplayTimeChanged: {
        settingsChanged()
        saveSettings()
    }
    onVideoPathChanged: {
        settingsChanged()
        saveSettings()
    }
    onWallpaperDirectoryChanged: {
        settingsChanged()
        saveSettings()
    }
    onLastWallpaperPathChanged: {
        settingsChanged()
        saveSettings()
    }

    Component.onCompleted: {
        settingsFile.reload()
    }
}