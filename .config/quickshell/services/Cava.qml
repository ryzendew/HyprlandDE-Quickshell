pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var values: []
    property int count: 44
    property bool isRunning: false

    // Start the cava process
    function start() {
        if (!isRunning) {
            isRunning = true
            cavaProcess.running = true
        }
    }

    // Stop the cava process
    function stop() {
        isRunning = false
        cavaProcess.running = false
    }

    Process {
        id: cavaProcess
        running: false
        command: ["/usr/bin/cava", "-p", "/tmp/cava_config"]

        stdout: SplitParser {
            onRead: data => {
                if (data.trim()) {
                    const lines = data.trim().split('\n')
                    const newValues = []
                    for (let line of lines) {
                        if (line.trim()) {
                            // Split the line into numbers (semicolon-separated format)
                            const parts = line.trim().split(';')
                            for (let part of parts) {
                                const value = parseFloat(part)
                                if (!isNaN(value)) {
                                    newValues.push(Math.min(1.0, Math.max(0.0, value / 1000.0)))
                                }
                            }
                        }
                    }
                    if (newValues.length > 0) {
                        root.values = newValues
                    }
                }
            }
        }
        
        onExited: (exitCode) => {
            if (root.isRunning) {
                // Restart if it was supposed to be running
                cavaProcess.running = true
            }
        }
    }

    // Create cava config file
    Process {
        id: createConfigProcess
        running: false
        command: ["bash", "-c", `
            cat > /tmp/cava_config << 'EOF'
[general]
autosens = 1
overshoot = 1
bars = 35
bar_width = 0.0
bar_spacing = 1.0

[input]
method = pulse
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
channels = stereo

[color]
gradient = 1
gradient_color_1 = '#3b3c59'
gradient_color_2 = '#4b4464'
gradient_color_3 = '#4b4464'
gradient_color_4 = '#6d5276'
gradient_color_5 = '#7f597e'
gradient_color_6 = '#926184'
gradient_color_7 = '#a4688a'
gradient_color_8 = '#b6708e'
gradient_color_9 = '#c87990'
gradient_color_10 = '#d98292'

[smoothing]
monstercat = 0
waves = 0
gravity = 100

[eq]
#1 = 1 # bass
#2 = 1
#3 = 1 # midtone
#4 = 1
#5 = 1 # treble
EOF
        `]
        onExited: (exitCode) => {
            if (exitCode === 0) {
                root.start()
            }
        }
    }

    Component.onCompleted: {
        createConfigProcess.running = true
    }
    Component.onDestruction: {
        root.stop()
    }
} 