import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: parent ? parent.height * 0.6 : 600
    Layout.fillHeight: false
    property int currentTab: 0
    property var tabButtonList: [
        {"icon": "checklist", "name": qsTr("Active"), "filter": "active"},
        {"icon": "schedule", "name": qsTr("Today"), "filter": "today"},
        {"icon": "upcoming", "name": qsTr("Upcoming"), "filter": "upcoming"},
        {"icon": "check_circle", "name": qsTr("Completed"), "filter": "completed"}
    ]
    property bool showAddDialog: false
    property string searchQuery: ""
    property string currentFilter: "all"
    property string currentSort: "priority"

    // Filtered and sorted task list
    property var filteredTasks: {
        console.log("[TodoWidget] Total tasks:", Todo.list.length)
        let tasks = Todo.list
            .filter(item => item && typeof item.content === 'string' && item.content.trim() !== "")
            .map(function(item, i) { 
                return Object.assign({}, item, {originalIndex: i}); 
            })
        
        // Apply search filter
        if (searchQuery.length > 0) {
            const query = searchQuery.toLowerCase()
            tasks = tasks.filter(function(item) {
                return item.content.toLowerCase().includes(query) ||
                       (item.categories && item.categories.some(cat => cat.toLowerCase().includes(query)))
            })
        }
        
        // Apply tab filter
        if (currentTab === 0) { // Active
            tasks = tasks.filter(function(item) { return !item.done; })
        } else if (currentTab === 1) { // Today
            const today = new Date().toISOString().split('T')[0]
            tasks = tasks.filter(function(item) { 
                return !item.done && item.dueDate === today; 
            })
        } else if (currentTab === 2) { // Upcoming
            const today = new Date().toISOString().split('T')[0]
            tasks = tasks.filter(function(item) { 
                return !item.done && item.dueDate && item.dueDate > today; 
            })
        } else if (currentTab === 3) { // Completed
            tasks = tasks.filter(function(item) { return item.done; })
        }
        
        // Apply sorting
        tasks.sort(function(a, b) {
            if (currentSort === "priority") {
                const priorityOrder = {high: 3, medium: 2, low: 1}
                const aPriority = priorityOrder[a.priority] || 2
                const bPriority = priorityOrder[b.priority] || 2
                if (aPriority !== bPriority) return bPriority - aPriority
            } else if (currentSort === "dueDate") {
                if (a.dueDate && b.dueDate) {
                    return new Date(a.dueDate) - new Date(b.dueDate)
                } else if (a.dueDate) return -1
                else if (b.dueDate) return 1
            }
            return a.content.localeCompare(b.content)
        })
        
        return tasks
    }

    Keys.onPressed: (event) => {
        if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) && event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageDown) {
                currentTab = Math.min(currentTab + 1, root.tabButtonList.length - 1)
            } else if (event.key === Qt.Key_PageUp) {
                currentTab = Math.max(currentTab - 1, 0)
            }
            event.accepted = true;
        }
        // Open add dialog on "N" (any modifiers)
        else if (event.key === Qt.Key_N) {
            root.showAddDialog = true
            event.accepted = true;
        }
        // Close dialog on Esc if open
        else if (event.key === Qt.Key_Escape) {
            if (root.showAddDialog) {
                root.showAddDialog = false
            }
            event.accepted = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // Clean Header with title and add button
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            radius: 12
            color: Qt.rgba(1, 1, 1, 0.1)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.2)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12
                Layout.alignment: Qt.AlignVCenter

                // Title
                Text {
                    text: qsTr("Tasks")
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    color: "#FFFFFF"
                    verticalAlignment: Text.AlignVCenter
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                // Tab buttons
                RowLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter

                    Repeater {
                        model: root.tabButtonList
                        delegate: Rectangle {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            radius: 6
                            color: currentTab === index ? Qt.rgba(1, 1, 1, 0.3) : "transparent"
                            border.width: 1
                            border.color: currentTab === index ? Qt.rgba(1, 1, 1, 0.4) : Qt.rgba(1, 1, 1, 0.2)
                            Layout.alignment: Qt.AlignVCenter

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: modelData.icon
                                iconSize: 16
                                color: "#FFFFFF"
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: currentTab = index
                            }
                        }
                    }
                }

                // Add button
                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 8
                    color: addButton.pressed ? Qt.rgba(1, 1, 1, 0.3) : 
                           addButton.hovered ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.3)
                    Layout.alignment: Qt.AlignVCenter

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "add"
                        iconSize: 18
                        color: "#FFFFFF"
                    }

                    MouseArea {
                        id: addButton
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.showAddDialog = true
                    }
                }
            }
        }

        // Search bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: 10
            color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.15)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                MaterialSymbol {
                    text: "search"
                    iconSize: 16
                    color: "#FFFFFF"
                    opacity: 0.7
                    Layout.alignment: Qt.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                }

                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    placeholderText: qsTr("Search tasks...")
                    text: root.searchQuery
                    onTextChanged: root.searchQuery = text
                    color: "#FFFFFF"
                    font.pixelSize: 14
                    background: Rectangle { color: "transparent" }
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.5)
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    Keys.onEscapePressed: {
                        root.searchQuery = ""
                        text = ""
                    }
                }

                Button {
                    visible: root.searchQuery.length > 0
                    onClicked: {
                        root.searchQuery = ""
                        searchInput.text = ""
                    }
                    background: Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: parent.pressed ? Qt.rgba(1, 1, 1, 0.2) : 
                               parent.hovered ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                    }
                    contentItem: MaterialSymbol {
                        text: "close"
                        iconSize: 14
                        color: "#FFFFFF"
                        Layout.alignment: Qt.AlignVCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        // Task list content
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.1)

            Flickable {
                id: flickable
                anchors.fill: parent
                anchors.margins: 8
                contentHeight: taskColumn.height
                clip: true

                ColumnLayout {
                    id: taskColumn
                    width: parent.width
                    spacing: 8

                    // Empty state
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: 200
                        visible: filteredTasks.length === 0

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 12

                            MaterialSymbol {
                                text: root.tabButtonList[currentTab].icon
                                iconSize: 48
                                color: "#FFFFFF"
                                opacity: 0.3
                            }

                            Text {
                                text: getEmptyText(root.tabButtonList[currentTab].filter)
                                font.pixelSize: 16
                                color: "#FFFFFF"
                                opacity: 0.6
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    // Task items
                    Repeater {
                        model: filteredTasks
                        delegate: CleanTaskItem {
                            taskData: modelData
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }

    // Helper functions
    function getEmptyText(filter) {
        if (filter === "active") return qsTr("No active tasks")
        if (filter === "today") return qsTr("No tasks due today")
        if (filter === "upcoming") return qsTr("No upcoming tasks")
        if (filter === "completed") return qsTr("No completed tasks")
        return qsTr("No tasks")
    }

    // Simple Add Task Dialog
    Item {
        anchors.fill: parent
        z: 9999
        visible: opacity > 0
        opacity: root.showAddDialog ? 1 : 0
        
        Behavior on opacity {
            NumberAnimation { 
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        Rectangle { // Scrim
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.6)
            MouseArea {
                anchors.fill: parent
                onClicked: root.showAddDialog = false
            }
        }

        Rectangle { // Dialog
            anchors.centerIn: parent
            width: 400
            height: 280
            radius: 16
            color: "#23232A"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.2)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 18
                Layout.alignment: Qt.AlignVCenter

                // Title
                Text {
                    text: qsTr("Add New Task")
                    font.pixelSize: 20
                    font.weight: Font.Bold
                    color: "#FFFFFF"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                }

                // Task Description
                TextField {
                    id: newTaskInput
                    Layout.fillWidth: true
                    placeholderText: qsTr("Enter task description...")
                    color: "#FFFFFF"
                    font.pixelSize: 15
                    background: Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.18)
                    }
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.5)
                }

                // Priority Dropdown
                ComboBox {
                    id: priorityCombo
                    Layout.fillWidth: true
                    model: [qsTr("Low"), qsTr("Medium"), qsTr("High")]
                    currentIndex: 1
                    contentItem: Text {
                        text: priorityCombo.displayText
                        color: Appearance.m3colors.m3onSurface
                        font.pixelSize: 15
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        anchors.verticalCenter: parent.verticalCenter
                        leftPadding: 8
                    }
                    delegate: ItemDelegate {
                        width: priorityCombo.width
                        background: Rectangle {
                            color: Appearance.m3colors.m3surfaceContainer
                            radius: 10
                        }
                        contentItem: Text {
                            text: modelData
                            color: Appearance.m3colors.m3onSurface
                            font.pixelSize: 15
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            leftPadding: 8
                        }
                    }
                    background: Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: Appearance.m3colors.m3surfaceContainer
                        border.width: 1
                        border.color: Appearance.m3colors.m3outlineVariant
                    }
                    popup: Popup {
                        y: priorityCombo.height
                        width: priorityCombo.width
                        implicitHeight: contentItem.implicitHeight
                        background: Rectangle {
                            color: Appearance.m3colors.m3surfaceContainer
                            radius: 12
                        }
                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: priorityCombo.delegateModel
                            currentIndex: priorityCombo.highlightedIndex
                            delegate: priorityCombo.delegate
                        }
                    }
                }

                // Due Date
                TextField {
                    id: dueDateInput
                    Layout.fillWidth: true
                    placeholderText: qsTr("YYYY-MM-DD (Due date)")
                    color: "#FFFFFF"
                    font.pixelSize: 15
                    background: Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.18)
                    }
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.5)
                }

                // Buttons
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 18
                    Button {
                        text: qsTr("Cancel")
                        onClicked: root.showAddDialog = false
                        background: Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: parent.pressed ? Qt.rgba(1, 1, 1, 0.18) : parent.hovered ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.18)
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "#FFFFFF"
                            font.pixelSize: 15
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                    Button {
                        text: qsTr("Add")
                        onClicked: {
                            if (newTaskInput.text.trim()) {
                                var priority = ["low", "medium", "high"][priorityCombo.currentIndex]
                                var dueDate = dueDateInput.text.trim() || null
                                Todo.addTask(newTaskInput.text.trim(), dueDate, priority)
                                newTaskInput.text = ""
                                dueDateInput.text = ""
                                priorityCombo.currentIndex = 1
                                root.showAddDialog = false
                            }
                        }
                        background: Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: parent.pressed ? Qt.rgba(1, 1, 1, 0.25) : parent.hovered ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.12)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.18)
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "#FFFFFF"
                            font.pixelSize: 15
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        if (showAddDialog) {
            newTaskInput.focus = true
        }
    }
}
