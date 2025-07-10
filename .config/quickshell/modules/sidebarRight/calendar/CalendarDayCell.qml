import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.15

Item {
    id: root
    property string day: ""
    property bool isToday: false
    property bool isPast: false
    property bool isFuture: false
    property bool isOutOfMonth: false
    property string eventType: "" // "newMoon", "fullMoon", "summerSolstice", "winterSolstice"
    property string tooltip: ""
    width: 40; height: 40

    // Glass background
    Rectangle {
        id: glassBg
        anchors.fill: parent
        radius: 12
        color: isOutOfMonth ? "#00FFFFFF" : isToday ? "#66A3C9FF" : "#33FFFFFF"
        border.color: isToday ? "#FFB4D5FF" : "#33FFFFFF"
        border.width: isToday ? 2 : 1
        opacity: isOutOfMonth ? 0.2 : isPast ? 0.4 : 1.0
        layer.enabled: true
        layer.effect: FastBlur {
            radius: 16
            transparentBorder: true
        }
    }

    // Event icon overlay (emoji)
    Text {
        anchors.centerIn: parent
        font.pixelSize: 20
        visible: eventType !== ""
        text: eventType === "newMoon" ? "🌑"
            : eventType === "fullMoon" ? "🌕"
            : eventType === "summerSolstice" ? "☀️"
            : eventType === "winterSolstice" ? "❄️"
            : ""
        opacity: isOutOfMonth ? 0.2 : 1.0
        z: 2
    }

    // Day number
    Text {
        anchors.centerIn: parent
        text: day
        font.pixelSize: 18
        font.bold: isToday
        color: isOutOfMonth ? "#99FFFFFF" : isToday ? "#FFFAFAFA" : isPast ? "#99FFFFFF" : "#FFFFFFFF"
        opacity: isOutOfMonth ? 0.3 : 1.0
        z: 2
    }

    // Tooltip
    ToolTip.visible: tooltip !== "" && root.containsMouse
    ToolTip.text: tooltip
    ToolTip.delay: 200
    ToolTip.timeout: 2000
} 