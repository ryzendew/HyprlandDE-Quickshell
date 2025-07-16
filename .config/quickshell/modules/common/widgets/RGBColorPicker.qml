import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"

Rectangle {
    id: root
    
    property color selectedColor: Qt.rgba(redSlider.value, greenSlider.value, blueSlider.value, 1.0)
    property color initialColor: "#ffffff"
    
    signal colorChanged(color newColor)
    
    width: 300
    height: 200
    radius: 8
    color: Appearance.colors.colLayer1
    border.width: 1
    border.color: Appearance.colors.colOutline
    
    onInitialColorChanged: {
        var color = Qt.color(initialColor)
        redSlider.value = color.r
        greenSlider.value = color.g
        blueSlider.value = color.b
    }
    
    Component.onCompleted: {
        var color = Qt.color(initialColor)
        redSlider.value = color.r
        greenSlider.value = color.g
        blueSlider.value = color.b
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16
        
        // Color preview
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            radius: 8
            color: root.selectedColor
            border.width: 2
            border.color: Appearance.colors.colOutline
            
            Text {
                anchors.centerIn: parent
                text: "#" + Math.round(root.selectedColor.r * 255).toString(16).padStart(2, '0') + 
                      Math.round(root.selectedColor.g * 255).toString(16).padStart(2, '0') + 
                      Math.round(root.selectedColor.b * 255).toString(16).padStart(2, '0')
                font.pixelSize: 16
                font.family: "monospace"
                color: (root.selectedColor.r * 0.299 + root.selectedColor.g * 0.587 + root.selectedColor.b * 0.114) > 0.5 ? "#000000" : "#ffffff"
            }
        }
        
        // Red slider
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            
            RowLayout {
                Layout.fillWidth: true
                
                Rectangle {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    radius: 8
                    color: "#ff0000"
                }
                
                Text {
                    text: "Red"
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: 14
                }
                
                Text {
                    text: Math.round(redSlider.value * 255)
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: 14
                    font.family: "monospace"
                    Layout.alignment: Qt.AlignRight
                }
            }
            
            StyledSlider {
                id: redSlider
                Layout.fillWidth: true
                from: 0
                to: 1
                stepSize: 0.01
                highlightColor: "#ff0000"
                trackColor: Qt.rgba(1, 0, 0, 0.3)
                handleColor: "#ffffff"
                onValueChanged: {
                    root.colorChanged(root.selectedColor)
                }
            }
        }
        
        // Green slider
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            
            RowLayout {
                Layout.fillWidth: true
                
                Rectangle {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    radius: 8
                    color: "#00ff00"
                }
                
                Text {
                    text: "Green"
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: 14
                }
                
                Text {
                    text: Math.round(greenSlider.value * 255)
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: 14
                    font.family: "monospace"
                    Layout.alignment: Qt.AlignRight
                }
            }
            
            StyledSlider {
                id: greenSlider
                Layout.fillWidth: true
                from: 0
                to: 1
                stepSize: 0.01
                highlightColor: "#00ff00"
                trackColor: Qt.rgba(0, 1, 0, 0.3)
                onValueChanged: root.colorChanged(root.selectedColor)
            }
        }
        
        // Blue slider
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            
            RowLayout {
                Layout.fillWidth: true
                
                Rectangle {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    radius: 8
                    color: "#0000ff"
                }
                
                Text {
                    text: "Blue"
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: 14
                }
                
                Text {
                    text: Math.round(blueSlider.value * 255)
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: 14
                    font.family: "monospace"
                    Layout.alignment: Qt.AlignRight
                }
            }
            
            StyledSlider {
                id: blueSlider
                Layout.fillWidth: true
                from: 0
                to: 1
                stepSize: 0.01
                highlightColor: "#0000ff"
                trackColor: Qt.rgba(0, 0, 1, 0.3)
                onValueChanged: root.colorChanged(root.selectedColor)
            }
        }
    }
} 