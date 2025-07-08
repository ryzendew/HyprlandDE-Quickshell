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
    property int currentTab: 0
    property var tabButtonList: [
        {"icon": "checklist", "name": qsTr("Active"), "filter": "active"},
        {"icon": "schedule", "name": qsTr("Today"), "filter": "today"},
        {"icon": "upcoming", "name": qsTr("Upcoming"), "filter": "upcoming"},
        {"icon": "check_circle", "name": qsTr("Completed"), "filter": "completed"}
    ]
    property bool showAddDialog: false
    property bool showSearchBar: false
    property string searchQuery: ""
    property string currentFilter: "all"
    property string currentSort: "priority"
    property int dialogMargins: 20
    property int fabSize: 48
    property int fabMargins: 14

    // Filtered and sorted task list
    property var filteredTasks: {
        let tasks = Todo.list.map(function(item, i) { 
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
        // Toggle search on "S"
        else if (event.key === Qt.Key_S && event.modifiers === Qt.ControlModifier) {
            root.showSearchBar = !root.showSearchBar
            if (root.showSearchBar) searchInput.focus = true
            event.accepted = true;
        }
        // Close dialog on Esc if open
        else if (event.key === Qt.Key_Escape) {
            if (root.showAddDialog) {
                root.showAddDialog = false
            } else if (root.showSearchBar) {
                root.showSearchBar = false
                root.searchQuery = ""
            }
            event.accepted = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header with search and actions
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: headerLayout.implicitHeight + 16
            radius: Appearance.rounding.verylarge
            color: Appearance.colors.colLayer1
            border.width: 1
            border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)

            ColumnLayout {
                id: headerLayout
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                // Search bar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: showSearchBar ? 40 : 0
                    radius: Appearance.rounding.verylarge
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)
                    
                    Behavior on Layout.preferredHeight {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        MaterialSymbol {
                            text: "search"
                            iconSize: 16
                            color: Appearance.m3colors.m3outline
                        }

                        TextField {
                            id: searchInput
                            Layout.fillWidth: true
                            placeholderText: qsTr("Search tasks...")
                            text: root.searchQuery
                            onTextChanged: root.searchQuery = text
                            color: Appearance.colors.colOnLayer1
                            background: Rectangle { color: "transparent" }
                            
                            Keys.onEscapePressed: {
                                root.showSearchBar = false
                                root.searchQuery = ""
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
                                radius: Appearance.rounding.full
                                color: parent.pressed ? Qt.rgba(1, 1, 1, 0.2) : 
                                       parent.hovered ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                            }
                            contentItem: MaterialSymbol {
                                text: "close"
                                iconSize: 14
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                    }
                }

                // Replace the tab bar with a ComboBox dropdown for filter selection
                ComboBox {
                    id: filterDropdown
                    Layout.topMargin: 12
                    Layout.bottomMargin: 12
                    Layout.preferredWidth: 180
                    model: root.tabButtonList
                    textRole: "name"
                    currentIndex: currentTab
                    onCurrentIndexChanged: currentTab = currentIndex
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    font.family: "Inter, Arial, Segoe UI, sans-serif"
                    background: Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.verylarge
                        color: Appearance.colors.colLayer1
                        border.width: 1
                        border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)
                    }
                    contentItem: StyledText {
                        text: filterDropdown.displayText
                        color: "#fff"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        font.family: "Inter, Arial, Segoe UI, sans-serif"
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        leftPadding: 16
                    }
                    indicator: MaterialSymbol {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "expand_more"
                        iconSize: 20
                        color: "#fff"
                        rightPadding: 12
                    }
                    popup: Popup {
                        y: filterDropdown.height
                        width: filterDropdown.width
                        background: Rectangle {
                            color: "#18171c"
                            radius: 14
                        }
                        ListView {
                            implicitHeight: contentHeight
                            model: filterDropdown.delegateModel
                            currentIndex: filterDropdown.highlightedIndex
                            clip: true
                            delegate: ItemDelegate {
                                width: filterDropdown.width
                                background: Rectangle {
                                    color: highlighted ? "#333" : "transparent"
                                    radius: 14
                                }
                                contentItem: StyledText {
                                    text: model.name
                                    color: "#fff"
                                    font.pixelSize: 16
                                    font.weight: Font.Bold
                                    font.family: "Inter, Arial, Segoe UI, sans-serif"
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 16
                                }
                            }
                        }
                    }
                }

                // Sort and filter controls
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Sort dropdown
                    ComboBox {
                        id: sortComboBox
                        Layout.preferredWidth: 120
                        model: [
                            {"text": qsTr("Priority"), "value": "priority"},
                            {"text": qsTr("Due Date"), "value": "dueDate"},
                            {"text": qsTr("Name"), "value": "name"}
                        ]
                        textRole: "text"
                        currentIndex: 0
                        onCurrentIndexChanged: {
                            root.currentSort = model[currentIndex].value
                        }
                        
                        background: Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.small
                            color: Appearance.colors.colLayer2
                            border.width: 1
                            border.color: Appearance.m3colors.m3outline
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Search toggle button
                    Button {
                        onClicked: root.showSearchBar = !root.showSearchBar
                        background: Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.full
                            color: parent.pressed ? Qt.rgba(1, 1, 1, 0.2) : 
                                   parent.hovered ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                        }
                        contentItem: MaterialSymbol {
                            text: "search"
                            iconSize: 16
                            color: Appearance.colors.colOnLayer1
                        }
                    }

                    // Add task button
                    Button {
                        onClicked: root.showAddDialog = true
                        background: Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.full
                            color: parent.pressed ? Qt.rgba(1, 1, 1, 0.2) : 
                                   parent.hovered ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                        }
                        contentItem: MaterialSymbol {
                            text: "add"
                            iconSize: 16
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                }
            }
        }

        // Task list content
        SwipeView {
            id: swipeView
            Layout.topMargin: 12
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10
            clip: true
            currentIndex: currentTab
            onCurrentIndexChanged: {
                currentTab = currentIndex
            }

            // All tabs use the same TaskList with different filters
            Repeater {
                model: root.tabButtonList
                delegate: EnhancedTaskList {
                    listBottomPadding: root.fabSize + root.fabMargins * 2
                    emptyPlaceholderIcon: modelData.icon
                    emptyPlaceholderText: getEmptyText(modelData.filter)
                    taskList: root.filteredTasks
                    showProgress: index === 3 // Show progress for completed tasks
                }
            }
        }
    }

    // Helper functions
    function getTaskCount(filter) {
        let tasks = Todo.list
        if (filter === "active") {
            return tasks.filter(item => !item.done).length
        } else if (filter === "today") {
            const today = new Date().toISOString().split('T')[0]
            return tasks.filter(item => !item.done && item.dueDate === today).length
        } else if (filter === "upcoming") {
            const today = new Date().toISOString().split('T')[0]
            return tasks.filter(item => !item.done && item.dueDate && item.dueDate > today).length
        } else if (filter === "completed") {
            return tasks.filter(item => item.done).length
        }
        return tasks.length
    }

    function getEmptyText(filter) {
        if (filter === "active") return qsTr("No active tasks")
        if (filter === "today") return qsTr("No tasks due today")
        if (filter === "upcoming") return qsTr("No upcoming tasks")
        if (filter === "completed") return qsTr("No completed tasks")
        return qsTr("No tasks")
    }

    // Enhanced Add Task Dialog
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

        onVisibleChanged: {
            if (!visible) {
                resetDialog()
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

        Rectangle { // Enhanced Dialog
            id: enhancedDialog
            anchors.centerIn: parent
            width: Math.min(parent.width - 40, 500)
            height: dialogContent.implicitHeight + 40
            radius: Appearance.rounding.large
            color: Appearance.colors.colLayer1
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.1)

            layer.enabled: true
            layer.effect: MultiEffect {
                source: enhancedDialog
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.3)
                shadowBlur: 20
                shadowVerticalOffset: 10
            }

            ColumnLayout {
                id: dialogContent
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: Appearance.rounding.medium
                        color: Appearance.m3colors.m3primaryContainer

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "add_task"
                            iconSize: 20
                            color: Appearance.m3colors.m3onPrimaryContainer
                        }
                    }

                    StyledText {
                        text: qsTr("Add New Task")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer1
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        onClicked: root.showAddDialog = false
                        background: Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.full
                            color: parent.pressed ? Qt.rgba(1, 1, 1, 0.2) : 
                                   parent.hovered ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                        }
                        contentItem: MaterialSymbol {
                            text: "close"
                            iconSize: 16
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                }

                // Task description
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    StyledText {
                        text: qsTr("Description")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.m3colors.m3outline
                    }

                    TextField {
                        id: enhancedTaskInput
                        Layout.fillWidth: true
                        placeholderText: qsTr("What needs to be done?")
                        color: Appearance.colors.colOnLayer1
                        font.pixelSize: Appearance.font.pixelSize.normal
                        background: Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.medium
                            border.width: 2
                            border.color: enhancedTaskInput.activeFocus ? 
                                         Appearance.m3colors.m3primary : 
                                         Appearance.m3colors.m3outline
                            color: "transparent"
                        }
                        onAccepted: addEnhancedTask()
                    }
                }

                // Due date and priority row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // Due date
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        StyledText {
                            text: qsTr("Due Date")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.m3colors.m3outline
                        }

                        TextField {
                            id: enhancedDueDateInput
                            Layout.fillWidth: true
                            placeholderText: qsTr("YYYY-MM-DD")
                            inputMask: "0000-00-00;_"
                            color: Appearance.colors.colOnLayer1
                            background: Rectangle {
                                anchors.fill: parent
                                radius: Appearance.rounding.medium
                                border.width: 2
                                border.color: enhancedDueDateInput.activeFocus ? 
                                             Appearance.m3colors.m3primary : 
                                             Appearance.m3colors.m3outline
                                color: "transparent"
                            }
                        }
                    }

                    // Priority
                    ColumnLayout {
                        Layout.preferredWidth: 120
                        spacing: 4

                        StyledText {
                            text: qsTr("Priority")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.m3colors.m3outline
                        }

                        ComboBox {
                            id: enhancedPriorityInput
                            Layout.fillWidth: true
                            model: [
                                {"text": qsTr("Low"), "value": "low", "color": "#4CAF50"},
                                {"text": qsTr("Medium"), "value": "medium", "color": "#FF9800"},
                                {"text": qsTr("High"), "value": "high", "color": "#F44336"}
                            ]
                            textRole: "text"
                            currentIndex: 1
                            
                            background: Rectangle {
                                anchors.fill: parent
                                radius: Appearance.rounding.medium
                                border.width: 2
                                border.color: enhancedPriorityInput.activeFocus ? 
                                             Appearance.m3colors.m3primary : 
                                             Appearance.m3colors.m3outline
                                color: "transparent"
                            }

                            contentItem: RowLayout {
                                spacing: 8
                                Rectangle {
                                    Layout.preferredWidth: 8
                                    Layout.preferredHeight: 8
                                    radius: 4
                                    color: enhancedPriorityInput.model[enhancedPriorityInput.currentIndex].color
                                }
                                StyledText {
                                    text: enhancedPriorityInput.displayText
                                    color: Appearance.colors.colOnLayer1
                                }
                            }
                        }
                    }
                }

                // Categories
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    StyledText {
                        text: qsTr("Categories (comma separated)")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.m3colors.m3outline
                    }

                    TextField {
                        id: enhancedCategoriesInput
                        Layout.fillWidth: true
                        placeholderText: qsTr("work, personal, urgent")
                        color: Appearance.colors.colOnLayer1
                        background: Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.medium
                            border.width: 2
                            border.color: enhancedCategoriesInput.activeFocus ? 
                                         Appearance.m3colors.m3primary : 
                                         Appearance.m3colors.m3outline
                            color: "transparent"
                        }
                    }
                }

                // Action buttons
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    spacing: 8

                    Item { Layout.fillWidth: true }

                    Button {
                        text: qsTr("Cancel")
                        onClicked: root.showAddDialog = false
                        background: Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.medium
                            color: parent.pressed ? Qt.rgba(1, 1, 1, 0.2) : 
                                   parent.hovered ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                        }
                    }

                    Button {
                        text: qsTr("Add Task")
                        enabled: enhancedTaskInput.text.trim().length > 0
                        onClicked: addEnhancedTask()
                        background: Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.medium
                            color: parent.enabled ? 
                                   (parent.pressed ? Appearance.m3colors.m3primaryContainer : 
                                    parent.hovered ? Appearance.m3colors.m3primaryContainer : 
                                    Appearance.m3colors.m3primary) : 
                                   Appearance.m3colors.m3outline
                        }
                        contentItem: StyledText {
                            text: parent.text
                            color: parent.enabled ? 
                                   Appearance.m3colors.m3onPrimary : 
                                   Appearance.m3colors.m3onSurfaceVariant
                        }
                    }
                }
            }
        }
    }

    function addEnhancedTask() {
        if (enhancedTaskInput.text.trim().length > 0) {
            Todo.addTask(
                enhancedTaskInput.text.trim(),
                enhancedDueDateInput.text || null,
                enhancedPriorityInput.model[enhancedPriorityInput.currentIndex].value,
                enhancedCategoriesInput.text.split(",").map(x => x.trim()).filter(x => x)
            )
            resetDialog()
            root.showAddDialog = false
            root.currentTab = 0 // Show active tasks
        }
    }

    function resetDialog() {
        enhancedTaskInput.text = ""
        enhancedDueDateInput.text = ""
        enhancedPriorityInput.currentIndex = 1
        enhancedCategoriesInput.text = ""
    }
}
