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
    property double gpuClock: 0.0
    property double gpuPower: 0.0
    
    // Separate GPU properties for AMD
    property bool amdGpuAvailable: false
    property string amdGpuModel: "AMD GPU"
    property double amdGpuUsage: 0.0
    property double amdGpuTemperature: 0.0
    property double amdGpuMemoryUsage: 0.0
    property double amdGpuMemoryTotal: 0.0
    property double amdGpuClock: 0.0
    property double amdGpuPower: 0.0
    
    // Memory Properties
    property double memoryTotal: 0.0
    property double memoryUsed: 0.0
    property double memoryAvailable: 0.0
    property double memoryUsage: 0.0  // 0.0 to 1.0
    
    // Swap Properties
    property bool swapAvailable: false
    property double swapTotal: 0.0
    property double swapUsed: 0.0
    property double swapFree: 0.0
    property double swapUsage: 0.0  // 0.0 to 1.0
    property string swapType: "Unknown"  // "swap", "zram", or "none"
    
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
    property var amdGpuHistory: []
    property var memoryHistory: []
    property var swapHistory: []
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
            
            // CPU frequency and temperature every 3 seconds
            if (updateCounter % 3 === 0) {
                updateCpuFrequency()
                updateCpuTemperature()
            }
            
            // GPU monitoring every 3 seconds
            if (updateCounter % 3 === 0) {
                if (gpuAvailable) {
                    updateNvidiaGpuData()
                }
                if (amdGpuAvailable) {
                    updateAmdGpuData()
                }
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
            
            // GPU detection once on startup
            if ((!gpuAvailable || !amdGpuAvailable) && updateCounter >= 5) {
                detectGpu()
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
            
            // Update swap information
            updateSwapUsage()
        } catch (e) {
            // Memory usage update error
        }
    }
    
    // Swap usage monitoring
    function updateSwapUsage() {
        try {
            const swapTotalKB = Number(meminfoFile.text().match(/SwapTotal:\s+(\d+)/)?.[1] ?? 0)
            const swapFreeKB = Number(meminfoFile.text().match(/SwapFree:\s+(\d+)/)?.[1] ?? 0)
            
            if (swapTotalKB > 0) {
                swapTotal = swapTotalKB * 1024  // Convert KB to bytes
                swapFree = swapFreeKB * 1024
                swapUsed = swapTotal - swapFree
                swapUsage = swapUsed / swapTotal
                swapAvailable = true
                
                // Detect swap type
                detectSwapType()
            } else {
                swapAvailable = false
                swapType = "none"
            }
        } catch (e) {
            // Swap usage update error
        }
    }
    
    // Detect swap type (swap file/partition vs zram)
    function detectSwapType() {
        try {
            const process = Qt.createQmlObject('import QtQuick; Process { command: ["bash", "-c", "swapon --show | grep -q zram && echo zram || echo swap"] }', root)
            process.running = true
            
            process.onFinished.connect(function() {
                const output = process.readAllStandardOutput().trim()
                if (output === "zram") {
                    swapType = "zram"
                } else {
                    swapType = "swap"
                }
            })
        } catch (e) {
            swapType = "swap"
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
        cpuDetectionProcess.running = true
    }
    
    function detectCpuCores() {
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
                
                if (modelName && modelName !== 'Unknown' && modelName.length > 0) {
                    cpuModel = modelName
                    cpuAvailable = true
                    cpuModelUpdated()  // Emit signal to notify UI
                    
                    // Trigger core detection after model is found
                    detectCpuCores()
                }
            }
        }
        
        onExited: (exitCode) => {
            // CPU process finished
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
                        }
                    }
                    
                    if (line.includes('Thread(s) per core:')) {
                        const threadsPerCore = parseInt(line.split('Thread(s) per core:')[1].trim())
                        if (!isNaN(threadsPerCore) && threadsPerCore > 0) {
                            cpuThreads = cpuCores * threadsPerCore
                        }
                    }
                    
                    if (line.includes('CPU MHz:')) {
                        const mhz = parseFloat(line.split('CPU MHz:')[1].trim())
                        if (!isNaN(mhz) && mhz > 0) {
                            cpuClock = mhz / 1000.0  // Convert MHz to GHz
                        }
                    }
                }
            }
        }
        
        onExited: (exitCode) => {
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
                        }
                    }
                }
            }
        }
        
        onExited: (exitCode) => {
            // CPU frequency detection finished
        }
    }
    
    function detectCpuFrequency() {
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
                }
            }
        } catch (e) {
            // CPU frequency update error
        }
    }
    
    // Update CPU temperature using command
    function updateCpuTemperature() {
        cpuTempProcess.running = true
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
                }
            }
        }
        
        onExited: (exitCode) => {
            // If max frequency failed or is too low, try current frequency
            if (exitCode !== 0 || cpuClock < 1.0) {
                detectCpuFrequency()
            }
        }
    }
    
    function detectCpuMaxFrequency() {
        cpuMaxFreqProcess.running = true
    }
    
    // CPU temperature monitoring process using lm-sensors
    Process {
        id: cpuTempProcess
        running: false
        command: ["bash", "-c", "sensors 2>/dev/null | grep -E 'Tctl|Core|Package|CPU' | head -1 | grep -o '[0-9]\\+\\.[0-9]\\+' | head -1 || echo \"0\""]
        
        stdout: SplitParser {
            onRead: data => {
                const temp = parseFloat(data.trim())
                if (!isNaN(temp) && temp > 0) {
                    cpuTemperature = temp  // sensors already returns degrees Celsius
                }
            }
        }
        
        onExited: (exitCode) => {
            // CPU temperature monitoring finished
        }
    }
    
    // GPU detection process
    Process {
        id: gpuDetectionProcess
        running: false
        command: ["bash", "-c", "lspci | grep -i 'vga\\|3d\\|display'"]
        
        stdout: SplitParser {
            onRead: data => {
                const lines = data.trim().split('\n')
                for (const line of lines) {
                    if (line.includes('NVIDIA')) {
                        gpuAvailable = true
                        // Get detailed NVIDIA GPU info
                        detectNvidiaGpu()
                    } else if (line.includes('AMD') || line.includes('Advanced Micro Devices')) {
                        amdGpuAvailable = true
                        // Get detailed AMD GPU info
                        detectAmdGpu()
                    }
                }
            }
        }
        
        onExited: (exitCode) => {
            // GPU detection finished
        }
    }
    
    // NVIDIA GPU detection using NVML
    Process {
        id: nvidiaGpuDetectionProcess
        running: false
        command: ["bash", "-c", "python3 -c \"import pynvml; pynvml.nvmlInit(); handle = pynvml.nvmlDeviceGetHandleByIndex(0); name = pynvml.nvmlDeviceGetName(handle); print(name.decode('utf-8')); pynvml.nvmlShutdown()\" 2>/dev/null || nvidia-smi --query-gpu=name --format=csv,noheader,nounits"]
        
        stdout: SplitParser {
            onRead: data => {
                const gpuName = data.trim()
                if (gpuName && gpuName.length > 0) {
                    gpuModel = gpuName
                }
            }
        }
        
        onExited: (exitCode) => {
            if (exitCode === 0) {
                updateNvidiaGpuData()
            }
        }
    }
    
    // AMD GPU detection
    Process {
        id: amdGpuDetectionProcess
        running: false
        command: ["bash", "-c", "lspci | grep -i 'vga.*amd\\|amd.*vga' | head -1"]
        
        stdout: SplitParser {
            onRead: data => {
                const gpuInfo = data.trim()
                if (gpuInfo && gpuInfo.length > 0) {
                    amdGpuModel = gpuInfo
                    amdGpuAvailable = true
                }
            }
        }
        
        onExited: (exitCode) => {
            if (exitCode === 0 && amdGpuAvailable) {
                updateAmdGpuData()
            }
        }
    }
    
    // NVIDIA GPU monitoring process using NVML
    Process {
        id: nvidiaGpuMonitorProcess
        running: false
        command: ["bash", "-c", "python3 -c \"import pynvml; pynvml.nvmlInit(); handle = pynvml.nvmlDeviceGetHandleByIndex(0); util = pynvml.nvmlDeviceGetUtilizationRates(handle); mem = pynvml.nvmlDeviceGetMemoryInfo(handle); temp = pynvml.nvmlDeviceGetTemperature(handle, 0); clock = pynvml.nvmlDeviceGetClockInfo(handle, 0); power = pynvml.nvmlDeviceGetPowerUsage(handle) / 1000.0; print(f'{util.gpu},{mem.used},{mem.total},{temp},{clock},{power}'); pynvml.nvmlShutdown()\" 2>/dev/null || nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,clocks.current.graphics,power.draw --format=csv,noheader,nounits"]
        
        stdout: SplitParser {
            onRead: data => {
                const values = data.trim().split(',')
                if (values.length >= 6) {
                    // GPU utilization (0-100)
                    const usage = parseFloat(values[0]) || 0
                    gpuUsage = usage / 100.0  // Convert to 0.0-1.0
                    
                    // Memory usage (bytes)
                    const memUsed = parseFloat(values[1]) || 0
                    const memTotal = parseFloat(values[2]) || 0
                    gpuMemoryUsage = memUsed  // Already in bytes
                    gpuMemoryTotal = memTotal  // Already in bytes
                    
                    // Temperature (°C)
                    gpuTemperature = parseFloat(values[3]) || 0
                    
                    // Clock speed (MHz)
                    gpuClock = parseFloat(values[4]) || 0
                    
                    // Power draw (W)
                    gpuPower = parseFloat(values[5]) || 0
                    
                    // NVIDIA GPU data updated
                }
            }
        }
        
        onExited: (exitCode) => {
            // NVIDIA GPU monitoring finished
        }
    }
    
    // AMD GPU monitoring processes - split into separate commands for efficiency
    
    // AMD GPU product name detection (runs once)
    Process {
        id: amdGpuNameProcess
        running: false
        command: ["bash", "-c", "rocm-smi --showproductname 2>/dev/null || echo ''"]
        
        stdout: SplitParser {
            onRead: data => {
                const lines = data.trim().split('\n')
                for (const line of lines) {
                    if (line.includes('Subsystem ID:')) {
                        const match = line.match(/Subsystem ID:\s*(.+)/)
                        if (match) {
                            const subsystemInfo = match[1].trim()
                            // Extract the specific model from the subsystem info
                            const modelMatch = subsystemInfo.match(/Radeon RX (\d+[A-Z]*\s*[A-Z]*)/)
                            if (modelMatch) {
                                const gpuName = "Radeon RX " + modelMatch[1].trim()
                                if (gpuName && !amdGpuModel.includes("AMD")) {
                                    amdGpuModel = gpuName
                                }
                            }
                        }
                    }
                }
            }
        }
        
        onExited: (exitCode) => {
        }
    }
    
    // AMD GPU usage monitoring
    Process {
        id: amdGpuUsageProcess
        running: false
        command: ["bash", "-c", "rocm-smi --showuse 2>/dev/null || echo '0'"]
        
        stdout: SplitParser {
            onRead: data => {
                const lines = data.trim().split('\n')
                for (const line of lines) {
                    if (line.includes('GPU use (%)')) {
                        const match = line.match(/GPU use \(%\):\s*(\d+)/)
                        if (match) {
                            const usage = parseFloat(match[1]) || 0
                            amdGpuUsage = usage / 100.0
                        }
                    }
                }
            }
        }
        
        onExited: (exitCode) => {
            // AMD GPU usage monitoring finished
        }
    }
    
    // AMD GPU temperature monitoring
    Process {
        id: amdGpuTempProcess
        running: false
        command: ["bash", "-c", "rocm-smi --showtemp 2>/dev/null || echo '0'"]
        
        stdout: SplitParser {
            onRead: data => {
                const lines = data.trim().split('\n')
                for (const line of lines) {
                    if (line.includes('Temperature (Sensor edge)')) {
                        const match = line.match(/Temperature \(Sensor edge\) \(C\):\s*(\d+\.?\d*)/)
                        if (match) {
                            amdGpuTemperature = parseFloat(match[1]) || 0
                        }
                    }
                }
            }
        }
        
        onExited: (exitCode) => {
            // AMD GPU temperature monitoring finished
        }
    }
    
    // AMD GPU memory monitoring
    Process {
        id: amdGpuMemProcess
        running: false
        command: ["bash", "-c", "rocm-smi --showmemuse 2>/dev/null || echo '0'"]
        
        stdout: SplitParser {
            onRead: data => {
                const lines = data.trim().split('\n')
                for (const line of lines) {
                    if (line.includes('GPU Memory Allocated (VRAM%)')) {
                        const match = line.match(/GPU Memory Allocated \(VRAM%\):\s*(\d+)/)
                        if (match) {
                            const memUsed = parseFloat(match[1]) || 0
                            // Estimate total VRAM based on card series
                            let memTotal = 8  // Default fallback
                            if (amdGpuModel.includes("9070")) {
                                memTotal = 12  // 12GB for RX 9070 series
                            } else if (amdGpuModel.includes("7900")) {
                                memTotal = 20  // 20GB for RX 7900 series
                            } else if (amdGpuModel.includes("7800")) {
                                memTotal = 16  // 16GB for RX 7800 series
                            } else if (amdGpuModel.includes("7700")) {
                                memTotal = 12  // 12GB for RX 7700 series
                            }
                            
                            amdGpuMemoryUsage = (memUsed / 100.0) * (memTotal * 1024 * 1024 * 1024)  // Convert percentage to bytes
                            amdGpuMemoryTotal = memTotal * 1024 * 1024 * 1024  // Convert GB to bytes
                        }
                    }
                }
            }
        }
        
        onExited: (exitCode) => {
            // AMD GPU memory monitoring finished
        }
    }
    
    // AMD GPU power monitoring
    Process {
        id: amdGpuPowerProcess
        running: false
        command: ["bash", "-c", "rocm-smi --showpower 2>/dev/null || echo '0'"]
        
        stdout: SplitParser {
            onRead: data => {
                const lines = data.trim().split('\n')
                for (const line of lines) {
                    if (line.includes('Average Graphics Package Power')) {
                        const match = line.match(/Average Graphics Package Power \(W\):\s*(\d+\.?\d*)/)
                        if (match) {
                            amdGpuPower = parseFloat(match[1]) || 0
                        }
                    }
                }
            }
        }
        
        onExited: (exitCode) => {
            // AMD GPU power monitoring finished
        }
    }
    
    // AMD GPU clock monitoring
    Process {
        id: amdGpuClockProcess
        running: false
        command: ["bash", "-c", "rocm-smi --showclocks 2>/dev/null || echo '0'"]
        
        stdout: SplitParser {
            onRead: data => {
                const lines = data.trim().split('\n')
                for (const line of lines) {
                    if (line.includes('sclk clock level')) {
                        const match = line.match(/sclk clock level:\s*\d+:\s*\((\d+)Mhz\)/)
                        if (match) {
                            amdGpuClock = parseFloat(match[1]) || 0
                        }
                    }
                }
            }
        }
        
        onExited: (exitCode) => {
            // AMD GPU clock monitoring finished
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
        amdGpuHistory = amdGpuHistory.concat([amdGpuUsage]).slice(-historyLength)
        memoryHistory = memoryHistory.concat([memoryUsage]).slice(-historyLength)
        swapHistory = swapHistory.concat([swapUsage]).slice(-historyLength)
        diskHistory = diskHistory.concat([diskUsage]).slice(-historyLength)
        networkHistory = networkHistory.concat([networkTotalSpeed]).slice(-historyLength)
    }
    
    // Manual trigger for CPU details update
    function forceUpdateCpuDetails() {
        detectCpuModel()
    }
    
    // GPU detection and monitoring
    function detectGpu() {
        gpuDetectionProcess.running = true
    }
    
    function detectNvidiaGpu() {
        nvidiaGpuDetectionProcess.running = true
    }
    
    function detectAmdGpu() {
        amdGpuDetectionProcess.running = true
        // Also get the GPU name
        amdGpuNameProcess.running = true
    }
    
    function updateGpuData() {
        if (gpuAvailable) {
            updateNvidiaGpuData()
        }
        if (amdGpuAvailable) {
            updateAmdGpuData()
        }
    }
    
    function updateNvidiaGpuData() {
        nvidiaGpuMonitorProcess.running = true
    }
    
    function updateAmdGpuData() {
        // Run all AMD GPU monitoring processes
        amdGpuUsageProcess.running = true
        amdGpuTempProcess.running = true
        amdGpuMemProcess.running = true
        amdGpuPowerProcess.running = true
        amdGpuClockProcess.running = true
    }
    
    // Debug function to manually trigger AMD GPU detection
    function forceDetectAmdGpu() {
        amdGpuAvailable = false
        amdGpuModel = "AMD GPU"
        detectAmdGpu()
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