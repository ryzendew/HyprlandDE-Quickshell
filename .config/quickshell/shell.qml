//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

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
    
    // Enable/disable modules here. False = not loaded at all, so rest assured
    // no unnecessary stuff will take up memory if you decide to only use, say, the overview.
    property bool enableBar: true
    property bool enableCheatsheet: true
    property bool enableDock: ConfigOptions.dock.enable
    property bool enableMediaControls: false
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
    property bool enableHyprMenu: true

    // Force initialization of some singletons
    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        ConfigLoader.loadConfig()
        PersistentStateManager.loadStates()
        Cliphist.refresh()
        FirstRunExperience.load()
    }

    // Weather service for widgets
    property var weatherService: Weather {
        id: weatherService
        shell: root
    }
    property alias weatherData: weatherService.weatherData
    property alias weatherLoading: weatherService.loading

    // Modules
    Loader { active: enableBar; sourceComponent: Bar {} }
    Loader { active: enableCheatsheet; sourceComponent: Cheatsheet {} }
    Loader { active: enableDock; sourceComponent: Dock {} }
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
    Loader { active: enableHyprMenu; sourceComponent: HyprMenu {} }
}

