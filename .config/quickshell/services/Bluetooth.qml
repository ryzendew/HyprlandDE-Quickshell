pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell;
import Quickshell.Io;
import QtQuick;

/**
 * Enhanced Bluetooth service with device management
 */
Singleton {
    id: root

    property int updateInterval: 2000
    property bool bluetoothEnabled: false
    property bool bluetoothConnected: false
    property bool scanning: false
    property string bluetoothDeviceName: ""
    property string bluetoothDeviceAddress: ""
    property bool discoverable: false

    
    Process {
        id: discoverableProcess
        property bool _pendingDiscoverable: false
        
        onRunningChanged: {
            if (!running) {
                if (discoverableProcess.exitCode === 0) {
                    root.discoverable = discoverableProcess._pendingDiscoverable;
                    // console.log('[BT SERVICE] Discoverable set to', root.discoverable);
                } else {
                    // console.log('[BT SERVICE] Failed to set discoverable:', discoverableProcess.stderr);
                }
            }
        }
    }
    
    // Device lists
    property var connectedDevices: []
    property var availableDevices: []
    property var pairedDevices: []

    // Helper function to check if a device is real
    function isRealDevice(address, name) {
        // Only allow MAC addresses for real devices
        const macPattern = /^([A-Fa-f0-9]{2}:){5}[A-Fa-f0-9]{2}$/;
        
        // console.log(`[BT SERVICE] isRealDevice check: address='${address}', name='${name}'`)
        // console.log(`[BT SERVICE] MAC pattern match:`, macPattern.test(address))
        
        if (!macPattern.test(address)) {
            // console.log(`[BT SERVICE] Device filtered out: invalid address format (not MAC)`)
            return false;
        }
        if (!name || name.trim() === '') {
            // console.log(`[BT SERVICE] Device filtered out: no name`)
            return false;
        }
        
        // Filter out the adapter itself (Media device)
        if (name === "Media") {
            // console.log(`[BT SERVICE] Device filtered out: adapter device`)
            return false;
        }
        
        // Filter out devices where name is just the address repeated (with various separators)
        const addressWithDashes = address.replace(/:/g, '-');
        const addressWithUnderscores = address.replace(/:/g, '_');
        const addressNoSeparators = address.replace(/:/g, '');
        if (name === addressWithDashes || name === addressWithUnderscores || name === addressNoSeparators) {
            // console.log(`[BT SERVICE] Device filtered out: name is just address repeated`)
            return false;
        }
        
        // Filter out very short names that are likely not real device names
        if (name.length < 2) {
            // console.log(`[BT SERVICE] Device filtered out: name too short`)
            return false;
        }
        
        // console.log(`[BT SERVICE] Device accepted: ${name}`)
        return true;
    }

    // Helper function to parse device info
    function parseDeviceInfo(data) {
        let devices = []
        let lines = data.split('\n')
        let currentDevice = null
        
        // console.log("[BT SERVICE] Parsing data:", data)
        // console.log("[BT SERVICE] Number of lines:", lines.length)
        
        for (let line of lines) {
            line = line.trim()
            if (!line) continue
            
            // console.log("[BT SERVICE] Processing line:", line)
            
            // New device line - handle both formats
            let deviceMatch = line.match(/Device\s+(([A-F0-9]{2}:){5}[A-F0-9]{2})\s+(.+)/)
            if (deviceMatch) {
                // console.log("[BT SERVICE] Device match found:", deviceMatch)
                if (currentDevice && isRealDevice(currentDevice.address, currentDevice.name)) {
                    devices.push(currentDevice)
                }
                currentDevice = {
                    address: deviceMatch[1],
                    name: deviceMatch[3].trim(),
                    type: "Unknown",
                    connected: false,
                    paired: false,
                    battery: null
                }
            }
            

            
            // Handle [NEW] format from bluetoothctl - only for real devices, not adapters
            let newDeviceMatch = line.match(/\[NEW\]\s+Device\s+([A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2})\s+(.+)/)
            if (newDeviceMatch) {
                // console.log("[BT SERVICE] [NEW] Device match found:", newDeviceMatch)
                if (currentDevice && isRealDevice(currentDevice.address, currentDevice.name)) {
                    devices.push(currentDevice)
                }
                currentDevice = {
                    address: newDeviceMatch[1],
                    name: newDeviceMatch[2].trim(),
                    type: "Unknown",
                    connected: false,
                    paired: false,
                    battery: null
                }
            }
            
            // More permissive pattern for any line that looks like a device
            // This catches formats we might not have anticipated
            if (!deviceMatch && !newDeviceMatch) {
                let permissiveMatch = line.match(/([A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2})\s+(.+)/)
                if (permissiveMatch) {
                    // console.log("[BT SERVICE] Permissive match found:", permissiveMatch)
                    if (currentDevice && isRealDevice(currentDevice.address, currentDevice.name)) {
                        devices.push(currentDevice)
                    }
                    currentDevice = {
                        address: permissiveMatch[1],
                        name: permissiveMatch[2].trim(),
                        type: "Unknown",
                        connected: false,
                        paired: false,
                        battery: null
                    }
                }
            }
            
            // Device properties
            if (currentDevice) {
                if (line.includes("Connected: yes")) {
                    currentDevice.connected = true
                } else if (line.includes("Paired: yes")) {
                    currentDevice.paired = true
                } else if (line.includes("Icon:")) {
                    let iconMatch = line.match(/Icon:\s+(.+)/)
                    if (iconMatch) {
                        let icon = iconMatch[1].trim()
                        if (icon.includes("audio")) currentDevice.type = "Headphones"
                        else if (icon.includes("input")) currentDevice.type = "Mouse"
                        else if (icon.includes("phone")) currentDevice.type = "Phone"
                        else if (icon.includes("computer")) currentDevice.type = "Computer"
                        else if (icon.includes("tv")) currentDevice.type = "TV"
                        else currentDevice.type = "Device"
                    }
                }
            }
        }
        
        // Add last device
        if (currentDevice && isRealDevice(currentDevice.address, currentDevice.name)) {
            devices.push(currentDevice)
        }
        
        return devices
    }

    function update() {
        updateBluetoothStatus.running = true
        // Only update devices if not currently scanning
        if (!scanning) {
            updateDevices.running = true
        }
    }

    function powerOn() {
        powerOnBluetooth.running = true
    }

    function powerOff() {
        powerOffBluetooth.running = true
    }

    function startScan() {
        if (!bluetoothEnabled) return
        scanning = true
        availableDevices = []
        // console.log("[BT SERVICE] Starting 60s scan...")
        scanProcess.running = true
    }

    // Scan for devices for 60 seconds
    Process {
        id: scanProcess
        command: ["bash", "-c", "(echo -e 'scan on'; sleep 60; echo -e 'scan off') | bluetoothctl"]
        stdout: SplitParser {
            property string collectedOutput: ""
            onRead: data => {
                collectedOutput += data + "\n"
                // Parse for [NEW] Device lines
                if (data.indexOf('[NEW] Device') !== -1) {
                    // console.log('[BT SERVICE] New device found:', data)
                    // Optionally, parse and add to availableDevices here
                    // let device = root.parseDeviceInfo(data)
                    // root.availableDevices.push(device)
                }
            }
        }
        onRunningChanged: {
            if (!running) {
                // console.log('[BT SERVICE] 60s scan finished')
                scanning = false
                updateDevices.running = true // Always refresh full device list after scan
            }
        }
    }

    function stopScan() {
        scanning = false
        stopScanProcess.running = true
    }

    function connectDevice(address) {
        if (!bluetoothEnabled) return
        connectDeviceProcess.command = ["bash", "-c", "source /etc/environment && export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $USER -f dbus-daemon)/environ | tr -d '\\0' | cut -d= -f2-) && bluetoothctl connect " + address]
        connectDeviceProcess.running = true
    }

    function disconnectDevice(address) {
        if (!bluetoothEnabled) return
        disconnectDeviceProcess.command = ["bash", "-c", "source /etc/environment && export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $USER -f dbus-daemon)/environ | tr -d '\\0' | cut -d= -f2-) && bluetoothctl disconnect " + address]
        disconnectDeviceProcess.running = true
    }

    function pairDevice(address) {
        if (!bluetoothEnabled) return
        pairDeviceProcess.command = ["bash", "-c", "source /etc/environment && export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $USER -f dbus-daemon)/environ | tr -d '\\0' | cut -d= -f2-) && bluetoothctl pair " + address]
        pairDeviceProcess.running = true
    }

    function removeDevice(address) {
        if (!bluetoothEnabled) return
        removeDeviceProcess.command = ["bash", "-c", "source /etc/environment && export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $USER -f dbus-daemon)/environ | tr -d '\\0' | cut -d= -f2-) && bluetoothctl remove " + address]
        removeDeviceProcess.running = true
    }

    function setDiscoverable(on) {
        if (!bluetoothEnabled) return;
        discoverableProcess._pendingDiscoverable = on;
        discoverableProcess.command = ["bash", "-c", on ? "bluetoothctl discoverable on" : "bluetoothctl discoverable off"];
        discoverableProcess.running = true;
    }

    // Debug function to test scanning manually
    function debugScan() {
        // console.log("[BT SERVICE] === DEBUG SCAN START ===")
        // console.log("[BT SERVICE] Bluetooth enabled:", bluetoothEnabled)
        // console.log("[BT SERVICE] Currently scanning:", scanning)
        // console.log("[BT SERVICE] Available devices count:", availableDevices.length)
        // console.log("[BT SERVICE] Paired devices count:", pairedDevices.length)
        // console.log("[BT SERVICE] Connected devices count:", connectedDevices.length)
        
        // Force a device list update
        updateDevices.running = true
        
        // Also test scan output parsing
        // console.log("[BT SERVICE] Testing scan output parsing...")
        let testOutput = "[NEW] Device AA:BB:CC:DD:EE:FF TestDevice\n[NEW] Media /org/bluez/hci0\nSupportedUUIDs: 0000110a-0000-1000-8000-00805f9b34fb"
        let testDevices = parseDeviceInfo(testOutput)
        // console.log("[BT SERVICE] Test parse result:", testDevices.length, "devices")
        for (let i = 0; i < testDevices.length; i++) {
            // console.log(`[BT SERVICE] Test device ${i}:`, testDevices[i])
        }
    }

    Timer {
        interval: 10
        running: true
        repeat: true
        onTriggered: {
            update()
            interval = root.updateInterval
        }
    }

    // Check Bluetooth status
    Process {
        id: updateBluetoothStatus
        command: ["bash", "-c", "source /etc/environment && export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $USER -f dbus-daemon)/environ | tr -d '\\0' | cut -d= -f2-) && bluetoothctl show | grep -q 'Powered: yes' && echo 1 || echo 0"]
        stdout: SplitParser {
            onRead: data => {
                root.bluetoothEnabled = (parseInt(data) === 1)
            }
        }
    }

    // Update device lists
    Process {
        id: updateDevices
        command: ["bash", "-c", "source /etc/environment && export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $USER -f dbus-daemon)/environ | tr -d '\\0' | cut -d= -f2-) && bluetoothctl --timeout=5 devices"]
        stdout: SplitParser {
            property string collectedOutput: ""
            
            onRead: data => {
                collectedOutput += data + "\n"
            }
        }
        
        onRunningChanged: {
            if (!running) {
                // console.log("[BT SERVICE] Complete bluetoothctl devices output:", updateDevices.stdout.collectedOutput)
                let devices = root.parseDeviceInfo(updateDevices.stdout.collectedOutput)
                // console.log("[BT SERVICE] Parsed devices:", devices.length)
                for (let i = 0; i < devices.length; i++) {
                    let d = devices[i]
                    // console.log(`[BT SERVICE] Device ${i}: name='${d.name}', address='${d.address}', connected=${d.connected}, paired=${d.paired}`)
                }
                // Deduplicate by address
                let uniqueDevices = [];
                let seenAddresses = {};
                for (let i = 0; i < devices.length; ++i) {
                    let addr = devices[i].address;
                    if (!seenAddresses[addr]) {
                        seenAddresses[addr] = true;
                        uniqueDevices.push(devices[i]);
                    }
                }
                root.availableDevices = uniqueDevices;
                root.pairedDevices = devices.filter(d => d.paired && !d.connected)
                root.connectedDevices = devices.filter(d => d.connected)
                
                // console.log("[BT SERVICE] Available devices:", root.availableDevices.length)
                // console.log("[BT SERVICE] Paired devices:", root.pairedDevices.length)
                // console.log("[BT SERVICE] Connected devices:", root.connectedDevices.length)
                
                // Update connected device info
                if (root.connectedDevices.length > 0) {
                    let device = root.connectedDevices[0]
                    root.bluetoothDeviceName = device.name
                    root.bluetoothDeviceAddress = device.address
                    root.bluetoothConnected = true
                } else {
                    root.bluetoothDeviceName = ""
                    root.bluetoothDeviceAddress = ""
                    root.bluetoothConnected = false
                }
                
                // Reset for next update
                updateDevices.stdout.collectedOutput = ""
            }
        }
    }

    // Power on Bluetooth
    Process {
        id: powerOnBluetooth
        command: ["bash", "-c", "source /etc/environment && export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $USER -f dbus-daemon)/environ | tr -d '\\0' | cut -d= -f2-) && bluetoothctl power on"]
        onRunningChanged: {
            if (!running) {
                // console.log("Bluetooth powered on")
                update()
            }
        }
    }

    // Power off Bluetooth
    Process {
        id: powerOffBluetooth
        command: ["bash", "-c", "source /etc/environment && export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $USER -f dbus-daemon)/environ | tr -d '\\0' | cut -d= -f2-) && bluetoothctl power off"]
        onRunningChanged: {
            if (!running) {
                // console.log("Bluetooth powered off")
                update()
            }
        }
    }

    // Stop scanning
    Process {
        id: stopScanProcess
        command: ["bash", "-c", "source /etc/environment && export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $USER -f dbus-daemon)/environ | tr -d '\\0' | cut -d= -f2-) && bluetoothctl scan off"]
        onRunningChanged: {
            if (!running) {
                // console.log("Scan stopped")
                root.scanning = false
                update()
            }
        }
    }

    // Connect device
    Process {
        id: connectDeviceProcess
        onRunningChanged: {
            if (!running) {
                // console.log("Connect command completed")
                update()
            }
        }
    }

    // Disconnect device
    Process {
        id: disconnectDeviceProcess
        onRunningChanged: {
            if (!running) {
                // console.log("Disconnect command completed")
                update()
            }
        }
    }

    // Pair device
    Process {
        id: pairDeviceProcess
        onRunningChanged: {
            if (!running) {
                // console.log("Pair command completed")
                update()
            }
        }
    }

    // Remove device
    Process {
        id: removeDeviceProcess
        onRunningChanged: {
            if (!running) {
                // console.log("Remove command completed")
                update()
            }
        }
    }

    // Check discoverable state periodically
    Process {
        id: checkDiscoverableProcess
        command: ["bash", "-c", "source /etc/environment && export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $USER -f dbus-daemon)/environ | tr -d '\\0' | cut -d= -f2-) && bluetoothctl show"]
        stdout: SplitParser {
            onRead: data => {
                if (data.indexOf('Discoverable: yes') !== -1) {
                    root.discoverable = true;
                } else if (data.indexOf('Discoverable: no') !== -1) {
                    root.discoverable = false;
                }
            }
        }
    }

    Timer {
        id: discoverableCheckTimer
        interval: 5000 // Check every 5 seconds
        repeat: true
        onTriggered: {
            if (root.bluetoothEnabled) {
                checkDiscoverableProcess.running = true
            }
        }
    }
    
    // Update devices during scan
    // (scanUpdateTimer, scanTimer, etc. are no longer needed)


}
