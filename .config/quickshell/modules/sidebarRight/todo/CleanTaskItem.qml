import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property var taskData
    property bool pendingDoneToggle: false
    property bool pendingDelete: false
    property bool enableHeightAnimation: false

    Layout.fillWidth: true
    implicitHeight: card.implicitHeight + 8
    height: implicitHeight
    clip: true

    Behavior on implicitHeight {
        enabled: enableHeightAnimation
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    function startAction() {
        enableHeightAnimation = true
        root.implicitHeight = 0
        actionTimer.start()
    }

    Timer {
        id: actionTimer
        interval: 180
        repeat: false
        onTriggered: {
            if (root.pendingDelete) {
                Todo.deleteItem(taskData.originalIndex)
            } else if (root.pendingDoneToggle) {
                if (!taskData.done) Todo.markDone(taskData.originalIndex)
                else Todo.markUnfinished(taskData.originalIndex)
            }
        }
    }

    Rectangle {
        id: card
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 4
        implicitHeight: contentRow.implicitHeight + 16
        radius: 10
        color: Qt.rgba(1, 1, 1, 0.12)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.2)
        opacity: root.enabled ? 1 : 0.7

        RowLayout {
            id: contentRow
            anchors.fill: parent
            anchors.margins: Math.max(8, parent.width * 0.012) // Reduced margins
            spacing: Math.max(8, parent.width * 0.01) // Reduced spacing
            Layout.alignment: Qt.AlignVCenter

            // Checkbox
            Rectangle {
                id: checkCircle
                Layout.preferredWidth: Math.max(20, parent.height * 0.25) // Reduced size
                Layout.preferredHeight: Math.max(20, parent.height * 0.25) // Reduced size
                radius: 12
                color: taskData.done ? Qt.rgba(1, 1, 1, 0.3) : "transparent"
                border.width: 2
                border.color: taskData.done ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(1, 1, 1, 0.3)
                anchors.verticalCenter: parent.verticalCenter
                Layout.alignment: Qt.AlignVCenter

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "check"
                    iconSize: Math.max(12, parent.height * 0.15) // Reduced icon size
                    color: "#FFFFFF"
                    visible: taskData.done
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.pendingDoneToggle = true
                        root.startAction()
                    }
                }
            }

            // Task text
            Text {
                id: taskTitle
                Layout.fillWidth: true
                text: taskData && taskData.content ? taskData.content : "NO CONTENT"
                font.pixelSize: Math.max(Appearance.font.pixelSize.medium, parent.height * 0.08) // Reduced font size
                font.weight: Font.Bold
                color: "#FFFFFF"
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                clip: false
            }

            // Priority indicator (if high priority)
            Rectangle {
                visible: taskData.priority === "high"
                Layout.preferredWidth: Math.max(6, parent.height * 0.08) // Reduced size
                Layout.preferredHeight: Math.max(6, parent.height * 0.08) // Reduced size
                radius: 3
                color: "#FF6B6B"
                anchors.verticalCenter: parent.verticalCenter
                Layout.alignment: Qt.AlignVCenter
            }

            // Delete button
            Rectangle {
                Layout.preferredWidth: Math.max(16, parent.height * 0.2) // Reduced size
                Layout.preferredHeight: Math.max(16, parent.height * 0.2) // Reduced size
                radius: 4
                color: deleteButton.pressed ? Qt.rgba(1, 1, 1, 0.3) : 
                       deleteButton.hovered ? Qt.rgba(1, 1, 1, 0.2) : "transparent"
                anchors.verticalCenter: parent.verticalCenter
                Layout.alignment: Qt.AlignVCenter

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "close"
                    iconSize: Math.max(10, parent.height * 0.12) // Reduced icon size
                    color: Qt.rgba(1, 1, 1, 0.6)
                }

                MouseArea {
                    id: deleteButton
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.pendingDelete = true
                        root.startAction()
                    }
                }
            }
        }
    }
} 