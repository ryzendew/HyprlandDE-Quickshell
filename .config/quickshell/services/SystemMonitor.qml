pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Simple system monitoring service using FileView with reload method.
 */
Singleton {
    id: root
    
    // Update interval (2 seconds)
    property int updateInterval: 2000
    
    // CPU Properties
    property bool cpuAvailable: false
    property string cpuModel: "CPU"
    property double cpuUsage: 0.0  // 0.0 to 1.0
    property double cpuTemperature: 0.0
    property double cpuClock: 0.0
    property int cpuCores: 0
    property int cpuThreads: 0
    
    // GPU Properties
    property bool gpuAvailable: false
    property string gpuModel: "GPU"
    property double gpuUsage: 0.0  // 0.0 to 1.0
    property double gpuTemperature: 0.0
    property double gpuMemoryUsage: 0.0
    property double gpuMemoryTotal: 0.0
    
    // Memory Properties
    property double memoryTotal: 0.0
    property double memoryUsed: 0.0
    property double memoryAvailable: 0.0
    property double memoryUsage: 0.0  // 0.0 to 1.0
    
    // Disk Properties
    property bool diskAvailable: false
    property string diskMountPoint: "/"
    property string diskDevice: ""
    property double diskTotal: 0.0
    property double diskUsed: 0.0
    property double diskFree: 0.0
    property double diskUsage: 0.0  // 0.0 to 1.0
    
    // Available disk drives for selection
    property var availableDisks: []
    property string selectedDisk: "/"
    
    // Network Properties
    property bool networkAvailable: false
    property string networkInterface: ""
    property double networkDownloadSpeed: 0.0  // Bytes per second
    property double networkUploadSpeed: 0.0    // Bytes per second
    property double networkTotalSpeed: 0.0     // Combined speed
    property double networkDownloadTotal: 0.0  // Total bytes downloaded
    property double networkUploadTotal: 0.0    // Total bytes uploaded
    
    // System Info Properties
    property string osName: "Unknown"
    property string osVersion: "Unknown"
    property string kernelVersion: "Unknown"
    property string architecture: "Unknown"
    property string hostname: "Unknown"
    property string uptime: "Unknown"
    property string bootTime: "Unknown"
    property string totalMemory: "Unknown"
    property string availableMemory: "Unknown"
    property string ipAddress: "Unknown"
    
    // History arrays for graphs (60 data points)
    property var cpuHistory: []
    property var gpuHistory: []
    property var memoryHistory: []
    property var diskHistory: []
    property var networkHistory: []
    property int historyLength: 60
    
    // Previous values for calculations
    property var previousCpuStats: null
    property var previousNetworkStats: null
    
    // Main update timer
    Timer {
        interval: root.updateInterval
        running: true
        repeat: true
        onTriggered: {
            updateCpuUsage()
            updateMemoryUsage()
            updateDiskUsage()
            updateNetworkUsage()
            updateHistory()
        }
    }
    
    // CPU details timer (once on startup)
    Timer {
        interval: 3000  // Increased delay to ensure Quickshell is fully loaded
        running: true
        repeat: false
        onTriggered: {
            detectCpuModel()
        }
    }
    
    // System info update timer (every 60 seconds)
    Timer {
        interval: 60000  // 60 seconds
        running: true
        repeat: true
        onTriggered: {
            updateSystemInfo()
        }
    }
    
    // Disk detection timer (every 30 seconds)
    Timer {
        interval: 30000  // 30 seconds
        running: true
        repeat: true
        onTriggered: {
            detectAvailableDisks()
        }
    }
    
    // Initial disk detection timer (run once after startup)
    Timer {
        interval: 2000  // 2 seconds after startup
        running: true
        repeat: false
        onTriggered: {
            detectAvailableDisks()
        }
    }
    
    // Enhanced CPU Usage calculation
    function updateCpuUsage() {
        try {
            cpuStatFile.reload()
            
            const text = cpuStatFile.text()
            if (!text) return
            
            const cpuLine = text.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
            if (cpuLine) {
                const stats = cpuLine.slice(1).map(Number)
                const total = stats.reduce((a, b) => a + b, 0)
                const idle = stats[3]
                
                if (previousCpuStats) {
                    const totalDiff = total - previousCpuStats.total
                    const idleDiff = idle - previousCpuStats.idle
                    if (totalDiff > 0) {
                        cpuUsage = Math.max(0, Math.min(1, 1 - idleDiff / totalDiff))
                        cpuAvailable = true
                    }
                } else {
                    cpuAvailable = true
                }
                
                previousCpuStats = { total, idle }
            }
        } catch (e) {
            // CPU usage update error
        }
    }
    
    // Memory usage from /proc/meminfo
    function updateMemoryUsage() {
        try {
            meminfoFile.reload()
            const text = meminfoFile.text()
            if (!text) return
            
            const memTotal = Number(text.match(/MemTotal:\s+(\d+)/)?.[1] ?? 0)
            const memAvailable = Number(text.match(/MemAvailable:\s+(\d+)/)?.[1] ?? 0)
            
            if (memTotal > 0) {
                memoryTotal = memTotal * 1024  // Convert KB to bytes
                memoryAvailable = memAvailable * 1024
                memoryUsed = memoryTotal - memoryAvailable
                memoryUsage = memoryUsed / memoryTotal
            }
        } catch (e) {
            // Memory usage update error
        }
    }
    
    // Detect available disk drives
    function detectAvailableDisks() {
        try {
            const command = "lsblk -d -n -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E '^(nvme|sd|hd|vd)' | awk '{print $1 \"|\" $2 \"|\" $3 \"|\" $4}'"
            
            const process = Qt.createQmlObject('import QtQuick; Process { command: ["bash", "-c", "' + command + '"] }', root)
            process.running = true
            
            process.onFinished.connect(function() {
                try {
                    const output = process.readAllStandardOutput()
                    const lines = output.trim().split('\n')
                    const disks = []
                    
                    for (const line of lines) {
                        if (line.trim() === '') continue
                        
                        const parts = line.split('|')
                        if (parts.length >= 4) {
                            const name = parts[0]
                            const size = parts[1]
                            const type = parts[2]
                            const mountpoint = parts[3]
                            
                            // Only include disk devices (not partitions)
                            if (type === 'disk') {
                                disks.push({
                                    name: name,
                                    size: size,
                                    type: type,
                                    mountpoint: mountpoint || '',
                                    displayName: `${name} (${size})`
                                })
                            }
                        }
                    }
                    
                    availableDisks = disks
                    
                    // Set default selection to first disk if none selected
                    if (disks.length > 0 && (!selectedDisk || selectedDisk === "/")) {
                        selectedDisk = disks[0].name
                    }
                } catch (e) {
                    // Disk detection parsing error
                }
            })
        } catch (e) {
            // Disk detection error
        }
    }
    
    // Update disk usage for selected drive
    function updateSelectedDiskUsage() {
        if (!selectedDisk) return
        
        try {
            const command = `python3 -c "import os, statvfs; st = os.statvfs('/dev/${selectedDisk}'); total = st.f_blocks * st.f_frsize; free = st.f_bavail * st.f_frsize; used = total - free; usage = used/total if total > 0 else 0; print(f'/dev/${selectedDisk}\\n{total}\\n{used}\\n{free}\\n{usage}')" 2>/dev/null || echo "/dev/${selectedDisk}\\n0\\n0\\n0\\n0"`
            
            const process = Qt.createQmlObject('import QtQuick; Process { command: ["bash", "-c", "' + command + '"] }', root)
            process.running = true
            
            process.onFinished.connect(function() {
                try {
                    const output = process.readAllStandardOutput()
                    const lines = output.trim().split('\n')
                    
                    if (lines.length >= 5) {
                        const device = lines[0]
                        const total = parseFloat(lines[1])
                        const used = parseFloat(lines[2])
                        const free = parseFloat(lines[3])
                        const usage = parseFloat(lines[4])
                        
                        if (!isNaN(total) && !isNaN(used) && !isNaN(free) && !isNaN(usage)) {
                            diskMountPoint = device
                            diskDevice = device
                            diskTotal = total
                            diskUsed = used
                            diskFree = free
                            diskUsage = usage
                            diskAvailable = true
                        }
                    }
                } catch (e) {
                    // Disk usage parsing error
                }
            })
        } catch (e) {
            // Disk usage error
        }
    }
    
    // Simple disk usage for root filesystem (fallback)
    function updateDiskUsage() {
        updateSelectedDiskUsage()
    }
    
    // Network usage from /proc/net/dev
    function updateNetworkUsage() {
        try {
            networkDevFile.reload()
            const text = networkDevFile.text()
            if (!text) return
            
            const lines = text.trim().split('\n')
            let primaryIface = null
            let bytesReceived = 0
            let bytesTransmitted = 0
            
            // Find primary interface (prioritize enp8s0, then others)
            const interfacePriority = ['enp8s0', 'enp', 'eth0', 'wlan0', 'wlp', 'eno', 'wlx']
            
            for (const priority of interfacePriority) {
                for (const line of lines) {
                    if (line.match(new RegExp(`^${priority}`))) {
                        const parts = line.trim().split(/\s+/)
                        if (parts.length >= 10) {
                            primaryIface = parts[0].replace(':', '')
                            bytesReceived = parseInt(parts[1]) || 0
                            bytesTransmitted = parseInt(parts[9]) || 0
                            break
                        }
                    }
                }
                if (primaryIface) break
            }
            
            if (primaryIface && previousNetworkStats && previousNetworkStats.iface === primaryIface) {
                const timeDiff = root.updateInterval / 1000.0
                const downloadDiff = bytesReceived - previousNetworkStats.bytesReceived
                const uploadDiff = bytesTransmitted - previousNetworkStats.bytesTransmitted
                
                networkDownloadSpeed = Math.max(0, downloadDiff / timeDiff)
                networkUploadSpeed = Math.max(0, uploadDiff / timeDiff)
                networkTotalSpeed = networkDownloadSpeed + networkUploadSpeed
                networkDownloadTotal = bytesReceived
                networkUploadTotal = bytesTransmitted
                networkInterface = primaryIface
                networkAvailable = true
            }
            
            previousNetworkStats = { 
                iface: primaryIface, 
                bytesReceived, 
                bytesTransmitted 
            }
        } catch (e) {
            // Network usage update error
        }
    }
    
    // Simple CPU model detection
    function detectCpuModel() {
        console.log("[SystemMonitor] Starting CPU model detection...")
        try {
            const lscpuProcess = Qt.createQmlObject('import QtQuick; Process { command: ["lscpu"] }', root)
            lscpuProcess.running = true
            
            lscpuProcess.onFinished.connect(function() {
                console.log("[SystemMonitor] lscpu process finished, exit code:", lscpuProcess.exitCode)
                if (lscpuProcess.exitCode === 0) {
                    const output = lscpuProcess.readAllStandardOutput()
                    console.log("[SystemMonitor] lscpu output length:", output.length)
                    console.log("[SystemMonitor] lscpu output preview:", output.substring(0, 200))
                    
                    const lines = output.split('\n')
                    console.log("[SystemMonitor] Parsed lines count:", lines.length)
                    
                    for (const line of lines) {
                        if (line.includes('Model name:')) {
                            console.log("[SystemMonitor] Found Model name line:", line)
                            const modelName = line.split('Model name:')[1].trim()
                            console.log("[SystemMonitor] Extracted model name:", modelName)
                            if (modelName && modelName !== 'Unknown') {
                                cpuModel = modelName
                                cpuAvailable = true
                                console.log("[SystemMonitor] Set CPU model to:", cpuModel)
                                break
                            }
                        }
                        
                        if (line.includes('CPU MHz:')) {
                            const mhz = parseFloat(line.split('CPU MHz:')[1].trim())
                            if (!isNaN(mhz) && mhz > 0) {
                                cpuClock = mhz / 1000.0  // Convert MHz to GHz
                                console.log("[SystemMonitor] Set CPU clock to:", cpuClock, "GHz")
                            }
                        }
                        
                        if (line.includes('Core(s) per socket:')) {
                            const cores = parseInt(line.split('Core(s) per socket:')[1].trim())
                            if (!isNaN(cores) && cores > 0) {
                                cpuCores = cores
                                console.log("[SystemMonitor] Set CPU cores to:", cpuCores)
                            }
                        }
                        
                        if (line.includes('Thread(s) per core:')) {
                            const threadsPerCore = parseInt(line.split('Thread(s) per core:')[1].trim())
                            if (!isNaN(threadsPerCore) && threadsPerCore > 0) {
                                cpuThreads = cpuCores * threadsPerCore
                                console.log("[SystemMonitor] Set CPU threads to:", cpuThreads)
                            }
                        }
                    }
                    console.log("[SystemMonitor] CPU detection completed. Model:", cpuModel, "Available:", cpuAvailable)
                } else {
                    console.log("[SystemMonitor] lscpu process failed with exit code:", lscpuProcess.exitCode)
                }
            })
        } catch (e) {
            console.log("[SystemMonitor] CPU detection error:", e)
        }
    }
    
    // System info update
    function updateSystemInfo() {
        try {
            // OS and Version
            osReleaseFile.reload()
            const osText = osReleaseFile.text()
            if (osText) {
                const nameMatch = osText.match(/^NAME="([^"]+)"/m)
                const versionMatch = osText.match(/^VERSION="([^"]+)"/m)
                if (nameMatch) osName = nameMatch[1]
                if (versionMatch) osVersion = versionMatch[1]
            }
            
            // Kernel Version
            versionFile.reload()
            const versionText = versionFile.text()
            if (versionText) {
                const kernelMatch = versionText.match(/Linux version ([^\s]+)/)
                if (kernelMatch) kernelVersion = kernelMatch[1]
            }
            
            // Hostname
            hostnameFile.reload()
            const hostnameText = hostnameFile.text()
            if (hostnameText) hostname = hostnameText.trim()
            
            // Uptime
            uptimeFile.reload()
            const uptimeText = uptimeFile.text()
            if (uptimeText) {
                const uptimeMatch = uptimeText.match(/^(\d+\.\d+)/)
                if (uptimeMatch) {
                    const seconds = parseFloat(uptimeMatch[1])
                    const days = Math.floor(seconds / 86400)
                    const hours = Math.floor((seconds % 86400) / 3600)
                    const minutes = Math.floor((seconds % 3600) / 60)
                    
                    if (days > 0) {
                        uptime = days + "d " + hours + "h " + minutes + "m"
                    } else if (hours > 0) {
                        uptime = hours + "h " + minutes + "m"
                    } else {
                        uptime = minutes + "m"
                    }
                }
            }
            
            // Memory Info (formatted)
            if (memoryTotal > 0) {
                totalMemory = formatBytes(memoryTotal)
                availableMemory = formatBytes(memoryAvailable)
            }
        } catch (e) {
            // System info update error
        }
    }
    
    // Helper function to format bytes
    function formatBytes(bytes) {
        if (bytes < 1024) return bytes.toFixed(1) + " B"
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB"
        if (bytes < 1024 * 1024 * 1024) return (bytes / 1024 / 1024).toFixed(1) + " MB"
        return (bytes / 1024 / 1024 / 1024).toFixed(1) + " GB"
    }
    
    // Update history arrays
    function updateHistory() {
        cpuHistory = cpuHistory.concat([cpuUsage]).slice(-historyLength)
        gpuHistory = gpuHistory.concat([gpuUsage]).slice(-historyLength)
        memoryHistory = memoryHistory.concat([memoryUsage]).slice(-historyLength)
        diskHistory = diskHistory.concat([diskUsage]).slice(-historyLength)
        networkHistory = networkHistory.concat([networkTotalSpeed]).slice(-historyLength)
    }
    
    // Manual trigger for CPU details update
    function forceUpdateCpuDetails() {
        console.log("[SystemMonitor] forceUpdateCpuDetails called")
        detectCpuModel()
    }
    
    // File watchers for system files
    FileView {
        id: cpuStatFile
        path: "/proc/stat"
        watchChanges: true
        onLoadFailed: (error) => {
            // Failed to load /proc/stat
        }
    }
    
    FileView {
        id: meminfoFile
        path: "/proc/meminfo"
        watchChanges: true
        onLoadFailed: (error) => {
            // Failed to load /proc/meminfo
        }
    }
    
    FileView {
        id: networkDevFile
        path: "/proc/net/dev"
        watchChanges: true
        onLoadFailed: (error) => {
            // Failed to load /proc/net/dev
        }
    }
    
    FileView {
        id: osReleaseFile
        path: "/etc/os-release"
        watchChanges: false
        onLoadFailed: (error) => {
            // Failed to load OS release
        }
    }
    
    FileView {
        id: versionFile
        path: "/proc/version"
        watchChanges: true
        onLoadFailed: (error) => {
            // Failed to load kernel version
        }
    }
    
    FileView {
        id: hostnameFile
        path: "/proc/sys/kernel/hostname"
        watchChanges: false
        onLoadFailed: (error) => {
            // Failed to load hostname
        }
    }
    
    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        watchChanges: true
        onLoadFailed: (error) => {
            // Failed to load uptime
        }
    }
    
    // Initialize on component creation
    Component.onCompleted: {
        // Start initial monitoring
        updateCpuUsage()
        updateMemoryUsage()
        updateSelectedDiskUsage()
        updateNetworkUsage()
        updateSystemInfo()
        detectAvailableDisks()
    }
} 