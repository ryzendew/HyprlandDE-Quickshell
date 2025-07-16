import QtQuick

Item {
    id: root
    // Dynamic bar count calculation based on available width
    property int minBarWidth: 2
    property int minBarSpacing: 1 // 1px spacing between bars
    property int barWidth: 10
    property int barSpacing: 1 // 1px spacing between bars
    property color fillColor: Qt.lighter("#FFD700", 1.2)
    property color fillColor2: Qt.darker("#FFA500", 1.1)
    property var values: []

    width: parent ? parent.width : 120
    height: parent ? parent.height : 40

    // Calculate bar count based on available width
    readonly property int barCount: {
        if (width <= 0) return 28 // fallback
        var availableWidth = width
        var totalBarWidth = minBarWidth + barSpacing
        var calculatedBars = Math.floor(availableWidth / totalBarWidth)
        return Math.max(1, Math.min(calculatedBars, values.length > 0 ? values.length : 28))
    }

    // Calculate dynamic bar width to fill the entire width with 1px spacing
    readonly property real dynamicBarWidth: {
        if (barCount <= 0) return minBarWidth
        var totalSpacing = (barCount - 1) * barSpacing
        var availableWidthForBars = width - totalSpacing
        return Math.max(minBarWidth, availableWidthForBars / barCount)
    }

    Repeater {
        model: root.barCount
        Rectangle {
            width: root.dynamicBarWidth
            // Scale value by 0.08 for restrained bar height, clamp to height
            height: Math.min(root.height, Math.max(2, (root.values.length > index ? root.values[index] * 1.0 : 0.1) * root.height))
            x: index * (root.dynamicBarWidth + root.barSpacing)
            y: root.height - height
            radius: 0
            color: Qt.rgba(
                Qt.lerp(Qt.colorEqual(root.fillColor, "transparent") ? "#FFD700" : root.fillColor,
                        Qt.colorEqual(root.fillColor2, "transparent") ? "#FFA500" : root.fillColor2,
                        index / (root.barCount - 1)).r,
                Qt.lerp(Qt.colorEqual(root.fillColor, "transparent") ? "#FFD700" : root.fillColor,
                        Qt.colorEqual(root.fillColor2, "transparent") ? "#FFA500" : root.fillColor2,
                        index / (root.barCount - 1)).g,
                Qt.lerp(Qt.colorEqual(root.fillColor, "transparent") ? "#FFD700" : root.fillColor,
                        Qt.colorEqual(root.fillColor2, "transparent") ? "#FFA500" : root.fillColor2,
                        index / (root.barCount - 1)).b,
                0.2
            )
            antialiasing: true
        }
    }
} 