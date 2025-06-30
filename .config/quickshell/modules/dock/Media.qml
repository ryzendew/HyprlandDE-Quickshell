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
import Qt5Compat.GraphicalEffects

Item {
    id: root
    Component.onCompleted: {
        console.log("[DockMedia][DEBUG] Media.qml component loaded at very top!");
    }
    Rectangle {
        width: 40; height: 40; color: "magenta"; z: 9999
    }
    property bool borderless: ConfigOptions.bar.borderless
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || qsTr("No media")
    readonly property string formattedText: cleanedTitle + (activePlayer?.trackArtist ? (" - " + String(activePlayer.trackArtist)) : "")
    
    // Properties for album art, similar to PlayerControl.qml
    property var artUrl: activePlayer?.trackArtUrl
    property string artDownloadLocation: Quickshell.Io.Directories.coverArt // Assuming Directories is accessible via Quickshell.Io
    property string artFileName: Qt.md5(artUrl) + ".jpg"
    property string artFilePath: `${artDownloadLocation}/${artFileName}`
    property bool downloaded: false
    property color artDominantColor: colorQuantizer?.colors[0] || Appearance.m3colors.m3secondaryContainer

    // Track position and length separately for better accuracy
    property real currentPosition: activePlayer ? activePlayer.position : 0
    property real totalLength: activePlayer ? activePlayer.length : 0
    readonly property real progress: totalLength > 0 ? Math.min(1, Math.max(0, currentPosition / totalLength)) : 0

    // Add property to track the latest cover art file
    property string latestCoverArtFile: ""

    Layout.fillHeight: true
    implicitWidth: contentRow.implicitWidth + 35
    implicitHeight: parent.height

    Component.onCompleted: {
        console.log("[DockMedia][DEBUG] Component loaded. artUrl:", root.artUrl, "downloaded:", root.downloaded)
        updateLatestCoverArt()
    }

    // Function to update latest cover art file
    function updateLatestCoverArt() {
        var dir = Quickshell.Io.Directories.coverArt;
        var files = Quickshell.Io.listFiles(dir);
        console.log("[DockMedia][DEBUG] Scanning cover art dir:", dir);
        if (files) {
            console.log("[DockMedia][DEBUG] Files found:", JSON.stringify(files.map(f => f.path + ' (mtime: ' + f.mtime + ')')));
        } else {
            console.log("[DockMedia][DEBUG] No files found in cover art dir.");
        }
        if (files && files.length > 0) {
            // Sort by mtime descending
            files.sort(function(a, b) { return b.mtime - a.mtime; });
            root.latestCoverArtFile = files[0].path;
            console.log("[DockMedia][DEBUG] Latest cover art file:", root.latestCoverArtFile);
        } else {
            root.latestCoverArtFile = "";
            console.log("[DockMedia][DEBUG] No cover art file to display.");
        }
    }

    onLatestCoverArtFileChanged: {
        console.log("[DockMedia][DEBUG] latestCoverArtFile changed:", root.latestCoverArtFile);
        if (root.latestCoverArtFile.length > 0) {
            var exists = Quickshell.Io.fileExists(root.latestCoverArtFile);
            console.log("[DockMedia][DEBUG] File exists?", exists, root.latestCoverArtFile);
        }
    }

    onArtUrlChanged: {
        console.log("[DockMedia][DEBUG] artUrl changed:", root.artUrl);
        updateLatestCoverArt();
        if (root.artUrl.length == 0) {
            root.downloaded = false; // Reset downloaded state
            console.log("[DockMedia][DEBUG] artUrl is empty, not downloading.");
            return;
        }
        root.downloaded = false;
        const cmd = (root.artUrl && root.artUrl.startsWith("file://"))
            ? `mkdir -p '${root.artDownloadLocation}' && [ -f '${root.artFilePath}' ] || cp '${root.artUrl.replace("file://", "")}' '${root.artFilePath}'`
            : `mkdir -p '${root.artDownloadLocation}' && [ -f '${root.artFilePath}' ] || curl -sSL '${root.artUrl}' -o '${root.artFilePath}'`;
        console.log("[DockMedia][DEBUG] Download command:", cmd);
        coverArtDownloader.running = true;
    }

    onDownloadedChanged: {
        console.log("[DockMedia][DEBUG] downloaded changed:", root.downloaded);
    }

    // Album art image (fills the background)
    Image {
        id: albumArtBackground
        anchors.fill: parent
        source: root.downloaded ? Qt.resolvedUrl(root.artFilePath) : ""
        fillMode: Image.PreserveAspectCrop
        opacity: 0.15 // Low opacity for subtle background
        visible: root.activePlayer && root.artUrl.length > 0
        cache: false
        asynchronous: true
    }

    // Move Process to root level to prevent premature destruction
    Process { // Cover art downloader
        id: coverArtDownloader
        property string targetFile: root.artUrl
        property string downloadCmd: (root.artUrl && root.artUrl.startsWith("file://"))
            ? `mkdir -p '${root.artDownloadLocation}' && [ -f '${root.artFilePath}' ] || cp '${root.artUrl.replace("file://", "")}' '${root.artFilePath}'`
            : `mkdir -p '${root.artDownloadLocation}' && [ -f '${root.artFilePath}' ] || curl -sSL '${root.artUrl}' -o '${root.artFilePath}'`
        command: [ "bash", "-c", downloadCmd ]
        onExited: (exitCode, exitStatus) => {
            console.log("[DockMedia][DEBUG] Download exited. Exit code:", exitCode, "artFilePath:", root.artFilePath);
            if (exitCode === 0) {
                root.downloaded = true;
                console.log("[DockMedia][DEBUG] Album art downloaded/copied successfully.");
            } else {
                console.warn("[DockMedia][DEBUG] Failed to download/copy album art from", targetFile, "Exit code:", exitCode);
                root.downloaded = false;
            }
        }
    }

    ColorQuantizer { // Added for artDominantColor, if needed later, or for consistency
        id: colorQuantizer
        source: root.downloaded ? Qt.resolvedUrl(root.artFilePath) : ""
        depth: 0 // 2^0 = 1 color
        rescaleSize: 1 // Rescale to 1x1 pixel for faster processing
    }

    // Update position when player changes
    Connections {
        target: activePlayer
        function onPositionChanged() {
            currentPosition = activePlayer.position
        }
        function onLengthChanged() {
            totalLength = activePlayer.length
        }
    }

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: 500
        repeat: true
        onTriggered: {
            if (activePlayer) {
                currentPosition = activePlayer.position
                totalLength = activePlayer.length
            }
        }
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        height: parent.height
        spacing: 12
        Component.onCompleted: {
            console.log("[DockMedia] contentRow created. artUrl:", root.artUrl, "downloaded:", root.downloaded)
        }

        // Album art thumbnail (always show latest from coverart dir)
        Rectangle {
            id: albumArtContainer
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            height: 32
            radius: 6
            color: Qt.rgba(
                colorQuantizer.colors[0]?.r ?? Appearance.m3colors.m3secondaryContainer.r,
                colorQuantizer.colors[0]?.g ?? Appearance.m3colors.m3secondaryContainer.g,
                colorQuantizer.colors[0]?.b ?? Appearance.m3colors.m3secondaryContainer.b,
                0.85
            )
            visible: root.latestCoverArtFile.length > 0
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: albumArtContainer.width
                    height: albumArtContainer.height
                    radius: albumArtContainer.radius
                }
            }

            Image {
                id: albumArtThumbnail
                anchors.fill: parent
                source: root.latestCoverArtFile.length > 0 ? Qt.resolvedUrl(root.latestCoverArtFile) : ""
                fillMode: Image.PreserveAspectCrop
                cache: false
                asynchronous: true
                visible: root.latestCoverArtFile.length > 0
            }

            // Fallback icon when no album art
            MaterialSymbol {
                anchors.centerIn: parent
                fill: 1
                text: "music_note"
                iconSize: 18
                color: Appearance.m3colors.m3onSecondaryContainer
                visible: root.latestCoverArtFile.length == 0
            }
        }

        CircularProgress {
            id: progressCircle
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            height: 32
            lineWidth: 2
            value: root.progress
            Behavior on value {
                enabled: activePlayer?.playbackState == MprisPlaybackState.Playing
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.OutCubic
                }
            }
            secondaryColor: Appearance.m3colors.m3secondaryContainer
            primaryColor: Appearance.m3colors.m3onSecondaryContainer

            MaterialSymbol {
                anchors.centerIn: parent
                fill: 1
                text: activePlayer?.isPlaying ? "pause" : "play_arrow"
                iconSize: 20
                color: Appearance.m3colors.m3onSecondaryContainer
            }
        }

        Text {
            id: mediaText
            anchors.verticalCenter: parent.verticalCenter
            width: textMetrics.width
            color: Appearance.colors.colOnLayer1
            text: String(formattedText)
            font.pixelSize: Appearance.font.pixelSize.normal
            font.family: Appearance.font.family.main
            textFormat: Text.PlainText
            renderType: Text.NativeRendering
            elide: Text.ElideNone
            clip: false
        }
    }

    // Use TextMetrics to calculate the exact width needed
    TextMetrics {
        id: textMetrics
        text: String(formattedText)
        font.pixelSize: Appearance.font.pixelSize.normal
        font.family: Appearance.font.family.main
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
}
