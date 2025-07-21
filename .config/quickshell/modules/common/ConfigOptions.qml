import QtQuick
import Quickshell
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    property QtObject policies: QtObject {
        property int weeb: 0 // 0: No | 1: Yes | 2: Closet  
    }

    property QtObject windows: QtObject {
        property bool showTitlebar: true
        property bool centerTitle: false
    }

    property QtObject appearance: QtObject {
        property int fakeScreenRounding: 0 // 0: None | 1: Always | 2: When not fullscreen
        property bool transparency: false
        property string logo: "Nobara-linux-logo.svg" // Default logo
        property string logoColor: "#ffffff" // Default logo color (white)
        property QtObject palette: QtObject {
            property string type: "auto"
        }
    }

    property QtObject audio: QtObject { // Values in %
        property QtObject protection: QtObject { // Prevent sudden bangs
            property bool enable: false
            property real maxAllowedIncrease: 10
            property real maxAllowed: 100 // Allow full volume control
        }
    }

    property QtObject apps: QtObject {
        property string bluetooth: "kcmshell6 kcm_bluetooth"
        property string imageViewer: "loupe"
        property string network: "plasmawindowed org.kde.plasma.networkmanagement"
        property string networkEthernet: "kcmshell6 kcm_networkmanagement"
        property string settings: "systemsettings"
        property string taskManager: "flatpak run io.missioncenter.MissionCenter"
        property string terminal: "kitty -1" // This is only for shell actions
    }

    property QtObject battery: QtObject {
        property int low: 20
        property int critical: 5
        property int suspend: 2
        property bool automaticSuspend: false
    }

    property QtObject bar: QtObject {
        property bool showBackground: true
        property bool blurEnabled: true
        property bool xray: false
        property real transparency: 0.55
        property real brightness: 1.0
        property int blurAmount: 8
        property int blurPasses: 4
        property int height: 40
        property int iconSize: 0 // 0 = auto, will be calculated by getIconSize()
        property int workspaceIconSize: 0 // 0 = auto, will be calculated by getWorkspaceIconSize()
        property int indicatorIconSize: 0 // 0 = auto, will be calculated by getIndicatorIconSize()
        property int systrayIconSize: 0 // 0 = auto, will be calculated by getSystrayIconSize()
        property int logoIconSize: 0 // 0 = auto, will be calculated by getLogoIconSize()
        property string borderColor: "#ffffff" // Bar border color (white with opacity)
        property real borderOpacity: 0.12 // Bar border opacity (0.0-1.0)
        property bool borderTop: false // Top border visibility
        property bool borderBottom: true // Bottom border visibility
        property bool borderLeft: false // Left border visibility
        property bool borderRight: false // Right border visibility
        property QtObject workspaces: QtObject {
            property int shown: 10
        }
        property QtObject weather: QtObject {
            property bool enable: true
        }
        property QtObject media: QtObject {
            property bool showVisualizer: true
            property string visualizerType: "circular" // "circular", "radial", "diamond", "fire"
            property int visualizerBars: 44
        }
    }

    property QtObject dock: QtObject {
        property real height: 60
        property real hoverRegionHeight: 3
        property real margin: 20 // Distance from bottom of screen
        property bool pinnedOnStartup: false
        property bool hoverToReveal: false // When false, only reveals on empty workspace
        property bool enable: true
        property real radius: 12 // Dock corner radius
        property real iconSize: 48 // Size of dock icons
        property real spacing: 8 // Spacing between dock items
        property bool autoHide: false // Auto-hide dock when not in use
        property int hideDelay: 200 // Delay before hiding (ms)
        property int showDelay: 50 // Delay before showing (ms)
        property bool showPreviews: true // Show window previews on hover
        property bool showLabels: false // Show app labels under icons
        property real transparency: 0.9 // Dock background transparency (0.0-1.0)
        property string borderColor: "#ffffff" // Dock border color (white with opacity)
        property real borderOpacity: 0.15 // Dock border opacity (0.0-1.0)
        property string innerBorderColor: "#ffffff" // Dock inner border color (white with opacity)
        property real innerBorderOpacity: 0.05 // Dock inner border opacity (0.0-1.0)
        property list<string> pinnedApps: [] // IDs of pinned entries
        property QtObject shadow: QtObject {
            property bool enabled: true // Enable/disable dock shadow
            property string color: "#000000" // Shadow color
            property real opacity: 0.3 // Shadow opacity (0.0-1.0)
            property int horizontalOffset: 0 // Horizontal shadow offset in pixels
            property int verticalOffset: 4 // Vertical shadow offset in pixels
            property int blurRadius: 12 // Shadow blur radius in pixels
        }
    }

    // Remove the dockEnabled property and handlers
    // property bool dockEnabled: dock.enable
    // onDockChanged: {
    //     dockEnabled = dock.enable
    //     console.log("[CONFIG DEBUG] dockEnabled updated to:", dockEnabled)
    // }
    // onDockEnabledChanged: {
    //     console.log("[CONFIG DEBUG] dockEnabled changed to:", dockEnabled)
    // }

    property QtObject language: QtObject {
        property QtObject translator: QtObject {
            property string engine: "auto" // Run `trans -list-engines` for available engines. auto should use google
            property string targetLanguage: "auto" // Run `trans -list-all` for available languages
            property string sourceLanguage: "auto"
        }
    }

    property QtObject networking: QtObject {
        property string userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
        property QtObject wifi: QtObject {
            property bool autoScan: true
            property int scanInterval: 30000 // milliseconds
            property bool showSignalStrength: true
            property bool showSecurityType: true
            property bool autoConnect: true
            property bool rememberNetworks: true
            property list<string> preferredNetworks: []
            property bool showHiddenNetworks: false
            property QtObject connection: QtObject {
                property int timeout: 30000 // milliseconds
                property bool showPassword: false
                property bool autoReconnect: true
            }
        }
    }

    property QtObject osd: QtObject {
        property int timeout: 1000
    }

    property QtObject osk: QtObject {
        property string layout: "qwerty_full"
        property bool pinnedOnStartup: false
    }

    property QtObject overview: QtObject {
        property real scale: 0.18 // Relative to screen size
        property real numOfRows: 2
        property real numOfCols: 5
        property real rows: 2 // Alias for settings compatibility
        property real columns: 5 // Alias for settings compatibility
        property bool showXwaylandIndicator: true
    }

    property QtObject resources: QtObject {
        property int updateInterval: 3000
    }

    property QtObject search: QtObject {
        property int nonAppResultDelay: 30 // This prevents lagging when typing
        property string engineBaseUrl: "https://www.google.com/search?q="
        property list<string> excludedSites: [ "quora.com" ]
        property bool sloppy: false // Uses levenshtein distance based scoring instead of fuzzy sort. Very weird.
        property QtObject prefix: QtObject {
            property string action: "/"
            property string clipboard: ";"
            property string emojis: ":"
        }
    }

    property QtObject sidebar: QtObject {
        property QtObject translator: QtObject {
            property int delay: 300 // Delay before sending request. Reduces (potential) rate limits and lag.
        }
        property QtObject booru: QtObject {
            property bool allowNsfw: false
            property string defaultProvider: "yandere"
            property int limit: 20
            property QtObject zerochan: QtObject {
                property string username: "[unset]"
            }
        }
    }

    property QtObject time: QtObject {
        // https://doc.qt.io/qt-6/qtime.html#toString
        property string format: "hh:mm"
        property string dateFormat: "dddd, dd/MM"
        property string timeZone: "system" // "system" or specific timezone like "America/New_York"
        property bool use24Hour: false
        property bool showSeconds: false
        property bool showDate: true
        property bool showDayOfWeek: true
        property bool showYear: false
        property string customTimeFormat: ""
        property string customDateFormat: ""
        property QtObject display: QtObject {
            property bool showInBar: true
            property bool showInDock: false
            property bool showInSidebar: false
            property int fontSize: 0 // 0 = auto, otherwise specific size
            property bool bold: false
            property bool italic: false
        }
        property QtObject localization: QtObject {
            property string locale: "system" // "system" or specific locale like "en_US"
            property bool useLocalizedNames: true
            property string firstDayOfWeek: "monday" // "monday" or "sunday"
        }
    }

    property QtObject hacks: QtObject {
        property int arbitraryRaceConditionDelay: 20 // milliseconds
    }

    property QtObject logging: QtObject {
        property bool enabled: false // Master switch for all logging
        property bool debug: false
        property bool info: false
        property bool warning: false // Disable all warnings
        property bool error: false // Disable all errors
        property bool suppressIconWarnings: true // Suppress icon loading warnings
        property bool suppressQmlWarnings: true // Suppress QML warnings
        property bool suppressHyprlandWarnings: true // Suppress Hyprland dispatch warnings
        property bool suppressMediaDebug: true // Suppress media player debug spam
        property bool suppressShaderWarnings: true // Suppress shader effect warnings
    }

    function getIconSize() { return bar.iconSize !== undefined ? bar.iconSize : Math.round(bar.height * 0.7); }
    function getWorkspaceIconSize() { return bar.workspaceIconSize !== undefined ? bar.workspaceIconSize : Math.round(bar.height * 0.7); }
    function getIndicatorIconSize() { return bar.indicatorIconSize !== undefined ? bar.indicatorIconSize : Math.round(bar.height * 0.7); }
    function getSystrayIconSize() { return bar.systrayIconSize !== undefined ? bar.systrayIconSize : Math.round(bar.height * 0.7); }
    function getLogoIconSize() { return bar.logoIconSize !== undefined ? bar.logoIconSize : Math.round(bar.height * 0.8); }
}
