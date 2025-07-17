import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    id: iconScanner
    
    // List of available icons
    property var availableIcons: []
    
    // Current selected logo
    property string currentLogo: ConfigOptions.appearance.logo || "Nobara-linux-logo.svg"
    
    // Signal when icons are updated
    signal iconsUpdated()
    
    Component.onCompleted: {
        scanIcons()
    }
    
    // Scan icons from assets/icons directory
    function scanIcons() {
        const iconsDir = SystemPaths.quickshellConfigDir + "/assets/icons"
        
        try {
            const fileView = Qt.createQmlObject('import Quickshell.Io; FileView { }', this)
            fileView.path = iconsDir
            
            if (fileView.exists) {
                const entries = fileView.entries()
                availableIcons = []
                
                for (let i = 0; i < entries.length; i++) {
                    const entry = entries[i]
                    if (entry.isFile) {
                        const fileName = entry.name
                        // Filter for image files
                        if (fileName.match(/\.(svg|png|jpg|jpeg|gif)$/i)) {
                            availableIcons.push({
                                name: fileName,
                                path: "root:/assets/icons/" + fileName,
                                displayName: formatDisplayName(fileName)
                            })
                        }
                    }
                }
                
                // Sort icons alphabetically
                availableIcons.sort((a, b) => a.displayName.localeCompare(b.displayName))
                
                iconsUpdated()
            }
        } catch (e) {
            // Error scanning icons
        }
    }
    
    // Format display name from filename
    function formatDisplayName(fileName) {
        // Remove extension
        let name = fileName.replace(/\.(svg|png|jpg|jpeg|gif)$/i, '')
        
        // Replace hyphens and underscores with spaces
        name = name.replace(/[-_]/g, ' ')
        
        // Capitalize first letter of each word
        name = name.replace(/\b\w/g, l => l.toUpperCase())
        
        // Handle special cases
        name = name.replace(/Symbolic/g, '')
        name = name.replace(/Linux/g, 'Linux')
        name = name.replace(/Ai/g, 'AI')
        name = name.replace(/Openai/g, 'OpenAI')
        name = name.replace(/Github/g, 'GitHub')
        name = name.replace(/Flatpak/g, 'Flatpak')
        
        return name.trim()
    }
    
    // Set current logo
    function setLogo(logoName) {
        currentLogo = logoName
        ConfigLoader.setConfigValue("appearance.logo", logoName)
    }
    
    // Get current logo path
    function getCurrentLogoPath() {
        return "root:/assets/icons/" + currentLogo
    }
    
    // Check if icon exists
    function iconExists(iconName) {
        return availableIcons.some(icon => icon.name === iconName)
    }
} 