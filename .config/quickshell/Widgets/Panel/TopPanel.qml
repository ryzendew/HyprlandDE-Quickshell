import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "root:/Data" as Data
import "root:/Core/" as Core
import "./modules" as Modules

// Top panel wrapper with recording
Item {
    id: topPanelRoot
    required property var shell

    visible: true

    property bool isRecording: false
    property var recordingProcess: null
    property string lastError: ""
    property bool wallpaperSelectorVisible: false

    signal slideBarVisibilityChanged(bool visible)

    function triggerTopPanel() {
        panel.show()
    }

    // Auto-trigger panel
    onVisibleChanged: {
        if (visible) {
            triggerTopPanel()
        }
    }

    // Main panel instance
    Modules.Panel {
        id: panel
        shell: topPanelRoot.shell
        isRecording: topPanelRoot.isRecording

        anchors.top: topPanelRoot.top
        anchors.right: topPanelRoot.right
        anchors.topMargin: 8
        anchors.rightMargin: 8

        onVisibleChanged: slideBarVisibilityChanged(visible)

        onRecordingRequested: startRecording()
        onStopRecordingRequested: {
            stopRecording()
            // Hide entire TopPanel after stop recording
            if (topPanelRoot.parent && topPanelRoot.parent.hide) {
                topPanelRoot.parent.hide()
            }
        }
        onSystemActionRequested: function(action) {
            performSystemAction(action)
            // Hide entire TopPanel after system action
            if (topPanelRoot.parent && topPanelRoot.parent.hide) {
                topPanelRoot.parent.hide()
            }
        }
        onPerformanceActionRequested: function(action) {
            performPerformanceAction(action)
            // Hide entire TopPanel after performance action
            if (topPanelRoot.parent && topPanelRoot.parent.hide) {
                topPanelRoot.parent.hide()
            }
        }
    }

    // Start screen recording
    function startRecording() {
        var currentDate = new Date()
        var hours = String(currentDate.getHours()).padStart(2, '0')
        var minutes = String(currentDate.getMinutes()).padStart(2, '0')
        var day = String(currentDate.getDate()).padStart(2, '0')
        var month = String(currentDate.getMonth() + 1).padStart(2, '0')
        var year = currentDate.getFullYear()

        var filename = hours + "-" + minutes + "-" + day + "-" + month + "-" + year + ".mp4"
        var outputPath = Data.Settings.videoPath + filename
        var command = "gpu-screen-recorder -w portal -f 60 -a default_output -o " + outputPath

        var qmlString = 'import Quickshell.Io; Process { command: ["sh", "-c", "' + command + '"]; running: true }'

        recordingProcess = Qt.createQmlObject(qmlString, topPanelRoot)
        isRecording = true
    }

    // Stop recording with cleanup
    function stopRecording() {
        if (recordingProcess && isRecording) {
            var stopQmlString = 'import Quickshell.Io; Process { command: ["sh", "-c", "pkill -SIGINT -f \'gpu-screen-recorder.*portal\'"]; running: true; onExited: function() { destroy() } }'

            var stopProcess = Qt.createQmlObject(stopQmlString, topPanelRoot)

            var cleanupTimer = Qt.createQmlObject('import QtQuick; Timer { interval: 3000; running: true; repeat: false }', topPanelRoot)
            cleanupTimer.triggered.connect(function() {
                if (recordingProcess) {
                    recordingProcess.running = false
                    recordingProcess.destroy()
                    recordingProcess = null
                }

                var forceKillQml = 'import Quickshell.Io; Process { command: ["sh", "-c", "pkill -9 -f \'gpu-screen-recorder.*portal\' 2>/dev/null || true"]; running: true; onExited: function() { destroy() } }'
                var forceKillProcess = Qt.createQmlObject(forceKillQml, topPanelRoot)

                cleanupTimer.destroy()
            })
        }
        isRecording = false
    }

    // System action router (lock, reboot, shutdown)
    function performSystemAction(action) {
        switch(action) {
            case "lock":
                Core.ProcessManager.lock()
                break
            case "reboot":
                Core.ProcessManager.reboot()
                break
            case "shutdown":
                Core.ProcessManager.shutdown()
                break
        }
    }

    function performPerformanceAction(action) {
        // Performance actions handled silently
    }
    
    // Clean up processes on destruction
    Component.onDestruction: {
        if (recordingProcess) {
            recordingProcess.running = false
            recordingProcess.destroy()
            recordingProcess = null
        }
    }
}
