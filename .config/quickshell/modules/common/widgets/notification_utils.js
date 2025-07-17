/**
 * @param { string } summary 
 * @returns { string }
 */
function findSuitableMaterialSymbol(summary = "") {
    const defaultType = 'chat';
    if(!summary || summary.length === 0) return defaultType;

    const keywordsToTypes = {
        'reboot': 'restart_alt',
        'recording': 'screen_record',
        'battery': 'power',
        'power': 'power',
        'screenshot': 'screenshot_monitor',
        'welcome': 'waving_hand',
        'time': 'scheduleb',
        'installed': 'download',
        'configuration reloaded': 'reset_wrench',
        'config': 'reset_wrench',
        'update': 'update',
        'ai response': 'neurology',
        'startswith:file': 'folder_copy', // Declarative startsWith check
    };

    const lowerSummary = summary.toLowerCase();

    for (const [keyword, type] of Object.entries(keywordsToTypes)) {
        if (keyword.startsWith('startswith:')) {
            const startsWithKeyword = keyword.replace('startswith:', '');
            if (lowerSummary.startsWith(startsWithKeyword)) {
                return type;
            }
        } else if (lowerSummary.includes(keyword)) {
            return type;
        }
    }

    return defaultType;
}

/**
 * @param { number | string | Date } timestamp 
 * @returns { string }
 */
const getFriendlyNotifTimeString = (timestamp) => {
    // Handle null, undefined or invalid timestamps
    if (timestamp === null || timestamp === undefined) {
        return 'Just now';
    }
    
    try {
        const messageTime = new Date(timestamp);
        
        // Check if date is valid
        if (isNaN(messageTime.getTime())) {
            return 'Just now';
        }
        
        const now = new Date();
        const oneMinuteAgo = new Date(now.getTime() - 60000);

        if (messageTime > oneMinuteAgo) 
            return 'Now';
        if (messageTime.toDateString() === now.toDateString())
            return Qt.formatDateTime(messageTime, "hh:mm");
        if (messageTime.toDateString() === new Date(now.getTime() - 86400000).toDateString()) 
            return 'Yesterday';
        return Qt.formatDateTime(messageTime, "MMMM dd");
    } catch (e) {
        return 'Just now';
    }
};