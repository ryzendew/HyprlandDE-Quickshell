import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/Data" as Data

// Simple theme toggle button with hover feedback
Rectangle {
    id: root
    property var shell: null
    color: Qt.darker(Data.Colors.bgColor, 1.15)
    radius: 20

    property bool containsMouse: themeMouseArea.containsMouse
    property bool menuJustOpened: false

    signal entered()
    signal exited()

    // Hover state management for parent components
    onContainsMouseChanged: {
        if (containsMouse) {
            entered()
        } else if (!menuJustOpened) {
            exited()
        }
    }

    MouseArea {
        id: themeMouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            Data.Colors.toggleTheme()
        }
    }

    // Theme toggle icon with color feedback
    Label {
        anchors.centerIn: parent
        text: "contrast"
        font.pixelSize: 24
        font.family: "Material Symbols Outlined"
        color: containsMouse ? Data.Colors.accentColor : Data.Colors.fgColor
    }
} 