import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import QtQuick.Dialogs

Item {
    id: root
    required property var taskList;
    property string emptyPlaceholderIcon
    property string emptyPlaceholderText
    property int taskItemSpacing: 8
    property int taskItemPadding: 12
    property int listBottomPadding: 80
    property bool showProgress: false

    // Progress tracking for completed tasks
    property var progressData: {
        if (!showProgress) return null
        
        const totalTasks = Todo.list.length
        const completedTasks = Todo.list.filter(item => item.done).length
        const today = new Date().toISOString().split('T')[0]
        const todayTasks = Todo.list.filter(item => item.dueDate === today).length
        const completedTodayTasks = Todo.list.filter(item => item.done && item.dueDate === today).length
        
        return {
            total: totalTasks,
            completed: completedTasks,
            today: todayTasks,
            completedToday: completedTodayTasks,
            overallProgress: totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0,
            todayProgress: todayTasks > 0 ? (completedTodayTasks / todayTasks) * 100 : 0
        }
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        contentHeight: columnLayout.height
        clip: true

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: flickable.width
                height: flickable.height
                radius: Appearance.rounding.small
            }
        }

        ColumnLayout {
            id: columnLayout
            width: parent.width
            spacing: 0

            // Progress section for completed tasks
            Rectangle {
                visible: showProgress && progressData
                Layout.fillWidth: true
                Layout.preferredHeight: progressSection.implicitHeight + 16
                radius: Appearance.rounding.medium
                color: Qt.rgba(
                    Appearance.colors.colLayer1.r,
                    Appearance.colors.colLayer1.g,
                    Appearance.colors.colLayer1.b,
                    0.3
                )
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.1)

                ColumnLayout {
                    id: progressSection
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    // Progress header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        MaterialSymbol {
                            text: "analytics"
                            iconSize: 16
                            color: Appearance.m3colors.m3primary
                        }

                        StyledText {
                            text: qsTr("Progress Overview")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }

                        Item { Layout.fillWidth: true }

                        StyledText {
                            text: `${progressData.completed}/${progressData.total}`
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.m3colors.m3outline
                        }
                    }

                    // Overall progress bar
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            StyledText {
                                text: qsTr("Overall")
                                font.pixelSize: Appearance.font.pixelSize.xsmall
                                color: Appearance.m3colors.m3outline
                            }

                            Item { Layout.fillWidth: true }

                            StyledText {
                                text: `${Math.round(progressData.overallProgress)}%`
                                font.pixelSize: Appearance.font.pixelSize.xsmall
                                color: Appearance.m3colors.m3outline
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 6
                            radius: 3
                            color: Appearance.m3colors.m3outlineVariant

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * (progressData.overallProgress / 100)
                                radius: 3
                                color: Appearance.m3colors.m3primary

                                Behavior on width {
                                    NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                                }
                            }
                        }
                    }

                    // Today's progress (if any tasks due today)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: progressData.today > 0

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            StyledText {
                                text: qsTr("Today")
                                font.pixelSize: Appearance.font.pixelSize.xsmall
                                color: Appearance.m3colors.m3outline
                            }

                            Item { Layout.fillWidth: true }

                            StyledText {
                                text: `${progressData.completedToday}/${progressData.today}`
                                font.pixelSize: Appearance.font.pixelSize.xsmall
                                color: Appearance.m3colors.m3outline
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 4
                            radius: 2
                            color: Appearance.m3colors.m3outlineVariant

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * (progressData.todayProgress / 100)
                                radius: 2
                                color: Appearance.m3colors.m3secondary

                                Behavior on width {
                                    NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                                }
                            }
                        }
                    }
                }
            }

            // Clear completed button (only for completed tasks)
            Rectangle {
                visible: showProgress && taskList.some(function(item) { return item.done; })
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                Layout.topMargin: 8
                radius: Appearance.rounding.medium
                color: clearButton.pressed ? Qt.rgba(1, 0, 0, 0.2) : 
                       clearButton.hovered ? Qt.rgba(1, 0, 0, 0.1) : 
                       Qt.rgba(1, 1, 1, 0.05)
                border.width: 1
                border.color: Qt.rgba(1, 0, 0, 0.3)

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    MaterialSymbol {
                        text: "delete_sweep"
                        iconSize: 14
                        color: "#F44336"
                    }

                    StyledText {
                        text: qsTr("Clear Completed")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: "#F44336"
                    }
                }

                MouseArea {
                    id: clearButton
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Todo.clearCompleted()
                }
            }

            // Task list
            Repeater {
                model: ScriptModel {
                    values: taskList
                }
                delegate: EnhancedTaskItem {
                    taskData: modelData
                }
            }

            // Bottom padding
            Item {
                implicitHeight: listBottomPadding
            }
        }
    }
    
    // Enhanced empty state
    Item {
        visible: opacity > 0
        opacity: taskList.length === 0 ? 1 : 0
        anchors.fill: parent

        Behavior on opacity {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16

            Rectangle {
                Layout.preferredWidth: 80
                Layout.preferredHeight: 80
                radius: 40
                color: Qt.rgba(
                    Appearance.m3colors.m3outline.r,
                    Appearance.m3colors.m3outline.g,
                    Appearance.m3colors.m3outline.b,
                    0.1
                )

                MaterialSymbol {
                    anchors.centerIn: parent
                    iconSize: 40
                    color: Appearance.m3colors.m3outline
                    text: emptyPlaceholderIcon
                }
            }

            ColumnLayout {
                spacing: 4

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                    text: emptyPlaceholderText
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.m3colors.m3outline
                    text: showProgress ? qsTr("Great job! All tasks completed.") : qsTr("Add a new task to get started.")
                }
            }
        }
    }
} 