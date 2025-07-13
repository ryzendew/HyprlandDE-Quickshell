import "root:/modules/common"
import QtQuick
import Quickshell
import "root:/services"
pragma Singleton
pragma ComponentBehavior: Bound

/**
 * A nice wrapper for default Pipewire audio sink and source.
 */
Singleton {
    id: root

    property bool ready: Pipewire.sinkId !== ""
    property var sink: sinkWrapper
    property var source: sourceWrapper

    signal sinkProtectionTriggered(string reason);

    // Wrapper objects to maintain compatibility with existing code
    property var sinkWrapper: QtObject {
        property var audio: sinkAudio
        property bool ready: Pipewire.sinkId !== ""
        property string name: Pipewire.sinkName
        property string description: Pipewire.sinkDescription
        property string id: Pipewire.sinkId

        property var sinkAudio: QtObject {
            property real volume: Pipewire.sinkVolume
            property bool muted: Pipewire.sinkMuted

            onVolumeChanged: {
                if (Pipewire.sinkId && volume !== Pipewire.sinkVolume) {
                    Pipewire.setSinkVolume(volume)
                }
            }

            onMutedChanged: {
                if (Pipewire.sinkId && muted !== Pipewire.sinkMuted) {
                    Pipewire.setSinkMuted(muted)
                }
            }
        }
    }

    property var sourceWrapper: QtObject {
        property var audio: sourceAudio
        property bool ready: Pipewire.sourceId !== ""
        property string name: Pipewire.sourceName
        property string description: Pipewire.sourceDescription
        property string id: Pipewire.sourceId

        property var sourceAudio: QtObject {
            property real volume: Pipewire.sourceVolume
            property bool muted: Pipewire.sourceMuted

            onVolumeChanged: {
                if (Pipewire.sourceId && volume !== Pipewire.sourceVolume) {
                    Pipewire.setSourceVolume(volume)
                }
            }

            onMutedChanged: {
                if (Pipewire.sourceId && muted !== Pipewire.sourceMuted) {
                    Pipewire.setSourceMuted(muted)
                }
            }
        }
    }

    Connections { // Protection against sudden volume changes
        target: sink?.audio ?? null
        property bool lastReady: false
        property real lastVolume: 0
        function onVolumeChanged() {
            if (!ConfigOptions.audio.protection.enable) return;
            if (!lastReady) {
                lastVolume = sink.audio.volume;
                lastReady = true;
                return;
            }
            const newVolume = sink.audio.volume;
            const maxAllowedIncrease = ConfigOptions.audio.protection.maxAllowedIncrease / 100; 
            const maxAllowed = ConfigOptions.audio.protection.maxAllowed / 100;

            if (newVolume - lastVolume > maxAllowedIncrease) {
                sink.audio.volume = lastVolume;
                root.sinkProtectionTriggered("Illegal increment");
            } else if (newVolume > maxAllowed) {
                sink.audio.volume = lastVolume;
                root.sinkProtectionTriggered("Exceeded max allowed");
            }
            lastVolume = sink.audio.volume;
        }
        
    }

}
