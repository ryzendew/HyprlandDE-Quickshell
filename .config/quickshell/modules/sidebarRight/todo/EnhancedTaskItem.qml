import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root
    required property var taskData
    property int cardRadius: 18
    property int cardPadding: 20
    property int cardSpacing: 16
    property bool pendingDoneToggle: false
    property bool pendingDelete: false
    property bool enableHeightAnimation: false
    property bool hovered: false

    Layout.fillWidth: true
    implicitHeight: card.implicitHeight + cardSpacing
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
        anchors.margins: 8 // spacing between cards
        implicitHeight: contentRow.implicitHeight + cardPadding * 2
        radius: Appearance.rounding.large // modern, not pill
        color: Appearance.m3colors.m3surfaceContainer
        border.width: 1
        border.color: Appearance.m3colors.m3outline
        opacity: root.enabled ? 1 : 0.95
        z: hovered ? 2 : 1
        y: hovered ? -2 : 0
        layer.enabled: true
        layer.effect: MultiEffect {
            source: card
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, hovered ? 0.18 : 0.10)
            shadowBlur: hovered ? 24 : 12
            shadowVerticalOffset: hovered ? 6 : 2
        }
        clip: false
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: root.hovered = true
            onExited: root.hovered = false
        }
        RowLayout {
            id: contentRow
            anchors.fill: parent
            anchors.margins: cardPadding
            spacing: 18
            Layout.alignment: Qt.AlignVCenter
            // Checkbox
            Rectangle {
                id: checkCircle
                width: 32; height: 32
                radius: 16
                color: taskData.done ? Appearance.m3colors.m3primary : Appearance.m3colors.m3surfaceContainer
                border.width: 2
                border.color: taskData.done ? Appearance.m3colors.m3primary : Appearance.m3colors.m3outline
                Layout.alignment: Qt.AlignVCenter
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "check"
                    iconSize: 20
                    color: taskData.done ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3outline
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
                text: taskData.content
                font.pixelSize: 20
                font.bold: true
                color: "#fff"
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                leftPadding: 8
                clip: false
            }
        }
    }
} 