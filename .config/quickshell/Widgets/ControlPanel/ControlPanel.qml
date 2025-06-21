import QtQuick
import "root:/Data" as Data
import "root:/Core" as Core

// Main control panel coordinator - handles recording and system actions
Item {
    id: controlPanelContainer
    
    required property var shell
    property bool isRecording: false
    property int currentTab: 0 // 0=main, 1=calendar, 2=clipboard, 3=notifications, 4=wallpapers
    property var tabIcons: ["widgets", "calendar_month", "content_paste", "notifications", "wallpaper"]
    
    property bool isShown: false
    property var recordingProcess: null

    signal recordingRequested()
    signal stopRecordingRequested()
    signal systemActionRequested(string action)
    signal performanceActionRequested(string action)

    // Screen recording
    onRecordingRequested: {
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
        
        try {
            recordingProcess = Qt.createQmlObject(qmlString, controlPanelContainer)
            isRecording = true
        } catch (e) {
            console.error("Failed to start recording:", e)
        }
    }
    
    // Stop recording with cleanup
    onStopRecordingRequested: {
        if (recordingProcess && isRecording) {
            var stopQmlString = 'import Quickshell.Io; Process { command: ["sh", "-c", "pkill -SIGINT -f \'gpu-screen-recorder.*portal\'"]; running: true; onExited: function() { destroy() } }'

            try {
                var stopProcess = Qt.createQmlObject(stopQmlString, controlPanelContainer)

                var cleanupTimer = Qt.createQmlObject('import QtQuick; Timer { interval: 3000; running: true; repeat: false }', controlPanelContainer)
                cleanupTimer.triggered.connect(function() {
                    if (recordingProcess) {
                        recordingProcess.running = false
                        recordingProcess.destroy()
                        recordingProcess = null
                    }

                    var forceKillQml = 'import Quickshell.Io; Process { command: ["sh", "-c", "pkill -9 -f \'gpu-screen-recorder.*portal\' 2>/dev/null || true"]; running: true; onExited: function() { destroy() } }'
                    var forceKillProcess = Qt.createQmlObject(forceKillQml, controlPanelContainer)

                    cleanupTimer.destroy()
                })
            } catch (e) {
                console.error("Failed to stop recording:", e)
            }
        }
        isRecording = false
    }
    
    // System action routing
    onSystemActionRequested: function(action) {
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
    
    onPerformanceActionRequested: function(action) {
        console.log("Performance action requested:", action)
    }

    // Control panel window component
    ControlPanelWindow {
        id: controlPanelWindow
        
        // Pass through properties
        shell: controlPanelContainer.shell
        isRecording: controlPanelContainer.isRecording
        currentTab: controlPanelContainer.currentTab
        tabIcons: controlPanelContainer.tabIcons
        isShown: controlPanelContainer.isShown
        
        // Bind state changes back to parent
        onCurrentTabChanged: controlPanelContainer.currentTab = currentTab
        onIsShownChanged: controlPanelContainer.isShown = isShown
        
        // Forward signals
        onRecordingRequested: controlPanelContainer.recordingRequested()
        onStopRecordingRequested: controlPanelContainer.stopRecordingRequested()
        onSystemActionRequested: function(action) { controlPanelContainer.systemActionRequested(action) }
        onPerformanceActionRequested: function(action) { controlPanelContainer.performanceActionRequested(action) }
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