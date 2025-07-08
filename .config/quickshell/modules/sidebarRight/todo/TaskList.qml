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
    property int todoListItemSpacing: 5
    property int todoListItemPadding: 8
    property int listBottomPadding: 80

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

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            spacing: 8
            Item { Layout.fillWidth: true }
            Button {
                text: qsTr("Clear Completed")
                enabled: taskList.some(function(item) { return item.done; })
                onClicked: Todo.clearCompleted()
            }
        }

        ColumnLayout {
            id: columnLayout
            width: parent.width
            spacing: 0
            Repeater {
                model: ScriptModel {
                    values: taskList
                }
                delegate: Item {
                    id: todoItem
                    property bool pendingDoneToggle: false
                    property bool pendingDelete: false
                    property bool enableHeightAnimation: false
                    property bool editing: false
                    property bool showDeleteDialog: false

                    Layout.fillWidth: true
                    implicitHeight: todoItemRectangle.implicitHeight + todoListItemSpacing
                    height: implicitHeight
                    clip: true

                    Behavior on implicitHeight {
                        enabled: enableHeightAnimation
                        NumberAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }

                    function startAction() {
                        enableHeightAnimation = true
                        todoItem.implicitHeight = 0
                        actionTimer.start()
                    }

                    Timer {
                        id: actionTimer
                        interval: Appearance.animation.elementMoveFast.duration
                        repeat: false
                        onTriggered: {
                            if (todoItem.pendingDelete) {
                                Todo.deleteItem(modelData.originalIndex)
                            } else if (todoItem.pendingDoneToggle) {
                                if (!modelData.done) Todo.markDone(modelData.originalIndex)
                                else Todo.markUnfinished(modelData.originalIndex)
                            }
                        }
                    }

                    Rectangle {
                        id: todoItemRectangle
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        implicitHeight: todoContentRowLayout.implicitHeight
                        color: Appearance.colors.colLayer2
                        radius: Appearance.rounding.small
                        ColumnLayout {
                            id: todoContentRowLayout
                            anchors.left: parent.left
                            anchors.right: parent.right

                            StyledText {
                                id: todoContentText
                                Layout.fillWidth: true // Needed for wrapping
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                Layout.topMargin: todoListItemPadding
                                visible: !todoItem.editing
                                text: modelData.content
                                wrapMode: Text.Wrap
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.IBeamCursor
                                    onClicked: todoItem.editing = true
                                }
                            }
                            StyledText {
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                color: Appearance.m3colors.m3outline
                                font.pixelSize: Appearance.font.pixelSize.small
                                text: modelData.dueDate ? (qsTr("Due: ") + Qt.formatDate(new Date(modelData.dueDate), "yyyy-MM-dd")) : ""
                                visible: !!modelData.dueDate
                            }
                            StyledText {
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                color: modelData.priority === 'high' ? "#E53E3E" : modelData.priority === 'low' ? "#4CAF50" : Appearance.m3colors.m3outline
                                font.pixelSize: Appearance.font.pixelSize.small
                                text: modelData.priority ? (qsTr("Priority: ") + modelData.priority.charAt(0).toUpperCase() + modelData.priority.slice(1)) : ""
                                visible: !!modelData.priority
                            }
                            RowLayout {
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                spacing: 4
                                visible: modelData.categories && modelData.categories.length > 0
                                Repeater {
                                    model: modelData.categories || []
                                    delegate: Rectangle {
                                        radius: 6
                                        color: Appearance.m3colors.m3secondaryContainer
                                        height: 20
                                        width: tagText.implicitWidth + 12
                                        StyledText {
                                            id: tagText
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.pixelSize: Appearance.font.pixelSize.xsmall
                                            color: Appearance.m3colors.m3onSecondaryContainer
                                        }
                                    }
                                }
                            }
                            TextField {
                                id: editField
                                Layout.fillWidth: true
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                Layout.topMargin: todoListItemPadding
                                visible: todoItem.editing
                                text: modelData.content
                                selectByMouse: true
                                focus: todoItem.editing
                                onEditingFinished: {
                                    if (editField.text.trim() !== "" && (editField.text !== modelData.content || dueDateEdit.text !== (modelData.dueDate || "") || priorityEdit.currentIndex !== priorityIndex(modelData.priority) || categoriesEdit.text !== (modelData.categories ? modelData.categories.join(",") : ""))) {
                                        Todo.editTask(modelData.originalIndex, editField.text.trim(), dueDateEdit.text, priorityEdit.currentText.toLowerCase(), categoriesEdit.text.split(",").map(x => x.trim()).filter(x => x))
                                    }
                                    todoItem.editing = false
                                }
                                Keys.onReturnPressed: editField.focus = false
                                Keys.onEscapePressed: {
                                    todoItem.editing = false
                                }
                            }
                            TextField {
                                id: dueDateEdit
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                visible: todoItem.editing
                                placeholderText: qsTr("YYYY-MM-DD (Due date)")
                                text: modelData.dueDate || ""
                                inputMask: "0000-00-00;_"
                            }
                            ComboBox {
                                id: priorityEdit
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                visible: todoItem.editing
                                model: [qsTr("Low"), qsTr("Medium"), qsTr("High")]
                                currentIndex: priorityIndex(modelData.priority)
                            }
                            TextField {
                                id: categoriesEdit
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                visible: todoItem.editing
                                placeholderText: qsTr("Tags (comma separated)")
                                text: modelData.categories ? modelData.categories.join(",") : ""
                            }
                            RowLayout {
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                Layout.bottomMargin: todoListItemPadding
                                Item {
                                    Layout.fillWidth: true
                                }
                                TodoItemActionButton {
                                    Layout.fillWidth: false
                                    onClicked: {
                                        todoItem.pendingDoneToggle = true
                                        todoItem.startAction()
                                    }
                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        text: modelData.done ? "remove_done" : "check"
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: "#FFFFFF"
                                    }
                                }
                                TodoItemActionButton {
                                    Layout.fillWidth: false
                                    onClicked: {
                                        todoItem.showDeleteDialog = true
                                    }
                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        text: "delete_forever"
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: "#FFFFFF"
                                    }
                                }
                            }
                        }
                    }
                }

            }
            // Bottom padding
            Item {
                implicitHeight: listBottomPadding
            }
        }
    }
    
    Item { // Placeholder when list is empty
        visible: opacity > 0
        opacity: taskList.length === 0 ? 1 : 0
        anchors.fill: parent

        Behavior on opacity {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 5

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                iconSize: 55
                color: Appearance.m3colors.m3outline
                text: emptyPlaceholderIcon
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.m3colors.m3outline
                horizontalAlignment: Text.AlignHCenter
                text: emptyPlaceholderText
            }
        }
    }

    // Delete confirmation dialog
    Dialog {
        id: deleteDialog
        modal: true
        visible: todoItem.showDeleteDialog
        onAccepted: {
            todoItem.pendingDelete = true
            todoItem.startAction()
            todoItem.showDeleteDialog = false
        }
        onRejected: todoItem.showDeleteDialog = false
        title: qsTr("Delete Task")
        standardButtons: Dialog.Ok | Dialog.Cancel
        contentItem: ColumnLayout {
            spacing: 10
            StyledText {
                text: qsTr("Are you sure you want to delete this task?")
                color: Appearance.m3colors.m3onSurface
            }
        }
    }
}