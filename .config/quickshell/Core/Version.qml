import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "root:/Data" as Data

// System version watermark
PanelWindow {
    id: systemVersion

    anchors {
        right: true
        bottom: true
    }

    margins {
        right: 60
        bottom: 60
    }
    visible: false
    
    implicitWidth: systemInfoContent.width
    implicitHeight: systemInfoContent.height

    color: "transparent"

    mask: Region {}

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-version"

    // Delayed startup
    Timer {
        id: startupTimer
        interval: 1500
        running: true
        onTriggered: {
            visible = true
        }
    }

    // Data structures for system information
    component Details: QtObject {
        property string version
        property string commit
    }

    property QtObject os: QtObject {
        property string name: "Loading..."
        property Details details: Details {
            property string generation: "?"
        }
    }

    property QtObject wm: QtObject {
        property string name: "Loading..."
        property Details details: Details {}
    }

    Component.onCompleted: {
        osFile.reload();
        genProcess.running = true;
        wmProcess.running = true;
        niriProcess.running = true;
    }

    // Periodic refresh disabled to save memory - version info rarely changes
    Timer {
        running: false
        interval: 300000
        repeat: true
        onTriggered: {
            osFile.reload();
            genProcess.running = true;
            wmProcess.running = true;
            niriProcess.running = true;
        }
    }

    // Parse OS information from /etc/os-release
    FileView {
        id: osFile
        path: "/etc/os-release"

        onLoaded: {
            const data = text().trim().split("\n");
            
            const nameLine = data.find((str) => str.match(/^NAME=/));
            const versionLine = data.find((str) => str.match(/^VERSION_ID=/));
            const buildLine = data.find((str) => str.match(/^BUILD_ID=/));
            
            if (nameLine) {
                systemVersion.os.name = nameLine.split("=")[1].replace(/"/g, "");
            }
            if (versionLine) {
                systemVersion.os.details.version = versionLine.split("=")[1].replace(/"/g, "");
            }
            if (buildLine) {
                const commit = buildLine.split("=")[1].split(".")[3];
                if (commit) {
                    systemVersion.os.details.commit = commit.replace(/"/g, "").toUpperCase();
                }
            }
        }
    }

    // Get current NixOS generation number
    Process {
        id: genProcess
        running: true
        command: ["sh", "-c", "nixos-rebuild list-generations"]

        stdout: SplitParser {
            splitMarker: ""
            onRead: (data) => {
                const line = data.trim().split("\n").find((str) => str.match(/current/));
                if (line) {
                    const current = line.split(" ")[0];
                    systemVersion.os.details.generation = current;
                }
            }
        }
    }

    // Detect current desktop environment
    Process {
        id: wmProcess
        running: true
        command: ["sh", "-c", "echo $XDG_CURRENT_DESKTOP"]

        stdout: SplitParser {
            splitMarker: ""
            onRead: (data) => {
                const result = data.trim();
                if (result && result !== "") {
                    systemVersion.wm.name = result;
                }
            }
        }
    }

    // Get Niri compositor version information
    Process {
        id: niriProcess
        running: true
        command: ["sh", "-c", "niri msg version"]

        stdout: SplitParser {
            splitMarker: ""
            onRead: (data) => {
                const output = data.trim();
                
                const compositorMatch = output.match(/Compositor version: (\S+)/);
                if (compositorMatch && compositorMatch[1]) {
                    systemVersion.wm.details.version = compositorMatch[1];
                }
                
                const commitMatch = output.match(/\((\S+)\)/);
                if (commitMatch && commitMatch[1]) {
                    systemVersion.wm.details.commit = commitMatch[1].toUpperCase();
                }
            }
        }
    }

    // Version display layout with macOS-inspired typography
    ColumnLayout {
        id: systemInfoContent
        spacing: 6
        
        RowLayout {
            spacing: 16
            Layout.alignment: Qt.AlignRight
            
            // Operating system information
            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignRight
                
                Text {
                    text: systemVersion.os.name
                    color: Data.Colors.isDarkTheme ? "#40ffffff" : "#40000000"
                    font.family: "SF Pro Display, -apple-system, system-ui, sans-serif"
                    font.pointSize: 16
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.4
                    Layout.alignment: Qt.AlignRight
                }

                Text {
                    text: {
                        let details = [];
                        if (systemVersion.os.details.version) {
                            details.push(systemVersion.os.details.version);
                        }
                        if (systemVersion.os.details.commit) {
                            details.push("(" + systemVersion.os.details.commit + ")");
                        }
                        if (systemVersion.os.details.generation && systemVersion.os.details.generation !== "?") {
                            details.push("Gen " + systemVersion.os.details.generation);
                        }
                        return details.join(" ");
                    }
                    color: Data.Colors.isDarkTheme ? "#30ffffff" : "#30000000"
                    font.family: "SF Mono, Consolas, Monaco, monospace"
                    font.pointSize: 10
                    font.weight: Font.Medium
                    visible: text.length > 0
                    Layout.alignment: Qt.AlignRight
                }
            }
            
            Text {
                text: "│"
                color: Data.Colors.isDarkTheme ? "#20ffffff" : "#20000000"
                font.family: "SF Pro Display, -apple-system, system-ui, sans-serif"
                font.pointSize: 14
                font.weight: Font.Light
                Layout.alignment: Qt.AlignCenter
            }
            
            // Window manager information
            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignRight
                
                Text {
                    text: systemVersion.wm.name
                    color: Data.Colors.isDarkTheme ? "#40ffffff" : "#40000000"
                    font.family: "SF Pro Display, -apple-system, system-ui, sans-serif"
                    font.pointSize: 16
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.4
                    Layout.alignment: Qt.AlignRight
                }

                Text {
                    text: {
                        let details = [];
                        if (systemVersion.wm.details.version) {
                            details.push(systemVersion.wm.details.version);
                        }
                        if (systemVersion.wm.details.commit) {
                            details.push("(" + systemVersion.wm.details.commit + ")");
                        }
                        return details.join(" ");
                    }
                    color: Data.Colors.isDarkTheme ? "#30ffffff" : "#30000000"
                    font.family: "SF Mono, Consolas, Monaco, monospace"
                    font.pointSize: 10
                    font.weight: Font.Medium
                    visible: text.length > 0
                    Layout.alignment: Qt.AlignRight
                }
            }
        }
    }
    
    // Clean up processes on destruction
    Component.onDestruction: {
        if (genProcess.running) genProcess.running = false
        if (wmProcess.running) wmProcess.running = false
        if (niriProcess.running) niriProcess.running = false
    }
}