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
    property string latestCoverArtFile: ""
    property string artUrl: activePlayer?.trackArtUrl || ""

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
        implicitHeight: 48
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        anchors.topMargin: 4
        anchors.bottomMargin: 4
        color: borderless ? "transparent" : Qt.rgba(
            Appearance.colors.colLayer1.r,
            Appearance.colors.colLayer1.g,
            Appearance.colors.colLayer1.b,
            0.25
        )
        radius: Appearance.rounding.small
    }

    function updateLatestCoverArt() {
        var dir = "/home/matt1909/.cache/Quickshell/media/coverart/";
        var files = Quickshell.Io.listFiles(dir);
        console.log("[BarMedia][DEBUG] Scanning cover art dir:", dir);
        if (files) {
            console.log("[BarMedia][DEBUG] Files found:", JSON.stringify(files.map(f => f.path + ' (mtime: ' + f.mtime + ')')));
        } else {
            console.log("[BarMedia][DEBUG] No files found in cover art dir.");
        }
        if (files && files.length > 0) {
            files.sort(function(a, b) { return b.mtime - a.mtime; });
            root.latestCoverArtFile = files[0].path;
            console.log("[BarMedia][DEBUG] Latest cover art file:", root.latestCoverArtFile);
        } else {
            root.latestCoverArtFile = "";
            console.log("[BarMedia][DEBUG] No cover art file to display.");
        }
    }

    onLatestCoverArtFileChanged: {
        console.log("[BarMedia][DEBUG] latestCoverArtFile changed:", root.latestCoverArtFile);
    }

    Component.onCompleted: updateLatestCoverArt()
    Connections {
        target: activePlayer
        function onTrackTitleChanged() { updateLatestCoverArt() }
        function onTrackArtistChanged() { updateLatestCoverArt() }
        function onTrackArtUrlChanged() { root.artUrl = activePlayer?.trackArtUrl || "" }
        function onLengthChanged() {
            console.log('[BarMedia] activePlayer properties:', JSON.stringify(activePlayer))
        }
    }

    RowLayout { // Real content
        id: rowLayout
        spacing: 8
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16

        Rectangle {
            id: albumArtContainer
            width: 36
            height: 36
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
                0.3
            )
            border.width: 1
            visible: root.artUrl.length > 0
            Layout.alignment: Qt.AlignVCenter
            layer.enabled: true
            layer.smooth: true
            Image {
                anchors.fill: parent
                source: root.artUrl.startsWith("file://") ? root.artUrl : ""
                fillMode: Image.PreserveAspectCrop
                cache: false
                asynchronous: true
                visible: root.artUrl.length > 0 && root.artUrl.startsWith("file://")
                layer.enabled: true
                layer.smooth: true
            }
            MaterialSymbol {
                anchors.centerIn: parent
                fill: 1
                text: "music_note"
                iconSize: 16
                color: Appearance.m3colors.m3onSecondaryContainer
                visible: root.artUrl.length == 0 || !root.artUrl.startsWith("file://")
            }
        }

        // Song/album/artist stacked, fill width
        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            spacing: 2
            StyledText {
                text: activePlayer?.trackTitle || cleanedTitle
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.normal
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            StyledText {
                property var meta: activePlayer?.metadata || {}
                property var year: meta["xesam:contentCreated"] ? meta["xesam:contentCreated"].toString().slice(0,4) : (meta["xesam:year"] ? meta["xesam:year"].toString() : (activePlayer?.trackYear ? activePlayer.trackYear.toString() : ""))
                property bool validYear: year && year.length === 4 && !isNaN(Number(year))
                text: (activePlayer?.trackAlbum ? activePlayer.trackAlbum : "")
                    + (validYear ? ` [${year}]` : "")
                    + (activePlayer?.trackArtist ? ` - ${activePlayer.trackArtist}` : "")
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.bold: false
                opacity: 0.8
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        // Elapsed time and year (right side)
        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            StyledText {
                property real pos: activePlayer?.position || 0
                text: formatTime(pos)
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.bold: true
                horizontalAlignment: Text.AlignRight
            }
            StyledText {
                property var meta: activePlayer?.metadata || {}
                property var year: meta["xesam:contentCreated"] ? meta["xesam:contentCreated"].toString().slice(0,4) : (meta["xesam:year"] ? meta["xesam:year"].toString() : (activePlayer?.trackYear ? activePlayer.trackYear.toString() : ""))
                text: (year && year.length === 4 && !isNaN(Number(year))) ? year : ""
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.smaller
                opacity: 0.7
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
