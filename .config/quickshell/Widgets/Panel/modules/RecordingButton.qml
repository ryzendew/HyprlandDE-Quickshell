import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "root:/Data" as Data

Rectangle {
    id: root
    required property var shell
    required property bool isRecording
    radius: 20
    
    signal recordingRequested()
    signal stopRecordingRequested()
    signal mouseChanged(bool containsMouse)
    
    // Gray by default, accent color on hover or when recording
    color: isRecording ? Data.Colors.accentColor : 
           (mouseArea.containsMouse ? Data.Colors.accentColor : Qt.darker(Data.Colors.bgColor, 1.15))
    
    property bool isHovered: mouseArea.containsMouse
    readonly property alias containsMouse: mouseArea.containsMouse
    
    RowLayout {
        anchors.centerIn: parent
        spacing: 10
        
        Text {
            text: isRecording ? "stop_circle" : "radio_button_unchecked"
            font.family: "Material Symbols Outlined"
            font.pixelSize: 16
            color: isRecording || mouseArea.containsMouse ? "#ffffff" : Data.Colors.fgColor
            
            Layout.alignment: Qt.AlignVCenter
        }
        
        Label {
            text: isRecording ? "Stop Recording" : "Start Recording"
            font.pixelSize: 13
            font.weight: Font.Medium
            color: isRecording || mouseArea.containsMouse ? "#ffffff" : Data.Colors.fgColor
            
            Layout.alignment: Qt.AlignVCenter
        }
    }
    
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