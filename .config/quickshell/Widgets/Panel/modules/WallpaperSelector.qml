import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "root:/Data" as Data

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

    // Wallpaper grid - use all available space
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
            cellWidth: parent.width / 2 - 8 // 2 columns with spacing for bigger previews
            cellHeight: cellWidth * 0.6 // Aspect ratio for wallpapers
            model: Data.WallpaperManager.wallpaperList
            cacheBuffer: 0  // Disable cache buffer to save massive memory
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

                    Image {
                        id: wallpaperImage
                        anchors.fill: parent
                        anchors.margins: 4
                        source: modelData
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false  // Disable caching to save massive memory
                        sourceSize.width: Math.min(width, 150)  // Further reduced from 200 to 150
                        sourceSize.height: Math.min(height, 90) // Further reduced from 120 to 90
                        
                        // Only load when item is visible in viewport
                        visible: parent.parent.y >= wallpaperGrid.contentY - parent.parent.height &&
                                parent.parent.y <= wallpaperGrid.contentY + wallpaperGrid.height
                        
                        // Disable layer effects to save memory
                        // layer.enabled: true
                        // layer.effect: OpacityMask {
                        //     maskSource: Rectangle {
                        //         width: wallpaperImage.width
                        //         height: wallpaperImage.height
                        //         radius: 18  // Slightly smaller than parent to account for margins
                        //     }
                        // }
                    }

                    // Selected indicator
                    Rectangle {
                        visible: modelData === Data.WallpaperManager.currentWallpaper
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.color: Data.Colors.accentColor
                        border.width: 2
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: wallpaperItem.scale = 1.05
                        onExited: wallpaperItem.scale = 1.0
                        onClicked: {
                            Data.WallpaperManager.setWallpaper(modelData)
                            // Removed the close behavior - stays in wallpaper tab
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