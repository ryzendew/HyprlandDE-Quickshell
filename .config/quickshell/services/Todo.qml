pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common"
import Quickshell;
import Quickshell.Io;
import Qt.labs.platform
import QtQuick;

/**
 * Enhanced to-do list manager with advanced features using .conf file format.
 * Each item is stored as a section in the conf file with properties.
 */
Singleton {
    id: root
    property var filePath: Directories.todoPath
    property var list: []
    
    // Statistics
    property var stats: {
        const total = list.length
        const completed = list.filter(item => item.done).length
        const overdue = list.filter(item => {
            if (item.done || !item.dueDate) return false
            const today = new Date().toISOString().split('T')[0]
            return item.dueDate < today
        }).length
        const dueToday = list.filter(item => {
            if (item.done || !item.dueDate) return false
            const today = new Date().toISOString().split('T')[0]
            return item.dueDate === today
        }).length
        
        return {
            total: total,
            completed: completed,
            overdue: overdue,
            dueToday: dueToday,
            completionRate: total > 0 ? (completed / total) * 100 : 0
        }
    }
    
    function addItem(item) {
        // Validate item
        if (!item.content || item.content.trim() === "") {
            return false
        }
        
        // Set default values
        const newItem = {
            content: item.content.trim(),
            done: item.done || false,
            dueDate: item.dueDate || null,
            priority: item.priority || "medium",
            categories: item.categories || [],
            recurring: item.recurring || null,
            createdAt: item.createdAt || new Date().toISOString(),
            completedAt: item.completedAt || null
        }
        
        list.push(newItem)
        // Reassign to trigger onListChanged
        root.list = list.slice(0)
        saveToFile()
        return true
    }

    function addTask(desc, dueDate, priority, categories, recurring) {
        const item = {
            "content": desc,
            "done": false,
            "dueDate": dueDate || null,
            "priority": priority || "medium",
            "categories": categories || [],
            "recurring": recurring || null
        }
        return addItem(item)
    }

    function markDone(index) {
        if (index >= 0 && index < list.length) {
            const item = list[index]
            item.done = true
            item.completedAt = new Date().toISOString()
            
            // Handle recurring tasks
            if (item.recurring && item.recurring.enabled) {
                createNextRecurringTask(item)
            }
            
            // Reassign to trigger onListChanged
            root.list = list.slice(0)
            saveToFile()
        }
    }

    function markUnfinished(index) {
        if (index >= 0 && index < list.length) {
            list[index].done = false
            list[index].completedAt = null
            // Reassign to trigger onListChanged
            root.list = list.slice(0)
            saveToFile()
        }
    }

    function deleteItem(index) {
        if (index >= 0 && index < list.length) {
            list.splice(index, 1)
            // Reassign to trigger onListChanged
            root.list = list.slice(0)
            saveToFile()
            refresh() // Force reload after delete
        }
    }

    function clearCompleted() {
        list = list.filter(function(item) { return !item.done; });
        root.list = list.slice(0);
        saveToFile();
    }

    function editTask(index, newContent, newDueDate, newPriority, newCategories, newRecurring) {
        if (index >= 0 && index < list.length && typeof newContent === 'string') {
            const item = list[index]
            item.content = newContent.trim()
            if (typeof newDueDate !== 'undefined') {
                item.dueDate = newDueDate || null
            }
            if (typeof newPriority !== 'undefined') {
                item.priority = newPriority
            }
            if (typeof newCategories !== 'undefined') {
                item.categories = newCategories
            }
            if (typeof newRecurring !== 'undefined') {
                item.recurring = newRecurring
            }
            root.list = list.slice(0);
            saveToFile();
        }
    }

    function createNextRecurringTask(completedTask) {
        if (!completedTask.recurring || !completedTask.recurring.enabled) return
        
        const recurring = completedTask.recurring
        let nextDueDate = null
        
        if (completedTask.dueDate) {
            const currentDate = new Date(completedTask.dueDate)
            
            switch (recurring.type) {
                case "daily":
                    currentDate.setDate(currentDate.getDate() + 1)
                    break
                case "weekly":
                    currentDate.setDate(currentDate.getDate() + 7)
                    break
                case "monthly":
                    currentDate.setMonth(currentDate.getMonth() + 1)
                    break
                case "yearly":
                    currentDate.setFullYear(currentDate.getFullYear() + 1)
                    break
                case "custom":
                    if (recurring.days) {
                        currentDate.setDate(currentDate.getDate() + recurring.days)
                    }
                    break
            }
            
            nextDueDate = currentDate.toISOString().split('T')[0]
        }
        
        const newTask = {
            content: completedTask.content,
            done: false,
            dueDate: nextDueDate,
            priority: completedTask.priority,
            categories: completedTask.categories,
            recurring: completedTask.recurring,
            createdAt: new Date().toISOString()
        }
        
        addItem(newTask)
    }

    function getTasksByCategory(category) {
        return list.filter(item => 
            item.categories && item.categories.includes(category)
        )
    }

    function getOverdueTasks() {
        const today = new Date().toISOString().split('T')[0]
        return list.filter(item => 
            !item.done && item.dueDate && item.dueDate < today
        )
    }

    function getTasksDueToday() {
        const today = new Date().toISOString().split('T')[0]
        return list.filter(item => 
            !item.done && item.dueDate && item.dueDate === today
        )
    }

    function getTasksDueThisWeek() {
        const today = new Date()
        const endOfWeek = new Date(today)
        endOfWeek.setDate(today.getDate() + 7)
        
        return list.filter(item => {
            if (item.done || !item.dueDate) return false
            const dueDate = new Date(item.dueDate)
            return dueDate >= today && dueDate <= endOfWeek
        })
    }

    function getAllCategories() {
        const categories = new Set()
        list.forEach(item => {
            if (item.categories) {
                item.categories.forEach(cat => categories.add(cat))
            }
        })
        return Array.from(categories).sort()
    }

    function refresh() {
        todoFileView.reload()
    }

    // Convert task object to conf format
    function taskToConf(task, index) {
        let conf = `[Task${index}]\n`
        conf += `content=${escapeConfValue(task.content)}\n`
        conf += `done=${task.done}\n`
        conf += `priority=${task.priority || "medium"}\n`
        
        if (task.dueDate) {
            conf += `dueDate=${task.dueDate}\n`
        }
        
        if (task.categories && task.categories.length > 0) {
            conf += `categories=${task.categories.join(",")}\n`
        }
        
        if (task.recurring) {
            conf += `recurring=${JSON.stringify(task.recurring)}\n`
        }
        
        if (task.createdAt) {
            conf += `createdAt=${task.createdAt}\n`
        }
        
        if (task.completedAt) {
            conf += `completedAt=${task.completedAt}\n`
        }
        
        return conf
    }

    // Escape special characters in conf values
    function escapeConfValue(value) {
        if (typeof value !== 'string') return value
        return value.replace(/\\/g, '\\\\').replace(/\n/g, '\\n').replace(/\r/g, '\\r')
    }

    // Unescape conf values
    function unescapeConfValue(value) {
        if (typeof value !== 'string') return value
        return value.replace(/\\n/g, '\n').replace(/\\r/g, '\r').replace(/\\\\/g, '\\')
    }

    // Parse conf file content into task objects
    function parseConfFile(content) {
        const tasks = []
        const lines = content.split('\n')
        let currentTask = null
        let currentSection = null
        
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            
            // Skip empty lines and comments
            if (line === '' || line.startsWith('#')) {
                continue
            }
            
            // Check for section header [TaskX]
            if (line.startsWith('[') && line.endsWith(']')) {
                if (currentTask && currentSection) {
                    tasks.push(currentTask)
                }
                currentSection = line.slice(1, -1)
                currentTask = {
                    content: '',
                    done: false,
                    dueDate: null,
                    priority: 'medium',
                    categories: [],
                    recurring: null,
                    createdAt: null,
                    completedAt: null
                }
                continue
            }
            
            // Parse key=value pairs
            if (currentTask && line.includes('=')) {
                const [key, ...valueParts] = line.split('=')
                const value = valueParts.join('=') // Rejoin in case value contains =
                
                switch (key.trim()) {
                    case 'content':
                        currentTask.content = unescapeConfValue(value.trim())
                        break
                    case 'done':
                        currentTask.done = value.trim() === 'true'
                        break
                    case 'priority':
                        currentTask.priority = value.trim()
                        break
                    case 'dueDate':
                        currentTask.dueDate = value.trim() || null
                        break
                    case 'categories':
                        currentTask.categories = value.trim() ? value.trim().split(',') : []
                        break
                    case 'recurring':
                        try {
                            currentTask.recurring = JSON.parse(value.trim())
                        } catch (e) {
                            currentTask.recurring = null
                        }
                        break
                    case 'createdAt':
                        currentTask.createdAt = value.trim() || null
                        break
                    case 'completedAt':
                        currentTask.completedAt = value.trim() || null
                        break
                }
            }
        }
        
        // Add the last task if exists
        if (currentTask && currentSection) {
            tasks.push(currentTask)
        }
        
        return tasks
    }

    function saveToFile() {
        let confContent = "# Todo List Configuration File\n"
        confContent += "# Generated by Quickshell Todo Service\n\n"
        
        list.forEach((task, index) => {
            confContent += taskToConf(task, index) + "\n"
        })
        
        todoFileView.setText(confContent)
    }

    function initializeWithSampleTasks() {
        // No default tasks, start empty
    }

    Component.onCompleted: {
        refresh()
        // Initialize with sample tasks after a short delay to ensure file is loaded
        Qt.callLater(initializeWithSampleTasks, 1000)
    }

    FileView {
        id: todoFileView
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        onLoaded: {
            try {
                const fileContents = todoFileView.text()
                
                if (fileContents && fileContents.trim() !== '') {
                    const parsedTasks = parseConfFile(fileContents)
                    
                    // Validate and clean up data
                    root.list = parsedTasks.filter(item => {
                        if (!item.content || typeof item.content !== 'string') {
                            return false
                        }
                        return true
                    }).map(item => {
                        // Ensure all required fields exist
                        return {
                            content: item.content,
                            done: item.done || false,
                            dueDate: item.dueDate || null,
                            priority: item.priority || "medium",
                            categories: Array.isArray(item.categories) ? item.categories : [],
                            recurring: item.recurring || null,
                            createdAt: item.createdAt || new Date().toISOString(),
                            completedAt: item.completedAt || null
                        }
                    })
                } else {
                    root.list = []
                    saveToFile()
                }
            } catch (e) {
                root.list = []
                saveToFile()
            }
        }
        onLoadFailed: (error) => {
            if(error == FileViewError.FileNotFound) {
                root.list = []
                saveToFile()
            } else {
                root.list = []
            }
        }
    }
}

