import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Hyprland

Item {
    id: root
    property bool borderless: ConfigOptions.bar.borderless
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || qsTr("No media")

    property string artUrl: activePlayer?.trackArtUrl || ""
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(artUrl) + ".jpg"
    property string artFilePath: `${artDownloadLocation}/${artFileName}`
    property bool downloaded: false

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
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: 40

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: 1000
        repeat: true
        onTriggered: activePlayer.positionChanged()
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
        width: parent.width
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
    }



    onArtUrlChanged: {
        if (root.artUrl && root.artUrl.length > 0) {
            root.downloaded = false
            coverArtDownloader.running = true
        } else {
            root.downloaded = false
        }
    }

    Process { // Cover art downloader - simplified
        id: coverArtDownloader
        property string targetFile: root.artUrl
        command: [ "bash", "-c", `mkdir -p '${artDownloadLocation}' && curl -sSL '${targetFile}' -o '${artFilePath}' 2>/dev/null || true` ]
        onExited: (exitCode, exitStatus) => {
            // Always try to set downloaded to true - let the Image component handle errors
                root.downloaded = true
        }
    }

    // Track the current song to detect changes
    property string currentTrackId: activePlayer ? (activePlayer.trackTitle + "|" + activePlayer.trackArtist) : ""
    property real displayPosition: 0
    
    onCurrentTrackIdChanged: {
        // Reset display position when song changes
        displayPosition = 0
    }
    
    // Update display position, but reset to 0 when song changes or ends
    Timer {
        id: positionUpdateTimer
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: 100
        repeat: true
        onTriggered: {
            if (activePlayer) {
                var actualPosition = activePlayer.position || 0
                var trackLength = activePlayer.length || 0
                
                // If position is very close to end or greater than length, reset to 0
                if (actualPosition >= trackLength - 1 || actualPosition >= trackLength) {
                    displayPosition = 0
                } else {
                    displayPosition = actualPosition
                }
            }
        }
    }

    Connections {
        target: activePlayer
        function onTrackArtUrlChanged() { root.artUrl = activePlayer?.trackArtUrl || "" }
        function onTrackTitleChanged() { 
            // Reset position when track changes
            displayPosition = 0
        }
    }

    RowLayout { // Real content
        id: rowLayout
        spacing: 10
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 2
        height: parent.height - anchors.topMargin

        // Album art on the left
        Rectangle {
            id: albumArtContainer
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: 6
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
                0.3
            )
            border.width: 1
            visible: root.activePlayer
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: -3
            layer.enabled: true
            layer.smooth: true
            
            Image {
                anchors.fill: parent
                source: root.downloaded ? Qt.resolvedUrl(root.artFilePath) : ""
                fillMode: Image.PreserveAspectCrop
                cache: false
                asynchronous: true
                visible: root.downloaded && status === Image.Ready
                layer.enabled: true
                layer.smooth: true
                
                onStatusChanged: {
                    if (status === Image.Error) {
                        console.log("[BarMedia] Image load error for:", source)
                    }
                }
            }
            
            MaterialSymbol {
                anchors.centerIn: parent
                fill: 1
                text: "music_note"
                iconSize: 16
                color: Appearance.m3colors.m3onSecondaryContainer
                visible: !root.downloaded || albumArtContainer.children[0].status !== Image.Ready
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
                Layout.fillWidth: true
                text: activePlayer?.trackTitle || cleanedTitle
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            // Album - Artist name with time display
            RowLayout {
                Layout.fillWidth: true
                spacing: 2
                
                StyledText {
                    id: albumArtistText
                    Layout.fillWidth: true
                    color: Appearance.colors.colOnLayer1
                    opacity: 0.7
                    text: {
                        var parts = []
                        if (activePlayer?.trackAlbum) parts.push(activePlayer.trackAlbum)
                        if (activePlayer?.trackArtist) parts.push(activePlayer.trackArtist)
                        return parts.join(" - ")
                    }
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    visible: text.length > 0
                }
                
            StyledText {
                    id: timeDisplay
                color: Appearance.colors.colOnLayer1
                    opacity: 0.6
                    text: formatTime(displayPosition) + " / " + formatTime(Math.max(0, (activePlayer?.length || 0) - 1))
                font.pixelSize: Appearance.font.pixelSize.smaller
                    visible: root.activePlayer
                }
            }

            // Progress bar at the bottom
            Rectangle {
                id: progressBarBackground
                Layout.fillWidth: true
                Layout.preferredHeight: 3
                Layout.topMargin: 4
                Layout.leftMargin: -41
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
                    width: parent.width * Math.max(0, Math.min(1, displayPosition / Math.max(1, activePlayer?.length || 1)))
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
    }
}
