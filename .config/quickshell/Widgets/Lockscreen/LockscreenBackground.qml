import QtQuick
import Qt5Compat.GraphicalEffects
import "root:/Data" as Data

// Background with wallpaper
Rectangle {
    id: backgroundContainer
    anchors.fill: parent
    color: Data.Colors.bgColor
    
    required property bool isVisible
    
    // Fade-in animation for the whole background
    opacity: isVisible ? 1.0 : 0.0
    Behavior on opacity {
        NumberAnimation {
            duration: 500
            easing.type: Easing.OutCubic
        }
    }
    
    // Wallpaper background
    Image {
        id: wallpaperImage
        anchors.fill: parent
        source: Data.WallpaperManager.currentWallpaper ? "file://" + Data.WallpaperManager.currentWallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
    }
    
    // Dark overlay
    Rectangle {
        anchors.fill: parent
        color: Data.Colors.withOpacity(Data.Colors.bgColor, 0.8)
    }
    
    // Blur effect overlay
    GaussianBlur {
        anchors.fill: wallpaperImage
        source: wallpaperImage
        radius: 32
        samples: 65
        
        // Blur animation - starts less blurred and increases
        Behavior on radius {
            NumberAnimation {
                duration: 1200
                easing.type: Easing.OutCubic
            }
        }
        
        Component.onCompleted: {
            if (isVisible) {
                radius = 32
            }
        }
    }
} 