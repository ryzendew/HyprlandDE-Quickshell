pragma Singleton
import QtQuick
import Quickshell.Io

// Process and resource monitor
QtObject {
    id: root
    
    // Current system resource metrics
    property real cpuUsage: 0
    property real ramUsage: 0
    property real totalRam: 0
    property real usedRam: 0
    
    // System control processes
    property Process shutdownProcess: Process {
        command: ["shutdown", "-h", "now"]
    }
    
    property Process rebootProcess: Process {
        command: ["reboot"]
    }
    
    property Process lockProcess: Process {
        command: ["hyprlock"]
    }
    
    property Process logoutProcess: Process {
        command: ["loginctl", "terminate-user", "$USER"]
    }
    
    property Process pavucontrolProcess: Process {
        command: ["pavucontrol"]
    }
    
    // Performance monitoring processes with shell commands
    property Process cpuProcess: Process {
        command: ["sh", "-c", "grep '^cpu ' /proc/stat | awk '{usage=($2+$3+$4)*100/($2+$3+$4+$5)} END {print usage}'"]
        stdout: SplitParser {
            onRead: data => {
                root.cpuUsage = parseFloat(data)
            }
        }
    }
    
    property Process ramProcess: Process {
        command: ["sh", "-c", "free -b | awk '/Mem:/ {print $2\" \"$3\" \"$3/$2*100}'"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(/\s+/)
                if (parts.length >= 3) {
                    root.totalRam = parseFloat(parts[0]) / (1024 * 1024 * 1024)
                    root.usedRam = parseFloat(parts[1]) / (1024 * 1024 * 1024)
                    root.ramUsage = parseFloat(parts[2])
                }
            }
        }
    }
    
    // Monitoring timers (disabled by default)
    property Timer cpuTimer: Timer {
        interval: 30000
        running: false   // Start manually when needed
        repeat: true
        onTriggered: {
            cpuProcess.running = false
            cpuProcess.running = true
        }
    }
    
    property Timer ramTimer: Timer {
        interval: 30000
        running: false   // Start manually when needed
        repeat: true
        onTriggered: {
            ramProcess.running = false
            ramProcess.running = true
        }
    }
    
    // System control functions
    function shutdown() {
        console.log("Executing shutdown command")
        shutdownProcess.running = true
    }
    
    function reboot() {
        console.log("Executing reboot command")
        rebootProcess.running = true
    }
    
    function lock() {
        console.log("Executing lock command")
        lockProcess.running = true
    }
    
    function logout() {
        console.log("Executing logout command")
        logoutProcess.running = true
    }
    
    function openPavuControl() {
        console.log("Opening PavuControl")
        pavucontrolProcess.running = true
    }
    
    // Performance monitoring control
    function startMonitoring() {
        console.log("Starting system monitoring")
        cpuTimer.running = true
        ramTimer.running = true
    }
    
    function stopMonitoring() {
        console.log("Stopping system monitoring")
        cpuTimer.running = false
        ramTimer.running = false
    }
    
    function setMonitoringInterval(intervalMs) {
        console.log("Setting monitoring interval to", intervalMs, "ms")
        cpuTimer.interval = intervalMs
        ramTimer.interval = intervalMs
    }
    
    function refreshSystemStats() {
        console.log("Manually refreshing system stats")
        cpuProcess.running = false
        cpuProcess.running = true
        ramProcess.running = false
        ramProcess.running = true
    }
    
    // Process state queries
    function isShutdownRunning() { return shutdownProcess.running }
    function isRebootRunning() { return rebootProcess.running }
    function isLockRunning() { return lockProcess.running }
    function isLogoutRunning() { return logoutProcess.running }
    function isPavuControlRunning() { return pavucontrolProcess.running }
    function isMonitoringActive() { return cpuTimer.running && ramTimer.running }
    
    function stopPavuControl() {
        pavucontrolProcess.running = false
    }
    
    // Formatted output helpers
    function getCpuUsageFormatted() {
        return Math.round(cpuUsage) + "%"
    }
    
    function getRamUsageFormatted() {
        return Math.round(ramUsage) + "% (" + usedRam.toFixed(1) + "GB/" + totalRam.toFixed(1) + "GB)"
    }
    
    function getRamUsageSimple() {
        return Math.round(ramUsage) + "%"
    }
    
    // Component cleanup
    Component.onDestruction: {
        // Stop all timers
        cpuTimer.running = false
        ramTimer.running = false
        
        // Stop all monitoring processes
        cpuProcess.running = false
        ramProcess.running = false
        
        // Stop control processes if running
        if (shutdownProcess.running) shutdownProcess.running = false
        if (rebootProcess.running) rebootProcess.running = false
        if (lockProcess.running) lockProcess.running = false
        if (logoutProcess.running) logoutProcess.running = false
        if (pavucontrolProcess.running) pavucontrolProcess.running = false
    }
}