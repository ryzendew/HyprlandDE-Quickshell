pragma Singleton
import QtQuick 2.15
import Quickshell.Io
import Quickshell.Hyprland

QtObject {
    id: root

    // General blur enable/disable
    property bool blurEnabled: true
    property bool hyprlandAvailable: true

    // Bar settings
    property int barBlurAmount: 8
    property int barBlurPasses: 4
    property bool barXray: false

    // Control Panel settings
    property real controlPanelTransparency: 0.65
    property int controlPanelBlurAmount: 8
    property int controlPanelBlurPasses: 4
    property bool controlPanelXray: false
    
    // Control Panel property change handlers
    onControlPanelTransparencyChanged: {
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }
    onControlPanelBlurAmountChanged: {
        if (blurEnabled) {
            safeDispatch("setvar decoration:blur:enabled 1")
            safeDispatch("setvar decoration:blur:size " + controlPanelBlurAmount)
            safeDispatch("layerrule blur,^(quickshell:controlpanel:blur)$")
        }
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }
    onControlPanelBlurPassesChanged: {
        if (blurEnabled) {
            safeDispatch("setvar decoration:blur:passes " + controlPanelBlurPasses)
        }
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }
    onControlPanelXrayChanged: {
        if (controlPanelXray) {
            safeDispatch("layerrule xray on,^(quickshell:controlpanel:blur)$")
        } else {
            safeDispatch("layerrule xray off,^(quickshell:controlpanel:blur)$")
        }
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }

    // Dock settings
    property real dockTransparency: 0.65
    property int dockBlurAmount: 20
    property int dockBlurPasses: 2
    property bool dockXray: false

    // Sidebar settings
    property real sidebarTransparency: 0.2
    property bool sidebarXray: false

    // Weather widget settings
    property real weatherTransparency: 0.8
    property int weatherBlurAmount: 8
    property int weatherBlurPasses: 4
    property bool weatherXray: false

    // Helper function to safely dispatch Hyprland commands
    function safeDispatch(command) {
        // Skip Hyprland commands since layer rules are already defined in config
        // This prevents the "Invalid dispatcher" warnings
        if (command.includes("layerrule") || command.includes("setvar")) {
            return;
        }
        
        if (!hyprlandAvailable) return;
        
        try {
            // Check if Hyprland is actually available before sending commands
            if (typeof Hyprland === 'undefined' || !Hyprland.dispatch) {
                hyprlandAvailable = false;
                return;
            }
            
            // Only send non-layerrule commands
            Hyprland.dispatch(command);
        } catch (e) {
            // If we get errors, assume Hyprland is not available or doesn't support these commands
            console.log("Hyprland command failed:", command, e);
        }
    }

    // Save settings when they change
    onBarBlurAmountChanged: safeDispatch("exec killall -SIGUSR2 quickshell")
    onBarBlurPassesChanged: safeDispatch("exec killall -SIGUSR2 quickshell")
    onBarXrayChanged: safeDispatch("exec killall -SIGUSR2 quickshell")
    
    onDockTransparencyChanged: {
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }
    onDockBlurAmountChanged: {
        if (blurEnabled) {
            safeDispatch("setvar decoration:blur:enabled 1")
            safeDispatch("setvar decoration:blur:size " + dockBlurAmount)
            safeDispatch("layerrule blur,^(quickshell:dock:blur)$")
        }
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }
    onDockBlurPassesChanged: {
        if (blurEnabled) {
            safeDispatch("setvar decoration:blur:passes " + dockBlurPasses)
        }
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }
    onDockXrayChanged: {
        if (dockXray) {
            safeDispatch("layerrule xray on,^(quickshell:dock:blur)$")
        } else {
            safeDispatch("layerrule xray off,^(quickshell:dock:blur)$")
        }
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }

    onSidebarTransparencyChanged: {
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }
    onSidebarXrayChanged: {
        if (sidebarXray) {
            safeDispatch("layerrule xray on,^(quickshell:sidebarLeft)$")
            safeDispatch("layerrule xray on,^(quickshell:sidebarRight)$")
        } else {
            safeDispatch("layerrule xray off,^(quickshell:sidebarLeft)$")
            safeDispatch("layerrule xray off,^(quickshell:sidebarRight)$")
        }
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }

    onWeatherTransparencyChanged: {
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }
    onWeatherBlurAmountChanged: {
        if (blurEnabled) {
            safeDispatch("setvar decoration:blur:enabled 1")
            safeDispatch("setvar decoration:blur:size " + weatherBlurAmount)
            safeDispatch("layerrule blur,^(quickshell:weather:blur)$")
        }
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }
    onWeatherBlurPassesChanged: {
        if (blurEnabled) {
            safeDispatch("setvar decoration:blur:passes " + weatherBlurPasses)
        }
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }
    onWeatherXrayChanged: {
        if (weatherXray) {
            safeDispatch("layerrule xray on,^(quickshell:weather:blur)$")
        } else {
            safeDispatch("layerrule xray off,^(quickshell:weather:blur)$")
        }
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }

    function updateDockBlurSettings() {
        if (!blurEnabled) {
            safeDispatch("layerrule unset,^(quickshell:dock:blur)$")
            return;
        }
        safeDispatch("setvar decoration:blur:enabled 1")
        safeDispatch("setvar decoration:blur:size " + dockBlurAmount)
        safeDispatch("setvar decoration:blur:passes " + dockBlurPasses)
        safeDispatch("layerrule blur,^(quickshell:dock:blur)$")
        if (dockXray) {
            safeDispatch("layerrule xray on,^(quickshell:dock:blur)$")
        } else {
            safeDispatch("layerrule xray off,^(quickshell:dock:blur)$")
        }
    }

    function updateWeatherBlurSettings() {
        if (!blurEnabled) {
            safeDispatch("layerrule unset,^(quickshell:weather:blur)$")
            return;
        }
        safeDispatch("setvar decoration:blur:enabled 1")
        safeDispatch("setvar decoration:blur:size " + weatherBlurAmount)
        safeDispatch("setvar decoration:blur:passes " + weatherBlurPasses)
        safeDispatch("layerrule blur,^(quickshell:weather:blur)$")
        if (weatherXray) {
            safeDispatch("layerrule xray on,^(quickshell:weather:blur)$")
        } else {
            safeDispatch("layerrule xray off,^(quickshell:weather:blur)$")
        }
    }
    
    function updateBarBlurSettings() {
        if (!blurEnabled) {
            safeDispatch("layerrule unset,^(quickshell:bar:blur)$")
            return;
        }
        safeDispatch("setvar decoration:blur:enabled 1")
        safeDispatch("layerrule blur,^(quickshell:bar:blur)$")
        if (barXray) {
            safeDispatch("layerrule xray on,^(quickshell:bar:blur)$")
        } else {
            safeDispatch("layerrule xray off,^(quickshell:bar:blur)$")
        }
    }
    
    function updateControlPanelBlurSettings() {
        if (!blurEnabled) {
            safeDispatch("layerrule unset,^(quickshell:controlpanel:blur)$")
            return;
        }
        safeDispatch("setvar decoration:blur:enabled 1")
        safeDispatch("setvar decoration:blur:size " + controlPanelBlurAmount)
        safeDispatch("setvar decoration:blur:passes " + controlPanelBlurPasses)
        safeDispatch("layerrule blur,^(quickshell:controlpanel:blur)$")
        if (controlPanelXray) {
            safeDispatch("layerrule xray on,^(quickshell:controlpanel:blur)$")
        } else {
            safeDispatch("layerrule xray off,^(quickshell:controlpanel:blur)$")
        }
    }

    // Apply initial settings
    Component.onCompleted: {
        // Check if Hyprland is available by checking if the object exists
        try {
            if (typeof Hyprland !== 'undefined' && Hyprland.dispatch) {
                hyprlandAvailable = true;
            } else {
                hyprlandAvailable = false;
            }
        } catch (e) {
            hyprlandAvailable = false;
        }
        
        if (hyprlandAvailable) {
            updateDockBlurSettings()
            updateWeatherBlurSettings()
            updateBarBlurSettings()
            updateControlPanelBlurSettings()
            if (sidebarXray) {
                safeDispatch("layerrule xray on,^(quickshell:sidebarLeft)$")
                safeDispatch("layerrule xray on,^(quickshell:sidebarRight)$")
            } else {
                safeDispatch("layerrule xray off,^(quickshell:sidebarLeft)$")
                safeDispatch("layerrule xray off,^(quickshell:sidebarRight)$")
            }
        }
    }
} 