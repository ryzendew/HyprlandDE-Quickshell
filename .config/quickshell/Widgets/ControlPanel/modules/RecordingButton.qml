import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "root:/Data" as Data

// Screen recording toggle button
Rectangle {
    id: root
    required property var shell
    required property bool isRecording
    radius: 20
    
    signal recordingRequested()
    signal stopRecordingRequested()
    signal mouseChanged(bool containsMouse)
    
    // Dynamic color: accent when recording/hovered, gray otherwise
    color: isRecording ? Data.Colors.accentColor : 
           (mouseArea.containsMouse ? Data.Colors.accentColor : Qt.darker(Data.Colors.bgColor, 1.15))
    
    property bool isHovered: mouseArea.containsMouse
    readonly property alias containsMouse: mouseArea.containsMouse
    
    // Button content with icon and text
    RowLayout {
        anchors.centerIn: parent
        spacing: 10
        
        // Recording state icon
        Text {
            text: isRecording ? "stop_circle" : "radio_button_unchecked"
            font.family: "Material Symbols Outlined"
            font.pixelSize: 16
            color: isRecording || mouseArea.containsMouse ? "#ffffff" : Data.Colors.fgColor
            
            Layout.alignment: Qt.AlignVCenter
        }
        
        // Recording state label
        Label {
            text: isRecording ? "Stop Recording" : "Start Recording"
            font.pixelSize: 13
            font.weight: Font.Medium
            color: isRecording || mouseArea.containsMouse ? "#ffffff" : Data.Colors.fgColor
            
            Layout.alignment: Qt.AlignVCenter
        }
    }
    
    // Click handling and hover detection
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        
        onContainsMouseChanged: root.mouseChanged(containsMouse)
        
        onClicked: {
            if (isRecording) {
                root.stopRecordingRequested()
            } else {
                root.recordingRequested()
            }
        }
    }
}