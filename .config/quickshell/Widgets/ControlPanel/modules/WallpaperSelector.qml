import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "root:/Data" as Data

// Wallpaper selector grid
Item {
    id: root

    property bool isVisible: false
    signal visibilityChanged(bool visible)

    // Use all space provided by parent
    anchors.fill: parent
    visible: isVisible
    enabled: visible
    clip: true

    property bool containsMouse: wallpaperSelectorMouseArea.containsMouse || scrollView.containsMouse
    property bool menuJustOpened: false

    // Hover state management for auto-hide functionality
    onContainsMouseChanged: {
        if (containsMouse) {
            hideTimer.stop()
        } else if (!menuJustOpened && !isVisible) {
            hideTimer.restart()
        }
    }

    onVisibleChanged: {
        if (visible) {
            menuJustOpened = true
            hideTimer.stop()
            Qt.callLater(function() {
                menuJustOpened = false
            })
        }
    }

    MouseArea {
        id: wallpaperSelectorMouseArea
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: false
        propagateComposedEvents: true
    }

    // Scrollable wallpaper grid with memory-conscious loading
    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true

        property bool containsMouse: gridMouseArea.containsMouse

        MouseArea {
            id: gridMouseArea
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
        }

        GridView {
            id: wallpaperGrid
            anchors.fill: parent
            cellWidth: parent.width / 2 - 8 // 2-column layout with spacing
            cellHeight: cellWidth * 0.6 // Wallpaper aspect ratio
            model: Data.WallpaperManager.wallpaperList
            cacheBuffer: 0  // Memory optimization - no cache buffer
            leftMargin: 4
            rightMargin: 4
            topMargin: 4
            bottomMargin: 4

            delegate: Item {
                width: wallpaperGrid.cellWidth - 8
                height: wallpaperGrid.cellHeight - 8

                Rectangle {
                    id: wallpaperItem
                    anchors.fill: parent
                    anchors.margins: 4
                    color: Qt.darker(Data.Colors.bgColor, 1.2)
                    radius: 20

                    Behavior on scale {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }

                    // Wallpaper preview image with viewport-based loading
                    Image {
                        id: wallpaperImage
                        anchors.fill: parent
                        anchors.margins: 4
                        source: modelData
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false  // Memory optimization - no image caching
                        sourceSize.width: Math.min(width, 150)  // Reduced resolution for memory
                        sourceSize.height: Math.min(height, 90)
                        
                        // Only load when visible in viewport - major memory optimization
                        visible: parent.parent.y >= wallpaperGrid.contentY - parent.parent.height &&
                                parent.parent.y <= wallpaperGrid.contentY + wallpaperGrid.height
                        
                        // Layer effects disabled for memory savings
                        // layer.enabled: true
                        // layer.effect: OpacityMask {
                        //     maskSource: Rectangle {
                        //         width: wallpaperImage.width
                        //         height: wallpaperImage.height
                        //         radius: 18
                        //     }
                        // }
                    }

                    // Current wallpaper selection indicator
                    Rectangle {
                        visible: modelData === Data.WallpaperManager.currentWallpaper
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.color: Data.Colors.accentColor
                        border.width: 2
                    }

                    // Hover and click handling
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: wallpaperItem.scale = 1.05
                        onExited: wallpaperItem.scale = 1.0
                        onClicked: {
                            Data.WallpaperManager.setWallpaper(modelData)
                            // Stays in wallpaper tab after selection
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        // Use lazy loading to only load wallpapers when this component is actually used
        Data.WallpaperManager.ensureWallpapersLoaded()
    }
} 