import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: wrapper
    property alias contentItem: contentItem
    property color borderColor: "#444"
    property color backgroundColor: "#23242a"
    property int borderWidth: 1
    property int radiusValue: 10
    property int margin: 8

    color: backgroundColor
    border.color: borderColor
    border.width: borderWidth
    radius: radiusValue
    anchors.margins: margin

    // Content goes here
    Item {
        id: contentItem
        anchors.fill: parent
        anchors.margins: 10
    }
} 