import QtQuick
import QtQuick.Layouts
import "root:/modules/common/widgets"
import "root:/modules/common"

Item {
    id: root
    property string label: ""
    property string subLabel: ""
    property real value: 0 // 0-1 for progress
    property string valueText: ""
    property color primaryColor: Appearance.colors.colAccent
    property color secondaryColor: Appearance.colors.colLayer1
    property int size: 120
    property int lineWidth: 8
    property var history: [] // Array of values (0-1) for history graph
    property int historyLength: 60 // Number of history points to show

    width: size
    height: size + 36 + 32 // Added 32px for history graph

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0
        Item {
            width: size
            height: size
            Layout.alignment: Qt.AlignHCenter
            CircularProgress {
                anchors.centerIn: parent
                size: root.size
                lineWidth: root.lineWidth
                value: root.value
                primaryColor: root.primaryColor
                secondaryColor: root.secondaryColor
            }
            Text {
                anchors.centerIn: parent
                text: root.valueText
                font.pixelSize: 28
                font.bold: true
                color: "white"
            }
        }
        
        // History Graph
        Canvas {
            id: historyCanvas
            width: size
            height: 32
            Layout.alignment: Qt.AlignHCenter
            
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                
                if (root.history.length < 2) return
                
                var width = historyCanvas.width
                var height = historyCanvas.height
                var step = width / (root.historyLength - 1)
                
                ctx.strokeStyle = Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.3)
                ctx.lineWidth = 2
                ctx.beginPath()
                
                for (var i = 0; i < root.history.length; i++) {
                    var x = i * step
                    var y = height - (root.history[i] * height)
                    
                    if (i === 0) {
                        ctx.moveTo(x, y)
                    } else {
                        ctx.lineTo(x, y)
                    }
                }
                
                ctx.stroke()
            }
        }
        // Remove: onHistoryChanged: historyCanvas.requestPaint()
        Connections {
            target: root
            onHistoryChanged: historyCanvas.requestPaint()
        }
        
        StyledText {
            text: root.label
            font.pixelSize: Appearance.font.pixelSize.normal
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }
        StyledText {
            text: root.subLabel
            font.pixelSize: Appearance.font.pixelSize.tiny
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }
    }
} 