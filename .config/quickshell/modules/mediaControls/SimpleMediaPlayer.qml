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

Scope {
    id: root
    property bool visible: false
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || "No media"

    // Album art properties
    property string artUrl: activePlayer?.trackArtUrl || ""
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: artUrl ? Qt.md5(artUrl) + ".jpg" : ""
    property string artFilePath: artFileName ? `${artDownloadLocation}/${artFileName}` : ""
    property bool downloaded: false
    property color artDominantColor: colorQuantizer?.colors[0] || Appearance.m3colors.m3secondaryContainer

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
        // console.log("[SimpleMediaPlayer] Art URL changed to:", artUrl)
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
                // console.log("[SimpleMediaPlayer] Failed to download album art for:", root.artUrl)
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

    Loader {
        id: mediaPlayerLoader
        active: false

        sourceComponent: PanelWindow {
            id: mediaPlayerRoot
            visible: mediaPlayerLoader.active
            color: "transparent"
            implicitWidth: Math.min(420, screen.width - 80)
            implicitHeight: Math.min(600, screen.height - 80)
            
            WlrLayershell.namespace: "quickshell:simpleMediaPlayer"
            WlrLayershell.layer: WlrLayer.Overlay

            // Close on escape
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    mediaPlayerLoader.active = false
                }
            }

            Item {
                id: mediaPlayerContent
                anchors.centerIn: parent
                width: parent.width
                height: parent.height

                Rectangle {
                    id: mediaPlayerBackground
                    anchors.fill: parent
                    color: "transparent"
                    radius: 20

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: mediaPlayerBackground.width
                            height: mediaPlayerBackground.height
                            radius: mediaPlayerBackground.radius
                        }
                    }

                    // Album art background with FastBlur effect
                    Rectangle {
                        anchors.fill: parent
                        color: blendedColors.colLayer0
                        radius: mediaPlayerBackground.radius
                        
                        Behavior on color {
                            ColorAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }
                        
                        // Blurred album art background
                        Image {
                            id: backgroundArt
                            anchors.fill: parent
                            source: root.downloaded ? Qt.resolvedUrl(root.artFilePath) : ""
                            fillMode: Image.PreserveAspectCrop
                            cache: false
                            antialiasing: true
                            asynchronous: true
                            
                            layer.enabled: true
                            layer.effect: FastBlur {
                                radius: 64
                                transparentBorder: false
                            }
                            
                            onStatusChanged: {
                                if (status === Image.Error) {
                                    // console.log("[SimpleMediaPlayer] Background art load error for:", source)
                                }
                            }
                        }
                        
                        // Color overlay to blend with theme
                        Rectangle {
                            anchors.fill: parent
                            color: Qt.rgba(
                                blendedColors.colLayer0.r,
                                blendedColors.colLayer0.g,
                                blendedColors.colLayer0.b,
                                0.7
                            )
                            radius: mediaPlayerBackground.radius
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 28
                        spacing: 20

                        // Album art (large, centered)
                        Rectangle {
                            id: albumArtContainer
                            Layout.preferredWidth: 280
                            Layout.preferredHeight: 280
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 16
                            radius: 16
                            clip: true
                            color: Qt.rgba(1, 1, 1, 0.1)
                            border.color: Qt.rgba(1, 1, 1, 0.2)
                            border.width: 1

                            Image {
                                anchors.fill: parent
                                anchors.margins: 0
                                source: root.downloaded ? Qt.resolvedUrl(root.artFilePath) : ""
                                fillMode: Image.PreserveAspectCrop
                                cache: false
                                asynchronous: true
                                visible: root.downloaded && status === Image.Ready
                                
                                onStatusChanged: {
                                    if (status === Image.Error) {
                                        root.downloaded = false
                                    }
                                }
                            }
                            
                            // Fallback icon when no album art
                            Image {
                                anchors.centerIn: parent
                                width: 120
                                height: 120
                                source: "image://icon/" + (root.getPlayerIcon() || "multimedia-player")
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                                visible: !root.downloaded || albumArtContainer.children[0].status !== Image.Ready
                            }
                        }

                        // Track info section
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 8

                            // Track title
                            StyledText {
                                Layout.fillWidth: true
                                text: activePlayer?.trackTitle || "No track"
                                color: "#ffffff"
                                font.pixelSize: 20
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignHCenter
                            }

                            // Artist and album
                            StyledText {
                                Layout.fillWidth: true
                                text: {
                                    var parts = []
                                    if (activePlayer?.trackArtist) parts.push(activePlayer.trackArtist)
                                    if (activePlayer?.trackAlbum) parts.push(activePlayer.trackAlbum)
                                    return parts.join(" • ")
                                }
                                color: Qt.rgba(1, 1, 1, 0.8)
                                font.pixelSize: 16
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                visible: text.length > 0
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        // Progress section
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 8

                            // Time display row
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: 20
                                Layout.rightMargin: 20

                                StyledText {
                                    text: formatTime(Math.max(0, activePlayer?.position || 0))
                                    color: "#ffffff"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                }

                                Item { Layout.fillWidth: true }

                                StyledText {
                                    text: "-" + formatTime(Math.max(0, (activePlayer?.length || 0) - (activePlayer?.position || 0)))
                                    color: "#ffffff"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                }
                            }

                            // Progress bar with seeking
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 6
                                Layout.leftMargin: 20
                                Layout.rightMargin: 20
                                radius: 3
                                color: Qt.rgba(1, 1, 1, 0.3)
                                visible: activePlayer

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width * Math.max(0, Math.min(1, (activePlayer?.position || 0) / Math.max(1, activePlayer?.length || 1)))
                                    height: parent.height
                                    radius: parent.radius
                                    color: "#ffffff"
                                    
                                    Behavior on width {
                                        enabled: activePlayer?.playbackState == MprisPlaybackState.Playing && !progressMouseArea.pressed
                                        NumberAnimation {
                                            duration: 300
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }

                                // Seeking functionality
                                MouseArea {
                                    id: progressMouseArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: activePlayer && activePlayer.length > 0
                                }
                            }
                        }

                        // Control buttons section
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 16
                            spacing: 20

                            // Shuffle button
                            Rectangle {
                                implicitWidth: 48
                                implicitHeight: 48
                                radius: 24
                                color: "transparent"
                                border.color: Qt.rgba(1, 1, 1, 0.3)
                                border.width: 1

                                RippleButton {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    buttonRadius: 23
                                    colBackground: Qt.rgba(1, 1, 1, 0.1)
                                    colBackgroundHover: Qt.rgba(1, 1, 1, 0.2)
                                    enabled: activePlayer

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "shuffle"
                                        iconSize: 24
                                        color: "#ffffff"
                                    }
                                }
                            }

                            // Previous button
                            Rectangle {
                                implicitWidth: 48
                                implicitHeight: 48
                                radius: 24
                                color: "transparent"
                                border.color: Qt.rgba(1, 1, 1, 0.3)
                                border.width: 1

                                RippleButton {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    buttonRadius: 23
                                    colBackground: Qt.rgba(1, 1, 1, 0.1)
                                    colBackgroundHover: Qt.rgba(1, 1, 1, 0.2)
                                    enabled: activePlayer?.canGoPrevious ?? false
                                    onClicked: activePlayer?.previous()

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "skip_previous"
                                        iconSize: 28
                                        color: "#ffffff"
                                    }
                                }
                            }

                            // Play/Pause button
                            Rectangle {
                                implicitWidth: 64
                                implicitHeight: 64
                                radius: 32
                                color: "transparent"
                                border.color: Qt.rgba(1, 1, 1, 0.3)
                                border.width: 1

                                RippleButton {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    buttonRadius: 31
                                    colBackground: "#ffffff"
                                    colBackgroundHover: Qt.rgba(1, 1, 1, 0.9)
                                    enabled: activePlayer?.canTogglePlaying ?? false
                                    onClicked: activePlayer?.togglePlaying()

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: activePlayer?.playbackState == MprisPlaybackState.Playing ? "pause" : "play_arrow"
                                        iconSize: 32
                                        color: "#000000"
                                    }
                                }
                            }

                            // Next button
                            Rectangle {
                                implicitWidth: 48
                                implicitHeight: 48
                                radius: 24
                                color: "transparent"
                                border.color: Qt.rgba(1, 1, 1, 0.3)
                                border.width: 1

                                RippleButton {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    buttonRadius: 23
                                    colBackground: Qt.rgba(1, 1, 1, 0.1)
                                    colBackgroundHover: Qt.rgba(1, 1, 1, 0.2)
                                    enabled: activePlayer?.canGoNext ?? false
                                    onClicked: activePlayer?.next()

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "skip_next"
                                        iconSize: 28
                                        color: "#ffffff"
                                    }
                                }
                            }

                            // Repeat button
                            Rectangle {
                                implicitWidth: 48
                                implicitHeight: 48
                                radius: 24
                                color: "transparent"
                                border.color: Qt.rgba(1, 1, 1, 0.3)
                                border.width: 1

                                RippleButton {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    buttonRadius: 23
                                    colBackground: Qt.rgba(1, 1, 1, 0.1)
                                    colBackgroundHover: Qt.rgba(1, 1, 1, 0.2)
                                    enabled: activePlayer

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "repeat"
                                        iconSize: 24
                                        color: "#ffffff"
                                    }
                                }
                            }
                        }

                        // Volume control
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 24
                            Layout.rightMargin: 24
                            Layout.topMargin: 4
                            Layout.bottomMargin: 24
                            spacing: 16

                            MaterialSymbol {
                                text: "volume_down"
                                iconSize: 24
                                color: Qt.rgba(1, 1, 1, 0.8)
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 6
                                radius: 3
                                color: Qt.rgba(1, 1, 1, 0.3)

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width * (Audio.sink?.audio?.volume ?? 0)
                                    height: parent.height
                                    radius: parent.radius
                                    color: "#ffffff"
                                    
                                    Behavior on width {
                                        enabled: !volumeMouseArea.pressed
                                        NumberAnimation {
                                            duration: 200
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                    
                                    // Volume handle
                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 16
                                        height: 16
                                        radius: 8
                                        color: "#ffffff"
                                        border.color: Qt.rgba(0, 0, 0, 0.1)
                                        border.width: 1
                                    }
                                }

                                // Volume control functionality
                                MouseArea {
                                    id: volumeMouseArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    
                                    onClicked: (mouse) => {
                                        if (Audio.sink?.audio) {
                                            const progress = mouse.x / width
                                            const newVolume = Math.max(0, Math.min(1, progress))
                                            Audio.sink.audio.volume = newVolume
                                        }
                                    }
                                    
                                    onPositionChanged: (mouse) => {
                                        if (pressed && Audio.sink?.audio) {
                                            const progress = mouse.x / width
                                            const newVolume = Math.max(0, Math.min(1, progress))
                                            Audio.sink.audio.volume = newVolume
                                        }
                                    }
                                }
                            }

                            MaterialSymbol {
                                text: "volume_up"
                                iconSize: 24
                                color: Qt.rgba(1, 1, 1, 0.8)
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "simpleMediaPlayer"

        function toggle(): void {
            mediaPlayerLoader.active = !mediaPlayerLoader.active
        }

        function close(): void {
            mediaPlayerLoader.active = false
        }

        function open(): void {
            mediaPlayerLoader.active = true
        }
    }

    GlobalShortcut {
        name: "simpleMediaPlayerToggle"
        description: qsTr("Toggles simple media player on press")

        onPressed: {
            if (!mediaPlayerLoader.active && !activePlayer) {
                return
            }
            mediaPlayerLoader.active = !mediaPlayerLoader.active
        }
    }
} 