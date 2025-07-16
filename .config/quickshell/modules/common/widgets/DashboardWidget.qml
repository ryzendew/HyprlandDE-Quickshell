import QtQuick
import QtQuick.Layouts
import "root:/modules/common"

/**
 * Professional dashboard widget component for system monitoring.
 * Displays a title, line graph, and detailed statistics in a clean, modern style.
 */
Rectangle {
    id: root
    
    // Properties
    property string title: "Widget"
    property double value: 0.0  // 0.0 to 1.0 for percentage
    property string valueText: "0%"
    property string subtitle: ""
    property var history: []
    property color graphColor: "#6366f1"  // Indigo
    property bool showGraph: true
    property bool showSubtitle: true
    property Component headerRight: null  // Optional right header content
    
    // Layout
    implicitWidth: 280
    implicitHeight: 200
    radius: 12
    color: Qt.rgba(0.1, 0.1, 0.15, 0.8)
    border.color: Qt.rgba(1, 1, 1, 0.1)
    border.width: 1
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        
        // Title row with optional right content
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            StyledText {
                text: root.title
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Bold
                color: "white"
                Layout.fillWidth: true
            }
            
            Item {
                Layout.preferredWidth: root.headerRight ? 20 : 0
                Layout.preferredHeight: root.headerRight ? 20 : 0
                
                Loader {
                    anchors.centerIn: parent
                    sourceComponent: root.headerRight
                }
            }
        }
        
        // Graph
        Rectangle {
            id: graphContainer
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            Layout.minimumHeight: 60
            color: Qt.rgba(0.05, 0.05, 0.1, 0.5)
            radius: 8
            border.color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
            visible: root.showGraph
            
            // Line graph
            Canvas {
                id: graphCanvas
                anchors.fill: parent
                anchors.margins: 4
                
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    
                    if (root.history.length < 2) return
                    
                    const width = graphCanvas.width
                    const height = graphCanvas.height
                    const step = width / (root.history.length - 1)
                    
                    ctx.strokeStyle = root.graphColor
                    ctx.lineWidth = 2
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    
                    ctx.beginPath()
                    
                    for (let i = 0; i < root.history.length; i++) {
                        const x = i * step
                        // Center the line vertically by using only 80% of the height and centering it
                        const graphHeight = height * 0.8
                        const yOffset = height * 0.1  // 10% margin top and bottom
                        const y = yOffset + graphHeight - (root.history[i] * graphHeight)
                        
                        if (i === 0) {
                            ctx.moveTo(x, y)
                        } else {
                            ctx.lineTo(x, y)
                        }
                    }
                    
                    ctx.stroke()
                }
                
                Connections {
                    target: root
                    function onHistoryChanged() {
                        graphCanvas.requestPaint()
                    }
                }
            }
        }
        
        // Statistics
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            
            // Main value
            StyledText {
                text: root.valueText
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Bold
                color: "white"
                Layout.fillWidth: true
            }
            
            // Subtitle
            StyledText {
                text: root.subtitle
                font.pixelSize: Appearance.font.pixelSize.small
                color: Qt.rgba(1, 1, 1, 0.7)
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                visible: root.showSubtitle && root.subtitle !== ""
            }
        }
    }
} 