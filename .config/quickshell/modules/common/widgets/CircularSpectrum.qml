import QtQuick

Item {
    id: root
    // Fixed bar count to match Cava configuration
    property int minBarWidth: 2
    property int minBarSpacing: 1
    property int barCount: 28
    property int barWidth: 10
    property int barSpacing: 1
    property color fillColor: Qt.lighter("#FFD700", 1.2)
    property color fillColor2: Qt.darker("#FFA500", 1.1)
    property var values: []

    width: parent ? parent.width : 120
    height: parent ? parent.height : 40

    Repeater {
        model: root.barCount
        Rectangle {
            width: root.barWidth
            // Scale value by 0.08 for restrained bar height, clamp to height
            height: Math.min(root.height, Math.max(2, (root.values.length > index ? root.values[index] * 0.9 : 0.1) * root.height))
            x: index * (root.barWidth + root.barSpacing)
            y: root.height - height
            radius: 0
            color: Qt.rgba(
                Qt.lerp(Qt.rgba(Qt.colorEqual(root.fillColor, "transparent") ? "#FFD700" : root.fillColor),
                        Qt.colorEqual(root.fillColor2, "transparent") ? "#FFA500" : root.fillColor2,
                        index / (root.barCount - 1)).r,
                Qt.lerp(Qt.rgba(Qt.colorEqual(root.fillColor, "transparent") ? "#FFD700" : root.fillColor),
                        Qt.colorEqual(root.fillColor2, "transparent") ? "#FFA500" : root.fillColor2,
                        index / (root.barCount - 1)).g,
                Qt.lerp(Qt.rgba(Qt.colorEqual(root.fillColor, "transparent") ? "#FFD700" : root.fillColor),
                        Qt.colorEqual(root.fillColor2, "transparent") ? "#FFA500" : root.fillColor2,
                        index / (root.barCount - 1)).b,
                0.2
            )
            antialiasing: true
        }
    }
} 