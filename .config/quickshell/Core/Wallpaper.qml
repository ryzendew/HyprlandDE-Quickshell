import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/Data" as Data

// Wallpaper background layer rendered behind all other content
PanelWindow {
    id: wallpaperWindow
    required property var screen

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    margins.top: 0
    margins.left: 0
    margins.right: 0
    margins.bottom: 0
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-wallpaper"
    color: "transparent"
    visible: true

    Image {
        id: wallpaperImage
        anchors.fill: parent
        source: Data.WallpaperManager.currentWallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false  // Disable Qt caching to reduce memory usage
        visible: true

        // Fallback background when wallpaper fails to load
        Rectangle {
            id: fallbackBackground
            anchors.fill: parent
            color: Data.Colors.bgColor
            visible: wallpaperImage.status !== Image.Ready || !wallpaperImage.source
        }
    }
} 
