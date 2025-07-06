import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"

Popup {
    id: audioControlPopup
    width: 200
    height: 150
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    // Dock-style background
    background: Rectangle {
        color: Qt.rgba(
            Appearance.colors.colLayer0.r,
            Appearance.colors.colLayer0.g,
            Appearance.colors.colLayer0.b,
            1.0
        )
        radius: Appearance.rounding.normal
        border.width: 1
        border.color: Qt.rgba(
            Appearance.colors.colOnLayer0.r,
            Appearance.colors.colOnLayer0.g,
            Appearance.colors.colOnLayer0.b,
            0.1
        )
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4
        
        // Volume mute/unmute button
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            color: volumeMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
            radius: Appearance.rounding.small
            
            Text {
                anchors.centerIn: parent
                text: Audio.sink?.audio?.muted ? "Unmute Volume" : "Mute Volume"
                color: "#ffffff"
                font.pixelSize: Appearance.font.pixelSize.normal
            }
            
            MouseArea {
                id: volumeMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (Audio.sink?.audio) {
                        Audio.sink.audio.muted = !Audio.sink.audio.muted
                    }
                    audioControlPopup.close()
                }
            }
        }
        
        // Microphone mute/unmute button
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            color: micMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
            radius: Appearance.rounding.small
            
            Text {
                anchors.centerIn: parent
                text: Audio.source?.audio?.muted ? "Unmute Microphone" : "Mute Microphone"
                color: "#ffffff"
                font.pixelSize: Appearance.font.pixelSize.normal
            }
            
            MouseArea {
                id: micMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (Audio.source?.audio) {
                        Audio.source.audio.muted = !Audio.source.audio.muted
                    }
                    audioControlPopup.close()
                }
            }
        }
        
        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.rgba(1, 1, 1, 0.2)
        }
        
        // Volume level display
        Text {
            Layout.fillWidth: true
            text: "Volume: " + Math.round((Audio.sink?.audio?.volume ?? 0) * 100) + "%"
            color: "#cccccc"
            font.pixelSize: Appearance.font.pixelSize.smaller
            horizontalAlignment: Text.AlignHCenter
        }
        
        // Microphone level display
        Text {
            Layout.fillWidth: true
            text: "Microphone: " + Math.round((Audio.source?.audio?.volume ?? 0) * 100) + "%"
            color: "#cccccc"
            font.pixelSize: Appearance.font.pixelSize.smaller
            horizontalAlignment: Text.AlignHCenter
        }
    }
} 