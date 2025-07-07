import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Rectangle {
    id: root
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    property string artUrl: activePlayer?.trackArtUrl || ""
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: artUrl ? Qt.md5(artUrl) + ".jpg" : ""
    property string artFilePath: artFileName ? `${artDownloadLocation}/${artFileName}` : ""
    property bool downloaded: false
    property color artDominantColor: (colorQuantizer && colorQuantizer.colors && colorQuantizer.colors.length > 0) ? colorQuantizer.colors[0] : Appearance.m3colors.m3secondaryContainer

    implicitHeight: 80
    radius: Appearance.rounding.large
    color: Qt.rgba(
        Appearance.colors.colLayer1.r,
        Appearance.colors.colLayer1.g,
        Appearance.colors.colLayer1.b,
        0.3
    )
    border.color: Qt.rgba(1, 1, 1, 0.1)
    border.width: 1
    visible: true

    // Time formatting function
    function formatTime(seconds) {
        if (!seconds || isNaN(seconds)) return "0:00"
        var mins = Math.floor(seconds / 60)
        var secs = Math.floor(seconds % 60)
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    // Album art download handler
    onArtUrlChanged: {
        if (artUrl.length == 0) {
            artDominantColor = Appearance.m3colors.m3secondaryContainer
            downloaded = false
            return;
        }
        downloaded = false
        
        // Check if file already exists before downloading
        var fileExistsCmd = [ "bash", "-c", `[ -f '${artFilePath}' ] && [ -s '${artFilePath}' ] && echo "exists" || echo "missing"` ]
        var fileChecker = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
        fileChecker.command = fileExistsCmd
        fileChecker.onExited.connect(function(exitCode, exitStatus) {
            if (exitCode === 0) {
                var output = fileChecker.stdout ? fileChecker.stdout.trim() : ""
                if (output === "exists") {
                    downloaded = true
                } else {
                    coverArtDownloader.running = true
                }
            } else {
                coverArtDownloader.running = true
            }
            fileChecker.destroy()
        })
        fileChecker.running = true
    }

    Process { // Cover art downloader
        id: coverArtDownloader
        property string targetFile: root.artUrl
        command: [ "bash", "-c", `mkdir -p '${root.artDownloadLocation}' && curl -sSL --max-time 10 --retry 2 '${root.artUrl}' -o '${root.artFilePath}' && [ -s '${root.artFilePath}' ]` ]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.downloaded = true
            } else {
                console.log("[SidebarMediaPlayer] Failed to download album art for:", root.artUrl)
                root.downloaded = false
            }
        }
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.downloaded ? Qt.resolvedUrl(root.artFilePath) : ""
        depth: 0 // 2^0 = 1 color
        rescaleSize: 1 // Rescale to 1x1 pixel for faster processing
    }

    property QtObject blendedColors: QtObject {
        property color colLayer0: ColorUtils.mix(Appearance.colors.colLayer0, artDominantColor, 0.3)
        property color colLayer1: ColorUtils.mix(Appearance.colors.colLayer1, artDominantColor, 0.3)
        property color colOnLayer0: ColorUtils.mix(Appearance.colors.colOnLayer0, artDominantColor, 0.2)
        property color colOnLayer1: ColorUtils.mix(Appearance.colors.colOnLayer1, artDominantColor, 0.2)
        property color colPrimary: ColorUtils.mix(Appearance.colors.colPrimary, artDominantColor, 0.3)
    }

    // Background with subtle album art influence
    Rectangle {
        anchors.fill: parent
        color: activePlayer ? blendedColors.colLayer0 : Qt.rgba(
            Appearance.colors.colLayer1.r,
            Appearance.colors.colLayer1.g,
            Appearance.colors.colLayer1.b,
            0.3
        )
        radius: parent.radius
        opacity: 0.8
        
        Behavior on color {
            ColorAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 10

        // Album art
        Rectangle {
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            radius: 8
            color: Qt.rgba(1, 1, 1, 0.1)
            border.color: Qt.rgba(1, 1, 1, 0.2)
            border.width: 1

            Image {
                anchors.fill: parent
                anchors.margins: 1
                source: root.downloaded ? Qt.resolvedUrl(root.artFilePath) : ""
                fillMode: Image.PreserveAspectCrop
                cache: false
                asynchronous: true
                visible: root.downloaded && status === Image.Ready
                
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: parent.width
                        height: parent.height
                        radius: 7
                    }
                }
                
                onStatusChanged: {
                    if (status === Image.Error) {
                        root.downloaded = false
                    }
                }
            }
            
            // Fallback icon when no album art
            MaterialSymbol {
                anchors.centerIn: parent
                text: activePlayer ? "music_note" : "play_circle"
                iconSize: activePlayer ? 32 : 40
                color: activePlayer ? blendedColors.colOnLayer0 : Appearance.colors.colOnLayer1
                visible: !root.downloaded || parent.children[0].status !== Image.Ready || !activePlayer
            }
        }

        // Track info and controls
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4

            // Track info
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    text: activePlayer ? (activePlayer.trackTitle || "No track") : "No media playing"
                    color: activePlayer ? blendedColors.colOnLayer0 : Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                StyledText {
                    Layout.fillWidth: true
                    text: activePlayer ? (activePlayer.trackArtist || "") : "Start playing music to see controls"
                    color: activePlayer ? blendedColors.colOnLayer1 : Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    opacity: 0.8
                    visible: text.length > 0
                }
            }

            // Progress bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                radius: 2
                color: Qt.rgba(1, 1, 1, 0.2)
                visible: activePlayer

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * Math.max(0, Math.min(1, (activePlayer && activePlayer.position ? activePlayer.position : 0) / Math.max(1, activePlayer && activePlayer.length ? activePlayer.length : 1)))
                    height: parent.height
                    radius: parent.radius
                    color: blendedColors.colPrimary
                    
                    Behavior on width {
                        enabled: activePlayer?.playbackState == MprisPlaybackState.Playing
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // Controls row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Time display
                StyledText {
                    text: formatTime(Math.max(0, activePlayer && activePlayer.position ? activePlayer.position : 0))
                    color: blendedColors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.tiny
                    opacity: 0.7
                }

                Item { Layout.fillWidth: true }

                // Control buttons
                RowLayout {
                    spacing: 4

                    RippleButton {
                        implicitWidth: 28
                        implicitHeight: 28
                        buttonRadius: 14
                        colBackground: Qt.rgba(1, 1, 1, 0.1)
                        colBackgroundHover: Qt.rgba(1, 1, 1, 0.2)
                        enabled: activePlayer?.canGoPrevious ?? false
                        onClicked: activePlayer?.previous()

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "skip_previous"
                            iconSize: 16
                            color: blendedColors.colOnLayer0
                        }
                    }

                    RippleButton {
                        implicitWidth: 32
                        implicitHeight: 32
                        buttonRadius: 16
                        colBackground: blendedColors.colPrimary
                        colBackgroundHover: Qt.rgba(blendedColors.colPrimary.r, blendedColors.colPrimary.g, blendedColors.colPrimary.b, 0.8)
                        enabled: activePlayer?.canTogglePlaying ?? false
                        onClicked: activePlayer?.togglePlaying()

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: activePlayer?.playbackState == MprisPlaybackState.Playing ? "pause" : "play_arrow"
                            iconSize: 18
                            color: "#ffffff"
                        }
                    }

                    RippleButton {
                        implicitWidth: 28
                        implicitHeight: 28
                        buttonRadius: 14
                        colBackground: Qt.rgba(1, 1, 1, 0.1)
                        colBackgroundHover: Qt.rgba(1, 1, 1, 0.2)
                        enabled: activePlayer?.canGoNext ?? false
                        onClicked: activePlayer?.next()

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "skip_next"
                            iconSize: 16
                            color: blendedColors.colOnLayer0
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Duration
                StyledText {
                    text: formatTime(Math.max(0, activePlayer && activePlayer.length ? activePlayer.length : 0))
                    color: blendedColors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.tiny
                    opacity: 0.7
                }
            }
        }
    }

    // Click to open full media player
    MouseArea {
        anchors.fill: parent
        onClicked: {
            Hyprland.dispatch("global quickshell:simpleMediaPlayer:toggle")
        }
    }
} 