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
        anchors.margins: Math.max(8, parent.width * 0.025) // Reduced margins for more content space
        spacing: Math.max(6, parent.height * 0.015) // Reduced spacing for more content space
        
        // Title row with optional right content
        RowLayout {
            Layout.fillWidth: true
            spacing: Math.max(4, parent.width * 0.01) // Reduced spacing
            
            StyledText {
                text: root.title
                font.pixelSize: Math.max(Appearance.font.pixelSize.medium, parent.height * 0.06) // Reduced font size for more space
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
            Layout.preferredHeight: Math.max(40, parent.height * 0.20) // Reduced graph height for more text space
            Layout.minimumHeight: 60
            color: Qt.rgba(0.05, 0.05, 0.1, 0.8)
            radius: 8
            border.color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
            visible: root.showGraph
            
            // Glow effect canvas (behind the main line)
            Canvas {
                id: glowCanvas
                anchors.fill: parent
                anchors.margins: 4
                z: 1
                
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    
                    if (root.history.length < 2) return
                    
                    const width = glowCanvas.width
                    const height = glowCanvas.height
                    const step = width / (root.history.length - 1)
                    
                    // Create glow effect with multiple strokes
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    
                    // Draw multiple glow layers
                    for (let glow = 0; glow < 3; glow++) {
                        ctx.strokeStyle = Qt.rgba(
                            root.graphColor.r, 
                            root.graphColor.g, 
                            root.graphColor.b, 
                            0.3 - (glow * 0.1)
                        )
                        ctx.lineWidth = 6 - (glow * 1.5)
                        
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
                }
                
                Connections {
                    target: root
                    function onHistoryChanged() {
                        glowCanvas.requestPaint()
                    }
                }
            }
            
            // Main line graph (on top of glow)
            Canvas {
                id: graphCanvas
                anchors.fill: parent
                anchors.margins: 4
                z: 2
                
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
            spacing: Math.max(2, parent.height * 0.008) // Reduced spacing for more content
            
            // Main value
            StyledText {
                text: root.valueText
                font.pixelSize: Math.max(Appearance.font.pixelSize.medium, parent.height * 0.05) // Reduced font size for more space
                font.weight: Font.Bold
                color: "white"
                Layout.fillWidth: true
            }
            
            // Subtitle
            StyledText {
                text: root.subtitle
                font.pixelSize: Math.max(Appearance.font.pixelSize.small, parent.height * 0.035) // Reduced font size to fit more content
                color: Qt.rgba(1, 1, 1, 0.7)
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                maximumLineCount: 5 // Allow more lines to fit all information
                elide: Text.ElideRight
                visible: root.showSubtitle && root.subtitle !== ""
            }
        }
    }
} 