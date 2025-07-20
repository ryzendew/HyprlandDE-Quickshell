//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_LOGGING_RULES=qt.qpa.*=false;qt.qml.*=false;qt.quick.*=false;qt.qml.qt5compat.*=false;qt.quick.layouts.*=false;qt.quick.controls.*=false

import "./modules/common/"
import "./modules/bar/"
import "./modules/dock/"
import "./modules/mediaControls/"
import "./modules/notificationPopup/"
import "./modules/onScreenDisplay/"
import "./modules/onScreenKeyboard/"
import "./modules/overview/"
import "./modules/session/"
import "./modules/settings/"
import "./modules/sidebarRight/"
import "./modules/sidebarLeft/"
import "./modules/hyprmenu/"
import "./modules/cheatsheet/"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import "./services/"

// AI DISABLED - User requested complete removal of AI functionality

ShellRoot {
    id: root
    
    // Set organization properties immediately when the component is created
    Component.onCompleted: {
        // Set organization properties for QSettings first, before any other initialization
        Qt.application.organizationName = "Quickshell"
        Qt.application.organizationDomain = "quickshell.org"
        Qt.application.applicationName = "Quickshell"
        
        // Force initialization of some singletons
        MaterialThemeLoader.reapplyTheme()
        ConfigLoader.loadConfig()
        PersistentStateManager.loadStates()
        Cliphist.refresh()
        FirstRunExperience.load()
        
        // Initialize DefaultApps service
        DefaultApps.refreshApps()
        
        // Initialize enableDock
        // root.enableDock = ConfigOptions.dock.enable
    }
    
    // Set organization properties immediately to prevent QSettings warnings
    Timer {
        running: true
        repeat: false
        interval: 0
        onTriggered: {
            Qt.application.organizationName = "Quickshell"
            Qt.application.organizationDomain = "quickshell.org"
            Qt.application.applicationName = "Quickshell"
        }
    }
    property bool enableBar: true
    property bool enableCheatsheet: true
    property bool enableDock: true
    // property bool enableDock: false // Will be set by connection
    
    // Force reactivity by watching the property
    // onEnableDockChanged: {
    //     console.log("[SHELL DEBUG] enableDock changed to:", enableDock)
    // }
    property bool enableMediaControls: true
    property bool enableSimpleMediaPlayer: true
    property bool enableNotificationPopup: true
    property bool enableOnScreenDisplayBrightness: true
    property bool enableOnScreenDisplayVolume: true
    property bool enableOnScreenDisplayMicrophone: true
    property bool enableOnScreenKeyboard: true
    property bool enableOverview: true
    property bool enableReloadPopup: true
    property bool enableSession: true
    property bool enableSettings: true
    property bool enableSidebarRight: true
    property bool enableSidebarLeft: true
    property bool enableHyprMenu: true

    // Enhanced Weather service for widgets
    property var weatherService: WeatherEnhanced {
        id: weatherService
        shell: root
    }
    property alias weatherData: weatherService.weatherData
    property alias weatherLoading: weatherService.loading
    property alias enhancedWeatherData: weatherService.enhancedWeatherData

    // Watch for dock enable/disable changes
    // Connections {
    //     target: ConfigOptions.dock
    //     function onEnableChanged() {
    //         console.log("[SHELL DEBUG] Dock enable changed to:", ConfigOptions.dock.enable)
    //         root.enableDock = ConfigOptions.dock.enable
    //     }
    // }
    

    
    // Modules
    Loader { active: enableBar; sourceComponent: Bar {} }
    Loader { active: enableCheatsheet; sourceComponent: Cheatsheet {} }
    Loader { active: enableDock && ConfigOptions.dock.enable; sourceComponent: Dock {} }
    Loader { active: enableMediaControls; sourceComponent: MediaControls {} }
    Loader { active: enableSimpleMediaPlayer; sourceComponent: SimpleMediaPlayer {} }
    Loader { active: enableNotificationPopup; sourceComponent: NotificationPopup {} }
    Loader { active: enableOnScreenDisplayBrightness; sourceComponent: OnScreenDisplayBrightness {} }
    Loader { active: enableOnScreenDisplayVolume; sourceComponent: OnScreenDisplayVolume {} }
    Loader { active: enableOnScreenDisplayMicrophone; sourceComponent: OnScreenDisplayMicrophone {} }
    Loader { active: enableOnScreenKeyboard; sourceComponent: OnScreenKeyboard {} }
    Loader { active: enableOverview; sourceComponent: Overview {} }
    Loader { active: enableReloadPopup; sourceComponent: ReloadPopup {} }
    Loader { active: enableSession; sourceComponent: Session {} }
    Loader { active: enableSettings; sourceComponent: Settings {} }
    Loader { active: enableSidebarRight; sourceComponent: SidebarRight {} }
    Loader { active: enableSidebarLeft; sourceComponent: SidebarLeft {} }
    Loader { active: enableHyprMenu; sourceComponent: HyprMenu {} }
}

