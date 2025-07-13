pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Pipewire service that provides audio sink and source controls using pactl
 */
Singleton {
    id: root

    // Update interval
    property int updateInterval: 1000

    // Default audio sink properties
    property real sinkVolume: 0.0
    property bool sinkMuted: false
    property string sinkName: ""
    property string sinkDescription: ""
    property string sinkId: ""

    // Default audio source properties
    property real sourceVolume: 0.0
    property bool sourceMuted: false
    property string sourceName: ""
    property string sourceDescription: ""
    property string sourceId: ""

    // Process to set sink volume
    Process {
        id: setVolumeProcess
        running: false
    }

    // Process to set sink mute
    Process {
        id: setMuteProcess
        running: false
    }

    // Process to set source volume
    Process {
        id: setSourceVolumeProcess
        running: false
    }

    // Process to set source mute
    Process {
        id: setSourceMuteProcess
        running: false
    }

    // Update sink info
    Process {
        id: updateSinkInfo
        command: ["pactl", "info"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const lines = data.split('\n')
                for (let line of lines) {
                    if (line.includes('Default Sink:')) {
                        const sinkName = line.split(':')[1].trim()
                        root.sinkName = sinkName
                        root.sinkId = sinkName
                        updateSinkDetails.running = true
                        break
                    }
                }
            }
        }
    }

    // Update source info
    Process {
        id: updateSourceInfo
        command: ["pactl", "info"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const lines = data.split('\n')
                for (let line of lines) {
                    if (line.includes('Default Source:')) {
                        const sourceName = line.split(':')[1].trim()
                        root.sourceName = sourceName
                        root.sourceId = sourceName
                        updateSourceDetails.running = true
                        break
                    }
                }
            }
        }
    }

    // Get sink details (volume, mute, description)
    Process {
        id: updateSinkDetails
        command: ["pactl", "list", "sinks"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const blocks = data.split(/\n(?=Sink #)/);
                for (let block of blocks) {
                    // Find the Name: line in this block
                    const nameLine = block.split('\n').find(function(l) { return l.trim().startsWith('Name:'); });
                    if (nameLine) {
                        var blockName = nameLine.split(':')[1].trim();
                        // QML: use toLowerCase() and trim() for robust comparison
                        if (blockName.toLowerCase() === root.sinkName.trim().toLowerCase()) {
                            // console.log('[Pipewire] Matched sink blockName:', blockName, 'root.sinkName:', root.sinkName);
                            // Find the 'Volume:' line (first channel)
                            const volumeLine = block.split('\n').find(function(l) { return l.trim().startsWith('Volume:'); });
                            if (volumeLine) {
                                // Example: 'Volume: front-left: 65536 / 100% / 0.00 dB, ...'
                                const match = volumeLine.match(/\b(\d+)%/);
                                if (match) {
                                    root.sinkVolume = parseInt(match[1]) / 100.0;
                                }
                            }
                            // Find the 'Mute:' line
                            const muteLine = block.split('\n').find(function(l) { return l.trim().startsWith('Mute:'); });
                            if (muteLine) {
                                root.sinkMuted = muteLine.indexOf('yes') !== -1;
                            }
                            break;
                        } else {
                            // console.log('[Pipewire] No match: blockName:', blockName, 'root.sinkName:', root.sinkName);
                        }
                    }
                }
            }
        }
    }

    // Get source details (volume, mute, description)
    Process {
        id: updateSourceDetails
        command: ["pactl", "list", "sources"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const blocks = data.split(/\n(?=Source #)/);
                for (let block of blocks) {
                    const nameLine = block.split('\n').find(function(l) { return l.trim().startsWith('Name:'); });
                    if (nameLine) {
                        var blockName = nameLine.split(':')[1].trim();
                        if (blockName.toLowerCase() === root.sourceName.trim().toLowerCase()) {
                            // console.log('[Pipewire] Matched source blockName:', blockName, 'root.sourceName:', root.sourceName);
                            // Find the 'Volume:' line (first channel)
                            const volumeLine = block.split('\n').find(function(l) { return l.trim().startsWith('Volume:'); });
                            if (volumeLine) {
                                // Example: 'Volume: front-left: 65536 / 100% / 0.00 dB, ...'
                                const match = volumeLine.match(/\b(\d+)%/);
                                if (match) {
                                    root.sourceVolume = parseInt(match[1]) / 100.0;
                                }
                            }
                            // Find the 'Mute:' line
                            const muteLine = block.split('\n').find(function(l) { return l.trim().startsWith('Mute:'); });
                            if (muteLine) {
                                root.sourceMuted = muteLine.indexOf('yes') !== -1;
                            }
                            break;
                        } else {
                            // console.log('[Pipewire] No match: blockName:', blockName, 'root.sourceName:', root.sourceName);
                        }
                    }
                }
            }
        }
    }

    // Timer to periodically update audio state
    Timer {
        interval: root.updateInterval
        running: true
        repeat: true
        onTriggered: {
            if (root.sinkId) {
                updateSinkDetails.running = true
            }
            if (root.sourceId) {
                updateSourceDetails.running = true
            }
        }
    }

    // Initialize on component creation
    Component.onCompleted: {
        updateSinkInfo.running = true
        updateSourceInfo.running = true
    }

    // Functions to set sink volume and mute
    function setSinkVolume(volume) {
        if (root.sinkId) {
            setVolumeProcess.command = ["pactl", "set-sink-volume", root.sinkId, Math.round(volume * 100) + "%"]
            setVolumeProcess.running = true
        }
    }

    function setSinkMuted(muted) {
        if (root.sinkId) {
            setMuteProcess.command = ["pactl", "set-sink-mute", root.sinkId, muted ? "1" : "0"]
            setMuteProcess.running = true
        }
    }

    // Functions to set source volume and mute
    function setSourceVolume(volume) {
        if (root.sourceId) {
            setSourceVolumeProcess.command = ["pactl", "set-source-volume", root.sourceId, Math.round(volume * 100) + "%"]
            setSourceVolumeProcess.running = true
        }
    }

    function setSourceMuted(muted) {
        if (root.sourceId) {
            setSourceMuteProcess.command = ["pactl", "set-source-mute", root.sourceId, muted ? "1" : "0"]
            setSourceMuteProcess.running = true
        }
    }

    // Functions to manually refresh
    function refreshSink() {
        updateSinkInfo.running = true
    }

    function refreshSource() {
        updateSourceInfo.running = true
    }
} 