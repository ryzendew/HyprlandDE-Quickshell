pragma Singleton

import "root:/modules/common"
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.UPower

Singleton {
    // Basic battery detection
    property bool available: UPower.displayDevice.isLaptopBattery || hasBatteryDevices
    // Fix remaining array operation errors with better null checks
    property bool hasBatteryDevices: UPower.devices && UPower.devices.length > 0 ? UPower.devices.some(device => device && device.isLaptopBattery) : false
    
    // Primary battery (display device)
    property var primaryBattery: UPower.displayDevice
    property var chargeState: primaryBattery.state
    property bool isCharging: chargeState == UPowerDeviceState.Charging
    property bool isPluggedIn: isCharging || chargeState == UPowerDeviceState.PendingCharge || chargeState == UPowerDeviceState.FullyCharged
    property real percentage: primaryBattery.percentage
    property bool isFullyCharged: chargeState == UPowerDeviceState.FullyCharged

    // Battery status properties
    property bool isLow: percentage <= ConfigOptions.battery.low / 100
    property bool isCritical: percentage <= ConfigOptions.battery.critical / 100
    property bool isSuspending: percentage <= ConfigOptions.battery.suspend / 100
    property bool isLowAndNotCharging: isLow && !isCharging
    property bool isCriticalAndNotCharging: isCritical && !isCharging

    // Time estimates
    property string timeToEmpty: primaryBattery.timeToEmpty > 0 ? formatTime(primaryBattery.timeToEmpty) : ""
    property string timeToFull: primaryBattery.timeToFull > 0 ? formatTime(primaryBattery.timeToFull) : ""
    
    // Multiple battery support
    property var allBatteries: UPower.devices && UPower.devices.length > 0 ? UPower.devices.filter(device => device && device.isLaptopBattery) : []
    property int batteryCount: allBatteries ? allBatteries.length : 0
    property real averagePercentage: batteryCount > 0 ? 
        allBatteries.reduce((sum, battery) => sum + battery.percentage, 0) / batteryCount : 0
    
    // Battery health and capacity
    property real designCapacity: primaryBattery.energyFullDesign || 0
    property real currentCapacity: primaryBattery.energyFull || 0
    property real batteryHealth: designCapacity > 0 ? (currentCapacity / designCapacity) * 100 : 100
    
    // Temperature and voltage
    property real temperature: primaryBattery.temperature || 0
    property real voltage: primaryBattery.voltage || 0
    
    // Status text for tooltips
    property string statusText: {
        if (!available) return "No battery detected"
        if (isFullyCharged) return "Fully charged"
        if (isCharging) return "Charging - " + timeToFull + " remaining"
        if (isCritical) return "Critical battery - " + timeToEmpty + " remaining"
        if (isLow) return "Low battery - " + timeToEmpty + " remaining"
        return "Battery - " + timeToEmpty + " remaining"
    }
    
    // Enhanced icon selection
    property string batteryIcon: {
        if (!available) return ""
        if (isFullyCharged) return "battery_full"
        if (isCharging) return "battery_charging_full"
        if (percentage > 80) return "battery_full"
        if (percentage > 60) return "battery_6_bar"
        if (percentage > 40) return "battery_4_bar"
        if (percentage > 20) return "battery_2_bar"
        return "battery_alert"
    }
    
    // Color based on status
    property var batteryColor: {
        if (!available) return "transparent"
        if (isCritical) return "#ff6b6b"
        if (isLow) return "#ffd93d"
        if (isCharging) return "#4CAF50"
        return "inherit"
    }
    
    // Helper function to format time
    function formatTime(seconds) {
        if (seconds <= 0) return ""
        const hours = Math.floor(seconds / 3600)
        const minutes = Math.floor((seconds % 3600) / 60)
        if (hours > 0) {
            return `${hours}h ${minutes}m`
        } else {
            return `${minutes}m`
        }
    }
    
    // Enhanced notifications
    onIsLowAndNotChargingChanged: {
        if (available && isLowAndNotCharging) {
            Hyprland.dispatch(`exec notify-send "Low battery" "Consider plugging in your device (${Math.round(percentage * 100)}%)" -u critical -a "Shell"`)
        }
    }

    onIsCriticalAndNotChargingChanged: {
        if (available && isCriticalAndNotCharging) {
            Hyprland.dispatch(`exec notify-send "Critically low battery" "🙏 Please charge immediately (${Math.round(percentage * 100)}%)\nAutomatic suspend triggers at ${ConfigOptions.battery.suspend}%" -u critical -a "Shell"`)
        }
    }
    
    // Automatic suspend functionality
    onIsSuspendingChanged: {
        if (available && isSuspending && !isCharging && ConfigOptions.battery.automaticSuspend) {
            // console.log(`[BATTERY] Automatic suspend triggered at ${Math.round(percentage * 100)}%`)
            Hyprland.dispatch(`exec notify-send "Automatic suspend" "Battery at ${Math.round(percentage * 100)}% - suspending system" -u critical -a "Shell"`)
            // Trigger system suspend
            Hyprland.dispatch(`exec systemctl suspend`)
        }
    }
    
    // Monitor battery health
    onBatteryHealthChanged: {
        if (batteryHealth < 80 && available) {
            // console.log(`[BATTERY] Health warning: ${batteryHealth.toFixed(1)}%`)
        }
    }
}
