import "root:/modules/common/widgets"
import "root:/modules/common"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

/**
 * System Status Tab - Split into Dashboard and System Info
 * 70% System Dashboard + 30% System Information (bottom)
 */
Rectangle {
    id: root
    radius: Appearance.rounding.normal
    color: "transparent"
    border.color: Qt.rgba(1, 1, 1, 0.12)
    border.width: 1
    
    Component.onCompleted: {
        console.log("FanControlPage: SystemMonitor available:", typeof SystemMonitor !== 'undefined')
        if (SystemMonitor) {
            console.log("FanControlPage: SystemMonitor properties:", SystemMonitor.cpuModel, SystemMonitor.cpuUsage)
        }
    }
    
    // Helper function to format network speeds
    function formatNetworkSpeed(bytesPerSecond) {
        if (bytesPerSecond < 1024) {
            return bytesPerSecond.toFixed(1) + " B/s"
        } else if (bytesPerSecond < 1024 * 1024) {
            return (bytesPerSecond / 1024).toFixed(1) + " KB/s"
        } else if (bytesPerSecond < 1024 * 1024 * 1024) {
            return (bytesPerSecond / 1024 / 1024).toFixed(1) + " MB/s"
        } else {
            return (bytesPerSecond / 1024 / 1024 / 1024).toFixed(1) + " GB/s"
        }
    }
    

    
    // Main layout - split into two sections vertically
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // System Dashboard Section (65% height)
        Rectangle {
            id: dashboardSection
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: parent.height * 0.65
            radius: 12
            color: Qt.rgba(0.1, 0.1, 0.15, 0.8)
            border.color: Qt.rgba(1, 1, 1, 0.1)
            border.width: 1
            
            // Dashboard title
                    StyledText {
                id: dashboardTitle
                text: "System Dashboard"
                        font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Bold
                        color: "white"
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 16
            }
            
            // Refresh button
            Rectangle {
                id: refreshButton
                width: 32
                height: 32
                radius: 6
                color: Qt.rgba(0.15, 0.15, 0.2, 0.8)
                border.color: Qt.rgba(1, 1, 1, 0.1)
                border.width: 1
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 16
                
                    MaterialSymbol {
                    anchors.centerIn: parent
                    text: "refresh"
                    iconSize: 16
                    color: "white"
                }
                
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        // Force refresh of all data
                        if (SystemMonitor) {
                            SystemMonitor.updateCpuUsage()
                            SystemMonitor.updateMemoryUsage()
                            SystemMonitor.updateDiskUsage()
                            SystemMonitor.updateNetworkUsage()
                            SystemMonitor.updateGpuData()
                            SystemMonitor.updateCpuDetails()
                            SystemMonitor.updateSystemInfo()
                        }
                    }
                    onEntered: parent.color = Qt.rgba(0.2, 0.2, 0.25, 0.8)
                    onExited: parent.color = Qt.rgba(0.15, 0.15, 0.2, 0.8)
                }
            }
            
            // Dashboard grid
            GridLayout {
                anchors.top: dashboardTitle.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 16
                anchors.topMargin: 24
                columns: 2
                rowSpacing: 12
                columnSpacing: 12
                
                // GPU Widget
                DashboardWidget {
                    title: "GPU"
                    value: SystemMonitor ? SystemMonitor.gpuUsage : 0
                    valueText: (SystemMonitor && SystemMonitor.gpuAvailable) ? 
                        Math.round(SystemMonitor.gpuUsage * 100) + "%" : "N/A"
                    subtitle: (SystemMonitor && SystemMonitor.gpuAvailable) ? 
                        SystemMonitor.gpuModel + " • " + Math.round(SystemMonitor.gpuTemperature) + "°C" + 
                        (SystemMonitor.gpuMemoryTotal > 0 ? " • " + (SystemMonitor.gpuMemoryUsage / 1024 / 1024 / 1024).toFixed(1) + " GB VRAM" : "") : 
                        "No GPU detected"
                    history: SystemMonitor ? SystemMonitor.gpuHistory : []
                    graphColor: "#8b5cf6"  // Purple
                Layout.fillWidth: true
                    Layout.fillHeight: true
                }
                
                // Memory Widget
                DashboardWidget {
                    title: "Memory"
                    value: SystemMonitor ? SystemMonitor.memoryUsage : 0
                    valueText: SystemMonitor ? (SystemMonitor.memoryUsed / 1024 / 1024 / 1024).toFixed(1) + " GB" : "0.0 GB"
                    subtitle: SystemMonitor ? "Used of " + (SystemMonitor.memoryTotal / 1024 / 1024 / 1024).toFixed(1) + " GB • " + 
                        Math.round(SystemMonitor.memoryUsage * 100) + "%" : "No memory data"
                    history: SystemMonitor ? SystemMonitor.memoryHistory : []
                    graphColor: "#3b82f6"  // Blue
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
                
                // CPU Widget
                DashboardWidget {
                    title: "CPU"
                    value: SystemMonitor ? SystemMonitor.cpuUsage : 0
                    valueText: (SystemMonitor && SystemMonitor.cpuAvailable) ? 
                        Math.round(SystemMonitor.cpuUsage * 100) + "%" : "N/A"
                    subtitle: (SystemMonitor && SystemMonitor.cpuAvailable) ? 
                        SystemMonitor.cpuModel + " • " + SystemMonitor.cpuClock.toFixed(1) + " GHz • " + 
                        Math.round(SystemMonitor.cpuTemperature) + "°C • " + 
                        SystemMonitor.cpuCores + " cores" : 
                        "No CPU data"
                    history: SystemMonitor ? SystemMonitor.cpuHistory : []
                    graphColor: "#10b981"  // Green
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
                
                // Disk Widget
                DashboardWidget {
                    title: "Disk"
                    value: SystemMonitor ? SystemMonitor.diskUsage : 0
                    valueText: (SystemMonitor && SystemMonitor.diskAvailable) ? 
                        Math.round(SystemMonitor.diskUsage * 100) + "%" : "N/A"
                    subtitle: (SystemMonitor && SystemMonitor.diskAvailable) ? 
                        (SystemMonitor.diskUsed / 1024 / 1024 / 1024).toFixed(1) + " GB used of " + 
                        (SystemMonitor.diskTotal / 1024 / 1024 / 1024).toFixed(1) + " GB • " + 
                        (SystemMonitor.diskFree / 1024 / 1024 / 1024).toFixed(1) + " GB free • " + 
                        SystemMonitor.diskDevice + " on " + SystemMonitor.diskMountPoint : 
                        "No disk data"
                    history: SystemMonitor ? SystemMonitor.diskHistory : []
                    graphColor: "#ef4444"  // Red
                Layout.fillWidth: true
                    Layout.fillHeight: true
                }
                
                // Network Widget
                DashboardWidget {
                    title: "Network"
                    value: SystemMonitor ? (SystemMonitor.networkAvailable ? Math.min(SystemMonitor.networkTotalSpeed / 1024 / 1024 / 50, 1.0) : 0) : 0  // Normalize to 0-1 range (50 MB/s max)
                    valueText: SystemMonitor && SystemMonitor.networkAvailable ? 
                        formatNetworkSpeed(SystemMonitor.networkTotalSpeed) : "N/A"
                    subtitle: SystemMonitor && SystemMonitor.networkAvailable ? 
                        "↓ " + formatNetworkSpeed(SystemMonitor.networkDownloadSpeed) + " ↑ " + formatNetworkSpeed(SystemMonitor.networkUploadSpeed) + 
                        " • " + SystemMonitor.networkInterface : 
                        "No network monitoring"
                    history: SystemMonitor ? SystemMonitor.networkHistory.map(speed => Math.min(speed / 1024 / 1024 / 50, 1.0)) : []  // Normalize to 0-1 range (50 MB/s max)
                    graphColor: "#f59e0b"  // Orange
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
        
        // System Info Section (35% height) - Redesigned
        Rectangle {
            id: systemInfoSection
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: parent.height * 0.35
            radius: 12
            color: Qt.rgba(0.1, 0.1, 0.15, 0.8)
                border.color: Qt.rgba(1, 1, 1, 0.1)
                border.width: 1
            
            // System Info title with status indicator
                RowLayout {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 16
                anchors.topMargin: 16
                spacing: 12
                
                    StyledText {
                    text: "System Information"
                    font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Bold
                        color: "white"
                }
                
                // Status indicator
                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: SystemMonitor && SystemMonitor.cpuAvailable ? "#10b981" : "#ef4444"
                }
                
                StyledText {
                    text: SystemMonitor && SystemMonitor.cpuAvailable ? "Live" : "Offline"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: SystemMonitor && SystemMonitor.cpuAvailable ? "#10b981" : "#ef4444"
                }
                
                Item { Layout.fillWidth: true }
            }
            
            // System Information - Grid layout for better organization
            GridLayout {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 20
                anchors.topMargin: 48
                columns: 2
                rowSpacing: 16
                columnSpacing: 20
                
                // System Section
            Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 120
                    radius: 8
                    color: Qt.rgba(0.15, 0.15, 0.2, 0.6)
                    border.color: Qt.rgba(1, 1, 1, 0.05)
                border.width: 1
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10
                        
                        // Section header
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            MaterialSymbol {
                                text: "computer"
                                iconSize: 16
                                color: "#3b82f6"
                            }
                            
                            StyledText {
                                text: "System"
                                font.pixelSize: Appearance.font.pixelSize.medium
                                font.weight: Font.Bold
                                color: "white"
                            }
                            
                            Item { Layout.fillWidth: true }
                        }
                        
                        // System info items
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            StyledText {
                                text: "OS:"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Qt.rgba(1, 1, 1, 0.7)
                                Layout.preferredWidth: 80
                            }
                            
                            StyledText {
                                text: SystemMonitor ? SystemMonitor.osName + " " + SystemMonitor.osVersion : "Unknown"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: "white"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            StyledText {
                                text: "Kernel:"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Qt.rgba(1, 1, 1, 0.7)
                                Layout.preferredWidth: 80
                            }
                            
                            StyledText {
                                text: SystemMonitor ? SystemMonitor.kernelVersion : "Unknown"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: "white"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            StyledText {
                                text: "Hostname:"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Qt.rgba(1, 1, 1, 0.7)
                                Layout.preferredWidth: 80
                            }
                            
                            StyledText {
                                text: SystemMonitor ? SystemMonitor.hostname : "Unknown"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: "white"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            StyledText {
                                text: "Arch:"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Qt.rgba(1, 1, 1, 0.7)
                                Layout.preferredWidth: 80
                            }
                            
                            StyledText {
                                text: SystemMonitor ? SystemMonitor.architecture : "Unknown"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: "white"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
                
                // Hardware Section
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 120
                    radius: 8
                    color: Qt.rgba(0.15, 0.15, 0.2, 0.6)
                    border.color: Qt.rgba(1, 1, 1, 0.05)
                    border.width: 1
                    
                    ColumnLayout {
                    anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10
                        
                        // Section header
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            MaterialSymbol {
                                text: "memory"
                                iconSize: 16
                                color: "#10b981"
                            }
                            
                            StyledText {
                                text: "Hardware"
                                font.pixelSize: Appearance.font.pixelSize.medium
                                font.weight: Font.Bold
                                color: "white"
                            }
                            
                            Item { Layout.fillWidth: true }
                        }
                        
                        // Hardware info items
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            StyledText {
                                text: "CPU:"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Qt.rgba(1, 1, 1, 0.7)
                                Layout.preferredWidth: 80
                            }
                            
                            StyledText {
                                text: SystemMonitor ? SystemMonitor.cpuModel : "Unknown"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: "white"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            StyledText {
                                text: "Cores:"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Qt.rgba(1, 1, 1, 0.7)
                                Layout.preferredWidth: 80
                            }
                            
                            StyledText {
                                text: SystemMonitor ? SystemMonitor.cpuCores + "C, " + SystemMonitor.cpuThreads + "T" : "Unknown"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: "white"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            StyledText {
                                text: "Memory:"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Qt.rgba(1, 1, 1, 0.7)
                                Layout.preferredWidth: 80
                            }
                            
                            StyledText {
                                text: SystemMonitor ? SystemMonitor.totalMemory + " total" : "Unknown"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: "white"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            StyledText {
                                text: "Available:"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Qt.rgba(1, 1, 1, 0.7)
                                Layout.preferredWidth: 80
                            }
                            
                            StyledText {
                                text: SystemMonitor ? SystemMonitor.availableMemory + " free" : "Unknown"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: "white"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
                
                // Runtime Section
                Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
                    Layout.preferredHeight: 80
                    radius: 8
                    color: Qt.rgba(0.15, 0.15, 0.2, 0.6)
                    border.color: Qt.rgba(1, 1, 1, 0.05)
                    border.width: 1
                    
            ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10
                        
                        // Section header
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            MaterialSymbol {
                                text: "schedule"
                                iconSize: 16
                                color: "#f59e0b"
                            }
                            
                            StyledText {
                                text: "Runtime"
                                font.pixelSize: Appearance.font.pixelSize.medium
                                font.weight: Font.Bold
                                color: "white"
                            }
                            
                            Item { Layout.fillWidth: true }
                        }
                        
                        // Runtime info items
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            StyledText {
                                text: "Uptime:"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Qt.rgba(1, 1, 1, 0.7)
                                Layout.preferredWidth: 80
                            }
                            
                            StyledText {
                                text: SystemMonitor ? SystemMonitor.uptime : "Unknown"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: "white"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            StyledText {
                                text: "Boot:"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Qt.rgba(1, 1, 1, 0.7)
                                Layout.preferredWidth: 80
                            }
                            
                            StyledText {
                                text: SystemMonitor ? SystemMonitor.bootTime : "Unknown"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: "white"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
                
                // Network Section
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 80
                    radius: 8
                    color: Qt.rgba(0.15, 0.15, 0.2, 0.6)
                    border.color: Qt.rgba(1, 1, 1, 0.05)
                    border.width: 1
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10
                        
                        // Section header
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            MaterialSymbol {
                                text: "wifi"
                                iconSize: 16
                                color: "#8b5cf6"
                            }
                            
                            StyledText {
                                text: "Network"
                                font.pixelSize: Appearance.font.pixelSize.medium
                                font.weight: Font.Bold
                                color: "white"
                            }
                            
                            Item { Layout.fillWidth: true }
                        }
                        
                        // Network info items
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            StyledText {
                                text: "Interface:"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Qt.rgba(1, 1, 1, 0.7)
                                Layout.preferredWidth: 80
                            }
                            
                            StyledText {
                                text: SystemMonitor ? SystemMonitor.networkInterface : "Unknown"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: "white"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            StyledText {
                                text: "IP:"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Qt.rgba(1, 1, 1, 0.7)
                                Layout.preferredWidth: 80
                            }
                            
                            StyledText {
                                text: SystemMonitor ? SystemMonitor.ipAddress : "Unknown"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: "white"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
    }
} 