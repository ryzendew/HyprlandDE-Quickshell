import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Hyprland
import QtQuick.Effects

Item {
    id: root
    property bool borderless: ConfigOptions.bar?.borderless ?? false
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || qsTr("No media")
    // Properties to control progress bar position
    property int progressBarYOffset: 35 // Positive moves down, negative moves up
    property int progressBarXOffset: 3 // Positive moves right, negative moves left
    property int progressBarWidth: 0 // Set this to control the width of the progress bar
    // Properties to control time display position
    property int timeYOffset: 20 // Positive moves down, negative moves up
    property int timeXOffset: 290 // Positive moves right, negative moves left

    property string artUrl: activePlayer?.trackArtUrl || ""
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: artUrl ? Qt.md5(artUrl) + ".jpg" : ""
    property string artFilePath: artFileName ? `${artDownloadLocation}/${artFileName}` : ""
    property bool downloaded: false
    
    // Visualizer properties
    property bool showVisualizer: ConfigOptions.bar.media.showVisualizer
    property string visualizerType: ConfigOptions.bar.media.visualizerType
    property int visualizerBars: ConfigOptions.bar.media.visualizerBars
    
    // Cava visualizer service
    readonly property var cavaValues: Cava.values

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

    // Time formatting functions
    function formatTime(seconds) {
        if (!seconds || seconds <= 0) return "0:00"
        let timeInSeconds = seconds
        if (seconds > 1000000) {
            timeInSeconds = seconds / 1000000
        } else if (seconds > 1000) {
            timeInSeconds = seconds / 1000
        }
        return Math.floor(timeInSeconds / 60) + ":" + Math.floor(timeInSeconds % 60).toString().padStart(2, '0')
    }

    function getTrackYear() {
        // Try to get year from metadata, fallback to current year
        if (activePlayer?.trackYear) return activePlayer.trackYear
        if (activePlayer?.releaseYear) return activePlayer.releaseYear
        return new Date().getFullYear()
    }

    Layout.fillHeight: true
    // Set the pill's width to match content (album art + song title + artist text + progress bar + padding)
    implicitWidth: {
        var albumArtWidth = albumArtContainer ? albumArtContainer.width : 40
        var songTitleWidth = songTitle ? songTitle.contentWidth : 0
        var artistTextWidth = albumArtistText ? albumArtistText.contentWidth : 0
        var maxTextWidth = Math.max(songTitleWidth, artistTextWidth)
        return albumArtWidth + maxTextWidth + 40
    }
    implicitHeight: 40



    // Enhanced position tracking with fallbacks
    property real displayPosition: 0
    property real displayLength: 0
    property string currentTrackId: ""
    property real lastValidPosition: 0
    property real positionStartTime: 0
    
    // Track current song to detect changes
    function updateTrackId() {
        var newTrackId = (activePlayer?.trackTitle || "") + "|" + (activePlayer?.trackArtist || "")
        if (newTrackId !== currentTrackId) {
            currentTrackId = newTrackId
            displayPosition = 0
            lastValidPosition = 0
            positionStartTime = Date.now()
            // console.log("[BarMedia] New track detected, resetting position")
        }
    }
    
    // Enhanced position update timer with fallbacks
    Timer {
        id: positionTracker
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: 100
        repeat: true
        onTriggered: {
            if (!activePlayer) return
            
            updateTrackId()
            
            var mprisPosition = activePlayer.position || 0
            var mprisLength = activePlayer.length || 0
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
        running: activePlayer != null
        interval: 50  // Very fast polling for seeking detection
        repeat: true
        onTriggered: {
            if (!activePlayer) return
            
            // Force MPRIS position update to trigger onPositionChanged
            activePlayer.positionChanged()
            
            var currentMprisPosition = activePlayer.position || 0
            var trackLength = activePlayer.length || 0
            
            // Check for significant position jumps that indicate seeking
            var positionJump = Math.abs(currentMprisPosition - lastValidPosition)
            var isValidJump = currentMprisPosition >= 0 && (trackLength <= 0 || currentMprisPosition <= trackLength)
            
            // If we detect a jump of more than 3 seconds, it's likely seeking
            if (isValidJump && positionJump > 3) {
                // console.log("[BarMedia] Seeking detected! Jump from", lastValidPosition, "to", currentMprisPosition)
                displayPosition = Math.max(0, currentMprisPosition)
                lastValidPosition = currentMprisPosition
                positionStartTime = Date.now()
            }
        }
    }
    
    // Reset position when playback state changes
    Connections {
        target: activePlayer
        function onPlaybackStateChanged() {
            if (activePlayer?.playbackState == MprisPlaybackState.Playing) {
                positionStartTime = Date.now()
            }
        }
        function onPositionChanged() {
            // Update our fallback tracking when we get valid MPRIS position
            var newPosition = activePlayer?.position || 0
            var trackLength = activePlayer?.length || 0
            
            // Check if this is a significant position change (seeking)
            var positionDifference = Math.abs(newPosition - displayPosition)
            var isValidPosition = newPosition >= 0 && (trackLength <= 0 || newPosition <= trackLength)
            
            // Be more sensitive to position changes - even 1 second could be seeking
            if (isValidPosition && (positionDifference > 0.5 || newPosition != lastValidPosition)) {
                // Immediately update display position for any significant change
                displayPosition = Math.max(0, newPosition)
                lastValidPosition = newPosition
                positionStartTime = Date.now()
                // console.log("[BarMedia] Position changed - updated to:", displayPosition, "diff:", positionDifference)
            }
        }
    }

    // Timer to retry album art download if it's missing
    Timer {
        id: artRetryTimer
        running: activePlayer && !root.downloaded && root.artUrl && root.artUrl.length > 0
        interval: 2000  // Check every 2 seconds
        repeat: true
        onTriggered: {
            // console.log("[BarMedia] Retrying album art download for:", root.artUrl)
            if (root.artUrl && root.artUrl.length > 0 && root.artFilePath && root.artFilePath.length > 0) {
                coverArtDownloader.running = true
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        onPressed: (event) => {
            if (event.button === Qt.MiddleButton) {
                activePlayer.togglePlaying();
            } else if (event.button === Qt.BackButton) {
                activePlayer.previous();
            } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                activePlayer.next();
            } else if (event.button === Qt.LeftButton) {
                Hyprland.dispatch("global quickshell:mediaControlsToggle")
            }
        }
    }

    Rectangle { // Background
        anchors.centerIn: parent
        width: root.implicitWidth // Match the content width
        implicitHeight: 56
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        anchors.topMargin: 2
        anchors.bottomMargin: 2
        color: borderless ? "transparent" : Qt.rgba(
            Appearance.colors.colLayer1.r,
            Appearance.colors.colLayer1.g,
            Appearance.colors.colLayer1.b,
            0.35
        )
        radius: Appearance.rounding.small

        // Cava visualizer as pill background
        CircularSpectrum {
            id: pillSpectrum
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.rightMargin: 2 // Add 2px padding on the right side
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -9 // Move the visualizer up
            fillColor: Appearance.colors.colPrimary
            values: Cava.values
            opacity: 0.08 // Increased semi-transparent effect
            z: 0
        }
    }

    onArtUrlChanged: {
        // console.log("[BarMedia] Art URL changed to:", root.artUrl)
        if (root.artUrl && root.artUrl.length > 0 && root.artFilePath && root.artFilePath.length > 0) {
            root.downloaded = false
            // console.log("[BarMedia] Starting download for:", root.artUrl)
            // console.log("[BarMedia] File path will be:", root.artFilePath)
            coverArtDownloader.running = true
        } else {
            root.downloaded = false
            // console.log("[BarMedia] No art URL provided or invalid file path")
        }
    }

    Process { // Cover art downloader - simplified for debugging
        id: coverArtDownloader
        property string targetFile: root.artUrl
        command: [ "bash", "-c", `mkdir -p '${root.artDownloadLocation}' && curl -sSL --max-time 10 --retry 2 '${root.artUrl}' -o '${root.artFilePath}' && [ -s '${root.artFilePath}' ]` ]
        onExited: (exitCode, exitStatus) => {
            // console.log("[BarMedia] Download process exited with code:", exitCode)
            if (exitCode === 0) {
                // console.log("[BarMedia] Download successful, setting downloaded = true")
                root.downloaded = true
            } else {
                // console.log("[BarMedia] Download failed for:", root.artUrl)
                root.downloaded = false
            }
        }
    }



    Connections {
        target: activePlayer
        function onTrackArtUrlChanged() { 
            // console.log("[BarMedia] Track art URL changed via signal:", activePlayer?.trackArtUrl)
            root.artUrl = activePlayer?.trackArtUrl || "" 
        }
        function onTrackTitleChanged() { 
            // Reset position when track changes
            displayPosition = 0
            // Also reset download state for new track
            root.downloaded = false
            // Reset position tracking
            lastValidPosition = 0
            positionStartTime = Date.now()
        }
        function onTrackAlbumChanged() {
            // Sometimes album art URL is updated when album info changes
            // console.log("[BarMedia] Track album changed, checking for art URL updates")
            if (activePlayer?.trackArtUrl && activePlayer.trackArtUrl !== root.artUrl) {
                root.artUrl = activePlayer.trackArtUrl
            }
        }
        function onTrackArtistChanged() {
            // Sometimes album art URL is updated when artist info changes
            // console.log("[BarMedia] Track artist changed, checking for art URL updates")
            if (activePlayer?.trackArtUrl && activePlayer.trackArtUrl !== root.artUrl) {
                root.artUrl = activePlayer.trackArtUrl
            }
        }
        function onLengthChanged() {
            // Update display length when we get valid length data
            if (activePlayer?.length > 0) {
                displayLength = activePlayer.length
            }
        }
    }

    RowLayout { // Real content
        id: rowLayout
        spacing: 10
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 12
        height: parent.height - anchors.topMargin

        // Album art on the left with visualizer
        Item {
            id: albumArtContainer
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            Layout.leftMargin: 2
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: -8
            visible: root.activePlayer

            // Album art on top
            Rectangle {
                id: albumArtRect
                anchors.centerIn: parent
                width: 40
                height: 40
                radius: 8
                color: Qt.rgba(
                    Appearance.colors.colLayer1.r,
                    Appearance.colors.colLayer1.g,
                    Appearance.colors.colLayer1.b,
                    0.65
                )
                border.color: Qt.rgba(
                    Appearance.colors.colOnLayer1.r,
                    Appearance.colors.colOnLayer1.g,
                    Appearance.colors.colOnLayer1.b,
                    0.6
                )
                border.width: 2
                layer.enabled: true
                layer.smooth: true
                clip: true

                // Album art image with rounded corners
                Image {
                    id: albumArtImage
                    anchors.fill: parent
                    anchors.margins: 2
                    source: root.downloaded ? Qt.resolvedUrl(root.artFilePath) : ""
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    asynchronous: true
                    visible: root.downloaded && status === Image.Ready
                    layer.enabled: true
                    layer.smooth: true
                    onStatusChanged: {
                        if (status === Image.Error) {
                            root.downloaded = false
                        }
                    }
                }

                // Show player icon when no album art is available or image failed to load
                MaterialSymbol {
                    anchors.centerIn: parent
                    iconSize: 20
                    text: "music_note"
                    color: Appearance.colors.colOnLayer1
                    visible: !root.downloaded || albumArtImage.status !== Image.Ready
                }
            }
        }

        // Main content area with song info and progress bar
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: -3
            spacing: 0

            // Song name on top
            StyledText {
                id: songTitle
                Layout.fillWidth: false
                Layout.preferredWidth: contentWidth
                text: activePlayer?.trackTitle || cleanedTitle
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                elide: Text.ElideNone
                maximumLineCount: 1
            }
            MultiEffect {
                Layout.fillWidth: false
                Layout.fillHeight: false
                anchors.fill: songTitle
                source: songTitle
                shadowEnabled: true
                shadowColor: "black"
                shadowBlur: 1.0
                shadowVerticalOffset: 1.5
                shadowOpacity: 0.7
            }

            // Album - Artist name with time display
            RowLayout {
                id: albumInfoRow
                Layout.topMargin: -20
                spacing: 0 // No extra spacing needed
                StyledText {
                    id: albumArtistText
                    Layout.fillWidth: false
                    Layout.preferredWidth: contentWidth
                    color: Appearance.colors.colOnLayer1
                    opacity: 0.7
                    text: {
                        var parts = []
                        if (activePlayer?.trackAlbum) parts.push(activePlayer.trackAlbum)
                        if (activePlayer?.trackArtist) parts.push(activePlayer.trackArtist)
                        var main = parts.join(" - ")
                        var currentTime = formatTime(Math.max(0, displayPosition))
                        var timeRemaining = formatTime(Math.max(0, displayLength - displayPosition))
                        var timeText = (root.activePlayer ? (" " + currentTime + " / " + timeRemaining) : "")
                        return main + timeText
                    }
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    elide: Text.ElideNone
                    maximumLineCount: 1
                    visible: text.length > 0
                }
                MultiEffect {
                    Layout.fillWidth: false
                    Layout.fillHeight: false
                    anchors.fill: albumArtistText
                    source: albumArtistText
                    shadowEnabled: true
                    shadowColor: "black"
                    shadowBlur: 1.0
                    shadowVerticalOffset: 1.5
                    shadowOpacity: 0.7
                }
                // Removed separate time StyledText and MultiEffect
            }
        }
    }

    // Time display absolutely positioned
    // StyledText {
    //     id: timeDisplay
    //     x: timeXOffset
    //     y: timeYOffset
    //     color: Appearance.colors.colOnLayer1
    //     opacity: 0.6
    //     text: {
    //         var currentTime = formatTime(Math.max(0, displayPosition))
    //         var timeRemaining = formatTime(Math.max(0, displayLength - displayPosition))
    //         return currentTime + " / -" + timeRemaining
    //     }
    //     font.pixelSize: Appearance.font.pixelSize.smaller
    //     font.weight: Font.Bold
    //     visible: root.activePlayer
    // }

    // Progress bar absolutely positioned
    Rectangle {
        id: progressBarBackground
        anchors.top: rowLayout.top
        anchors.left: rowLayout.left
        anchors.topMargin: progressBarYOffset
        anchors.leftMargin: progressBarXOffset
        width: albumArtistText.width + 55 // 4px more than before
        height: 3
        radius: 1.5
        color: Qt.rgba(
            Appearance.m3colors.m3secondaryContainer.r,
            Appearance.m3colors.m3secondaryContainer.g,
            Appearance.m3colors.m3secondaryContainer.b,
            0.4
        )
        visible: root.activePlayer

        Rectangle {
            id: progressBarFill
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * Math.max(0, Math.min(1, displayPosition / Math.max(1, displayLength)))
            height: parent.height
            radius: parent.radius
            color: Appearance.m3colors.m3primary
            Behavior on width {
                enabled: activePlayer?.playbackState == MprisPlaybackState.Playing
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
