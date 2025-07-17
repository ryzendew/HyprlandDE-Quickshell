pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common"
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * System Information Service
 * Provides detailed system information like OS, kernel, uptime, etc.
 */
Singleton {
    id: root
    
    // System Information Properties
    property string osName: "Unknown"
    property string osVersion: "Unknown"
    property string kernelVersion: "Unknown"
    property string hostname: "Unknown"
    property string architecture: "Unknown"
    property string uptime: "Unknown"
    property string bootTime: "Unknown"
    property string cpuModel: "Unknown"
    property int cpuCores: 0
    property int cpuThreads: 0
    property string gpuModel: "Unknown"
    property string totalMemory: "Unknown"
    property string availableMemory: "Unknown"
    property string diskUsage: "Unknown"
    property string networkInterface: "Unknown"
    property string ipAddress: "Unknown"
    
    // Update interval
    property int updateInterval: 100 // 10 seconds
    
    // Main update timer
    Timer {
        interval: root.updateInterval
        running: true
        repeat: true
        onTriggered: {
            updateSystemInfo()
        }
    }
    
    // Update all system information
    function updateSystemInfo() {
        updateOSInfo()
        updateKernelInfo()
        updateHostnameInfo()
        updateUptimeInfo()
        updateCPUInfo()
        updateMemoryInfo()
        updateDiskInfo()
        updateNetworkInfo()
    }
    
    // OS Information
    function updateOSInfo() {
        osInfoProcess.running = true
    }
    
    // Kernel Information
    function updateKernelInfo() {
        kernelInfoProcess.running = true
    }
    
    // Hostname Information
    function updateHostnameInfo() {
        hostnameProcess.running = true
    }
    
    // Uptime Information
    function updateUptimeInfo() {
        uptimeProcess.running = true
    }
    
    // CPU Information
    function updateCPUInfo() {
        cpuInfoProcess.running = true
    }
    
    // Memory Information
    function updateMemoryInfo() {
        memoryInfoProcess.running = true
    }
    
    // Disk Information
    function updateDiskInfo() {
        diskInfoProcess.running = true
    }
    
    // Network Information
    function updateNetworkInfo() {
        networkInfoProcess.running = true
    }
    
    // OS Info Process
    Process {
        id: osInfoProcess
        command: ["bash", "-c", "cat /etc/os-release | grep -E '^(NAME|VERSION)=' | sed 's/NAME=//' | sed 's/VERSION=//' | tr '\\n' ' '"]
        onExited: {
            if (stdout) {
                const parts = stdout.trim().split(/\s+/)
                if (parts.length >= 2) {
                    osName = parts[0].replace(/"/g, '')
                    osVersion = parts[1].replace(/"/g, '')
                }
            }
        }
    }
    
    // Kernel Info Process
    Process {
        id: kernelInfoProcess
        command: ["bash", "-c", "uname -r && uname -m"]
        onExited: {
            if (stdout) {
                const lines = stdout.trim().split('\n')
                if (lines.length >= 2) {
                    kernelVersion = lines[0]
                    architecture = lines[1]
                }
            }
        }
    }
    
    // Hostname Process
    Process {
        id: hostnameProcess
        command: ["hostname"]
        onExited: {
            if (stdout) {
                hostname = stdout.trim()
            }
        }
    }
    
    // Uptime Process
    Process {
        id: uptimeProcess
        command: ["bash", "-c", "uptime -p | sed 's/up //' && echo '---' && date -d @$(cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1) | date '+%Y-%m-%d %H:%M:%S'"]
        onExited: {
            if (stdout) {
                const parts = stdout.trim().split('---')
                if (parts.length >= 2) {
                    uptime = parts[0].trim()
                    bootTime = parts[1].trim()
                }
            }
        }
    }
    
    // CPU Info Process
    Process {
        id: cpuInfoProcess
        command: ["bash", "-c", "cat /proc/cpuinfo | grep 'model name' | head -1 | sed 's/.*: //' && echo '---' && nproc && echo '---' && cat /proc/cpuinfo | grep 'processor' | wc -l"]
        onExited: {
            if (stdout) {
                const parts = stdout.trim().split('---')
                if (parts.length >= 3) {
                    cpuModel = parts[0].trim()
                    cpuCores = parseInt(parts[1].trim())
                    cpuThreads = parseInt(parts[2].trim())
                }
            }
        }
    }
    
    // Memory Info Process
    Process {
        id: memoryInfoProcess
        command: ["bash", "-c", "free -h | grep '^Mem:' | awk '{print $2}' && echo '---' && free -h | grep '^Mem:' | awk '{print $7}'"]
        onExited: {
            if (stdout) {
                const parts = stdout.trim().split('---')
                if (parts.length >= 2) {
                    totalMemory = parts[0].trim()
                    availableMemory = parts[1].trim()
                }
            }
        }
    }
    
    // Disk Info Process
    Process {
        id: diskInfoProcess
        command: ["bash", "-c", "df -h / | tail -1 | awk '{print $5}'"]
        onExited: {
            if (stdout) {
                diskUsage = stdout.trim()
            }
        }
    }
    
    // Network Info Process
    Process {
        id: networkInfoProcess
        command: ["bash", "-c", "ip route | grep default | awk '{print $5}' | head -1 && echo '---' && ip addr show | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}' | cut -d'/' -f1"]
        onExited: {
            if (stdout) {
                const parts = stdout.trim().split('---')
                if (parts.length >= 2) {
                    networkInterface = parts[0].trim()
                    ipAddress = parts[1].trim()
                }
            }
        }
    }
    
    // Initialize on component creation
    Component.onCompleted: {
        updateSystemInfo()
    }
}