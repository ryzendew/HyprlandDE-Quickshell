pragma Singleton
import QtQuick 2.15
import Quickshell.Io
import Quickshell.Hyprland

QtObject {
    id: root

    // General blur enable/disable
    property bool blurEnabled: true
    property bool hyprlandAvailable: true
    
    // Store original global blur settings
    property int originalBlurSize: 8
    property int originalBlurPasses: 4

    // Bar settings
    property bool barBlurEnabled: true
    property int barBlurAmount: 8
    property int barBlurPasses: 4
    property bool barXray: false
    property real barTransparency: 0.3
    property real barBrightness: 1.0

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
        updateControlPanelBlurSettings();
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }
    onControlPanelBlurPassesChanged: {
        updateControlPanelBlurSettings();
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }
    onControlPanelXrayChanged: {
        updateControlPanelBlurSettings();
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
        if (!hyprlandAvailable) return;
        
        try {
            // Check if Hyprland is actually available before sending commands
            if (typeof Hyprland === 'undefined' || !Hyprland.dispatch) {
                hyprlandAvailable = false;
                return;
            }
            
            // Send all commands
            Hyprland.dispatch(command);
        } catch (e) {
            // If we get errors, assume Hyprland is not available or doesn't support these commands
            console.log("Hyprland command failed:", command, e);
        }
    }

    // Function to save current global blur settings
    function saveGlobalBlurSettings() {
        if (!hyprlandAvailable) return;
        
        try {
            // Note: We can't easily read current settings via hyprctl
            // So we'll use reasonable defaults and let user adjust if needed
            originalBlurSize = 8;
            originalBlurPasses = 4;
        } catch (e) {
            console.log("Failed to save global blur settings:", e);
        }
    }
    
    // Function to restore original global blur settings
    function restoreGlobalBlurSettings() {
        if (!hyprlandAvailable) return;
        
        try {
            safeDispatch(`exec hyprctl keyword decoration:blur:size ${originalBlurSize}`)
            safeDispatch(`exec hyprctl keyword decoration:blur:passes ${originalBlurPasses}`)
        } catch (e) {
            console.log("Failed to restore global blur settings:", e);
        }
    }
    
    // New function for proper blur control using hyprctl keyword
    // Note: This sets GLOBAL blur settings that affect all windows with blur
    // Hyprland doesn't support per-layer blur amounts
    function updateBlurSettings() {
        if (!hyprlandAvailable) return;
        
        try {
            if (barBlurEnabled) {
                // Enable global blur and set to bar values
                safeDispatch(`exec hyprctl keyword decoration:blur:enabled true`)
                safeDispatch(`exec hyprctl keyword decoration:blur:size ${barBlurAmount}`)
                safeDispatch(`exec hyprctl keyword decoration:blur:passes ${barBlurPasses}`)
                
                // Apply layer-specific rules for bar only
                safeDispatch(`exec hyprctl keyword layerrule "blur,^(quickshell:bar:blur)$"`)
            } else {
                // Disable global blur
                safeDispatch(`exec hyprctl keyword decoration:blur:enabled false`)
                
                // Remove blur from bar layer
                safeDispatch(`exec hyprctl keyword layerrule "noanim,^(quickshell:bar:blur)$"`)
            }
            
            if (barXray) {
                safeDispatch(`exec hyprctl keyword layerrule "xray on,^(quickshell:bar:blur)$"`)
            } else {
                safeDispatch(`exec hyprctl keyword layerrule "xray off,^(quickshell:bar:blur)$"`)
            }
        } catch (e) {
            console.log("Blur settings update failed:", e);
        }
    }

    // Save settings when they change
    onBarBlurEnabledChanged: {
        updateBarBlurSettings();
        safeDispatch("exec killall -SIGUSR2 quickshell");
    }
    onBarBlurAmountChanged: {
        updateBarBlurSettings();
        safeDispatch("exec killall -SIGUSR2 quickshell");
    }
    onBarBlurPassesChanged: {
        updateBarBlurSettings();
        safeDispatch("exec killall -SIGUSR2 quickshell");
    }
    onBarXrayChanged: {
        updateBarBlurSettings();
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }
    onBarTransparencyChanged: safeDispatch("exec killall -SIGUSR2 quickshell")
    onBarBrightnessChanged: safeDispatch("exec killall -SIGUSR2 quickshell")
    
    onDockTransparencyChanged: {
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }
    onDockBlurAmountChanged: {
        updateDockBlurSettings();
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }
    onDockBlurPassesChanged: {
        updateDockBlurSettings();
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }
    onDockXrayChanged: {
        updateDockBlurSettings();
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }

    onSidebarTransparencyChanged: {
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }
    onSidebarXrayChanged: {
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }

    onWeatherTransparencyChanged: {
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }
    onWeatherBlurAmountChanged: {
        updateWeatherBlurSettings();
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }
    onWeatherBlurPassesChanged: {
        updateWeatherBlurSettings();
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }
    onWeatherXrayChanged: {
        updateWeatherBlurSettings();
        safeDispatch("exec killall -SIGUSR2 quickshell")
    }

    function updateDockBlurSettings() {
        if (!hyprlandAvailable) return;
        
        try {
            // Set global blur settings to dock values
            safeDispatch(`exec hyprctl keyword decoration:blur:size ${dockBlurAmount}`)
            safeDispatch(`exec hyprctl keyword decoration:blur:passes ${dockBlurPasses}`)
            
            // Apply layer-specific rules for dock only
            safeDispatch(`exec hyprctl keyword layerrule "blur,^(quickshell:dock:blur)$"`)
            
            if (dockXray) {
                safeDispatch(`exec hyprctl keyword layerrule "xray on,^(quickshell:dock:blur)$"`)
            } else {
                safeDispatch(`exec hyprctl keyword layerrule "xray off,^(quickshell:dock:blur)$"`)
            }
        } catch (e) {
            console.log("Dock blur settings update failed:", e);
        }
    }

    function updateWeatherBlurSettings() {
        if (!hyprlandAvailable) return;
        
        try {
            // Apply layer-specific rules for weather with specific blur settings
            safeDispatch(`exec hyprctl keyword layerrule "blur ${weatherBlurAmount} ${weatherBlurPasses},^(quickshell:weather:blur)$"`)
            
            if (weatherXray) {
                safeDispatch(`exec hyprctl keyword layerrule "xray on,^(quickshell:weather:blur)$"`)
            } else {
                safeDispatch(`exec hyprctl keyword layerrule "xray off,^(quickshell:weather:blur)$"`)
            }
        } catch (e) {
            console.log("Weather blur settings update failed:", e);
        }
    }
    
    function updateBarBlurSettings() {
        updateBlurSettings()
    }
    
    function updateControlPanelBlurSettings() {
        if (!hyprlandAvailable) return;
        
        try {
            // Apply layer-specific rules for control panel with specific blur settings
            safeDispatch(`exec hyprctl keyword layerrule "blur ${controlPanelBlurAmount} ${controlPanelBlurPasses},^(quickshell:controlpanel:blur)$"`)
            
            if (controlPanelXray) {
                safeDispatch(`exec hyprctl keyword layerrule "xray on,^(quickshell:controlpanel:blur)$"`)
            } else {
                safeDispatch(`exec hyprctl keyword layerrule "xray off,^(quickshell:controlpanel:blur)$"`)
            }
        } catch (e) {
            console.log("Control panel blur settings update failed:", e);
        }
    }

    // Apply initial settings
    Component.onCompleted: {
        // Initialize from ConfigOptions
        barTransparency = ConfigOptions.bar?.transparency ?? 0.3;
        barBrightness = ConfigOptions.bar?.brightness ?? 1.0;
        barBlurEnabled = ConfigOptions.bar?.blurEnabled ?? true;
        barXray = ConfigOptions.bar?.xray ?? false;
        barBlurAmount = ConfigOptions.bar?.blurAmount ?? 8;
        barBlurPasses = ConfigOptions.bar?.blurPasses ?? 4;
        
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
        
        // Blur settings are controlled by static layer rules in hyprland config
        // No dynamic initialization needed to avoid "Invalid dispatcher" errors
    }
} 