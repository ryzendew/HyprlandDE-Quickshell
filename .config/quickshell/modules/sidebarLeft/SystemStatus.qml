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
        if (SystemMonitor) {
            // Force update CPU details on page load
            SystemMonitor.forceUpdateCpuDetails()
        }
    }
    
    // Timer to check CPU model detection
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            if (SystemMonitor) {
                if (SystemMonitor.cpuModel === "CPU") {
                    SystemMonitor.forceUpdateCpuDetails()
                }
            }
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
    
    // Helper function to format CPU name
    function formatCpuName(cpuModel) {
        if (!cpuModel || cpuModel === "CPU") return "CPU"
        
        // Remove "AMD" and "Intel(R)" prefixes
        let name = cpuModel.replace(/^AMD\s+/, "").replace(/^Intel\(R\)\s+/, "")
        
        // Remove "CPU @ X.XXGHz" suffix
        name = name.replace(/\s+CPU\s+@\s+\d+\.\d+GHz.*$/, "")
        
        // Remove "Processor" suffix
        name = name.replace(/\s+Processor$/, "")
        
        // For AMD Ryzen, format as "Ryzen R9 9900X"
        if (name.includes("Ryzen")) {
            name = name.replace(/^Core\(TM\)\s+/, "")
            // Extract Ryzen model (e.g., "Ryzen 9 9900X")
            const ryzenMatch = name.match(/Ryzen\s+(\d+)\s+(\d+X?)/)
            if (ryzenMatch) {
                return `Ryzen R${ryzenMatch[1]} ${ryzenMatch[2]}`
            }
        }
        
        // For Intel, format as "Core i7-10700K"
        if (name.includes("Core")) {
            const coreMatch = name.match(/Core\s+(i\d+)-(\d+)/)
            if (coreMatch) {
                return `Core ${coreMatch[1]}-${coreMatch[2]}`
            }
        }
        
        return name
    }
    
    // Helper function to format GPU name
    function formatGpuName(gpuModel) {
        if (!gpuModel || gpuModel === "GPU") return "GPU"
        
        // For NVIDIA GeForce RTX series
        if (gpuModel.includes("GeForce RTX")) {
            const rtxMatch = gpuModel.match(/GeForce RTX (\d+)/)
            if (rtxMatch) {
                return `RTX ${rtxMatch[1]}`
            }
        }
        
        // For NVIDIA GeForce GTX series
        if (gpuModel.includes("GeForce GTX")) {
            const gtxMatch = gpuModel.match(/GeForce GTX (\d+)/)
            if (gtxMatch) {
                return `GTX ${gtxMatch[1]}`
            }
        }
        
        // For NVIDIA GeForce GT series
        if (gpuModel.includes("GeForce GT")) {
            const gtMatch = gpuModel.match(/GeForce GT (\d+)/)
            if (gtMatch) {
                return `GT ${gtMatch[1]}`
                        }
                    }
        
        // For AMD Radeon RX series
        if (gpuModel.includes("Radeon RX")) {
            const rxMatch = gpuModel.match(/Radeon RX (\d+)/)
            if (rxMatch) {
                return `RX ${rxMatch[1]}`
        }
    }
    
        // For AMD Radeon HD series
        if (gpuModel.includes("Radeon HD")) {
            const hdMatch = gpuModel.match(/Radeon HD (\d+)/)
            if (hdMatch) {
                return `HD ${hdMatch[1]}`
        }
    }
    
        // For Intel integrated graphics
        if (gpuModel.includes("Intel")) {
            if (gpuModel.includes("UHD Graphics")) {
                const uhdMatch = gpuModel.match(/UHD Graphics (\d+)/)
                if (uhdMatch) {
                    return `UHD ${uhdMatch[1]}`
                }
            }
            if (gpuModel.includes("HD Graphics")) {
                const hdMatch = gpuModel.match(/HD Graphics (\d+)/)
                if (hdMatch) {
                    return `HD ${hdMatch[1]}`
                }
            }
        }
        
        return gpuModel
    }
    

    
    // Main layout - split into two sections vertically
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.max(12, parent.width * 0.02) // Responsive margins
        spacing: Math.max(12, parent.height * 0.015) // Responsive spacing

        // System Dashboard Section (65% height)
        Rectangle {
            id: dashboardSection
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: parent.height ? parent.height * 0.65 : 400 // Increased back for better readability
            radius: 12
            color: Qt.rgba(0.1, 0.1, 0.15, 0.8)
            border.color: Qt.rgba(1, 1, 1, 0.1)
            border.width: 1
            
            // Dashboard title
                    StyledText {
                id: dashboardTitle
                text: "System Dashboard"
                        font.pixelSize: Math.max(Appearance.font.pixelSize.large, parent.height * 0.03) // Increased font size for better readability
                font.weight: Font.Bold
                        color: "white"
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: Math.max(12, parent.width * 0.025) // Increased margins for better spacing
            }

            // Settings and Refresh buttons
            RowLayout {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: Math.max(12, parent.width * 0.025) // Increased margins for better spacing
                spacing: Math.max(6, parent.width * 0.01) // Responsive spacing
                
                // Settings button
            Rectangle {
                    id: settingsButton
                    width: Math.max(28, parent.height * 0.04) // Responsive width
                    height: Math.max(28, parent.height * 0.04) // Responsive height
                    radius: Math.max(4, parent.height * 0.005) // Responsive radius
                    color: Qt.rgba(0.15, 0.15, 0.2, 0.8)
                    border.color: Qt.rgba(1, 1, 1, 0.1)
                border.width: 1
                    
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "settings"
                        iconSize: Math.max(14, parent.height * 0.02) // Responsive icon size
                        color: "white"
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            settingsPopup.open()
                        }
                        onEntered: parent.color = Qt.rgba(0.2, 0.2, 0.25, 0.8)
                        onExited: parent.color = Qt.rgba(0.15, 0.15, 0.2, 0.8)
                    }
                }
                
                // Refresh button
                Rectangle {
                    id: refreshButton
                    width: Math.max(28, parent.height * 0.04) // Responsive width
                    height: Math.max(28, parent.height * 0.04) // Responsive height
                    radius: Math.max(4, parent.height * 0.005) // Responsive radius
                    color: Qt.rgba(0.15, 0.15, 0.2, 0.8)
                    border.color: Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1
                    
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "refresh"
                        iconSize: Math.max(14, parent.height * 0.02) // Responsive icon size
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
                                SystemMonitor.forceUpdateCpuDetails()
                                SystemMonitor.updateSystemInfo()
                                SystemMonitor.updateGpuData()
                                SystemMonitor.forceDetectAmdGpu()
                            }
                        }
                        onEntered: parent.color = Qt.rgba(0.2, 0.2, 0.25, 0.8)
                        onExited: parent.color = Qt.rgba(0.15, 0.15, 0.2, 0.8)
                    }
                }
            }
            
            // Dashboard grid
            GridLayout {
                anchors.top: dashboardTitle.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Math.max(8, parent.width * 0.02) // Reduced margins for more compact layout
                anchors.topMargin: Math.max(12, parent.height * 0.015) // Reduced top margin for more space
                columns: 2
                rowSpacing: Math.max(6, parent.height * 0.008) // Reduced row spacing for more compact layout
                columnSpacing: Math.max(6, parent.width * 0.012) // Reduced column spacing for more compact layout
                
                // NVIDIA GPU Widget
                DashboardWidget {
                    title: (SystemMonitor && SystemMonitor.gpuAvailable && SystemMonitor.gpuModel !== "GPU") ? 
                        "NVIDIA • " + formatGpuName(SystemMonitor.gpuModel) : "NVIDIA"
                    value: SystemMonitor ? SystemMonitor.gpuUsage : 0
                    valueText: (SystemMonitor && SystemMonitor.gpuAvailable) ? 
                        Math.round(SystemMonitor.gpuUsage * 100) + "%" : "N/A"
                    subtitle: (SystemMonitor && SystemMonitor.gpuAvailable) ? 
                        Math.round(SystemMonitor.gpuTemperature) + "°C • " + 
                        Math.round(SystemMonitor.gpuClock) + " MHz • " + 
                        Math.round(SystemMonitor.gpuPower) + "W • " +
                        (SystemMonitor.gpuMemoryTotal > 0 ? (SystemMonitor.gpuMemoryUsage / 1024 / 1024 / 1024).toFixed(1) + " GB VRAM" : "") : 
                        "No NVIDIA GPU"
                    history: SystemMonitor ? SystemMonitor.gpuHistory : []
                    graphColor: "#8a5cf634"  // Purple
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: SystemMonitor && SystemMonitor.gpuAvailable
                }
                
                // AMD GPU Widget
                DashboardWidget {
                    title: (SystemMonitor && SystemMonitor.amdGpuAvailable && SystemMonitor.amdGpuModel !== "AMD GPU") ? 
                        "AMD • " + formatGpuName(SystemMonitor.amdGpuModel) : "AMD"
                    value: SystemMonitor ? SystemMonitor.amdGpuUsage : 0
                    valueText: (SystemMonitor && SystemMonitor.amdGpuAvailable) ? 
                        Math.round(SystemMonitor.amdGpuUsage * 100) + "%" : "N/A"
                    subtitle: (SystemMonitor && SystemMonitor.amdGpuAvailable) ? 
                        Math.round(SystemMonitor.amdGpuTemperature) + "°C • " + 
                        Math.round(SystemMonitor.amdGpuClock) + " MHz • " + 
                        Math.round(SystemMonitor.amdGpuPower) + "W • " +
                        (SystemMonitor.amdGpuMemoryTotal > 0 ? (SystemMonitor.amdGpuMemoryUsage / 1024 / 1024 / 1024).toFixed(1) + " GB VRAM" : "") : 
                        "No AMD GPU"
                    history: SystemMonitor ? SystemMonitor.amdGpuHistory : []
                    graphColor: "#ef4444"  // Red
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: SystemMonitor && SystemMonitor.amdGpuAvailable
                }
                
                // Memory Widget
                DashboardWidget {
                    title: "Memory"
                                        value: SystemMonitor && typeof SystemMonitor.memoryUsage === 'number' ? SystemMonitor.memoryUsage : 0
                    valueText: SystemMonitor && typeof SystemMonitor.memoryUsed === 'number' ? (SystemMonitor.memoryUsed / 1024 / 1024 / 1024).toFixed(1) + " GB" : "0.0 GB"
                    subtitle: SystemMonitor && typeof SystemMonitor.memoryTotal === 'number' && typeof SystemMonitor.memoryUsage === 'number' ? "Used of " + (SystemMonitor.memoryTotal / 1024 / 1024 / 1024).toFixed(1) + " GB • " +
                        Math.round(SystemMonitor.memoryUsage * 100) + "%" : "No memory data"
                    history: SystemMonitor ? SystemMonitor.memoryHistory : []
                    graphColor: "#3b82f6"  // Blue
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
                
                // CPU Widget
                DashboardWidget {
                    title: (SystemMonitor && SystemMonitor.cpuAvailable && SystemMonitor.cpuModel !== "CPU") ? 
                        "CPU • " + formatCpuName(SystemMonitor.cpuModel) : "CPU"
                                        value: SystemMonitor && typeof SystemMonitor.cpuUsage === 'number' ? SystemMonitor.cpuUsage : 0
                    valueText: (SystemMonitor && SystemMonitor.cpuAvailable && typeof SystemMonitor.cpuUsage === 'number') ?
                        Math.round(SystemMonitor.cpuUsage * 100) + "%" : "N/A"
                    subtitle: (SystemMonitor && SystemMonitor.cpuAvailable && typeof SystemMonitor.cpuClock === 'number' && typeof SystemMonitor.cpuTemperature === 'number' && typeof SystemMonitor.cpuCores === 'number') ?
                        SystemMonitor.cpuClock.toFixed(1) + " GHz • " +
                        Math.round(SystemMonitor.cpuTemperature) + "°C • " +
                        SystemMonitor.cpuCores + " cores" :
                        "No CPU data"
                    history: SystemMonitor ? SystemMonitor.cpuHistory : []
                    graphColor: "#10b981"  // Green
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
                

                
                // Disk Selection Popup
                Popup {
                    id: diskSelectionPopup
                    width: 300
                    height: 400
                    modal: true
                    focus: true
                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                    
                    background: Rectangle {
                        radius: 12
                        color: Qt.rgba(0.1, 0.1, 0.15, 0.95)
                        border.color: Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1
                    }
                    
                    contentItem: ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12
                        
                        StyledText {
                            text: "Select Disk Drive"
                            font.pixelSize: Appearance.font.pixelSize.medium
                            font.weight: Font.Bold
                            color: "white"
                            Layout.fillWidth: true
                        }
                        
                        StyledText {
                            text: "Available disks: " + (SystemMonitor && SystemMonitor.availableDisks ? SystemMonitor.availableDisks.length : 0)
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Qt.rgba(1, 1, 1, 0.7)
                            Layout.fillWidth: true
                        }
                        
                        ListView {
                            id: diskListView
                Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredHeight: 200
                            clip: true
                            spacing: 4
                            
                            model: SystemMonitor ? SystemMonitor.availableDisks : []
                            
                            delegate: Rectangle {
                                width: diskListView.width
                                height: 40
                                radius: 6
                                color: SystemMonitor && SystemMonitor.selectedDisk === modelData.name ? 
                                    Qt.rgba(0.2, 0.2, 0.3, 0.8) : Qt.rgba(0.15, 0.15, 0.2, 0.6)
                                border.color: SystemMonitor && SystemMonitor.selectedDisk === modelData.name ? 
                                    Qt.rgba(0.3, 0.3, 0.5, 0.8) : "transparent"
                border.width: 1
                                
                RowLayout {
                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 8
                                    
                    MaterialSymbol {
                                        text: "storage"
                                        iconSize: 16
                                        color: "#ef4444"
                                    }
                                    
                                    StyledText {
                                        text: modelData.displayName
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: "white"
                                        Layout.fillWidth: true
                                    }
                                    
                    StyledText {
                                        text: modelData.mountpoint || "Not mounted"
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Qt.rgba(1, 1, 1, 0.6)
                                    }
                                }
                                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                                        if (SystemMonitor) {
                                            SystemMonitor.selectedDisk = modelData.name
                                            SystemMonitor.updateSelectedDiskUsage()
                                        }
                                        diskSelectionPopup.close()
                                    }
                    }
                }
            }

                        // Test button
            Rectangle {
                Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            radius: 6
                            color: Qt.rgba(0.2, 0.2, 0.3, 0.8)
                            
                    StyledText {
                                anchors.centerIn: parent
                                text: "Test: Force Disk Detection"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: "white"
                    }
                            
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                                    if (SystemMonitor) {
                                        SystemMonitor.detectAvailableDisks()
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Network Widget
                DashboardWidget {
                    title: "Network"
                    value: SystemMonitor ? (SystemMonitor.networkAvailable ? Math.min(SystemMonitor.networkTotalSpeed / 1024 / 1024 / 50, 1.0) : 0) : 0  // Normalize to 0-1 range (50 MB/s max)
                    valueText: SystemMonitor && SystemMonitor.networkAvailable ? 
                        formatNetworkSpeed(SystemMonitor.networkTotalSpeed) : "N/A"
                    subtitle: SystemMonitor && SystemMonitor.networkAvailable ? 
                        "↓ " + formatNetworkSpeed(SystemMonitor.networkDownloadSpeed) + " ↑ " + formatNetworkSpeed(SystemMonitor.networkUploadSpeed) : 
                        "No network monitoring"
                    history: SystemMonitor ? SystemMonitor.networkHistory.map(speed => Math.min(speed / 1024 / 1024 / 50, 1.0)) : []  // Normalize to 0-1 range (50 MB/s max)
                    graphColor: "#f59e0b"  // Orange
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
                
                // Swap/ZRAM Widget
                DashboardWidget {
                    title: SystemMonitor && SystemMonitor.swapAvailable ? 
                        (SystemMonitor.swapType === "zram" ? "ZRAM" : "Swap") : "Swap"
                    value: SystemMonitor ? SystemMonitor.swapUsage : 0
                    valueText: SystemMonitor && SystemMonitor.swapAvailable ? 
                        (SystemMonitor.swapUsed / 1024 / 1024 / 1024).toFixed(1) + " GB" : "0.0 GB"
                    subtitle: SystemMonitor && SystemMonitor.swapAvailable ? 
                        "Used of " + (SystemMonitor.swapTotal / 1024 / 1024 / 1024).toFixed(1) + " GB • " + 
                        Math.round(SystemMonitor.swapUsage * 100) + "%" : "No swap available"
                    history: SystemMonitor ? SystemMonitor.swapHistory : []
                    graphColor: "#ec4899"  // Pink
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: SystemMonitor && SystemMonitor.swapAvailable
                }
            }
        }

        // System Info Section (35% height) - Redesigned
        Rectangle {
            id: systemInfoSection
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: parent.height && typeof parent.height === 'number' ? parent.height * 0.35 : 200 // Reduced back to balance with dashboard
            radius: Math.max(8, parent.height * 0.01) // Responsive radius
            color: Qt.rgba(0.1, 0.1, 0.15, 0.8)
                border.color: Qt.rgba(1, 1, 1, 0.1)
                border.width: 1
            
            // System Info title with status indicator
                RowLayout {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Math.max(10, parent.width * 0.02) // Reduced margins for 1080p
                anchors.topMargin: Math.max(8, parent.height * 0.012) // Reduced top margin for 1080p
                spacing: Math.max(8, parent.width * 0.015) // Responsive spacing
                
                    StyledText {
                    text: "System Information"
                    font.pixelSize: Math.max(Appearance.font.pixelSize.medium, parent.height * 0.022) // Reduced font size for 1080p
                        font.weight: Font.Bold
                        color: "white"
                }
                
                // Status indicator
                Rectangle {
                    width: Math.max(5, parent.height * 0.006) // Reduced size for 1080p
                    height: Math.max(5, parent.height * 0.006) // Reduced size for 1080p
                    radius: Math.max(3, parent.height * 0.004) // Responsive radius
                    color: SystemMonitor && SystemMonitor.cpuAvailable ? "#10b981" : "#ef4444"
                }
                
                StyledText {
                    text: SystemMonitor && SystemMonitor.cpuAvailable ? "Live" : "Offline"
                    font.pixelSize: Math.max(Appearance.font.pixelSize.small, parent.height * 0.012) // Reduced font size for 1080p
                    color: SystemMonitor && SystemMonitor.cpuAvailable ? "#10b981" : "#ef4444"
                }
                
            Item { Layout.fillWidth: true }
            }
            
            // System Information - Side-by-side layout for cleaner appearance
            RowLayout {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Math.max(12, parent.width * 0.025) // Reduced margins for 1080p
                anchors.topMargin: Math.max(28, parent.height * 0.035) // Reduced top margin for 1080p
                spacing: Math.max(12, parent.width * 0.02) // Responsive spacing between columns
                
                // System Section
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Math.max(8, parent.height * 0.01) // Responsive radius
                    color: Qt.rgba(0.12, 0.12, 0.18, 0.8)
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Math.max(10, parent.width * 0.022) // Reduced margins for 1080p
                        spacing: Math.max(8, parent.height * 0.01) // Reduced spacing for 1080p
                        
                        // Section header with icon
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Math.max(6, parent.width * 0.012) // Reduced spacing for 1080p
                            
                            MaterialSymbol {
                                text: "computer"
                                iconSize: Math.max(14, parent.height * 0.018) // Reduced icon size for 1080p
                                color: "#3b82f6"
                            }
                            
                            StyledText {
                                text: "System Information"
                                font.pixelSize: Math.max(Appearance.font.pixelSize.small, parent.height * 0.02) // Reduced font size for 1080p
                                font.weight: Font.Bold
                                color: "white"
                            }
                            
                            Item { Layout.fillWidth: true }
                        }
                        
                        // Divider line
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.1)
                        }
                        
                        // System info items in columns
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: Math.max(12, parent.height * 0.015) // Reduced spacing for 1080p
                            
                            // OS Information
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Math.max(1, parent.height * 0.002) // Tighter spacing for 1080p
                                
                                StyledText {
                                    text: "Operating System"
                                    font.pixelSize: Math.max(Appearance.font.pixelSize.medium, parent.height * 0.025) // Reduced font size for 1080p
                                    font.weight: Font.Bold
                                    color: Qt.rgba(1, 1, 1, 0.8)
                                    style: Text.Outline
                                    styleColor: "#3b82f6"
                                    Layout.fillWidth: true
                                }
                                
                                StyledText {
                                    text: SystemMonitor ? SystemMonitor.osName + " " + SystemMonitor.osVersion : "Unknown"
                                    font.pixelSize: Math.max(Appearance.font.pixelSize.medium, parent.height * 0.03) // Reduced font size for 1080p
                                    color: "white"
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                    Layout.maximumHeight: Math.max(60, parent.height * 0.15) // Reduced height limit for 1080p
                                }
                            }
                            
                            // Kernel Information
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Math.max(1, parent.height * 0.002) // Tighter spacing for 1080p
                                
                                StyledText {
                                    text: "Kernel Version"
                                    font.pixelSize: Math.max(Appearance.font.pixelSize.medium, parent.height * 0.025) // Reduced font size for 1080p
                                    font.weight: Font.Bold
                                    color: Qt.rgba(1, 1, 1, 0.8)
                                    style: Text.Outline
                                    styleColor: "#3b82f6"
                                    Layout.fillWidth: true
                                }
                                
                                StyledText {
                                    text: SystemMonitor ? SystemMonitor.kernelVersion : "Unknown"
                                    font.pixelSize: Math.max(Appearance.font.pixelSize.medium, parent.height * 0.03) // Reduced font size for 1080p
                                    color: "white"
                                    wrapMode: Text.WrapAnywhere
                                    Layout.fillWidth: true
                                    Layout.maximumHeight: Math.max(60, parent.height * 0.15) // Reduced height limit for 1080p
                                }
                            }
                            
                            // Hostname Information
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Math.max(1, parent.height * 0.002) // Tighter spacing for 1080p
                                
                                StyledText {
                                    text: "Hostname"
                                    font.pixelSize: Math.max(Appearance.font.pixelSize.medium, parent.height * 0.025) // Reduced font size for 1080p
                                    font.weight: Font.Bold
                                    color: Qt.rgba(1, 1, 1, 0.8)
                                    style: Text.Outline
                                    styleColor: "#3b82f6"
                                    Layout.fillWidth: true
                                }
                                
                                StyledText {
                                    text: SystemMonitor ? SystemMonitor.hostname : "Unknown"
                                    font.pixelSize: Math.max(Appearance.font.pixelSize.medium, parent.height * 0.03) // Reduced font size for 1080p
                                    color: "white"
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                            
                            // Spacer to push content to top
                            Item { Layout.fillHeight: true }
                        }
                    }
                }
                
                // Hardware Section
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Math.max(8, parent.height * 0.01) // Responsive radius
                    color: Qt.rgba(0.12, 0.12, 0.18, 0.8)
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Math.max(10, parent.width * 0.022) // Reduced margins for 1080p
                        spacing: Math.max(8, parent.height * 0.01) // Reduced spacing for 1080p
                        
                        // Section header with icon
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Math.max(6, parent.width * 0.012) // Reduced spacing for 1080p
                            
                            MaterialSymbol {
                                text: "memory"
                                iconSize: Math.max(14, parent.height * 0.018) // Reduced icon size for 1080p
                                color: "#10b981"
                            }
                            
                            StyledText {
                                text: "Hardware Specifications"
                                font.pixelSize: Math.max(Appearance.font.pixelSize.small, parent.height * 0.02) // Reduced font size for 1080p
                                font.weight: Font.Bold
                                color: "white"
                            }
                            
                            Item { Layout.fillWidth: true }
                        }
                        
                        // Divider line
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.1)
                        }
                        
                        // Hardware info items in columns
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: Math.max(12, parent.height * 0.015) // Reduced spacing for 1080p
                            
                            // CPU Information
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Math.max(1, parent.height * 0.002) // Tighter spacing for 1080p
                                
                                StyledText {
                                    text: "Processor"
                                    font.pixelSize: Math.max(Appearance.font.pixelSize.medium, parent.height * 0.025) // Reduced font size for 1080p
                                    font.weight: Font.Bold
                                    color: Qt.rgba(1, 1, 1, 0.8)
                                    style: Text.Outline
                                    styleColor: "#3b82f6"
                                    Layout.fillWidth: true
                                }
                                
                                StyledText {
                                    text: SystemMonitor ? formatCpuName(SystemMonitor.cpuModel) : "Unknown"
                                    font.pixelSize: Math.max(Appearance.font.pixelSize.medium, parent.height * 0.03) // Reduced font size for 1080p
                                    color: "white"
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                    Layout.maximumHeight: Math.max(60, parent.height * 0.15) // Reduced height limit for 1080p
                                }
                            }
                            
                            // CPU Cores Information
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Math.max(1, parent.height * 0.002) // Tighter spacing for 1080p
                                
                                StyledText {
                                    text: "CPU Cores"
                                    font.pixelSize: Math.max(Appearance.font.pixelSize.medium, parent.height * 0.025) // Reduced font size for 1080p
                                    font.weight: Font.Bold
                                    color: Qt.rgba(1, 1, 1, 0.8)
                                    style: Text.Outline
                                    styleColor: "#3b82f6"
                                    Layout.fillWidth: true
                                }
                                
                                StyledText {
                                    text: SystemMonitor && SystemMonitor.cpuCores && SystemMonitor.cpuThreads ? 
                                        SystemMonitor.cpuCores + " cores, " + SystemMonitor.cpuThreads + " threads" : "Unknown"
                                    font.pixelSize: Math.max(Appearance.font.pixelSize.medium, parent.height * 0.03) // Reduced font size for 1080p
                                    color: "white"
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                            
                            // Total Memory Information
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Math.max(1, parent.height * 0.002) // Tighter spacing for 1080p
                                
                                StyledText {
                                    text: "Total Memory"
                                    font.pixelSize: Math.max(Appearance.font.pixelSize.medium, parent.height * 0.025) // Reduced font size for 1080p
                                    font.weight: Font.Bold
                                    color: Qt.rgba(1, 1, 1, 0.8)
                                    style: Text.Outline
                                    styleColor: "#3b82f6"
                                    Layout.fillWidth: true
                                }
                                
                                StyledText {
                                    text: SystemMonitor && SystemMonitor.memoryTotal && SystemMonitor.memoryTotal > 0 ? 
                                        (SystemMonitor.memoryTotal / 1024 / 1024 / 1024).toFixed(1) + " GB" : "Unknown"
                                    font.pixelSize: Math.max(Appearance.font.pixelSize.medium, parent.height * 0.03) // Reduced font size for 1080p
                                    color: "white"
                                    Layout.fillWidth: true
                                }
                            }
                            
                            // Available Memory Information
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Math.max(1, parent.height * 0.002) // Tighter spacing for 1080p
                                
                                StyledText {
                                    text: "Available Memory"
                                    font.pixelSize: Math.max(Appearance.font.pixelSize.medium, parent.height * 0.025) // Reduced font size for 1080p
                                    font.weight: Font.Bold
                                    color: Qt.rgba(1, 1, 1, 0.8)
                                    style: Text.Outline
                                    styleColor: "#3b82f6"
                                    Layout.fillWidth: true
                                }
                                
                                StyledText {
                                    text: SystemMonitor && SystemMonitor.memoryAvailable > 0 ? 
                                        (SystemMonitor.memoryAvailable / 1024 / 1024 / 1024).toFixed(1) + " GB free" : "Unknown"
                                    font.pixelSize: Math.max(Appearance.font.pixelSize.medium, parent.height * 0.03) // Reduced font size for 1080p
                                    color: "white"
                                    Layout.fillWidth: true
                                }
                            }
                            
                            // Spacer to push content to top
                            Item { Layout.fillHeight: true }
                        }
                    }
                }
            }
        }
    }
    
    // Settings Popup
    Popup {
        id: settingsPopup
        width: 300
        height: 200
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        background: Rectangle {
            radius: 12
            color: Qt.rgba(0.1, 0.1, 0.15, 0.95)
            border.color: Qt.rgba(1, 1, 1, 0.1)
            border.width: 1
        }
        
        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16
            
            // Title
            StyledText {
                text: "Dashboard Settings"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Bold
                color: "white"
                Layout.alignment: Qt.AlignHCenter
            }
            
            // Disk Selection
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                
                StyledText {
                    text: "Monitor Disk:"
                    font.pixelSize: Appearance.font.pixelSize.medium
                    color: "white"
                }
                
                ComboBox {
                    id: diskSelector
                    Layout.fillWidth: true
                    model: ListModel {
                        id: diskModel
                    }
                    
                    textRole: "display"
                    valueRole: "mountPoint"
                    
                    background: Rectangle {
                        radius: 6
                        color: Qt.rgba(0.15, 0.15, 0.2, 0.8)
                        border.color: Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1
                    }
                    
                    contentItem: StyledText {
                        text: diskSelector.displayText
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: "white"
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 8
                    }
                    
                    onActivated: {
                        if (currentValue) {
                            // Update the disk monitoring target
                            SystemMonitor.setDiskTarget(currentValue)
                }
            }
                }
            }
            
            // Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Item { Layout.fillWidth: true }
                
                Button {
                    text: "Cancel"
                    onClicked: settingsPopup.close()
                    
                    background: Rectangle {
                        radius: 6
                        color: Qt.rgba(0.15, 0.15, 0.2, 0.8)
                        border.color: Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1
                    }
                    
                    contentItem: StyledText {
                        text: parent.text
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onPressed: parent.color = Qt.rgba(0.2, 0.2, 0.25, 0.8)
                    onReleased: parent.color = Qt.rgba(0.15, 0.15, 0.2, 0.8)
                }
                
                Button {
                    text: "Apply"
                    onClicked: {
                        settingsPopup.close()
                    }
                    
                    background: Rectangle {
                        radius: 6
                        color: Qt.rgba(0.15, 0.15, 0.2, 0.8)
                        border.color: Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1
                    }
                    
                    contentItem: StyledText {
                        text: parent.text
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                }
                    
                    onPressed: parent.color = Qt.rgba(0.2, 0.2, 0.25, 0.8)
                    onReleased: parent.color = Qt.rgba(0.15, 0.15, 0.2, 0.8)
                }
            }
        }
        
        onOpened: {
            // Populate disk list when popup opens
            populateDiskList()
        }
    }
    
    // Function to populate disk list
    function populateDiskList() {
        if (diskModel && typeof diskModel.clear === 'function' && typeof diskModel.append === 'function') {
            diskModel.clear()
            
            // Add common mount points
            diskModel.append({display: "Root Filesystem (/)", mountPoint: "/"})
            diskModel.append({display: "Home Directory (/home)", mountPoint: "/home"})
            diskModel.append({display: "User Data (/home/matt)", mountPoint: "/home/matt"})
        }
        
        // Try to get additional mount points from /proc/mounts
        try {
            const process = Qt.createQmlObject('import QtQuick; Process { command: ["cat", "/proc/mounts"] }', root)
            process.onExited = function(exitCode, exitStatus) {
                if (exitCode === 0) {
                    const output = process.readAllStandardOutput()
                    const lines = output.split('\n')
                    
                    for (const line of lines) {
                        const parts = line.split(/\s+/)
                        if (parts.length >= 2) {
                            const device = parts[0]
                            const mountPoint = parts[1]
                            
                            // Skip system filesystems and duplicates
                            if (mountPoint.startsWith('/') && 
                                !mountPoint.includes('/proc') && 
                                !mountPoint.includes('/sys') && 
                                !mountPoint.includes('/dev') &&
                                mountPoint !== '/' &&
                                mountPoint !== '/home') {
                                
                                if (diskModel && typeof diskModel.append === 'function') {
                                    diskModel.append({
                                        display: `${mountPoint} (${device})`, 
                                        mountPoint: mountPoint
                                    })
                                }
                            }
                        }
                    }
                }
            }
            process.start()
        } catch (e) {
            // Failed to get mount points
        }
    }
}