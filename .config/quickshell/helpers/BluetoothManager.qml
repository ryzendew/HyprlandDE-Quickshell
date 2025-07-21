import QtQuick
import Quickshell.Io

QtObject {
    // List all known devices
    function listDevices(callback) {
        var proc = Qt.createQmlObject('
            import Quickshell.Io;\n\
            Process {\n\
                command: ["bluetoothctl", "devices"],\n\
                running: true;\n\
                stdout: StdioCollector {\n\
                    onStreamFinished: {\n\
                        var lines = this.text.split("\n");\n\
                        var devs = [];\n\
                        for (var i = 0; i < lines.length; ++i) {\n\
                            var line = lines[i].trim();\n\
                            if (line.startsWith("Device ")) {\n\
                                var parts = line.split(" ");\n\
                                if (parts.length >= 3) {\n\
                                    var mac = parts[1];\n\
                                    var name = parts.slice(2).join(" ");\n\
                                    devs.push({ mac: mac, name: name, address: mac });\n\
                                }\n\
                            }\n\
                        }\n\
                        callback(devs);\n\
                        parent.destroy();\n\
                    }\n\
                }\n\
            }', this);
    }

    // Check if a device is connected
    function checkConnected(mac, callback) {
        var proc = Qt.createQmlObject('
            import Quickshell.Io;\n\
            Process {\n\
                command: ["bluetoothctl", "info", "' + mac + '"],\n\
                running: true;\n\
                stdout: StdioCollector {\n\
                    onStreamFinished: {\n\
                        var connected = this.text.indexOf("Connected: yes") !== -1;\n\
                        callback(connected);\n\
                        parent.destroy();\n\
                    }\n\
                }\n\
            }', this);
    }

    // Connect to a device
    function connect(mac, callback) {
        var proc = Qt.createQmlObject('
            import Quickshell.Io;\n\
            Process {\n\
                command: ["bluetoothctl", "connect", "' + mac + '"],\n\
                running: true;\n\
                stdout: StdioCollector { onStreamFinished: { callback(true); parent.destroy(); } }\n\
            }', this);
    }

    // Disconnect from a device
    function disconnect(mac, callback) {
        var proc = Qt.createQmlObject('
            import Quickshell.Io;\n\
            Process {\n\
                command: ["bluetoothctl", "disconnect", "' + mac + '"],\n\
                running: true;\n\
                stdout: StdioCollector { onStreamFinished: { callback(true); parent.destroy(); } }\n\
            }', this);
    }

    // Pair with a device
    function pair(mac, callback) {
        var proc = Qt.createQmlObject('
            import Quickshell.Io;\n\
            Process {\n\
                command: ["sh", "-c", "echo \'pair " + mac + "\' | bluetoothctl"],\n\
                running: true;\n\
                stdout: StdioCollector { \n\
                    onRead: function(data) { \n\
                        console.log("Pairing output:", data); \n\
                    },\n\
                    onStreamFinished: { \n\
                        console.log("Pairing process finished"); \n\
                        callback(true); \n\
                        parent.destroy(); \n\
                    } \n\
                },\n\
                stderr: StdioCollector { \n\
                    onRead: function(data) { \n\
                        console.log("Pairing error:", data); \n\
                    } \n\
                }\n\
            }', this);
    }

    // Remove/forget a device
    function remove(mac, callback) {
        var proc = Qt.createQmlObject('
            import Quickshell.Io;\n\
            Process {\n\
                command: ["bluetoothctl", "remove", "' + mac + '"],\n\
                running: true;\n\
                stdout: StdioCollector { onStreamFinished: { callback(true); parent.destroy(); } }\n\
            }', this);
    }

    // Scan for new devices
    function scan(callback) {
        var proc = Qt.createQmlObject('
            import Quickshell.Io;\n\
            Process {\n\
                command: ["bluetoothctl", "scan", "on"],\n\
                running: true;\n\
                stdout: StdioCollector { \n\
                    onRead: function(data) { \n\
                        console.log("Scan output:", data); \n\
                    },\n\
                    onStreamFinished: { \n\
                        console.log("Scan finished"); \n\
                        callback(true); \n\
                        parent.destroy(); \n\
                    } \n\
                }\n\
            }', this);
    }
} 