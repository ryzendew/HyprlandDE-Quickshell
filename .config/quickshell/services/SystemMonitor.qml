pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Optimized system monitoring service with reduced overhead.
 */
Singleton {
    id: root
    
    // Update interval (1 second for faster response)
    property int updateInterval: 1000
    
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
    
    // State tracking
    property bool cpuModelDetected: false
    property bool systemInfoLoaded: false
    property int updateCounter: 0
    
    // Signal for CPU model updates
    signal cpuModelUpdated()
    
    // Main update timer - consolidated
    Timer {
        interval: root.updateInterval
        running: true
        repeat: true
        onTriggered: {
            updateCounter++
            
            // Core metrics every second
            updateCpuUsage()
            updateMemoryUsage()
            updateNetworkUsage()
            updateHistory()
            
            // CPU frequency every 3 seconds
            if (updateCounter % 3 === 0) {
                updateCpuFrequency()
            }
            
            // Disk usage every 5 seconds
            if (updateCounter % 5 === 0) {
                updateDiskUsage()
            }
            
            // System info every 30 seconds (or once on startup)
            if (updateCounter % 30 === 0 || !systemInfoLoaded) {
                updateSystemInfo()
                systemInfoLoaded = true
            }
            
            // CPU model detection once on startup
            if (!cpuModelDetected && updateCounter >= 3) {
                detectCpuModel()
                cpuModelDetected = true
            }
            
            // Disk detection every 60 seconds
            if (updateCounter % 60 === 0) {
                detectAvailableDisks()
            }
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
                
                // Update formatted memory strings
                totalMemory = formatBytes(memoryTotal)
                availableMemory = formatBytes(memoryAvailable)
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
    function updateDiskUsage() {
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
    
        // CPU model and core/thread detection
    function detectCpuModel() {
        console.log("[SystemMonitor] Starting CPU model detection...")
        cpuDetectionProcess.running = true
    }
    
    function detectCpuCores() {
        console.log("[SystemMonitor] Starting CPU core/thread detection...")
        cpuCoreDetectionProcess.running = true
    }
    
    // CPU model detection process
    Process {
        id: cpuDetectionProcess
        running: false
        command: ["bash", "-c", "cat /proc/cpuinfo | grep -m 1 'model name' | cut -d ':' -f2 | sed 's/^ *//'"]
        
        stdout: SplitParser {
            onRead: data => {
                const modelName = data.trim()
                console.log("[SystemMonitor] CPU output:", modelName)
                
                if (modelName && modelName !== 'Unknown' && modelName.length > 0) {
                    cpuModel = modelName
                    cpuAvailable = true
                    console.log("[SystemMonitor] Set CPU model to:", cpuModel)
                    cpuModelUpdated()  // Emit signal to notify UI
                    
                    // Trigger core detection after model is found
                    detectCpuCores()
                } else {
                    console.log("[SystemMonitor] Invalid CPU model name:", modelName)
                }
            }
        }
        
        onExited: (exitCode) => {
            console.log("[SystemMonitor] CPU process finished, exit code:", exitCode)
            if (exitCode !== 0) {
                console.log("[SystemMonitor] CPU process failed with exit code:", exitCode)
            }
        }
    }
    
    // CPU core/thread detection process
    Process {
        id: cpuCoreDetectionProcess
        running: false
        command: ["lscpu"]
        
        stdout: SplitParser {
            onRead: data => {
                const lines = data.trim().split('\n')
                for (const line of lines) {
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
                    
                    if (line.includes('CPU MHz:')) {
                        const mhz = parseFloat(line.split('CPU MHz:')[1].trim())
                        if (!isNaN(mhz) && mhz > 0) {
                            cpuClock = mhz / 1000.0  // Convert MHz to GHz
                            console.log("[SystemMonitor] Set CPU clock to:", cpuClock, "GHz")
                        }
                    }
                }
            }
        }
        
        onExited: (exitCode) => {
            console.log("[SystemMonitor] CPU core detection finished, exit code:", exitCode)
            if (exitCode !== 0) {
                console.log("[SystemMonitor] CPU core detection failed with exit code:", exitCode)
            }
            // After lscpu, try to get better CPU frequency info
            detectCpuMaxFrequency()
        }
    }
    
    // CPU frequency detection process
    Process {
        id: cpuFrequencyProcess
        running: false
        command: ["bash", "-c", "cat /proc/cpuinfo | grep -E 'cpu MHz|model name' | head -2"]
        
        stdout: SplitParser {
            onRead: data => {
                const lines = data.trim().split('\n')
                for (const line of lines) {
                    if (line.includes('cpu MHz')) {
                        const mhz = parseFloat(line.split('cpu MHz')[1].replace(':', '').trim())
                        if (!isNaN(mhz) && mhz > 0) {
                            cpuClock = mhz / 1000.0  // Convert MHz to GHz
                            console.log("[SystemMonitor] Set CPU clock from /proc/cpuinfo to:", cpuClock, "GHz")
                        }
                    }
                }
            }
        }
        
        onExited: (exitCode) => {
            console.log("[SystemMonitor] CPU frequency detection finished, exit code:", exitCode)
            if (exitCode !== 0) {
                console.log("[SystemMonitor] CPU frequency detection failed with exit code:", exitCode)
            }
        }
    }
    
    function detectCpuFrequency() {
        console.log("[SystemMonitor] Starting CPU frequency detection...")
        cpuFrequencyProcess.running = true
    }
    
    // Update CPU frequency (for periodic updates)
    function updateCpuFrequency() {
        try {
            cpuFreqFile.reload()
            const freqText = cpuFreqFile.text()
            if (freqText) {
                const freq = parseFloat(freqText.trim())
                if (!isNaN(freq) && freq > 0) {
                    cpuClock = freq / 1000000.0  // Convert kHz to GHz
                    console.log("[SystemMonitor] Updated CPU frequency to:", cpuClock, "GHz")
                }
            }
        } catch (e) {
            console.log("[SystemMonitor] CPU frequency update error:", e)
        }
    }
    
    // CPU max frequency detection process
    Process {
        id: cpuMaxFreqProcess
        running: false
        command: ["bash", "-c", "cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null || echo '0'"]
        
        stdout: SplitParser {
            onRead: data => {
                const maxFreq = parseFloat(data.trim())
                if (!isNaN(maxFreq) && maxFreq > 0) {
                    cpuClock = maxFreq / 1000000.0  // Convert kHz to GHz
                    console.log("[SystemMonitor] Set CPU max frequency to:", cpuClock, "GHz")
                } else {
                    console.log("[SystemMonitor] Could not read max frequency from sysfs")
                }
            }
        }
        
        onExited: (exitCode) => {
            console.log("[SystemMonitor] CPU max frequency detection finished, exit code:", exitCode)
            // If max frequency failed or is too low, try current frequency
            if (exitCode !== 0 || cpuClock < 1.0) {
                detectCpuFrequency()
            }
        }
    }
    
    function detectCpuMaxFrequency() {
        console.log("[SystemMonitor] Starting CPU max frequency detection...")
        cpuMaxFreqProcess.running = true
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
    
    FileView {
        id: cpuFreqFile
        path: "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq"
        watchChanges: true
        onLoadFailed: (error) => {
            // Failed to load CPU frequency
        }
    }
    
    // Initialize on component creation
    Component.onCompleted: {
        // Start initial monitoring
        updateCpuUsage()
        updateMemoryUsage()
        updateNetworkUsage()
        updateSystemInfo()
        detectAvailableDisks()
    }
} 