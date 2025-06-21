import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "root:/Data" as Data

// Notification history viewer
Item {
    id: root
    implicitHeight: 400

    required property var shell
    property bool hovered: false
    property real targetX: 0

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header with title, count, and clear all button
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            spacing: 8

            Text {
                text: "Notification History"
                color: Data.Colors.accentColor
                font.pixelSize: 18
                font.bold: true
                font.family: "FiraCode Nerd Font"
            }

            Text {
                text: "(" + (shell.notificationHistory ? shell.notificationHistory.count : 0) + ")"
                color: Data.Colors.fgColor
                font.pixelSize: 12
                opacity: 0.7
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                visible: shell.notificationHistory && shell.notificationHistory.count > 0
                width: clearText.implicitWidth + 16
                height: 24
                radius: 12
                color: clearMouseArea.containsMouse ? Qt.rgba(Data.Colors.accentColor.r, Data.Colors.accentColor.g, Data.Colors.accentColor.b, 0.2) : "transparent"
                border.color: Data.Colors.accentColor
                border.width: 1

                Text {
                    id: clearText
                    anchors.centerIn: parent
                    text: "Clear All"
                    color: Data.Colors.accentColor
                    font.pixelSize: 11
                }

                MouseArea {
                    id: clearMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: shell.notificationHistory.clear()
                }
            }
        }

        // Scrollable notification list
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ScrollView {
                id: scrollView
                anchors.fill: parent
                clip: true
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    interactive: true
                    visible: notificationListView.contentHeight > notificationListView.height
                    contentItem: Rectangle {
                        implicitWidth: 6
                        radius: width / 2
                        color: parent.pressed ? Data.Colors.accentColor 
                             : parent.hovered ? Qt.lighter(Data.Colors.accentColor, 1.2)
                             : Qt.rgba(Data.Colors.accentColor.r, Data.Colors.accentColor.g, Data.Colors.accentColor.b, 0.7)
                    }
                }
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ListView {
                    id: notificationListView
                    model: shell.notificationHistory
                    spacing: 12
                    cacheBuffer: 50  // Memory optimization
                    reuseItems: true
                    boundsBehavior: Flickable.StopAtBounds
                    maximumFlickVelocity: 2500
                    flickDeceleration: 1500
                    clip: true
                    interactive: true

                    // Smooth scrolling behavior
                    property real targetY: contentY
                    Behavior on targetY {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutQuad
                        }
                    }

                    onTargetYChanged: {
                        if (!moving && !dragging) {
                            contentY = targetY
                        }
                    }

                    delegate: Rectangle {
                        width: notificationListView.width
                        height: Math.max(80, contentLayout.implicitHeight + 24)
                        radius: 8
                        color: mouseArea.containsMouse ? Qt.darker(Data.Colors.bgColor, 1.15) : Qt.darker(Data.Colors.bgColor, 1.1)
                        border.color: Data.Colors.accentColor
                        border.width: 1

                        // View optimization - only render visible items
                        visible: y + height > notificationListView.contentY - height && 
                                y < notificationListView.contentY + notificationListView.height + height

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                        }

                        // Main notification content layout
                        RowLayout {
                            id: contentLayout
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            // App icon area
                            Item {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                Layout.alignment: Qt.AlignTop

                                Image {
                                    width: 24
                                    height: 24
                                    source: model.icon || ""
                                    visible: source.toString() !== ""
                                }
                            }

                            // Notification text content
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 6

                                // App name and timestamp row
                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        Layout.fillWidth: true
                                        text: model.appName || "Unknown"
                                        color: Data.Colors.accentColor
                                        font.pixelSize: 13
                                        font.bold: true
                                    }

                                    Text {
                                        text: Qt.formatDateTime(model.timestamp, "hh:mm")
                                        color: Data.Colors.fgColor
                                        font.pixelSize: 10
                                        opacity: 0.7
                                    }
                                }

                                // Notification summary
                                Text {
                                    Layout.fillWidth: true
                                    visible: model.summary && model.summary.length > 0
                                    text: model.summary || ""
                                    color: Data.Colors.fgColor
                                    font.pixelSize: 13
                                    font.bold: true
                                    wrapMode: Text.WordWrap
                                    lineHeight: 1.2
                                }

                                // Notification body text
                                Text {
                                    Layout.fillWidth: true
                                    visible: model.body && model.body.length > 0
                                    text: model.body || ""
                                    color: Data.Colors.fgColor
                                    font.pixelSize: 12
                                    opacity: 0.9
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 4
                                    elide: Text.ElideRight
                                    lineHeight: 1.2
                                }
                            }
                        }

                        // Individual delete button
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 12
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            color: deleteArea.containsMouse ? Qt.rgba(255, 0, 0, 0.2) : "transparent"
                            border.color: deleteArea.containsMouse ? "#ff4444" : Data.Colors.fgColor
                            border.width: 1
                            opacity: deleteArea.containsMouse ? 1 : 0.5

                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                color: deleteArea.containsMouse ? "#ff4444" : Data.Colors.fgColor
                                font.pixelSize: 16
                            }

                            MouseArea {
                                id: deleteArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: shell.notificationHistory.remove(model.index)
                            }
                        }
                    }
                }
            }

            // Empty state message
            Text {
                anchors.centerIn: parent
                visible: !notificationListView.count
                text: "No notifications"
                color: Data.Colors.fgColor
                font.pixelSize: 14
                opacity: 0.7
            }
        }
    }
} 