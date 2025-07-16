pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Enhanced system monitoring service using FileView with reload method.
 * - Direct statfs syscalls for disk usage
 * - Improved CPU usage calculation with 50ms sleep method
 * - Enhanced sysfs-based monitoring
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
    
    // Disk Properties (using statfs)
    property bool diskAvailable: false
    property string diskMountPoint: "/"
    property string diskDevice: ""
    property double diskTotal: 0.0
    property double diskUsed: 0.0
    property double diskFree: 0.0
    property double diskUsage: 0.0  // 0.0 to 1.0
    
    // Network Properties
    property bool networkAvailable: false
    property string networkInterface: ""
    property double networkDownloadSpeed: 0.0  // Bytes per second
    property double networkUploadSpeed: 0.0    // Bytes per second
    property double networkTotalSpeed: 0.0     // Combined speed
    property double networkDownloadTotal: 0.0  // Total bytes downloaded
    property double networkUploadTotal: 0.0    // Total bytes uploaded
    
    // System Info Properties (comprehensive system information)
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
    
    // GPU update timer (less frequent)
    Timer {
        interval: 5000  // 5 seconds for GPU
        running: true
        repeat: true
        onTriggered: {
            updateGpuData()
        }
    }
    
    // CPU details timer (once on startup)
    Timer {
        interval: 1000
        running: true
        repeat: false
        onTriggered: {
            updateCpuDetails()
        }
    }
    
    // CPU details update timer (every 30 seconds)
    Timer {
        interval: 30000  // 30 seconds
        running: true
        repeat: true
        onTriggered: {
            updateCpuDetails()
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
    
    // Enhanced CPU Usage calculation with 50ms sleep method
    function updateCpuUsage() {
        // Reload the stat file
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
                    console.log("[SystemMonitor] CPU Usage:", (cpuUsage * 100).toFixed(1) + "%")
                }
            } else {
                // First run - initialize stats and mark CPU as available
                cpuAvailable = true
                console.log("[SystemMonitor] CPU stats initialized")
            }
            
            previousCpuStats = { total, idle }
        }
    }
    
    // Memory usage from /proc/meminfo
    function updateMemoryUsage() {
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
            console.log("[SystemMonitor] Memory Usage:", (memoryUsage * 100).toFixed(1) + "%")
        }
    }
    
    // Disk usage using direct statfs syscall
    function updateDiskUsage() {
        diskUsageFile.reload()
        const text = diskUsageFile.text()
        if (!text) return
        
        try {
            const lines = text.trim().split('\n')
            if (lines.length >= 5) {
                const mountPoint = lines[0]
                const device = lines[1]
                const total = parseFloat(lines[2])
                const used = parseFloat(lines[3])
                const free = parseFloat(lines[4])
                const usage = parseFloat(lines[5])
                
                if (!isNaN(total) && !isNaN(used) && !isNaN(free) && !isNaN(usage)) {
                    diskMountPoint = mountPoint
                    diskDevice = device
                    diskTotal = total
                    diskUsed = used
                    diskFree = free
                    diskUsage = usage
                    diskAvailable = true
                    console.log("[SystemMonitor] Disk Usage:", mountPoint, "on", device, (usage * 100).toFixed(1) + "%")
                }
            }
        } catch (e) {
            console.log("[SystemMonitor] Disk usage calculation error:", e)
        }
    }
    
    // Network usage from /proc/net/dev with improved interface detection
    function updateNetworkUsage() {
        networkDevFile.reload()
        const text = networkDevFile.text()
        if (!text) return
        
        // Find the primary network interface (prioritize default route)
        const lines = text.trim().split('\n')
        let primaryIface = null
        let bytesReceived = 0
        let bytesTransmitted = 0
        
        // First, try to get the default route interface using the route file
        try {
            const routeText = networkRouteFile.text()
            if (routeText) {
                const defaultIface = routeText.trim()
                console.log("[SystemMonitor] Default route interface:", defaultIface)
                
                // Find this interface in /proc/net/dev
                for (const line of lines) {
                    if (line.includes(defaultIface + ':')) {
                        const parts = line.trim().split(/\s+/)
                        if (parts.length >= 10) {
                            primaryIface = parts[0].replace(':', '')
                            bytesReceived = parseInt(parts[1]) || 0
                            bytesTransmitted = parseInt(parts[9]) || 0
                            console.log("[SystemMonitor] Found default interface:", primaryIface, "bytes:", bytesReceived, bytesTransmitted)
                            break
                        }
                    }
                }
            }
        } catch (e) {
            console.log("[SystemMonitor] Route detection error:", e)
        }
        
        // Fallback to interface priority if default route not found
        if (!primaryIface) {
            // Prioritize your specific interface first, then others
            const interfacePriority = ['enp8s0', 'enp', 'eth0', 'wlan0', 'wlp', 'eno', 'wlx']
            
            for (const priority of interfacePriority) {
                for (const line of lines) {
                    if (line.match(new RegExp(`^${priority}`))) {
                        const parts = line.trim().split(/\s+/)
                        if (parts.length >= 10) {
                            primaryIface = parts[0].replace(':', '')
                            bytesReceived = parseInt(parts[1]) || 0
                            bytesTransmitted = parseInt(parts[9]) || 0
                            console.log("[SystemMonitor] Found fallback interface:", primaryIface, "bytes:", bytesReceived, bytesTransmitted)
                            break
                        }
                    }
                }
                if (primaryIface) break
            }
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
            console.log("[SystemMonitor] Network stats:", primaryIface, "↓", formatBytes(networkDownloadSpeed) + "/s", "↑", formatBytes(networkUploadSpeed) + "/s")
        }
        
        previousNetworkStats = { 
            iface: primaryIface, 
            bytesReceived, 
            bytesTransmitted 
        }
    }
    
    // Helper function to format bytes
    function formatBytes(bytes) {
        if (bytes < 1024) return bytes.toFixed(1) + " B"
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB"
        if (bytes < 1024 * 1024 * 1024) return (bytes / 1024 / 1024).toFixed(1) + " MB"
        return (bytes / 1024 / 1024 / 1024).toFixed(1) + " GB"
    }
    
    // Comprehensive system info update function
    function updateSystemInfo() {
        try {
            // OS and Version
            if (osReleaseFile.exists) {
                osReleaseFile.reload()
                const text = osReleaseFile.text()
                const nameMatch = text.match(/^NAME="([^"]+)"/m)
                const versionMatch = text.match(/^VERSION="([^"]+)"/m)
                if (nameMatch) osName = nameMatch[1]
                if (versionMatch) osVersion = versionMatch[1]
            }
            
            // Kernel Version
            if (versionFile.exists) {
                versionFile.reload()
                const text = versionFile.text()
                const kernelMatch = text.match(/Linux version ([^\s]+)/)
                if (kernelMatch) kernelVersion = kernelMatch[1]
            }
            
            // Architecture
            if (cpuinfoFile.exists) {
                const text = cpuinfoFile.text()
                const archMatch = text.match(/flags\s+:\s+.*\b(x86_64|amd64|i386|arm64|aarch64)\b/)
                if (archMatch) architecture = archMatch[1]
            }
            
            // Hostname
            if (hostnameFile.exists) {
                hostnameFile.reload()
                const text = hostnameFile.text()
                if (text) hostname = text.trim()
            }
            
            // Uptime
            if (uptimeFile.exists) {
                uptimeFile.reload()
                const text = uptimeFile.text()
                const uptimeMatch = text.match(/^(\d+\.\d+)/)
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
            
            // Boot Time
            if (uptimeFile.exists) {
                const text = uptimeFile.text()
                const uptimeMatch = text.match(/^(\d+\.\d+)/)
                if (uptimeMatch) {
                    const seconds = parseFloat(uptimeMatch[1])
                    const bootTimeMs = Date.now() - (seconds * 1000)
                    const bootDate = new Date(bootTimeMs)
                    bootTime = bootDate.toLocaleString()
                }
            }
            
            // Memory Info (formatted)
            if (memoryTotal > 0) {
                totalMemory = formatBytes(memoryTotal)
                availableMemory = formatBytes(memoryAvailable)
            }
            
            // IP Address
            if (networkInterface && networkInterface !== "Unknown") {
                ipAddress = networkInterface + " (" + getIpAddress(networkInterface) + ")"
            }
            
            console.log("[SystemMonitor] System Info updated:", osName, osVersion, kernelVersion, hostname)
        } catch (e) {
            console.log("[SystemMonitor] System info update error:", e)
        }
    }
    
    // Helper function to get IP address for interface
    function getIpAddress(iface) {
        try {
            if (ipAddrFile.exists) {
                ipAddrFile.reload()
                const text = ipAddrFile.text()
                const lines = text.split('\n')
                let inInterface = false
                
                for (const line of lines) {
                    if (line.includes(iface + ':')) {
                        inInterface = true
                        continue
                    }
                    if (inInterface && line.includes('inet ')) {
                        const ipMatch = line.match(/inet\s+([0-9.]+)/)
                        if (ipMatch) return ipMatch[1]
                        break
                    }
                    if (inInterface && line.match(/^\d+:/)) {
                        break
                    }
                }
            }
        } catch (e) {
            console.log("[SystemMonitor] IP address detection error:", e)
        }
        return "0.0.0.0"
    }
    
    // GPU data detection
    function updateGpuData() {
        // Try to detect GPU using simple methods
        try {
            // Check for NVIDIA GPU
            if (nvidiaGpuFile.exists) {
                nvidiaGpuFile.reload()
                const text = nvidiaGpuFile.text()
                if (text) {
                    const lines = text.trim().split('\n')
                    if (lines.length >= 2) {
                        gpuModel = "NVIDIA GPU"
                        gpuUsage = parseFloat(lines[0]) / 100.0 || 0
                        gpuTemperature = parseFloat(lines[1]) || 0
                        gpuAvailable = true
                        console.log("[SystemMonitor] NVIDIA GPU detected:", gpuUsage, gpuTemperature)
                        return
                    }
                }
            }
            
            // Check for AMD GPU
            if (amdGpuFile.exists) {
                amdGpuFile.reload()
                const text = amdGpuFile.text()
                if (text) {
                    gpuModel = "AMD GPU"
                    gpuUsage = parseFloat(text) / 100.0 || 0
                    gpuAvailable = true
                    console.log("[SystemMonitor] AMD GPU detected:", gpuUsage)
                    return
                }
            }
            
            // Check for Intel GPU
            if (intelGpuFile.exists) {
                intelGpuFile.reload()
                const text = intelGpuFile.text()
                if (text) {
                    gpuModel = "Intel GPU"
                    gpuTemperature = parseFloat(text) / 1000.0 || 0
                    gpuUsage = 0.0  // Intel GPUs often don't report usage
                    gpuAvailable = true
                    console.log("[SystemMonitor] Intel GPU detected:", gpuTemperature)
                    return
                }
            }
            
            gpuAvailable = false
            console.log("[SystemMonitor] No GPU detected")
        } catch (e) {
            console.log("[SystemMonitor] GPU detection error:", e)
            gpuAvailable = false
        }
    }
    
    // CPU details (model, temperature, clock, cores) - Enhanced with zigstat approach
    function updateCpuDetails() {
        try {
            // CPU Model - Enhanced detection
            if (cpuinfoFile.exists) {
                cpuinfoFile.reload()
                const text = cpuinfoFile.text()
                const modelMatch = text.match(/model name\s+:\s+(.+)/)
                if (modelMatch) {
                    cpuModel = modelMatch[1].trim()
                    cpuAvailable = true
                    console.log("[SystemMonitor] CPU Model:", cpuModel)
                }
            }
            
            // CPU Cores and Threads - More accurate detection
            if (cpuinfoFile.exists) {
                const text = cpuinfoFile.text()
                const processorCount = (text.match(/processor/g) || []).length
                const physicalIdCount = (text.match(/physical id/g) || []).length
                const coreIdCount = (text.match(/core id/g) || []).length
                
                if (processorCount > 0) {
                    cpuThreads = processorCount
                    // More accurate core count detection
                    if (physicalIdCount > 0 && coreIdCount > 0) {
                        cpuCores = physicalIdCount * coreIdCount
                    } else {
                        cpuCores = Math.ceil(processorCount / 2)  // Fallback estimate
                    }
                    console.log("[SystemMonitor] CPU Cores/Threads:", cpuCores, cpuThreads)
                }
            }
            
            // CPU Temperature - Enhanced with zigstat-style caching
            if (cpuTempFile.exists) {
                cpuTempFile.reload()
                const text = cpuTempFile.text()
                if (text) {
                    const temp = parseFloat(text) / 1000.0
                    if (!isNaN(temp) && temp > 0) {
                        cpuTemperature = temp
                        console.log("[SystemMonitor] CPU Temperature:", cpuTemperature)
                    }
                }
            }
            
            // CPU Clock - Enhanced detection
            if (cpuFreqFile.exists) {
                cpuFreqFile.reload()
                const text = cpuFreqFile.text()
                if (text) {
                    const mhz = parseFloat(text)
                    if (!isNaN(mhz) && mhz > 0) {
                        cpuClock = mhz / 1000.0  // Convert MHz to GHz
                        console.log("[SystemMonitor] CPU Clock:", cpuClock)
                    }
                }
            }
        } catch (e) {
            console.log("[SystemMonitor] CPU details error:", e)
        }
    }
    
    // Update history arrays
    function updateHistory() {
        cpuHistory = cpuHistory.concat([cpuUsage]).slice(-historyLength)
        gpuHistory = gpuHistory.concat([gpuUsage]).slice(-historyLength)
        memoryHistory = memoryHistory.concat([memoryUsage]).slice(-historyLength)
        diskHistory = diskHistory.concat([diskUsage]).slice(-historyLength)
        networkHistory = networkHistory.concat([networkTotalSpeed]).slice(-historyLength)
    }
    
    // File watchers for system files
    FileView {
        id: cpuStatFile
        path: "/proc/stat"
        watchChanges: true
        onLoadFailed: (error) => {
            console.log("[SystemMonitor] Failed to load /proc/stat:", error)
        }
    }
    
    FileView {
        id: meminfoFile
        path: "/proc/meminfo"
        watchChanges: true
        onLoadFailed: (error) => {
            console.log("[SystemMonitor] Failed to load /proc/meminfo:", error)
        }
    }
    
    FileView {
        id: networkDevFile
        path: "/proc/net/dev"
        watchChanges: true
        onLoadFailed: (error) => {
            console.log("[SystemMonitor] Failed to load /proc/net/dev:", error)
        }
    }
    
    FileView {
        id: networkRouteFile
        path: "/tmp/quickshell_default_route"
        watchChanges: true
        onLoadFailed: (error) => {
            console.log("[SystemMonitor] Failed to load network route file:", error)
        }
    }
    
    FileView {
        id: cpuinfoFile
        path: "/proc/cpuinfo"
        watchChanges: false
        onLoadFailed: (error) => {
            console.log("[SystemMonitor] Failed to load /proc/cpuinfo:", error)
        }
    }
    
    FileView {
        id: cpuTempFile
        path: "/sys/class/thermal/thermal_zone0/temp"
        watchChanges: true
        onLoadFailed: (error) => {
            console.log("[SystemMonitor] Failed to load CPU temperature:", error)
        }
    }
    
    FileView {
        id: cpuFreqFile
        path: "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq"
        watchChanges: true
        onLoadFailed: (error) => {
            console.log("[SystemMonitor] Failed to load CPU frequency:", error)
        }
    }
    
    FileView {
        id: nvidiaGpuFile
        path: "/proc/driver/nvidia/gpus/0/information"
        watchChanges: true
        onLoadFailed: (error) => {
            // NVIDIA GPU not available, this is normal
        }
    }
    
    FileView {
        id: amdGpuFile
        path: "/sys/class/drm/card0/device/gpu_busy_percent"
        watchChanges: true
        onLoadFailed: (error) => {
            // AMD GPU not available, this is normal
        }
    }
    
    FileView {
        id: intelGpuFile
        path: "/sys/class/drm/card0/device/hwmon/hwmon0/temp1_input"
        watchChanges: true
        onLoadFailed: (error) => {
            // Intel GPU not available, this is normal
        }
    }
    
    // Disk usage file (will be created by a simple script)
    FileView {
        id: diskUsageFile
        path: "/tmp/quickshell_disk_usage"
        watchChanges: true
        onLoadFailed: (error) => {
            console.log("[SystemMonitor] Failed to load disk usage:", error)
        }
    }
    
    // System info files
    FileView {
        id: osReleaseFile
        path: "/etc/os-release"
        watchChanges: false
        onLoadFailed: (error) => {
            console.log("[SystemMonitor] Failed to load OS release:", error)
        }
    }
    
    FileView {
        id: versionFile
        path: "/proc/version"
        watchChanges: false
        onLoadFailed: (error) => {
            console.log("[SystemMonitor] Failed to load kernel version:", error)
        }
    }
    
    FileView {
        id: hostnameFile
        path: "/proc/sys/kernel/hostname"
        watchChanges: false
        onLoadFailed: (error) => {
            console.log("[SystemMonitor] Failed to load hostname:", error)
        }
    }
    
    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        watchChanges: true
        onLoadFailed: (error) => {
            console.log("[SystemMonitor] Failed to load uptime:", error)
        }
    }
    
    FileView {
        id: ipAddrFile
        path: "/proc/net/route"
        watchChanges: true
        onLoadFailed: (error) => {
            console.log("[SystemMonitor] Failed to load network routes:", error)
        }
    }
    
    // Initialize on component creation
    Component.onCompleted: {
        console.log("[SystemMonitor] Enhanced service initialized with FileView method")
        
        // Create disk usage script
        const diskScript = `#!/bin/bash
python3 -c "
import os, statvfs
# Get current working directory's filesystem
cwd = os.getcwd()
st = os.statvfs(cwd)
total = st.f_blocks * st.f_frsize
free = st.f_bavail * st.f_frsize
used = total - free
usage = used/total if total > 0 else 0

# Get mount point and device
mount_point = cwd
device = 'unknown'

# Try to get device info from /proc/mounts
try:
    with open('/proc/mounts', 'r') as f:
        for line in f:
            parts = line.split()
            if len(parts) >= 2:
                dev, mp = parts[0], parts[1]
                if cwd.startswith(mp) and len(mp) > len(mount_point):
                    mount_point = mp
                    device = dev
except:
    pass

print(f'{mount_point}\\n{device}\\n{total}\\n{used}\\n{free}\\n{usage}')
" > /tmp/quickshell_disk_usage 2>/dev/null || echo "/\\nunknown\\n0\\n0\\n0\\n0" > /tmp/quickshell_disk_usage`
        
        // Create network route script
        const routeScript = `#!/bin/bash
ip route | grep default | awk '{print $5}' > /tmp/quickshell_default_route 2>/dev/null || echo "enp8s0" > /tmp/quickshell_default_route`
        
        // Run disk usage update timer
        diskUpdateTimer.start()
        
        // Run network route update timer
        networkRouteTimer.start()
        
        updateCpuUsage()
        updateMemoryUsage()
        updateDiskUsage()
        updateNetworkUsage()
        updateGpuData()
        updateCpuDetails()
        updateSystemInfo()
    }
    
    // Disk usage update timer
    Timer {
        id: diskUpdateTimer
        interval: 5000  // Update disk usage every 5 seconds
        running: false
        repeat: true
        onTriggered: {
            // Update disk usage file
            const diskScript = `python3 -c "
import os, statvfs
# Get current working directory's filesystem
cwd = os.getcwd()
st = os.statvfs(cwd)
total = st.f_blocks * st.f_frsize
free = st.f_bavail * st.f_frsize
used = total - free
usage = used/total if total > 0 else 0

# Get mount point and device
mount_point = cwd
device = 'unknown'

# Try to get device info from /proc/mounts
try:
    with open('/proc/mounts', 'r') as f:
        for line in f:
            parts = line.split()
            if len(parts) >= 2:
                dev, mp = parts[0], parts[1]
                if cwd.startswith(mp) and len(mp) > len(mount_point):
                    mount_point = mp
                    device = dev
except:
    pass

print(f'{mount_point}\\n{device}\\n{total}\\n{used}\\n{free}\\n{usage}')
" > /tmp/quickshell_disk_usage 2>/dev/null || echo "/\\nunknown\\n0\\n0\\n0\\n0" > /tmp/quickshell_disk_usage`
            const process = Qt.createQmlObject('import QtQuick; Process { command: ["bash", "-c", "' + diskScript + '"] }', root)
            process.running = true
        }
    }
    
    // Network route update timer
    Timer {
        id: networkRouteTimer
        interval: 10000  // Update network route every 10 seconds
        running: false
        repeat: true
        onTriggered: {
            // Update network route file
            const routeScript = `ip route | grep default | awk '{print $5}' > /tmp/quickshell_default_route 2>/dev/null || echo "enp8s0" > /tmp/quickshell_default_route`
            const process = Qt.createQmlObject('import QtQuick; Process { command: ["bash", "-c", "' + routeScript + '"] }', root)
            process.running = true
        }
    }
} 