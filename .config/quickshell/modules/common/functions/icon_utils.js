function resolveIconPath(icon) {
    if (!icon) return "";
    
    // Get current icon theme dynamically instead of hardcoding
    const homeDir = StandardPaths.writableLocation(StandardPaths.HomeLocation);
    const currentTheme = getCurrentIconTheme() || "Tela-circle-dark";
    const iconPath = `${homeDir}/.local/share/icons/${currentTheme}/scalable@2x/apps`;
    
    // Icon name mappings
    const iconMappings = {
        'edge.svg': 'microsoft-edge.svg',
        'files.svg': 'org.gnome.Files.svg'
    };
    
    if (icon.includes("?path=")) {
        const [name, path] = icon.split("?path=");
        const fileName = name.substring(name.lastIndexOf("/") + 1);
        
        // First try the specified path
        const specifiedPath = `file://${path}/${fileName}`;
        
        // If the file is an icon request, also check the current theme directory
        if (path.includes("icons")) {
            // Use mapped icon name if available
            const mappedName = iconMappings[fileName] || fileName;
            const themePath = `file://${iconPath}/${mappedName}`;
            return themePath;
        }
        
        return specifiedPath;
    }
    
    // For direct icon names, check in current theme
    if (icon.startsWith("/")) {
        const fileName = icon.substring(icon.lastIndexOf("/") + 1);
        const mappedName = iconMappings[fileName] || fileName;
        return `file://${iconPath}/${mappedName}`;
    }
    
    // For bare icon names, use mapping if available
    const mappedName = iconMappings[icon] || icon;
    return `file://${iconPath}/${mappedName}`;
}

// Function to get current icon theme (placeholder - should be implemented)
function getCurrentIconTheme() {
    // This should integrate with the icon theme detection system
    // For now, return a sensible default
    return "Tela-circle-dark";
} 