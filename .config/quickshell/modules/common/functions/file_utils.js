/**
 * Trims the File protocol off the input string
 * @param {string} str
 * @returns {string}
 */
function trimFileProtocol(str) {
    return str.startsWith("file://") ? str.slice(7) : str;
}

/**
 * Expands a path with ~ to home directory
 * @param {string} path
 * @returns {string}
 */
function expandPath(path) {
    if (path.startsWith("~")) {
        return path.replace("~", QtStandardPaths.writableLocation(QtStandardPaths.HomeLocation))
    }
    return path
}

/**
 * Gets the file name from a path
 * @param {string} path
 * @returns {string}
 */
function getFileName(path) {
    const trimmed = trimFileProtocol(path)
    return trimmed.split("/").pop()
}

/**
 * Gets a directory object for the given path
 * @param {string} path
 * @returns {object}
 */
function getDirectory(path) {
    const expanded = expandPath(path)
    return Qt.createQmlObject(`
        import QtQuick
        import Quickshell.Io
        
        FileView {
            path: "${expanded}"
        }
    `, wallpaperConfig)
}

/**
 * Copies a file from source to destination
 * @param {string} source
 * @param {string} dest
 * @returns {boolean}
 */
function copyFile(source, dest) {
    try {
        const sourceFile = Qt.createQmlObject(`
            import QtQuick
            import Quickshell.Io
            
            FileView {
                path: "${source}"
            }
        `, wallpaperConfig)
        
        const destFile = Qt.createQmlObject(`
            import QtQuick
            import Quickshell.Io
            
            FileView {
                path: "${dest}"
            }
        `, wallpaperConfig)
        
        destFile.setText(sourceFile.text)
        return true
    } catch (error) {
        console.error("Error copying file:", error)
        return false
    }
}

