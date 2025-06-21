import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/Data" as Data

Rectangle {
    id: root
    width: 42
    color: Qt.darker(Data.Colors.bgColor, 1.15)
    radius: 12
    z: 2  // Keep it above notification history

    required property bool notificationHistoryVisible
    required property bool clipboardHistoryVisible
    required property var notificationHistory
    signal notificationToggleRequested()
    signal clipboardToggleRequested()

    // Add containsMouse property for panel hover tracking
    property bool containsMouse: notifButtonMouseArea.containsMouse || clipButtonMouseArea.containsMouse

    // Ensure minimum height for buttons even when recording
    property real buttonHeight: 38
    height: buttonHeight * 2 + 4  // 4px spacing between buttons

    Item {
        anchors.fill: parent
        anchors.margins: 2

        // Top pill (Notifications)
        Rectangle {
            id: notificationPill
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                bottom: parent.verticalCenter
                bottomMargin: 2  // Half of the spacing
            }
            radius: 12
            color: notifButtonMouseArea.containsMouse || root.notificationHistoryVisible ? 
                   Qt.rgba(Data.Colors.accentColor.r, Data.Colors.accentColor.g, Data.Colors.accentColor.b, 0.2) : 
                   Qt.rgba(Data.Colors.fgColor.r, Data.Colors.fgColor.g, Data.Colors.fgColor.b, 0.05)
            border.color: notifButtonMouseArea.containsMouse || root.notificationHistoryVisible ? Data.Colors.accentColor : "transparent"
            border.width: 1

            MouseArea {
                id: notifButtonMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.notificationToggleRequested()
            }

            Label {
                anchors.centerIn: parent
                text: "notifications"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 16
                color: notifButtonMouseArea.containsMouse || root.notificationHistoryVisible ? 
                       Data.Colors.accentColor : Data.Colors.fgColor
            }
        }

        // Bottom pill (Clipboard)
        Rectangle {
            id: clipboardPill
            anchors {
                top: parent.verticalCenter
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                topMargin: 2  // Half of the spacing
            }
            radius: 12
            color: clipButtonMouseArea.containsMouse || root.clipboardHistoryVisible ? 
                   Qt.rgba(Data.Colors.accentColor.r, Data.Colors.accentColor.g, Data.Colors.accentColor.b, 0.2) : 
                   Qt.rgba(Data.Colors.fgColor.r, Data.Colors.fgColor.g, Data.Colors.fgColor.b, 0.05)
            border.color: clipButtonMouseArea.containsMouse || root.clipboardHistoryVisible ? Data.Colors.accentColor : "transparent"
            border.width: 1

            MouseArea {
                id: clipButtonMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.clipboardToggleRequested()
            }

            Label {
                anchors.centerIn: parent
                text: "content_paste"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 16
                color: clipButtonMouseArea.containsMouse || root.clipboardHistoryVisible ? 
                       Data.Colors.accentColor : Data.Colors.fgColor
            }
        }
    }
} 