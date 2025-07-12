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

Item { // Player instance
    id: playerController
    required property MprisPlayer player
    property var artUrl: player?.trackArtUrl
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: artUrl ? Qt.md5(artUrl) + ".jpg" : ""
    property string artFilePath: artFileName ? `${artDownloadLocation}/${artFileName}` : ""
    property color artDominantColor: colorQuantizer?.colors[0] || Appearance.m3colors.m3secondaryContainer
    property bool downloaded: false

    // Function to get application icon from MPRIS player
    function getPlayerIcon() {
        if (!player?.dbusName) return "music_note"
        
        // Extract app name from dbus name (e.g., "org.mpris.MediaPlayer2.cider" -> "cider")
        const dbusName = player.dbusName
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

    implicitWidth: widgetWidth
    implicitHeight: widgetHeight

    component TrackChangeButton: RippleButton {
        implicitWidth: 24
        implicitHeight: 24

        property var iconName
        colBackground: ColorUtils.transparentize(blendedColors.colSecondaryContainer, 1)
        colBackgroundHover: blendedColors.colSecondaryContainerHover
        colRipple: blendedColors.colSecondaryContainerActive

        contentItem: MaterialSymbol {
            iconSize: Appearance.font.pixelSize.huge
            fill: 1
            horizontalAlignment: Text.AlignHCenter
            color: blendedColors.colOnSecondaryContainer
            text: iconName

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }



    // Enhanced position tracking with fallbacks
    property real displayPosition: 0
    property real displayLength: 0
    property string currentTrackId: ""
    property real lastValidPosition: 0
    property real positionStartTime: 0
    
    // Track current song to detect changes
    function updateTrackId() {
        var newTrackId = (playerController.player?.trackTitle || "") + "|" + (playerController.player?.trackArtist || "")
        if (newTrackId !== currentTrackId) {
            currentTrackId = newTrackId
            displayPosition = 0
            lastValidPosition = 0
            positionStartTime = Date.now()
            console.log("[PlayerControl] New track detected, resetting position")
        }
    }
    
    // Enhanced position update timer with fallbacks
    Timer {
        id: positionTracker
        running: playerController.player?.playbackState == MprisPlaybackState.Playing
        interval: 100
        repeat: true
        onTriggered: {
            if (!playerController.player) return
            
            updateTrackId()
            
            var mprisPosition = playerController.player.position || 0
            var mprisLength = playerController.player.length || 0
            var currentTime = Date.now()
            
            // Update display length with fallback
            displayLength = mprisLength > 0 ? mprisLength : displayLength
            
            // Fallback position calculation if MPRIS position is invalid
            var calculatedPosition = mprisPosition
            
            // Check if MPRIS position is valid and different from our current display
            var positionDifference = Math.abs(mprisPosition - displayPosition)
            var isValidPosition = mprisPosition >= 0 && (mprisLength <= 0 || mprisPosition <= mprisLength)
            
            if (isValidPosition && positionDifference > 1) {
                // MPRIS position is valid and significantly different - likely seeking
                calculatedPosition = mprisPosition
                lastValidPosition = mprisPosition
                positionStartTime = currentTime
            } else if (mprisPosition <= 0 || mprisPosition > mprisLength) {
                // MPRIS position seems invalid, calculate from elapsed time
                var elapsedSeconds = (currentTime - positionStartTime) / 1000
                calculatedPosition = lastValidPosition + elapsedSeconds
            } else if (isValidPosition) {
                // MPRIS position is valid but close to current - update fallback tracking
                lastValidPosition = mprisPosition
                positionStartTime = currentTime
                calculatedPosition = mprisPosition
            }
            
            // Ensure position is within bounds
            calculatedPosition = Math.max(0, calculatedPosition)
            if (displayLength > 0) {
                calculatedPosition = Math.min(calculatedPosition, displayLength)
            }
            
            // Reset to 0 if we're at the end or beyond
            if (displayLength > 0 && calculatedPosition >= displayLength - 0.5) {
                calculatedPosition = 0
                lastValidPosition = 0
                positionStartTime = currentTime
            }
            
            displayPosition = calculatedPosition
        }
    }
    
    // Additional aggressive position polling timer for seeking detection
    Timer {
        id: seekingDetector
        running: playerController.player != null
        interval: 50  // Very fast polling for seeking detection
        repeat: true
        onTriggered: {
            if (!playerController.player) return
            
            // Force MPRIS position update to trigger onPositionChanged
            playerController.player.positionChanged()
            
            var currentMprisPosition = playerController.player.position || 0
            var trackLength = playerController.player.length || 0
            
            // Check for significant position jumps that indicate seeking
            var positionJump = Math.abs(currentMprisPosition - lastValidPosition)
            var isValidJump = currentMprisPosition >= 0 && (trackLength <= 0 || currentMprisPosition <= trackLength)
            
            // If we detect a jump of more than 3 seconds, it's likely seeking
            if (isValidJump && positionJump > 3) {
                console.log("[PlayerControl] Seeking detected! Jump from", lastValidPosition, "to", currentMprisPosition)
                displayPosition = Math.max(0, currentMprisPosition)
                lastValidPosition = currentMprisPosition
                positionStartTime = Date.now()
            }
        }
    }
    
    // Reset position when playback state changes
    Connections {
        target: playerController.player
        function onPlaybackStateChanged() {
            if (playerController.player?.playbackState == MprisPlaybackState.Playing) {
                positionStartTime = Date.now()
            }
        }
        function onPositionChanged() {
            // Update our fallback tracking when we get valid MPRIS position
            var newPosition = playerController.player?.position || 0
            var trackLength = playerController.player?.length || 0
            
            // Check if this is a significant position change (seeking)
            var positionDifference = Math.abs(newPosition - displayPosition)
            var isValidPosition = newPosition >= 0 && (trackLength <= 0 || newPosition <= trackLength)
            
            // Be more sensitive to position changes - even 1 second could be seeking
            if (isValidPosition && (positionDifference > 0.5 || newPosition != lastValidPosition)) {
                // Immediately update display position for any significant change
                displayPosition = Math.max(0, newPosition)
                lastValidPosition = newPosition
                positionStartTime = Date.now()
                console.log("[PlayerControl] Position changed - updated to:", displayPosition, "diff:", positionDifference)
            }
        }
    }

    // Timer to retry album art download if it's missing
    Timer {
        id: artRetryTimer
        running: playerController.player && !playerController.downloaded && playerController.artUrl && playerController.artUrl.length > 0
        interval: 2000  // Check every 2 seconds
        repeat: true
        onTriggered: {
            console.log("[PlayerControl] Retrying album art download for:", playerController.artUrl)
            if (playerController.artUrl && playerController.artUrl.length > 0 && playerController.artFilePath && playerController.artFilePath.length > 0) {
                coverArtDownloader.running = true
            }
        }
    }

    onArtUrlChanged: {
        if (playerController.artUrl.length == 0) {
            playerController.artDominantColor = Appearance.m3colors.m3secondaryContainer
            playerController.downloaded = false
            return;
        }
        console.log("[PlayerControl] Art URL changed to:", playerController.artUrl)
        playerController.downloaded = false
        
        // Check if file already exists before downloading
        var fileExistsCmd = [ "bash", "-c", `[ -f '${playerController.artFilePath}' ] && [ -s '${playerController.artFilePath}' ] && echo "exists" || echo "missing"` ]
        var fileChecker = Qt.createQmlObject('import Quickshell.Io; Process { }', playerController)
        fileChecker.command = fileExistsCmd
        fileChecker.onExited.connect(function(exitCode, exitStatus) {
            if (exitCode === 0) {
                var output = fileChecker.stdout ? fileChecker.stdout.trim() : ""
                if (output === "exists") {
                    playerController.downloaded = true
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

    // Add connections to handle metadata updates
    Connections {
        target: playerController.player
        function onTrackArtUrlChanged() { 
            console.log("[PlayerControl] Track art URL changed via signal:", playerController.player?.trackArtUrl)
            playerController.artUrl = playerController.player?.trackArtUrl || ""
        }
        function onTrackTitleChanged() { 
            // Reset download state for new track
            playerController.downloaded = false
            // Reset position tracking
            displayPosition = 0
            lastValidPosition = 0
            positionStartTime = Date.now()
        }
        function onTrackAlbumChanged() {
            // Sometimes album art URL is updated when album info changes
            console.log("[PlayerControl] Track album changed, checking for art URL updates")
            if (playerController.player?.trackArtUrl && playerController.player.trackArtUrl !== playerController.artUrl) {
                playerController.artUrl = playerController.player.trackArtUrl
            }
        }
        function onTrackArtistChanged() {
            // Sometimes album art URL is updated when artist info changes
            console.log("[PlayerControl] Track artist changed, checking for art URL updates")
            if (playerController.player?.trackArtUrl && playerController.player.trackArtUrl !== playerController.artUrl) {
                playerController.artUrl = playerController.player.trackArtUrl
            }
        }
        function onLengthChanged() {
            // Update display length when we get valid length data
            if (playerController.player?.length > 0) {
                displayLength = playerController.player.length
            }
        }
    }

    Process { // Cover art downloader
        id: coverArtDownloader
        property string targetFile: playerController.artUrl
        command: [ "bash", "-c", `mkdir -p '${playerController.artDownloadLocation}' && curl -sSL --max-time 10 --retry 2 '${playerController.artUrl}' -o '${playerController.artFilePath}' && [ -s '${playerController.artFilePath}' ]` ]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                playerController.downloaded = true
            } else {
                console.log("[PlayerControl] Failed to download album art for:", playerController.artUrl)
                playerController.downloaded = false
            }
        }
    }

    ColorQuantizer {
        id: colorQuantizer
        source: playerController.downloaded ? Qt.resolvedUrl(playerController.artFilePath) : ""
        depth: 0 // 2^0 = 1 color
        rescaleSize: 1 // Rescale to 1x1 pixel for faster processing
    }

    property QtObject blendedColors: QtObject {
        property color colLayer0: ColorUtils.mix(Appearance.colors.colLayer0, artDominantColor, 0.5)
        property color colLayer1: ColorUtils.mix(Appearance.colors.colLayer1, artDominantColor, 0.5)
        property color colOnLayer0: ColorUtils.mix(Appearance.colors.colOnLayer0, artDominantColor, 0.5)
        property color colOnLayer1: ColorUtils.mix(Appearance.colors.colOnLayer1, artDominantColor, 0.5)
        property color colSubtext: ColorUtils.mix(Appearance.colors.colOnLayer1, artDominantColor, 0.5)
        property color colPrimary: ColorUtils.mix(ColorUtils.adaptToAccent(Appearance.colors.colPrimary, artDominantColor), artDominantColor, 0.5)
        property color colPrimaryHover: ColorUtils.mix(ColorUtils.adaptToAccent(Appearance.colors.colPrimaryHover, artDominantColor), artDominantColor, 0.3)
        property color colPrimaryActive: ColorUtils.mix(ColorUtils.adaptToAccent(Appearance.colors.colPrimaryActive, artDominantColor), artDominantColor, 0.3)
        property color colSecondaryContainer: ColorUtils.mix(Appearance.m3colors.m3secondaryContainer, artDominantColor, 0.3)
        property color colSecondaryContainerHover: ColorUtils.mix(Appearance.colors.colSecondaryContainerHover, artDominantColor, 0.3)
        property color colSecondaryContainerActive: ColorUtils.mix(Appearance.colors.colSecondaryContainerActive, artDominantColor, 0.5)
        property color colOnPrimary: ColorUtils.mix(ColorUtils.adaptToAccent(Appearance.m3colors.m3onPrimary, artDominantColor), artDominantColor, 0.5)
        property color colOnSecondaryContainer: ColorUtils.mix(Appearance.m3colors.m3onSecondaryContainer, artDominantColor, 0.2)

    }

    StyledRectangularShadow {
        target: background
    }
    Rectangle { // Background
        id: background
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin
        color: blendedColors.colLayer0
        radius: root.popupRounding

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: background.width
                height: background.height
                radius: background.radius
            }
        }

        Image {
            id: blurredArt
            anchors.fill: parent
            source: playerController.downloaded ? Qt.resolvedUrl(playerController.artFilePath) : ""
            sourceSize.width: background.width
            sourceSize.height: background.height
            fillMode: Image.PreserveAspectCrop
            cache: false
            antialiasing: true
            asynchronous: true

            layer.enabled: true
            layer.effect: MultiEffect {
                source: blurredArt
                saturation: 0.2
                blurEnabled: true
                blurMax: 100
                blur: 1
            }
            
            onStatusChanged: {
                if (status === Image.Error) {
                    console.log("[PlayerControl] Blurred art load error for:", source)
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(
                    blendedColors.colLayer0.r,
                    blendedColors.colLayer0.g,
                    blendedColors.colLayer0.b,
                    0.65
                )
                radius: root.popupRounding
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: root.contentPadding
            spacing: 15

            Rectangle { // Art background
                id: artBackground
                Layout.fillHeight: true
                implicitWidth: height
                radius: root.artRounding
                color: Qt.rgba(
                    blendedColors.colLayer1.r,
                    blendedColors.colLayer1.g,
                    blendedColors.colLayer1.b,
                    0.85
                )

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: artBackground.width
                        height: artBackground.height
                        radius: artBackground.radius
                    }
                }

                Image { // Art image
                    id: mediaArt
                    property int size: parent.height
                    anchors.fill: parent

                    source: playerController.downloaded ? Qt.resolvedUrl(playerController.artFilePath) : ""
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    antialiasing: true
                    asynchronous: true

                    width: size
                    height: size
                    sourceSize.width: size
                    sourceSize.height: size
                    
                    onStatusChanged: {
                        if (status === Image.Error) {
                            console.log("[PlayerControl] Image load error for:", source)
                            playerController.downloaded = false
                        } else if (status === Image.Ready) {
                            console.log("[PlayerControl] Successfully loaded album art:", source)
                        }
                    }
                }

                // Show player icon when no album art is available
                Image {
                    anchors.centerIn: parent
                    width: 48
                    height: 48
                    source: "image://icon/" + (playerController.getPlayerIcon() || "multimedia-player")
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    visible: !playerController.downloaded || mediaArt.status !== Image.Ready
                }
            }

            ColumnLayout { // Info & controls
                Layout.fillHeight: true
                spacing: 2

                StyledText {
                    id: trackTitle
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.large
                    color: blendedColors.colOnLayer0
                    elide: Text.ElideRight
                    text: StringUtils.cleanMusicTitle(playerController.player?.trackTitle) || "Untitled"
                }
                StyledText {
                    id: trackArtist
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: blendedColors.colSubtext
                    elide: Text.ElideRight
                    text: playerController.player?.trackArtist
                }
                Item { Layout.fillHeight: true }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: trackTime.implicitHeight + sliderRow.implicitHeight

                    StyledText {
                        id: trackTime
                        anchors.bottom: sliderRow.top
                        anchors.bottomMargin: 5
                        anchors.left: parent.left
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: blendedColors.colSubtext
                        elide: Text.ElideRight
                        text: {
                            var currentTime = StringUtils.friendlyTimeForSeconds(Math.max(0, displayPosition))
                            var totalTime = StringUtils.friendlyTimeForSeconds(Math.max(0, displayLength))
                            return `${currentTime} / ${totalTime}`
                        }
                    }
                    RowLayout {
                        id: sliderRow
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                        }
                        TrackChangeButton {
                            iconName: "skip_previous"
                            onClicked: playerController.player?.previous()
                        }
                        StyledProgressBar {
                            id: slider
                            Layout.fillWidth: true
                            highlightColor: blendedColors.colPrimary
                            trackColor: blendedColors.colSecondaryContainer
                            value: {
                                var length = Math.max(1, displayLength)
                                var position = Math.max(0, displayPosition)
                                var progress = position / length
                                return Math.max(0, Math.min(1, progress))
                            }
                        }
                        TrackChangeButton {
                            iconName: "skip_next"
                            onClicked: playerController.player?.next()
                        }
                    }

                    RippleButton {
                        id: playPauseButton
                        anchors.right: parent.right
                        anchors.bottom: sliderRow.top
                        anchors.bottomMargin: 5
                        property real size: 44
                        implicitWidth: size
                        implicitHeight: size
                        onClicked: playerController.player.togglePlaying();

                        buttonRadius: playerController.player?.isPlaying ? Appearance?.rounding.normal : size / 2
                        colBackground: playerController.player?.isPlaying ? blendedColors.colPrimary : blendedColors.colSecondaryContainer
                        colBackgroundHover: playerController.player?.isPlaying ? blendedColors.colPrimaryHover : blendedColors.colSecondaryContainerHover
                        colRipple: playerController.player?.isPlaying ? blendedColors.colPrimaryActive : blendedColors.colSecondaryContainerActive

                        contentItem: MaterialSymbol {
                            iconSize: Appearance.font.pixelSize.huge
                            fill: 1
                            horizontalAlignment: Text.AlignHCenter
                            color: playerController.player?.isPlaying ? blendedColors.colOnPrimary : blendedColors.colOnSecondaryContainer
                            text: playerController.player?.isPlaying ? "pause" : "play_arrow"

                            Behavior on color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                            }
                        }
                    }
                }
            }
        }
    }
}