pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * Manages default applications for different file types and protocols.
 * Detects available applications and manages system defaults.
 */
Singleton {
    id: root

    // Signal when apps are loaded
    signal appsLoaded()

    // Properties to store detected apps and current defaults
    property var detectedApps: ({})
    property var currentDefaults: ({})
    property bool isLoading: false

    // Load detected apps from desktop entries
    function loadDetectedApps() {
        isLoading = true
        
        try {
            // Initialize detectedApps as an object if it doesn't exist
            if (!detectedApps || typeof detectedApps !== 'object') {
                detectedApps = {}
            }
            
            // Use DesktopEntries like AppSearch does
            const allApps = Array.from(DesktopEntries.applications.values)
            
            // Categorize apps based on their desktop entry categories
            const categorizedApps = {
                web: [],
                mail: [],
                calendar: [],
                music: [],
                video: [],
                photos: [],
                text_editor: [],
                file_manager: [],
                terminal: []
            }
            
            // Category keywords for classification with flexible matching
            const categoryKeywords = {
                web: [
                    "WebBrowser", "Network;WebBrowser", "Network;WebBrowser;",
                    "Network;", "Internet;", "Web;"
                ],
                mail: [
                    "Email", "EmailClient", "Network;Email", "Network;Email;",
                    "Office;Email", "Office;Email;", "Mail;"
                ],
                calendar: [
                    "Calendar", "Office;Calendar", "Office;Calendar;",
                    "Utility;Calendar", "Utility;Calendar;"
                ],
                music: [
                    "Audio", "Music", "AudioVideo;Audio", "AudioVideo;Audio;",
                    "Multimedia;Audio", "Multimedia;Audio;"
                ],
                video: [
                    "Video", "Player", "AudioVideo;Video", "AudioVideo;Video;",
                    "AudioVideo;", "Multimedia;Video", "Multimedia;Video;", "MediaPlayer",
                    "TV;", "AudioVideo;Player"
                ],
                photos: [
                    "Graphics", "ImageViewer", "Photography", "Graphics;2DGraphics",
                    "Graphics;2DGraphics;", "Graphics;Viewer", "Graphics;Viewer;",
                    "Image;", "Photo;"
                ],
                text_editor: [
                    "TextEditor", "Utility;TextEditor", "Utility;TextEditor;",
                    "Development;TextEditor", "Development;TextEditor;",
                    "Editor", "Text;"
                ],
                file_manager: [
                    "FileManager", "System;FileTools;FileManager", "System;FileTools;FileManager;",
                    "System;FileManager", "System;FileManager;", "File;"
                ],
                terminal: [
                    "TerminalEmulator", "System;TerminalEmulator", "System;TerminalEmulator;",
                    "Terminal", "System;Terminal", "System;Terminal;"
                ]
            }
            
            // Process each app
            allApps.forEach(app => {
                if (!app.categories) return
                
                const categories = app.categories
                let assigned = false
                
                // Try to assign to the most specific category first
                for (const [category, keywords] of Object.entries(categoryKeywords)) {
                    for (const keyword of keywords) {
                        // Check if any category contains the keyword (more flexible matching)
                        if (categories.some(cat => cat.includes(keyword))) {
                            // Additional validation for specific categories to ensure accuracy
                            let isValid = true
                            
                            // Terminal validation - must be a terminal emulator
                            if (category === 'terminal' && !categories.some(cat => 
                                cat.includes('TerminalEmulator') || cat.includes('Terminal'))) {
                                isValid = false
                            }
                            
                            // Web browser validation - must be a web browser
                            if (category === 'web' && !categories.some(cat => 
                                cat.includes('WebBrowser') || cat.includes('Network') || cat.includes('Internet'))) {
                                isValid = false
                            }
                            
                            // Email validation - must be an email client
                            if (category === 'mail' && !categories.some(cat => 
                                cat.includes('Email') || cat.includes('Mail'))) {
                                isValid = false
                            }
                            
                            // File manager validation - must be a file manager
                            if (category === 'file_manager' && !categories.some(cat => 
                                cat.includes('FileManager') || cat.includes('File'))) {
                                isValid = false
                            }
                            
                            // Video player validation - must be a video player
                            if (category === 'video' && !categories.some(cat => 
                                cat.includes('Video') || cat.includes('Player') || cat.includes('AudioVideo'))) {
                                isValid = false
                            }
                            
                            if (isValid) {
                                categorizedApps[category].push({
                                    name: app.name,
                                    icon: app.icon,
                                    exec: app.exec,
                                    desktopId: app.desktopId
                                })
                                assigned = true
                                break
                            }
                        }
                    }
                    if (assigned) break
                }
            })
            
            detectedApps = categorizedApps
            // console.log("[DefaultApps] Loaded apps from desktop entries:", Object.keys(detectedApps).map(k => `${k}: ${detectedApps[k].length}`))
            
            // Debug: Log all detected apps for each category
            // Object.keys(detectedApps).forEach(category => {
            //     console.log(`[DefaultApps] ${category} apps:`, detectedApps[category].map(app => `${app.name} (${app.desktopId || 'undefined'})`))
            // })
            
            // Debug: Log web apps specifically
            // if (detectedApps.web && detectedApps.web.length > 0) {
            //     console.log("[DefaultApps] Web apps detected:", detectedApps.web.map(app => `${app.name} (${app.desktopId || 'undefined'})`))
            // } else {
            //     console.log("[DefaultApps] No web apps detected")
            // }
            
            // Debug: Log terminal apps specifically
            // if (detectedApps.terminal && detectedApps.terminal.length > 0) {
            //     console.log("[DefaultApps] Terminal apps detected:", detectedApps.terminal.map(app => app.name))
            // } else {
            //     console.log("[DefaultApps] No terminal apps detected")
            // }
            
            // Debug: Log video apps specifically
            // if (detectedApps.video && detectedApps.video.length > 0) {
            //     console.log("[DefaultApps] Video apps detected:", detectedApps.video.map(app => app.name))
            // } else {
            //     console.log("[DefaultApps] No video apps detected")
            // }
            
        } catch (error) {
            console.error("[DefaultApps] Error loading detected apps:", error)
            detectedApps = {}
        }
        
        isLoading = false
        appsLoaded()
    }

    // Load current default app settings
    function loadCurrentDefaults() {
        try {
            // Initialize currentDefaults as an object if it doesn't exist
            if (!currentDefaults || typeof currentDefaults !== 'object') {
                currentDefaults = {}
            }
            
            // Load from config or use system defaults
            const newDefaults = {
                web: Config.options?.defaultApps?.web || getSystemDefault("web"),
                mail: Config.options?.defaultApps?.mail || getSystemDefault("mail"),
                calendar: Config.options?.defaultApps?.calendar || getSystemDefault("calendar"),
                music: Config.options?.defaultApps?.music || getSystemDefault("music"),
                video: Config.options?.defaultApps?.video || getSystemDefault("video"),
                photos: Config.options?.defaultApps?.photos || getSystemDefault("photos"),
                text_editor: Config.options?.defaultApps?.text_editor || getSystemDefault("text_editor"),
                file_manager: Config.options?.defaultApps?.file_manager || getSystemDefault("file_manager"),
                terminal: Config.options?.defaultApps?.terminal || getSystemDefault("terminal")
            }
            
            // Update currentDefaults with new values
            Object.keys(newDefaults).forEach(key => {
                currentDefaults[key] = newDefaults[key]
            })
            
            // console.log("[DefaultApps] Loaded current defaults:", currentDefaults)
        } catch (error) {
            console.error("[DefaultApps] Error loading current defaults:", error)
            currentDefaults = {}
        }
    }

    // Get system default for a category
    function getSystemDefault(category) {
        const mimeTypes = {
            web: "x-scheme-handler/http",
            mail: "x-scheme-handler/mailto",
            calendar: "text/calendar",
            music: "audio/mpeg",
            video: "video/mp4",
            photos: "image/jpeg",
            text_editor: "text/plain",
            file_manager: "inode/directory",
            terminal: "application/x-terminal"
        }
        
        const mimeType = mimeTypes[category]
        if (!mimeType) return ""
        
        // For now, return empty string and let the config defaults handle it
        // The system defaults will be properly detected when the user first sets them
        return ""
    }

    // Test current system defaults (for debugging)
    function testSystemDefaults() {
        // console.log("[DefaultApps] Testing current system defaults:")
        
        const testMimeTypes = {
            web: "x-scheme-handler/http",
            mail: "x-scheme-handler/mailto", 
            video: "video/mp4",
            music: "audio/mpeg",
            photos: "image/jpeg"
        }
        
        for (const [category, mimeType] of Object.entries(testMimeTypes)) {
            try {
                // Use Hyprland.dispatch to run xdg-mime query command
                Hyprland.dispatch(`exec xdg-mime query default "${mimeType}"`)
                // console.log(`[DefaultApps] ${category}: ${mimeType} -> query sent`)
            } catch (error) {
                console.error(`[DefaultApps] Error querying ${category}:`, error)
            }
        }
    }

    // Manual test function to set a specific default
    function testSetDefault(category, appName) {
        console.log(`[DefaultApps] Manual test: Setting ${category} to ${appName}`)
        setDefaultApp(category, appName)
    }

    // Test function to directly call the Python script
    function testPythonScript() {
        console.log("[DefaultApps] Testing Python script directly...")
        try {
            const scriptPath = "/home/matt/.config/quickshell/scripts/set_default_apps.py"
            const command = `python3 "${scriptPath}" "web" "microsoft-edge-dev.desktop"`
            console.log(`[DefaultApps] Executing Python script: ${command}`)
            Hyprland.dispatch(`exec ${command}`)
            console.log("[DefaultApps] Python script executed successfully")
        } catch (error) {
            console.error("[DefaultApps] Error executing Python script:", error)
        }
    }

    // Test function specifically for Microsoft Edge
    function testMicrosoftEdge() {
        console.log("[DefaultApps] Testing Microsoft Edge as default browser...")
        
        // First, let's see what web apps are detected
        console.log("[DefaultApps] Available web apps:", getAvailableApps("web"))
        
        // Try to find Microsoft Edge in the detected apps
        const webApps = getAvailableApps("web")
        const edgeApp = webApps.find(app => app.includes("Microsoft Edge") || app.includes("microsoft-edge"))
        
        if (edgeApp) {
            console.log(`[DefaultApps] Found Microsoft Edge: ${edgeApp}`)
            setDefaultApp("web", edgeApp)
        } else {
            console.error("[DefaultApps] Microsoft Edge not found in web apps")
            console.log("[DefaultApps] All web apps:", webApps)
            
            // Try manual approach with Python script
            console.log("[DefaultApps] Trying manual approach with Python script...")
            try {
                const scriptPath = "/home/matt/.config/quickshell/scripts/set_default_apps.py"
                const command = `python3 "${scriptPath}" "web" "microsoft-edge-dev.desktop"`
                console.log(`[DefaultApps] Executing: ${command}`)
                Hyprland.dispatch(`exec ${command}`)
                console.log("[DefaultApps] Manually set Microsoft Edge as default browser")
            } catch (error) {
                console.error("[DefaultApps] Error manually setting Microsoft Edge:", error)
            }
        }
    }

    // Test function to set any app as default
    function testSetAnyDefault(category, appName) {
        console.log(`[DefaultApps] Testing setting ${appName} as default ${category}...`)
        
        // Check if the app is available
        const availableApps = getAvailableApps(category)
        console.log(`[DefaultApps] Available ${category} apps:`, availableApps)
        
        if (availableApps.includes(appName)) {
            console.log(`[DefaultApps] App ${appName} found in ${category} apps, setting as default...`)
            setDefaultApp(category, appName)
        } else {
            console.error(`[DefaultApps] App ${appName} not found in ${category} apps`)
            console.log(`[DefaultApps] Available apps:`, availableApps)
            
            // Try direct script approach
            console.log(`[DefaultApps] Trying direct script approach...`)
            try {
                const scriptPath = "/home/matt/.config/quickshell/scripts/set_default_apps.py"
                const command = `python3 "${scriptPath}" "${category}" "${appName}.desktop"`
                console.log(`[DefaultApps] Executing: ${command}`)
                Hyprland.dispatch(`exec ${command}`)
                console.log(`[DefaultApps] Directly set ${appName} as default ${category}`)
            } catch (error) {
                console.error(`[DefaultApps] Error directly setting ${appName}:`, error)
            }
        }
    }

    // Set default app for a category
    function setDefaultApp(category, appName) {
        try {
            console.log(`[DefaultApps] Setting ${category} default to: ${appName}`)
            
            // Validate inputs
            if (!category || !appName) {
                console.error(`[DefaultApps] Invalid inputs: category=${category}, appName=${appName}`)
                return
            }
            
            // Initialize currentDefaults if it doesn't exist
            if (!currentDefaults || typeof currentDefaults !== 'object') {
                currentDefaults = {}
            }
            
            // Get app info to verify it exists and get desktopId
            const appInfo = getAppInfo(appName, category)
            if (!appInfo) {
                console.error(`[DefaultApps] App ${appName} not found in category ${category}`)
                return
            }
            
            console.log(`[DefaultApps] App info:`, appInfo)
            
            // Update internal state
            currentDefaults[category] = appName
            
            // Update config
            if (ConfigLoader && typeof ConfigLoader.setConfigValue === 'function') {
                ConfigLoader.setConfigValue(`defaultApps.${category}`, appName)
            }
            console.log(`[DefaultApps] Updated config for ${category} to:`, appName)
            
            // Also update system default using Python script
            updateSystemDefault(category, appName)
        } catch (error) {
            console.error("[DefaultApps] Error setting default app:", error)
        }
    }

    // Update system default using Python script
    function updateSystemDefault(category, appName) {
        try {
            console.log(`[DefaultApps] updateSystemDefault called for ${category}: ${appName}`)
            
            // Validate inputs
            if (!category || !appName) {
                console.error(`[DefaultApps] Invalid inputs for updateSystemDefault: category=${category}, appName=${appName}`)
                return
            }
            
            const appInfo = getAppInfo(appName, category)
            console.log(`[DefaultApps] App info:`, appInfo)
            
            if (appInfo && appInfo.desktopId) {
                try {
                    // Use Python script for reliable default app setting
                    const scriptPath = "/home/matt/.config/quickshell/scripts/set_default_apps.py"
                    const command = `python3 "${scriptPath}" "${category}" "${appInfo.desktopId}"`
                    console.log(`[DefaultApps] Executing Python script: ${command}`)
                    
                    // Add debug logging to see if the command is actually executed
                    console.log(`[DefaultApps] About to dispatch command: ${command}`)
                    Hyprland.dispatch(`exec ${command}`)
                    console.log(`[DefaultApps] Command dispatched successfully`)
                    
                    console.log(`[DefaultApps] Successfully executed Python script for ${category} -> ${appInfo.desktopId}`)
                } catch (error) {
                    console.error(`[DefaultApps] Error setting system default for ${category}:`, error)
                }
            } else {
                console.warn(`[DefaultApps] Could not set system default for ${category}: ${appName}`)
                console.warn(`[DefaultApps] App info exists: ${!!appInfo}`)
                console.warn(`[DefaultApps] Desktop ID: ${appInfo ? appInfo.desktopId : 'N/A'}`)
            }
        } catch (error) {
            console.error(`[DefaultApps] Error in updateSystemDefault:`, error)
        }
    }

    // Get app executable from detected apps
    function getAppExec(appName, category) {
        if (!detectedApps || typeof detectedApps !== 'object' || !detectedApps[category] || !Array.isArray(detectedApps[category])) {
            console.warn(`[DefaultApps] getAppExec: detectedApps[${category}] is not available`)
            return null
        }
        const app = detectedApps[category].find(a => a && a.name === appName)
        return app && app.exec ? app.exec : null
    }

    // Get available apps for a category
    function getAvailableApps(category) {
        if (!detectedApps || typeof detectedApps !== 'object' || !detectedApps[category] || !Array.isArray(detectedApps[category])) {
            console.warn(`[DefaultApps] getAvailableApps: detectedApps[${category}] is not available`)
            return []
        }
        return detectedApps[category].map(app => app && app.name ? app.name : "").filter(name => name !== "")
    }

    // Get current default for a category
    function getCurrentDefault(category) {
        if (!currentDefaults || typeof currentDefaults !== 'object') {
            console.warn(`[DefaultApps] getCurrentDefault: currentDefaults is not available for category ${category}`)
            return ""
        }
        return currentDefaults[category] || ""
    }

    // Get app info for a category and app name
    function getAppInfo(appName, category) {
        if (!detectedApps || typeof detectedApps !== 'object' || !detectedApps[category] || !Array.isArray(detectedApps[category])) {
            console.warn(`[DefaultApps] getAppInfo: detectedApps[${category}] is not available`)
            return null
        }
        return detectedApps[category].find(a => a && a.name === appName) || null
    }

    // Check if an app is available in a category
    function isAppAvailable(appName, category) {
        if (!detectedApps || typeof detectedApps !== 'object' || !detectedApps[category] || !Array.isArray(detectedApps[category])) {
            console.warn(`[DefaultApps] isAppAvailable: detectedApps[${category}] is not available`)
            return false
        }
        return detectedApps[category].some(a => a && a.name === appName)
    }

    // Refresh apps (compatibility with UI)
    function refreshApps() {
        // console.log("[DefaultApps] Refreshing apps...")
        loadDetectedApps()
        loadCurrentDefaults()
    }

    // Initialize the service
    Component.onCompleted: {
        loadDetectedApps()
        loadCurrentDefaults()
        
        // Test system defaults after a short delay
        testTimer.start()
    }

    // Timer for testing system defaults
    Timer {
        id: testTimer
        interval: 2000
        repeat: false
        onTriggered: {
            // console.log("[DefaultApps] Testing system defaults...")
            testSystemDefaults()
        }
    }
} 