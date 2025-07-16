import QtQuick
import QtQuick.Layouts
import "root:/modules/common"

/**
 * System Information Widget
 * Displays detailed system information in a clean, professional format.
 */
Rectangle {
    id: root
    
    // Properties
    property string title: "System Info"
    property bool showTitle: true
    
    // Layout
    implicitWidth: 280
    implicitHeight: 300
    radius: 12
    color: Qt.rgba(0.1, 0.1, 0.15, 0.8)
    border.color: Qt.rgba(1, 1, 1, 0.1)
    border.width: 1
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        
        // Title
        StyledText {
            text: root.title
            font.pixelSize: Appearance.font.pixelSize.large
            font.weight: Font.Bold
            color: "white"
            Layout.fillWidth: true
            visible: root.showTitle
        }
        
        // System Information
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            
            // OS Information
            InfoRow {
                label: "OS"
                value: SystemInfo.osName + " " + SystemInfo.osVersion
                icon: "computer"
            }
            
            // Kernel
            InfoRow {
                label: "Kernel"
                value: SystemInfo.kernelVersion + " (" + SystemInfo.architecture + ")"
                icon: "settings"
            }
            
            // Hostname
            InfoRow {
                label: "Hostname"
                value: SystemInfo.hostname
                icon: "dns"
            }
            
            // Uptime
            InfoRow {
                label: "Uptime"
                value: SystemInfo.uptime
                icon: "schedule"
            }
            
            // Boot Time
            InfoRow {
                label: "Boot Time"
                value: SystemInfo.bootTime
                icon: "power"
            }
            
            // CPU
            InfoRow {
                label: "CPU"
                value: SystemInfo.cpuModel
                icon: "memory"
            }
            
            // CPU Cores
            InfoRow {
                label: "Cores"
                value: SystemInfo.cpuCores + " cores, " + SystemInfo.cpuThreads + " threads"
                icon: "developer_board"
            }
            
            // Memory
            InfoRow {
                label: "Memory"
                value: SystemInfo.totalMemory + " total, " + SystemInfo.availableMemory + " available"
                icon: "storage"
            }
            
            // Disk Usage
            InfoRow {
                label: "Disk Usage"
                value: SystemInfo.diskUsage + " used"
                icon: "hard_drive"
            }
            
            // Network
            InfoRow {
                label: "Network"
                value: SystemInfo.networkInterface + " (" + SystemInfo.ipAddress + ")"
                icon: "wifi"
            }
        }
    }
} 