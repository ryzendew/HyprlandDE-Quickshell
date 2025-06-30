pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common"
import Quickshell;
import Quickshell.Io;
import Qt.labs.platform
import QtQuick;

/**
 * Simple to-do list manager.
 * Each item is an object with "content" and "done" properties.
 */
Singleton {
    id: root
    property var filePath: Directories.todoPath
    property var list: []
    
    function addItem(item) {
        list.push(item)
        // Reassign to trigger onListChanged
        root.list = list.slice(0)
        todoFileView.setText(JSON.stringify(root.list))
    }

    function addTask(desc) {
        const item = {
            "content": desc,
            "done": false,
        }
        addItem(item)
    }

    function markDone(index) {
        if (index >= 0 && index < list.length) {
            list[index].done = true
            // Reassign to trigger onListChanged
            root.list = list.slice(0)
            todoFileView.setText(JSON.stringify(root.list))
        }
    }

    function markUnfinished(index) {
        if (index >= 0 && index < list.length) {
            list[index].done = false
            // Reassign to trigger onListChanged
            root.list = list.slice(0)
            todoFileView.setText(JSON.stringify(root.list))
        }
    }

    function deleteItem(index) {
        if (index >= 0 && index < list.length) {
            list.splice(index, 1)
            // Reassign to trigger onListChanged
            root.list = list.slice(0)
            todoFileView.setText(JSON.stringify(root.list))
        }
    }

    function refresh() {
        todoFileView.reload()
    }

    function initializeWithSampleTasks() {
        if (list.length === 0) {
            addTask("Welcome to your todo list!")
            addTask("Click the + button to add new tasks")
            addTask("Click the checkmark to mark tasks as done")
            addTask("Click the trash icon to delete tasks")
        }
    }

    Component.onCompleted: {
        refresh()
        // Initialize with sample tasks after a short delay to ensure file is loaded
        Qt.callLater(initializeWithSampleTasks, 1000)
    }

    FileView {
        id: todoFileView
        path: Qt.resolvedUrl(root.filePath)
        onLoaded: {
            try {
                const fileContents = todoFileView.text()
                if (fileContents && fileContents.trim() !== '') {
                    const parsed = JSON.parse(fileContents)
                    if (Array.isArray(parsed)) {
                        root.list = parsed
                    } else {
                        console.log("[To Do] Invalid data format, creating new list")
                        root.list = []
                        todoFileView.setText(JSON.stringify(root.list))
                    }
                } else {
                    console.log("[To Do] Empty file, creating new list")
                    root.list = []
                    todoFileView.setText(JSON.stringify(root.list))
                }
                console.log("[To Do] File loaded successfully")
            } catch (e) {
                console.log("[To Do] Error parsing JSON, creating new list:", e)
                root.list = []
                todoFileView.setText(JSON.stringify(root.list))
            }
        }
        onLoadFailed: (error) => {
            if(error == FileViewError.FileNotFound) {
                console.log("[To Do] File not found, creating new file.")
                root.list = []
                todoFileView.setText(JSON.stringify(root.list))
            } else {
                console.log("[To Do] Error loading file: " + error)
                root.list = []
            }
        }
    }
}

