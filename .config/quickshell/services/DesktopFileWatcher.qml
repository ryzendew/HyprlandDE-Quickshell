pragma Singleton

import Quickshell
import Quickshell.Io

/**
 * Provides manual refresh capabilities for desktop applications
 * Can be extended later with file watching if needed
 */
Singleton {
    id: root
    
    // Signal emitted when manual refresh is requested
    signal refreshRequested()
    
    // Function to manually trigger a refresh
    function requestRefresh() {
        // console.log("[DESKTOPWATCHER] Manual refresh requested")
        root.refreshRequested()
    }
} 