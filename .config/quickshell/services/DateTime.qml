import "root:/modules/common"
import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

/**
 * A nice wrapper for date and time strings.
 */
Singleton {
    property string time: getFormattedTime()
    property string date: getFormattedDate()
    property string collapsedCalendarFormat: getCollapsedCalendarFormat()
    property string uptime: "0h, 0m"
    property string timeZone: getCurrentTimeZone()
    property string timeZoneName: getTimeZoneName()

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Helper functions to get formatted time and date based on config
    function getFormattedTime() {
        let format = ConfigOptions.time.customTimeFormat || ConfigOptions.time.format
        
        // Enforce 24-hour or 12-hour hour code in format
        if (ConfigOptions.time.use24Hour) {
            // Replace all 12-hour hour codes with 24-hour
            format = format.replace(/hh/g, "HH").replace(/h/g, "HH").replace(/AP/g, "");
        } else {
            // Replace all 24-hour hour codes with 12-hour
            format = format.replace(/HH/g, "h").replace(/H/g, "h");
            if (!format.includes("AP")) format += " AP";
        }
        
        // Add seconds if enabled
        if (ConfigOptions.time.showSeconds) {
            if (format.includes("mm")) {
                format = format.replace("mm", "mm:ss")
            } else {
                format += ":ss"
            }
        }
        
        return Qt.formatDateTime(clock.date, format)
    }
    
    function getFormattedDate() {
        if (!ConfigOptions.time.showDate) return ""
        
        let format = ConfigOptions.time.customDateFormat || ConfigOptions.time.dateFormat
        
        // Remove day of week if disabled
        if (!ConfigOptions.time.showDayOfWeek) {
            format = format.replace("dddd, ", "").replace("ddd, ", "")
        }
        
        // Add year if enabled
        if (ConfigOptions.time.showYear) {
            if (!format.includes("yyyy")) {
                format += " yyyy"
            }
        } else {
            format = format.replace(" yyyy", "").replace("/yyyy", "")
        }
        
        return Qt.formatDateTime(clock.date, format)
    }
    
    function getCollapsedCalendarFormat() {
        let format = "dd MMMM"
        if (ConfigOptions.time.showYear) {
            format += " yyyy"
        }
        return Qt.formatDateTime(clock.date, format)
    }
    
    function getCurrentTimeZone() {
        if (ConfigOptions.time.timeZone === "system") {
            // Get system timezone
            return Qt.locale().name
        }
        return ConfigOptions.time.timeZone
    }
    
    function getTimeZoneName() {
        const tz = getCurrentTimeZone()
        if (tz === "system") {
            return "System Default"
        }
        // Convert timezone to readable name
        return tz.split('/').pop().replace(/_/g, ' ')
    }

    Timer {
        interval: 10
        running: true
        repeat: true
        onTriggered: {
            fileUptime.reload()
            const textUptime = fileUptime.text()
            const uptimeSeconds = Number(textUptime.split(" ")[0] ?? 0)

            // Convert seconds to days, hours, and minutes
            const days = Math.floor(uptimeSeconds / 86400)
            const hours = Math.floor((uptimeSeconds % 86400) / 3600)
            const minutes = Math.floor((uptimeSeconds % 3600) / 60)

            // Build the formatted uptime string
            let formatted = ""
            if (days > 0) formatted += `${days}d`
            if (hours > 0) formatted += `${formatted ? ", " : ""}${hours}h`
            if (minutes > 0 || !formatted) formatted += `${formatted ? ", " : ""}${minutes}m`
            uptime = formatted
            interval = ConfigOptions?.resources?.updateInterval ?? 3000
        }
    }

    FileView {
        id: fileUptime

        path: "/proc/uptime"
    }

}
