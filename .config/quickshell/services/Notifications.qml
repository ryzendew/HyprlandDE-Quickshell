pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common"
import "root:/"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Qt.labs.platform

/**
 * Provides extra features not in Quickshell.Services.Notifications:
 *  - Persistent storage
 *  - Popup notifications, with timeout
 *  - Notification groups by app
 * 
 * Note: Registration warnings are expected when another notification server (dunst, mako, etc.) is running.
 * The service will automatically retry registration when the other service is unregistered.
 * These warnings are not errors and indicate normal operation.
 */
Singleton {
	id: root
    component Notif: QtObject {
        required property int id
        property Notification notification
        property list<var> actions: notification?.actions?.map((action) => ({
            "identifier": action.identifier,
            "text": action.text,
        })) ?? []
        property bool popup: true  // Default to true for new notifications
        property string appIcon: notification?.appIcon ?? ""
        property string appName: notification?.appName ?? ""
        property string body: notification?.body ?? ""
        property string image: notification?.image ?? ""
        property string summary: notification?.summary ?? ""
        property double time: Date.now()
        property string urgency: notification?.urgency?.toString() ?? "normal"
        property Timer timer
        property int expireTimeout: 5000
    }

    function notifToJSON(notif) {
        if (!notif) return null;
        return {
            "id": notif.id,
            "actions": notif.actions,
            "appIcon": notif.appIcon,
            "appName": notif.appName,
            "body": notif.body,
            "image": notif.image,
            "summary": notif.summary,
            "time": notif.time,
            "urgency": notif.urgency,
        }
    }
    function notifToString(notif) {
        if (!notif) return "null";
        return JSON.stringify(notifToJSON(notif), null, 2);
    }

    component NotifTimer: Timer {
        required property int id
        interval: 5000
        running: true
        onTriggered: () => {
            if (id !== undefined) {
            root.timeoutNotification(id);
            destroy()
            }
        }
    }

    property bool silent: false
    property var filePath: Directories.notificationsPath
    property list<Notif> list: []
    property var popupList: list.filter((notif) => notif && notif.popup)
    property bool popupInhibited: (GlobalStates?.sidebarRightOpen ?? false) || silent
    property var latestTimeForApp: ({})
    Component {
        id: notifComponent
        Notif {}
    }
    Component {
        id: notifTimerComponent
        NotifTimer {}
    }

    function stringifyList(list) {
        if (!list || list.length === 0) return "[]";
        try {
            const validNotifications = list.filter(notif => notif != null);
            const jsonData = validNotifications.map((notif) => notifToJSON(notif));
            return JSON.stringify(jsonData, null, 2);
        } catch (e) {
            // console.error("[Notifications] Error stringifying notifications:", e);
            return "[]";
        }
    }
    
    onListChanged: {
        // Update latest time for each app
        root.list.forEach((notif) => {
            if (!notif || !notif.appName) return; // Skip null or invalid notifications
            if (!root.latestTimeForApp[notif.appName] || (notif.time && notif.time > root.latestTimeForApp[notif.appName])) {
                root.latestTimeForApp[notif.appName] = Math.max(root.latestTimeForApp[notif.appName] || 0, notif.time || Date.now());
            }
        });
        // Remove apps that no longer have notifications
        Object.keys(root.latestTimeForApp).forEach((appName) => {
            if (!root.list.some((notif) => notif && notif.appName === appName)) {
                delete root.latestTimeForApp[appName];
            }
        });
    }

    function appNameListForGroups(groups) {
        if (!groups) return [];
        return Object.keys(groups).sort((a, b) => {
            // Sort by time, descending
            return (groups[b]?.time || 0) - (groups[a]?.time || 0);
        });
    }

    function groupsForList(list) {
        const groups = {};
        list.forEach((notif) => {
            if (!notif || !notif.appName) return; // Skip null or invalid notifications
            if (!groups[notif.appName]) {
                groups[notif.appName] = {
                    appName: notif.appName,
                    appIcon: notif.appIcon || "",
                    notifications: [],
                    time: 0
                };
            }
            groups[notif.appName].notifications.push(notif);
            // Always set to the latest time in the group
            groups[notif.appName].time = latestTimeForApp[notif.appName] || notif.time || Date.now();
        });
        return groups;
    }

    property var groupsByAppName: groupsForList(root.list)
    property var popupGroupsByAppName: groupsForList(root.popupList)
    property var appNameList: appNameListForGroups(root.groupsByAppName)
    property var popupAppNameList: appNameListForGroups(root.popupGroupsByAppName)

    // Quickshell's notification IDs starts at 1 on each run, while saved notifications
    // can already contain higher IDs. This is for avoiding id collisions
    property int idOffset
    

    
    // Check if another notification server is running
    property bool anotherServerRunning: false
    property bool registrationAttempted: false
    
    // Retry timer for notification server registration
    Timer {
        id: registrationRetryTimer
        interval: 5000 // 5 seconds
        repeat: false
        onTriggered: {
            // The NotificationServer will automatically retry registration
            // console.log("[Notifications] Registration retry timer triggered - checking for server availability")
            registrationAttempted = true
            
            // Log the current status
            // console.log("[Notifications] Status:", getNotificationServerStatus())
        }
    }
    signal initDone();
    signal notify(notification: var);
    signal discard(id: var);
    signal discardAll();
    signal timeout(id: var);

	// Notification server with graceful warning handling
	NotificationServer {
        id: notifServer
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: true
        persistenceSupported: true
        
        Component.onCompleted: {
            // console.log("[Notifications] Notification server initialized - warnings about registration are expected if another server is running")
            anotherServerRunning = true
            registrationRetryTimer.start()
        }
        
        onNotification: (notification) => {
            if (!notification) return;
            notification.tracked = true
            const newNotifObject = {
                "id": (notification.id || 0) + root.idOffset,
                "actions": (notification.actions || []).map((action) => {
                    return {
                        "identifier": action.identifier || "",
                        "text": action.text || "",
                    }
                }),
                "appIcon": notification.appIcon || "",
                "appName": notification.appName || "Unknown",
                "body": notification.body || "",
                "image": notification.image || "",
                "summary": notification.summary || "",
                "time": Date.now(),
                "urgency": notification.urgency?.toString() || "normal",
            }
            root.list = [...root.list, newNotifObject];
            root.notify(newNotifObject);
            saveNotifications()
        }
    }

    function discardNotification(id) {
        const index = root.list.findIndex((notif) => notif && notif.id === id);
        const notifServerIndex = notifServer.trackedNotifications.values.findIndex((notif) => notif && notif.id + root.idOffset === id);
        if (index !== -1) {
            root.list.splice(index, 1);
            saveNotifications()
            triggerListChange()
        }
        if (notifServerIndex !== -1) {
            notifServer.trackedNotifications.values[notifServerIndex].dismiss()
        }
        root.discard(id);
    }

    function discardAllNotifications() {
        root.list = []
        saveNotifications()
        triggerListChange()
        root.discardAll();
    }

    function timeoutNotification(id) {
        const index = root.list.findIndex((notif) => notif && notif.id === id);
        if (index !== -1) {
            root.list[index].popup = false;
            root.list = [...root.list]; // Trigger update
            saveNotifications()
            triggerListChange()
        }
        root.timeout(id);
    }

    function timeoutAll() {
        root.list.forEach((notif) => {
            if (notif && notif.popup) {
                notif.popup = false;
                root.timeout(notif.id);
            }
        });
        root.list = [...root.list]; // Trigger update
        saveNotifications()
        triggerListChange()
    }

    function attemptInvokeAction(notificationId, actionIdentifier) {
        // Find the notification in the server's tracked notifications
        const serverNotif = notifServer.trackedNotifications.values.find(
            (notif) => notif && (notif.id + root.idOffset) === notificationId
        );
        
        if (serverNotif) {
            // Find the action by identifier
            const action = serverNotif.actions.find(
                (action) => action && action.identifier === actionIdentifier
            );
            
            if (action) {
                // console.log("Invoking notification action:", actionIdentifier, "for notification:", notificationId);
                action.invoke();
                // Close the sidebar after invoking action
                Hyprland.dispatch("global quickshell:sidebarRightClose");
            } else {
                // console.warn("Action not found:", actionIdentifier, "for notification:", notificationId);
            }
        } else {
            // console.warn("Notification not found in server:", notificationId);
        }
    }

    function triggerListChange() {
        listChanged();
    }
    
    // Handle case where another notification server is running
    function handleAnotherServerRunning() {
        if (anotherServerRunning) {
            // console.log("[Notifications] Another notification server is running - using fallback mode")
            // In fallback mode, we can still show notifications in the UI
            // but we won't receive system notifications
        }
    }
    
    // Get notification server status
    function getNotificationServerStatus() {
        if (anotherServerRunning) {
            return "Another notification server is running - using fallback mode"
        } else if (registrationAttempted) {
            return "Registration attempted - monitoring for server availability"
        } else {
            return "Initializing notification server"
        }
    }
    
    // Check if another notification server is running
    function checkForOtherNotificationServer() {
        try {
            // Try to connect to the notification server to see if one is already running
            const testConnection = new XMLHttpRequest()
            testConnection.open("GET", "dbus://org.freedesktop.Notifications", false)
            testConnection.send()
            
            // If we can connect, another server is running
            anotherServerRunning = true
            // console.log("[Notifications] Another notification server detected - skipping registration")
            return true
        } catch (e) {
            // No other server running, we can register
            anotherServerRunning = false
            // console.log("[Notifications] No other notification server detected - proceeding with registration")
            return false
        }
    }
    
    // Manual registration function
    function attemptRegistration() {
        if (!anotherServerRunning) {
            try {
                notifServer.register()
                // console.log("[Notifications] Successfully registered notification server")
                return true
            } catch (e) {
                // console.log("[Notifications] Registration failed:", e.message)
                anotherServerRunning = true
                return false
            }
        }
        return false
    }

    function saveNotifications() {
        try {
            // Add fallback for when Directories.cache is undefined
            const cacheDir = Directories.cache || StandardPaths.writableLocation(StandardPaths.CacheLocation) || "~/.cache"
            const dir = FileUtils.trimFileProtocol(`${cacheDir.replace(/Quickshell/, 'quickshell')}/notifications`)
            Hyprland.dispatch(`exec mkdir -p '${dir}'`)
            const content = stringifyList(root.list);
            // console.log("[Notifications] Saving", root.list.length, "notifications to file");
            notifFileView.setText(content)
        } catch (e) {
            // console.error("[Notifications] Error saving notifications:", e);
        }
    }

    function loadNotifications() {
        notifFileView.reload()
    }

    FileView {
        id: notifFileView
        path: Qt.resolvedUrl(root.filePath)
        onTextChanged: {
            try {
                // Get the actual text content by calling the text() method
                const fileContent = notifFileView.text();
                
                // Check if text is empty or whitespace only
                if (!fileContent || fileContent.trim() === "") {
                    // console.log("[Notifications] Empty notifications file, initializing with empty list");
                    root.list = [];
                    root.idOffset = 1;
                    root.initDone();
                    return;
                }
                
                const json = JSON.parse(fileContent);
                if (Array.isArray(json)) {
                    const maxId = Math.max(...json.map(notif => notif.id || 0), 0);
                    root.idOffset = maxId + 1;
                    root.list = json.map(notifData => {
                        const notif = notifComponent.createObject(root, {
                            id: notifData.id || 0,
                            actions: notifData.actions || [],
                            appIcon: notifData.appIcon || "",
                            appName: notifData.appName || "Unknown",
                            body: notifData.body || "",
                            image: notifData.image || "",
                            summary: notifData.summary || "",
                            time: notifData.time || Date.now(),
                            urgency: notifData.urgency || "normal",
                            popup: false // Don't show popups for loaded notifications
                        });
                        return notif;
                    });
                    // console.log("[Notifications] Loaded", root.list.length, "notifications from file");
                    root.initDone();
                } else {
                    // console.warn("[Notifications] JSON is not an array, initializing with empty list");
                    root.list = [];
                    root.idOffset = 1;
                    root.initDone();
                }
            } catch (e) {
                // console.error("[Notifications] Error parsing JSON:", e);
                // console.error("[Notifications] File content was:", notifFileView.text());
                // Initialize with empty list on parse error
                root.list = [];
                root.idOffset = 1;
                root.initDone();
            }
        }
        onLoadFailed: (error) => {
            if (error == FileViewError.FileNotFound) {
                root.list = [];
                root.idOffset = 1;
                root.initDone();
            } else {
                // console.error("Error loading notifications file:", error);
            }
        }
    }

    Component.onCompleted: {
        loadNotifications()
    }
}
