import "../sidebarRight/quickToggles"
import "root:/modules/common/widgets"
import "root:/modules/common"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    radius: Appearance.rounding.normal
    color: "transparent"
    border.color: Qt.rgba(1, 1, 1, 0.12)
    border.width: 5
    
    // GPU Properties
    property int gpuUtil: 0
    property int gpuTemp: 0
    property int gpuMemUsed: 0
    property int gpuMemTotal: 1
    property real gpuMemPercent: gpuMemTotal > 0 ? gpuMemUsed / gpuMemTotal : 0
    property int gpuCoreClock: 0
    property int gpuMemClock: 0
    property string gpuModel: "NVIDIA GPU"
    property bool gpuAvailable: false
    
    // CPU Properties
    property string cpuModel: "CPU"
    property real cpuClock: 0
    property real cpuTemp: 0
    property real cpuUsage: 0
    property string cpuTempSource: ""
    property int cpuMaxTemp: 90
    property int gpuMaxTemp: 85
    property bool cpuAvailable: false
    
    // History Arrays
    property var cpuHistory: []
    property var gpuHistory: []
    property var memoryHistory: []
    property int historyLength: 60
    
    // Power Profile Properties
    property string currentPowerProfile: "balanced"
    property bool powerProfilesAvailable: false

    // --- CPU Model ---
    Process {
        id: cpuInfoProc
        command: ["bash", "-c", "cat /proc/cpuinfo | grep 'model name' | head -1"]
        onExited: {
            if (cpuInfoProc.stdout) {
                var modelLine = cpuInfoProc.stdout.trim()
                var modelParts = modelLine.split(/:\s+/)
                if (modelParts.length > 1) {
                    root.cpuModel = modelParts[1].trim()
                    root.cpuAvailable = true
                } else {
                    root.cpuModel = modelLine
                    root.cpuAvailable = true
                }
            }
        }
    }
    
    // --- CPU Clock ---
    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: cpuClockProc.running = true
    }
    Process {
        id: cpuClockProc
        command: ["bash", "-c", "cat /proc/cpuinfo | grep 'cpu MHz' | head -1"]
        onExited: {
            if (cpuClockProc.stdout) {
                var clockMatch = cpuClockProc.stdout.match(/cpu MHz\s+:\s+([0-9.]+)/)
                if (clockMatch) {
                    root.cpuClock = parseFloat(clockMatch[1])
                }
            }
        }
    }
    
    // --- CPU Temp (try sensors, fallback to /sys/class/thermal) ---
    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: cpuTempProc.running = true
    }
    Process {
        id: cpuTempProc
        command: ["bash", "-c", "sensors || cat /sys/class/thermal/thermal_zone0/temp"]
        onExited: {
            var found = false
            if (cpuTempProc.stdout) {
                var lines = cpuTempProc.stdout.split("\n")
                for (var i = 0; i < lines.length; ++i) {
                    var l = lines[i].trim()
                    // Accept common CPU temp labels
                    if (l.match(/^CPU:/) || l.match(/^Tctl:/) || l.match(/^Package id 0:/) || l.match(/^Core [0-9]+:/)) {
                        var tempMatch = l.match(/([+\-]?[0-9]+\.[0-9]+)°C/)
                        if (tempMatch) {
                            root.cpuTemp = parseFloat(tempMatch[1])
                            root.cpuTempSource = "sensors"
                            found = true
                            break
                        }
                    }
                }
                if (!found) {
                    // fallback: try thermal_zone0
                    for (var i = 0; i < lines.length; ++i) {
                        if (/^[0-9]+$/.test(lines[i].trim())) {
                            root.cpuTemp = parseInt(lines[i].trim()) / 1000.0
                            root.cpuTempSource = "thermal_zone0"
                            found = true
                            break
                        }
                    }
                }
            }
            if (!found) {
                root.cpuTemp = 0
                root.cpuTempSource = "unavailable"
            }
        }
    }
    
    // --- CPU Usage (parse /proc/stat) ---
    property var lastCpuStat: null
    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: cpuStatProc.running = true
    }
    Process {
        id: cpuStatProc
        command: ["bash", "-c", "cat /proc/stat | head -1"]
        onExited: {
            if (cpuStatProc.stdout) {
                var parts = cpuStatProc.stdout.trim().split(/\s+/)
                if (parts[0] === "cpu") {
                    var total = 0
                    for (var i = 1; i < parts.length; ++i) total += parseInt(parts[i])
                    var idle = parseInt(parts[4])
                    if (root.lastCpuStat) {
                        var diffTotal = total - root.lastCpuStat.total
                        var diffIdle = idle - root.lastCpuStat.idle
                        if (diffTotal > 0) {
                            root.cpuUsage = 1 - (diffIdle / diffTotal)
                        }
                    }
                    root.lastCpuStat = { total: total, idle: idle }
                }
            }
        }
    }
    
    // --- GPU (Nvidia) ---
    Process {
        id: gpuQuery
        command: ["nvidia-smi", "--query-gpu=name,utilization.gpu,temperature.gpu,memory.used,memory.total,clocks.gr,clocks.mem", "--format=csv,noheader,nounits"]
        onExited: {
            if (gpuQuery.stdout) {
                var parts = gpuQuery.stdout.trim().split(/,\s*/)
                if (parts.length >= 7) {
                    root.gpuModel = parts[0]
                    root.gpuUtil = parseInt(parts[1])
                    root.gpuTemp = parseInt(parts[2])
                    root.gpuMemUsed = parseInt(parts[3])
                    root.gpuMemTotal = parseInt(parts[4])
                    root.gpuCoreClock = parseInt(parts[5])
                    root.gpuMemClock = parseInt(parts[6])
                    root.gpuAvailable = true
                }
            }
        }
    }
    
    // --- GPU (AMD/Intel Fallback) ---
    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: gpuFallbackQuery.running = true
    }
    Process {
        id: gpuFallbackQuery
        command: ["bash", "-c", "sensors || cat /sys/class/drm/card0/device/hwmon/hwmon*/temp1_input"]
        onExited: {
            var found = false
            if (gpuFallbackQuery.stdout) {
                var lines = gpuFallbackQuery.stdout.split("\n")
                for (var i = 0; i < lines.length; ++i) {
                    var l = lines[i].trim()
                    // Try to match common GPU temp labels
                    if (l.match(/^edge:/) || l.match(/^temp1:/) || l.match(/^GPU:/)) {
                        var tempMatch = l.match(/([+\-]?[0-9]+\.[0-9]+)°C/)
                        if (tempMatch) {
                            root.gpuTemp = parseFloat(tempMatch[1])
                            root.gpuAvailable = true
                            found = true
                            break
                        }
                    }
                    // Try sysfs fallback (raw value)
                    if (/^[0-9]+$/.test(l)) {
                        root.gpuTemp = parseInt(l) / 1000.0
                        root.gpuAvailable = true
                        found = true
                        break
                    }
                }
            }
            if (!found) {
                root.gpuAvailable = false
            }
        }
    }
    
    // --- Power Profile Detection ---
    Process {
        id: powerProfileProc
        command: ["bash", "-c", "powerprofilesctl get 2>/dev/null || echo 'balanced'"]
        onExited: {
            if (powerProfileProc.stdout) {
                root.currentPowerProfile = powerProfileProc.stdout.trim()
                root.powerProfilesAvailable = true
            }
        }
    }
    
    // --- Refresh Button ---
    Component.onCompleted: {
        cpuInfoProc.running = true
        cpuClockProc.running = true
        cpuTempProc.running = true
        gpuQuery.running = true
        cpuStatProc.running = true
        powerProfileProc.running = true
    }

    // Usage history update
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            cpuHistory = cpuHistory.concat([ResourceUsage.cpuUsage]).slice(-historyLength)
            gpuHistory = gpuHistory.concat([gpuUtil / 100]).slice(-historyLength)
            memoryHistory = memoryHistory.concat([ResourceUsage.memoryUsedPercentage]).slice(-historyLength)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // Power Profile Toggles (Caelestia style)
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: powerProfilesAvailable ? 180 : 0
            spacing: 4
            visible: powerProfilesAvailable
            
            // Header
            Rectangle {
                Layout.fillWidth: true
                height: 48
                color: Qt.rgba(Appearance.colors.colLayer2.r, Appearance.colors.colLayer2.g, Appearance.colors.colLayer2.b, 0.55)
                border.color: Appearance.colors.colOnLayer0
                border.width: 1
                radius: Appearance.rounding.medium
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 0
                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Power Profile")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.bold: true
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // Performance Mode
            Rectangle {
                Layout.fillWidth: true
                height: 54
                color: currentPowerProfile === "performance" ? Appearance.m3colors.m3primary : Appearance.colors.colLayer1
                border.color: Appearance.colors.colOnLayer0
                border.width: 1
                radius: Appearance.rounding.medium
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    spacing: 12
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    Item { Layout.fillWidth: true }
                    MaterialSymbol {
                        iconSize: 28
                        fill: currentPowerProfile === "performance" ? 1 : 0
                        text: "speed"
                        color: currentPowerProfile === "performance" ? "#FFFFFF" : "#FFFFFF"
                    }
                    StyledText {
                        text: qsTr("Performance")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.bold: true
                        color: currentPowerProfile === "performance" ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer0
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    Item { Layout.fillWidth: true }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        setPowerProfile.running = true
                        setPowerProfile.command = ["powerprofilesctl", "set", "performance"]
                    }
                }
            }

            // Balanced Mode
            Rectangle {
                Layout.fillWidth: true
                height: 54
                color: currentPowerProfile === "balanced" ? Appearance.m3colors.m3primary : Appearance.colors.colLayer1
                border.color: Appearance.colors.colOnLayer0
                border.width: 1
                radius: Appearance.rounding.medium
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    spacing: 12
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    Item { Layout.fillWidth: true }
                    MaterialSymbol {
                        iconSize: 28
                        fill: currentPowerProfile === "balanced" ? 1 : 0
                        text: "balance"
                        color: currentPowerProfile === "balanced" ? "#FFFFFF" : "#FFFFFF"
                    }
                    StyledText {
                        text: qsTr("Balanced")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.bold: true
                        color: currentPowerProfile === "balanced" ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer0
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    Item { Layout.fillWidth: true }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        setPowerProfile.running = true
                        setPowerProfile.command = ["powerprofilesctl", "set", "balanced"]
                    }
                }
            }

            // Power Saver Mode
            Rectangle {
                Layout.fillWidth: true
                height: 54
                color: currentPowerProfile === "power-saver" ? Appearance.m3colors.m3primary : Appearance.colors.colLayer1
                border.color: Appearance.colors.colOnLayer0
                border.width: 1
                radius: Appearance.rounding.medium
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    spacing: 12
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    Item { Layout.fillWidth: true }
                    MaterialSymbol {
                        iconSize: 28
                        fill: currentPowerProfile === "power-saver" ? 1 : 0
                        text: "battery_saver"
                        color: currentPowerProfile === "power-saver" ? "#FFFFFF" : "#FFFFFF"
                    }
                    StyledText {
                        text: qsTr("Power Saver")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.bold: true
                        color: currentPowerProfile === "power-saver" ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer0
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    Item { Layout.fillWidth: true }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        setPowerProfile.running = true
                        setPowerProfile.command = ["powerprofilesctl", "set", "power-saver"]
                    }
                }
            }
        }

        // System Stats Header
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            Rectangle {
                radius: Appearance.rounding.full
                color: Qt.rgba(Appearance.colors.colLayer1.r, Appearance.colors.colLayer1.g, Appearance.colors.colLayer1.b, 0.3)
                border.color: Qt.rgba(1, 1, 1, 0.1)
                border.width: 1
                height: 64
                width: 180
                anchors.horizontalCenter: parent.horizontalCenter
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter // Ensure vertical centering
                    MaterialSymbol {
                        text: "info"
                        iconSize: 24
                        color: Appearance.colors.colAccent
                        verticalAlignment: Text.AlignVCenter
                    }
                    StyledText {
                        text: qsTr("System Status")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Bold
                        color: "white"
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                radius: Appearance.rounding.full
                color: Qt.rgba(Appearance.colors.colLayer1.r, Appearance.colors.colLayer1.g, Appearance.colors.colLayer1.b, 0.3)
                border.color: Qt.rgba(1, 1, 1, 0.1)
                border.width: 1
                height: 40
                width: 40
                QuickToggleButton {
                    anchors.centerIn: parent
                    buttonIcon: "refresh"
                    implicitWidth: 32
                    implicitHeight: 32
                    onClicked: {
                        cpuInfoProc.running = true;
                        cpuClockProc.running = true;
                        cpuTempProc.running = true;
                        gpuQuery.running = true;
                        cpuStatProc.running = true;
                        powerProfileProc.running = true;
                    }
                    StyledToolTip { content: qsTr("Refresh stats") }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: parent.color = Qt.rgba(Appearance.colors.colLayer1.r, Appearance.colors.colLayer1.g, Appearance.colors.colLayer1.b, 0.45)
                    onExited: parent.color = Qt.rgba(Appearance.colors.colLayer1.r, Appearance.colors.colLayer1.g, Appearance.colors.colLayer1.b, 0.3)
                }
            }
        }

        // Stacked StatCircles with History and Info Pills
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            // Add a spacer to move widgets down
            Item { Layout.preferredHeight: parent.height * 0.08 }
            
            // GPU Stats
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 0
                StatCircle {
                    label: qsTr("GPU")
                    value: gpuAvailable ? (gpuTemp / 100) : 0
                    valueText: gpuAvailable && gpuTemp > 0 ? gpuTemp + "°C" : "—"
                    subLabel: gpuAvailable && gpuUtil > 0 ? gpuUtil + "% Usage" : "—"
                    primaryColor: Qt.rgba(1, 1, 1, 0.35)
                    secondaryColor: Qt.rgba(1, 1, 1, 0.12)
                    size: Math.min(root.width, root.height / 6)
                    history: gpuHistory
                    historyLength: historyLength
                    Layout.alignment: Qt.AlignHCenter
                }
                InfoPill {
                    text: gpuAvailable ? 
                        gpuModel + " • " + gpuCoreClock + "MHz / " + gpuMemClock + "MHz • " + 
                        (gpuMemUsed / 1024).toFixed(1) + "/" + (gpuMemTotal / 1024).toFixed(1) + " GiB" : 
                        "GPU Unavailable"
                }
            }
            // CPU Stats
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 0
                StatCircle {
                    label: qsTr("CPU")
                    value: cpuAvailable ? (cpuTemp / 100) : 0
                    valueText: cpuAvailable && cpuTemp > 0 ? cpuTemp.toFixed(0) + "°C" : "—"
                    subLabel: cpuAvailable && cpuUsage > 0 ? Math.round(cpuUsage * 100) + "% Usage" : "—"
                    primaryColor: Qt.rgba(1, 1, 1, 0.35)
                    secondaryColor: Qt.rgba(1, 1, 1, 0.12)
                    size: Math.min(root.width, root.height / 6)
                    history: cpuHistory
                    historyLength: historyLength
                    Layout.alignment: Qt.AlignHCenter
                }
                InfoPill {
                    text: cpuAvailable ? 
                        cpuModel + " • " + (cpuClock / 1000).toFixed(1) + " GHz" : 
                        "CPU Unavailable"
                }
            }
            // Memory Stats
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 0
                StatCircle {
                    label: qsTr("Memory")
                    value: ResourceUsage.memoryUsedPercentage
                    valueText: (ResourceUsage.memoryUsed / 1024).toFixed(1) + " GiB"
                    subLabel: ResourceUsage.memoryTotal ? Math.round(ResourceUsage.memoryTotal / 1024) + " GiB Total" : "—"
                    primaryColor: Qt.rgba(1, 1, 1, 0.35)
                    secondaryColor: Qt.rgba(1, 1, 1, 0.12)
                    size: Math.min(root.width, root.height / 6)
                    history: memoryHistory
                    historyLength: historyLength
                    Layout.alignment: Qt.AlignHCenter
                }
                InfoPill {
                    text: ResourceUsage.memoryTotal ? 
                        "Used: " + (ResourceUsage.memoryUsed / 1024).toFixed(1) + " GiB / " + 
                        (ResourceUsage.memoryTotal / 1024).toFixed(1) + " GiB (" + 
                        Math.round(ResourceUsage.memoryUsedPercentage * 100) + "%)" : 
                        "Memory Unavailable"
                }
            }
        }
    }
    
    // Power Profile Setter Process
    Process {
        id: setPowerProfile
        onExited: {
            if (exitCode === 0) {
                powerProfileProc.running = true
            }
        }
    }
} 