import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import "root:/modules/common/functions/file_utils.js" as FileUtils
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import "../quickToggles"

Rectangle {
    id: root
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || "No media"

    // Album art properties
    property string artUrl: activePlayer?.trackArtUrl || ""
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: artUrl ? Qt.md5(artUrl) + ".jpg" : ""
    property string artFilePath: artFileName ? `${artDownloadLocation}/${artFileName}` : ""
    property bool downloaded: false
    property color artDominantColor: (colorQuantizer && colorQuantizer.colors && colorQuantizer.colors.length > 0) ? colorQuantizer.colors[0] : Appearance.m3colors.m3secondaryContainer

    // Time formatting functions
    function formatTime(seconds) {
        if (!seconds || isNaN(seconds)) return "0:00"
        var mins = Math.floor(seconds / 60)
        var secs = Math.floor(seconds % 60)
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    // Function to get application icon from MPRIS player
    function getPlayerIcon() {
        if (!activePlayer?.dbusName) return "music_note"
        
        // Extract app name from dbus name (e.g., "org.mpris.MediaPlayer2.cider" -> "cider")
        const dbusName = activePlayer.dbusName
        const parts = dbusName.split('.')
        const appName = parts[parts.length - 1]
        
        // Common media player icons
        const playerIcons = {
            "cider": "apple-music",
            "spotify": "spotify",
            "vlc": "vlc",
            "rhythmbox": "rhythmbox",
            "amarok": "amarok",
            "clementine": "clementine",
            "audacious": "audacious",
            "mpv": "mpv",
            "firefox": "firefox",
            "chromium": "chromium",
            "chrome": "google-chrome",
            "brave": "brave-browser",
            "discord": "discord",
            "telegram": "telegram",
            "youtube": "youtube",
            "soundcloud": "soundcloud"
        }
        
        return playerIcons[appName.toLowerCase()] || appName.toLowerCase() || "music_note"
    }

    // Album art download handler
    onArtUrlChanged: {
        if (artUrl.length == 0) {
            artDominantColor = Appearance.m3colors.m3secondaryContainer
            downloaded = false
            return;
        }
        console.log("[SimpleMediaPlayerSidebar] Art URL changed to:", artUrl)
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
                console.log("[SimpleMediaPlayerSidebar] Failed to download album art for:", root.artUrl)
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
        property color colLayer0: ColorUtils.mix(Appearance.colors.colLayer0, artDominantColor, 0.5)
        property color colLayer1: ColorUtils.mix(Appearance.colors.colLayer1, artDominantColor, 0.5)
        property color colOnLayer0: ColorUtils.mix(Appearance.colors.colOnLayer0, artDominantColor, 0.3)
        property color colOnLayer1: ColorUtils.mix(Appearance.colors.colOnLayer1, artDominantColor, 0.5)
        property color colSubtext: ColorUtils.mix(Appearance.colors.colOnLayer1, artDominantColor, 0.5)
        property color colPrimary: ColorUtils.mix(Appearance.colors.colPrimary, artDominantColor, 0.4)
        property color colPrimaryHover: ColorUtils.mix(ColorUtils.adaptToAccent(Appearance.colors.colPrimaryHover, artDominantColor), artDominantColor, 0.3)
        property color colPrimaryActive: ColorUtils.mix(ColorUtils.adaptToAccent(Appearance.colors.colPrimaryActive, artDominantColor), artDominantColor, 0.3)
        property color colSecondaryContainer: ColorUtils.mix(Appearance.m3colors.m3secondaryContainer, artDominantColor, 0.3)
        property color colSecondaryContainerHover: ColorUtils.mix(Appearance.colors.colSecondaryContainerHover, artDominantColor, 0.3)
        property color colSecondaryContainerActive: ColorUtils.mix(Appearance.colors.colSecondaryContainerActive, artDominantColor, 0.5)
        property color colOnPrimary: ColorUtils.mix(ColorUtils.adaptToAccent(Appearance.m3colors.m3onPrimary, artDominantColor), artDominantColor, 0.5)
        property color colOnSecondaryContainer: ColorUtils.mix(Appearance.m3colors.m3onSecondaryContainer, artDominantColor, 0.2)
    }

    // Background
    radius: Appearance.rounding.large
    clip: true
    color: "transparent"
    border.width: 0
    visible: true

    Behavior on color {
        ColorAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    // Blurred album art background (now just a semi-transparent background for Hyprland blur)
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.3) // Use theme color with alpha if preferred
        radius: root.radius
        clip: true
    }

    // Main content
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 32
        spacing: 18
        // Centered album art
        Rectangle {
            id: albumArtContainer
            Layout.preferredWidth: 120
            Layout.preferredHeight: 120
            Layout.alignment: Qt.AlignHCenter
            radius: 14
            clip: true
            color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 0
            Image {
                anchors.fill: parent
                source: root.downloaded ? Qt.resolvedUrl(root.artFilePath) : ""
                fillMode: Image.PreserveAspectCrop
                cache: false
                asynchronous: true
                visible: root.downloaded && status === Image.Ready
                onStatusChanged: { if (status === Image.Error) root.downloaded = false }
            }
            Image {
                anchors.centerIn: parent
                width: 48
                height: 48
                source: "image://icon/music_note"
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                visible: !root.downloaded || albumArtContainer.children[0].status !== Image.Ready
            }
        }
        // Track info
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 4
            StyledText {
                Layout.fillWidth: true
                text: activePlayer?.trackTitle || "No track"
                color: "#ffffff"
                font.pixelSize: 18
                font.weight: Font.Medium
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
            StyledText {
                Layout.fillWidth: true
                text: {
                    var parts = []
                    if (activePlayer?.trackArtist) parts.push(activePlayer.trackArtist)
                    if (activePlayer?.trackAlbum) parts.push(activePlayer.trackAlbum)
                    return parts.join(" • ")
                }
                color: Qt.rgba(1, 1, 1, 0.8)
                font.pixelSize: 14
                elide: Text.ElideRight
                maximumLineCount: 1
                visible: text.length > 0
                horizontalAlignment: Text.AlignHCenter
            }
        }
        // Controls
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 18
            z: 1
            // Shuffle (icon only)
            MaterialSymbol {
                text: "shuffle"
                iconSize: 20
                color: "#ffffff"
                opacity: 0.8
                enabled: activePlayer
                MouseArea {
                    anchors.fill: parent
                    onClicked: console.log("Shuffle button clicked", activePlayer)
                    cursorShape: Qt.PointingHandCursor
                }
            }
            // Previous
            QuickToggleButton {
                buttonIcon: "skip_previous"
                toggled: false
                enabled: activePlayer?.canGoPrevious ?? false
                onClicked: {
                    console.log("Previous button: dispatching activePlayer.previous()", activePlayer)
                    activePlayer?.previous()
                }
            }
            // Play/Pause
            QuickToggleButton {
                buttonIcon: activePlayer?.playbackState == MprisPlaybackState.Playing ? "pause" : "play_arrow"
                toggled: activePlayer?.playbackState == MprisPlaybackState.Playing
                enabled: activePlayer?.canTogglePlaying ?? false
                onClicked: {
                    console.log("Play/Pause button: dispatching activePlayer.togglePlaying()", activePlayer)
                    activePlayer?.togglePlaying()
                }
            }
            // Next
            QuickToggleButton {
                buttonIcon: "skip_next"
                toggled: false
                enabled: activePlayer?.canGoNext ?? false
                onClicked: {
                    console.log("Next button: dispatching activePlayer.next()", activePlayer)
                    activePlayer?.next()
                }
            }
            // Repeat (icon only)
            MaterialSymbol {
                text: "repeat"
                iconSize: 20
                color: "#ffffff"
                opacity: 0.8
                enabled: activePlayer
                MouseArea {
                    anchors.fill: parent
                    onClicked: console.log("Repeat button clicked", activePlayer)
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
        // Progress bar
        StyledSlider {
            id: progressBar
            Layout.fillWidth: true
            scale: 0.5
            from: 0
            to: activePlayer?.length || 1
            value: activePlayer?.position || 0
            onValueChanged: {
                if (activePlayer && !pressed) {
                    activePlayer.position = value
                }
            }
            onPressedChanged: console.log("Progress slider pressed changed", pressed)
            enabled: activePlayer && activePlayer.length > 0
            visible: activePlayer
            highlightColor: "#ffffff"
            trackColor: Qt.rgba(1, 1, 1, 0.3)
            handleColor: "#ffffff"
            tooltipContent: `${Math.round((value / Math.max(1, to)) * 100)}%`
            z: 1
        }
        // Volume control
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 10
            z: 1
            MaterialSymbol {
                text: "volume_down"
                iconSize: 18
                color: "#ffffff"
                opacity: 0.8
            }
            StyledSlider {
                id: volumeSlider
                Layout.fillWidth: true
                scale: 0.5
                from: 0
                to: 1
                value: Audio.sink?.audio?.volume || 0
                onValueChanged: {
                    if (Audio.sink?.audio) {
                        console.log("Volume slider: dispatching Audio.sink.audio.volume =", value, Audio.sink.audio)
                        Audio.sink.audio.volume = value
                    }
                }
                onPressedChanged: console.log("Volume slider pressed changed", pressed)
                highlightColor: "#ffffff"
                trackColor: Qt.rgba(1, 1, 1, 0.3)
                handleColor: "#ffffff"
                tooltipContent: `${Math.round(value * 100)}%`
                z: 1
            }
            MaterialSymbol {
                text: "volume_up"
                iconSize: 18
                color: "#ffffff"
                opacity: 0.8
            }
        }
    }

    // Place MouseArea behind all controls, only covering the background
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        z: 0 // ensure it's behind everything
        MouseArea {
            anchors.fill: parent
            onClicked: {
                console.log("Background MouseArea clicked, dispatching Hyprland popup")
                Hyprland.dispatch("global quickshell:simpleMediaPlayer:toggle")
            }
        }
    }
} 