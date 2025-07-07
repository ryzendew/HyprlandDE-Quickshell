import QtQuick 2.15
import QtQuick.Layouts 1.15
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils

Item {
    id: root
    anchors.fill: parent

    Rectangle {
        id: cheatsheetBg
        anchors.fill: parent
        color: "#80000000"
        border.color: "#66ffffff"
        border.width: 2
        radius: 12

        // Title
        StyledText {
            id: title
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 25
            text: "QuickShell Keybinds Reference"
            font.pixelSize: 28
            font.weight: Font.Bold
            color: "#ffffff"
        }

        // Main content area
        RowLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: 35
            anchors.topMargin: 75
            spacing: 45

            // Column 1: Essentials & Session
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 280
                spacing: 8

                StyledText {
                    text: "ESSENTIALS"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: "#cccccc"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 8
                }

                Repeater {
                    model: [
                        {keys: ["Super", "T"], desc: "LAUNCH TERMINAL"},
                        {keys: ["Super", "V"], desc: "CLIPBOARD HISTORY"},
                        {keys: ["Super", "."], desc: "PICK EMOJI"},
                        {keys: ["Super", "/"], desc: "SHOW CHEATSHEET"}
                    ]
                    
                    RowLayout {
                        spacing: 8
                        Layout.fillWidth: true
                        
                        Row {
                            spacing: 4
                            Repeater {
                                model: modelData.keys
                                Rectangle {
                                    width: modelData === "Super" ? 50 : 30
                                    height: 32
                                    color: "#333333"
                                    border.color: "#666666"
                                    border.width: 1
                                    radius: 4
                                    StyledText {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: "#ffffff"
                                        font.pixelSize: modelData === "Super" ? 10 : 12
                                        font.weight: Font.Bold
                                    }
                                }
                            }
                        }
                        
                        StyledText {
                            text: modelData.desc
                            color: "#ffffff"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Item { height: 15 }

                StyledText {
                    text: "SESSION"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: "#cccccc"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 8
                }

                Repeater {
                    model: [
                        {keys: ["Super", "L"], desc: "LOCK SCREEN"},
                        {keys: ["Super", "Shift", "L"], desc: "SUSPEND SYSTEM"}
                    ]
                    
                    RowLayout {
                        spacing: 8
                        Layout.fillWidth: true
                        
                        Row {
                            spacing: 4
                            Repeater {
                                model: modelData.keys
                                Rectangle {
                                    width: modelData === "Super" ? 50 : modelData === "Shift" ? 40 : 30
                                    height: 32
                                    color: "#333333"
                                    border.color: "#666666"
                                    border.width: 1
                                    radius: 4
                                    StyledText {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: "#ffffff"
                                        font.pixelSize: modelData === "Super" ? 10 : 12
                                        font.weight: Font.Bold
                                    }
                                }
                            }
                        }
                        
                        StyledText {
                            text: modelData.desc
                            color: "#ffffff"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            // Column 2: Screenshots & Media
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 280
                spacing: 8

                StyledText {
                    text: "SCREENSHOTS"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: "#cccccc"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 8
                }

                Repeater {
                    model: [
                        {keys: ["Super", "Shift", "S"], desc: "AREA SCREENSHOT"},
                        {keys: ["Print"], desc: "FULL SCREENSHOT"},
                        {keys: ["Super", "Shift", "C"], desc: "COLOR PICKER"},
                        {keys: ["Super", "Shift", "T"], desc: "OCR SCREENSHOT"},
                        {keys: ["Super", "Alt", "R"], desc: "RECORD REGION"}
                    ]
                    
                    RowLayout {
                        spacing: 8
                        Layout.fillWidth: true
                        
                        Row {
                            spacing: 4
                            Repeater {
                                model: modelData.keys
                                Rectangle {
                                    width: modelData === "Super" ? 50 : 
                                          modelData === "Shift" ? 40 : 
                                          modelData === "Print" ? 50 : 
                                          modelData === "Alt" ? 35 : 30
                                    height: 32
                                    color: "#333333"
                                    border.color: "#666666"
                                    border.width: 1
                                    radius: 4
                                    StyledText {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: "#ffffff"
                                        font.pixelSize: modelData === "Super" ? 10 : 12
                                        font.weight: Font.Bold
                                    }
                                }
                            }
                        }
                        
                        StyledText {
                            text: modelData.desc
                            color: "#ffffff"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Item { height: 15 }

                StyledText {
                    text: "MEDIA"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: "#cccccc"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 8
                }

                Repeater {
                    model: [
                        {keys: ["Super", "M"], desc: "MEDIA PLAYER"}
                    ]
                    
                    RowLayout {
                        spacing: 8
                        Layout.fillWidth: true
                        
                        Row {
                            spacing: 4
                            Repeater {
                                model: modelData.keys
                                Rectangle {
                                    width: modelData === "Super" ? 50 : modelData === "Shift" ? 40 : 30
                                    height: 32
                                    color: "#333333"
                                    border.color: "#666666"
                                    border.width: 1
                                    radius: 4
                                    StyledText {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: "#ffffff"
                                        font.pixelSize: modelData === "Super" ? 10 : 12
                                        font.weight: Font.Bold
                                    }
                                }
                            }
                        }
                        
                        StyledText {
                            text: modelData.desc
                            color: "#ffffff"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            // Column 3: Window Management
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 280
                spacing: 8

                StyledText {
                    text: "WINDOW MANAGEMENT"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: "#cccccc"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 8
                }

                Repeater {
                    model: [
                        {keys: ["Alt", "Tab"], desc: "SWITCH WINDOW"},
                        {keys: ["Super", "Q"], desc: "CLOSE WINDOW"},
                        {keys: ["Super", "F"], desc: "FULLSCREEN"},
                        {keys: ["Super", "D"], desc: "MAXIMIZE"},
                        {keys: ["Super", "Alt", "Space"], desc: "FLOAT WINDOW"},
                        {keys: ["Super", "P"], desc: "PIN WINDOW"},
                        {keys: ["Super", "S"], desc: "SPECIAL WORKSPACE"}
                    ]
                    
                    RowLayout {
                        spacing: 8
                        Layout.fillWidth: true
                        
                        Row {
                            spacing: 4
                            Repeater {
                                model: modelData.keys
                                Rectangle {
                                    width: modelData === "Super" ? 50 : 
                                          modelData === "Alt" ? 35 : 
                                          modelData === "Tab" ? 35 : 
                                          modelData === "Space" ? 50 : 30
                                    height: 32
                                    color: "#333333"
                                    border.color: "#666666"
                                    border.width: 1
                                    radius: 4
                                    StyledText {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: "#ffffff"
                                        font.pixelSize: modelData === "Super" ? 10 : 12
                                        font.weight: Font.Bold
                                    }
                                }
                            }
                        }
                        
                        StyledText {
                            text: modelData.desc
                            color: "#ffffff"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            // Column 4: Applications & System
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 280
                spacing: 8

                StyledText {
                    text: "APPLICATIONS"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: "#cccccc"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 8
                }

                Repeater {
                    model: [
                        {keys: ["Super", "Z"], desc: "LAUNCH ZED"},
                        {keys: ["Super", "C"], desc: "LAUNCH VSCODE"},
                        {keys: ["Super", "E"], desc: "FILE MANAGER"},
                        {keys: ["Ctrl", "Super", "W"], desc: "FIREFOX"},
                        {keys: ["Super", "X"], desc: "TEXT EDITOR"}
                    ]
                    
                    RowLayout {
                        spacing: 8
                        Layout.fillWidth: true
                        
                        Row {
                            spacing: 4
                            Repeater {
                                model: modelData.keys
                                Rectangle {
                                    width: modelData === "Super" ? 50 : 
                                          modelData === "Ctrl" ? 35 : 30
                                    height: 32
                                    color: "#333333"
                                    border.color: "#666666"
                                    border.width: 1
                                    radius: 4
                                    StyledText {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: "#ffffff"
                                        font.pixelSize: modelData === "Super" ? 10 : 12
                                        font.weight: Font.Bold
                                    }
                                }
                            }
                        }
                        
                        StyledText {
                            text: modelData.desc
                            color: "#ffffff"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Item { height: 15 }

                StyledText {
                    text: "SYSTEM"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: "#cccccc"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 8
                }

                Repeater {
                    model: [
                        {keys: ["Super", "Tab"], desc: "OVERVIEW"},
                        {keys: ["Super", "B"], desc: "TOGGLE BAR"},
                        {keys: ["Super", "K"], desc: "ON-SCREEN KEYBOARD"}
                    ]
                    
                    RowLayout {
                        spacing: 8
                        Layout.fillWidth: true
                        
                        Row {
                            spacing: 4
                            Repeater {
                                model: modelData.keys
                                Rectangle {
                                    width: modelData === "Super" ? 50 : 
                                          modelData === "Tab" ? 35 : 30
                                    height: 32
                                    color: "#333333"
                                    border.color: "#666666"
                                    border.width: 1
                                    radius: 4
                                    StyledText {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: "#ffffff"
                                        font.pixelSize: modelData === "Super" ? 10 : 12
                                        font.weight: Font.Bold
                                    }
                                }
                            }
                        }
                        
                        StyledText {
                            text: modelData.desc
                            color: "#ffffff"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }
}