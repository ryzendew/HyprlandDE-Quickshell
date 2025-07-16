import "root:/"
import "root:/services/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    
    // Position configuration - options: "top-left", "top-center", "top-right", "center", "bottom-left", "bottom-center", "bottom-right"
    property string menuPosition: "bottom-center" // Default fallback

    // Function to refresh desktop database and app list
    function refreshApps() {
        if (AppSearch.available) {
            // console.log("[HYPRMENU] Refreshing desktop application database...")
            // console.log("[HYPRMENU] Calling AppSearch.refresh()...")
            AppSearch.refresh().then(() => {
                // console.log("[HYPRMENU] AppSearch.refresh() completed successfully.");
            }).catch((error) => {
                // console.log("[HYPRMENU] Error calling AppSearch.refresh():", error);
            });
        } else {
            // Fallback or alternative refresh logic if AppSearch is not available
            // This section might need adjustment based on how you want to handle this case
            var window = null
            for (var i = 0; i < root.children.length; i++) {
                if (root.children[i].objectName === "menuWindow") {
                    window = root.children[i]
                    break
                }
            }
            if (window) {
                window.isRefreshing = true
            }
            try {
                // AppSearch.refresh() // Original call, assuming it might still be tried or logged
                // console.log("[HYPRMENU] AppSearch.refresh() called (fallback attempt)."); 
                // Set a timer to stop the refreshing state
                Qt.createQmlObject('
                    import QtQuick
                    Timer {
                        interval: 2000
                        running: true
                        onTriggered: {
                            root.onRefreshCompleted()
                            destroy()
                        }
                    }
                ', root)
            } catch (error) {
                // console.log("[HYPRMENU] Error in fallback refresh logic:", error);
                if (window) {
                    window.isRefreshing = false
                }
            }
        }
    }
    
    function onRefreshCompleted() {
        var window = null
        for (var i = 0; i < root.children.length; i++) {
            if (root.children[i].objectName === "menuWindow") {
                window = root.children[i]
                break
            }
        }
        if (window) {
            window.isRefreshing = false
        }
    }

    Variants {
        // Show on all screens
        model: Quickshell.screens
        
        PanelWindow {
            id: menuWindow
            required property var modelData
            objectName: "menuWindow"  // Add this so the refresh function can find it
            
            property bool isGridView: true
            property string searchText: ""
            property var filteredApps: []
            property var categories: ["All", "Development", "Games", "Graphics", "Internet", "Multimedia", "Office", "System", "Utilities"]
            property string selectedCategory: "All"
            property bool isRefreshing: false
            
            screen: modelData
            visible: GlobalStates.hyprMenuOpen || false
            
            WlrLayershell.namespace: "quickshell:hyprmenu"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            color: "transparent"
            
            // Make it float without affecting window layout
            exclusiveZone: 0
            
            // Position as floating popup
            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }
            
            onVisibleChanged: {
                if (visible) {
                    menuWindow.searchText = "" // Clear search on open
                    focusGrabTimer.start()
                } else {
                    focusGrabTimer.stop()
                    focusGrab.active = false
                }
            }
            
            // Focus grab to close menu when clicking outside
            HyprlandFocusGrab {
                id: focusGrab
                windows: [menuWindow]
                active: false // Start inactive
                onCleared: () => {
                    if (!active) return
                    GlobalStates.hyprMenuOpen = false
                }
            }
            
            // Timer to delay focus grab activation
            Timer {
                id: focusGrabTimer
                interval: 500 // Much longer delay to prevent interference with button clicks
                onTriggered: {
                    if (menuWindow.visible) {
                        focusGrab.active = true
                    }
                }
            }
            
            // Main container
            Rectangle {
                id: menuContainer
                
                // Animation properties
                property bool isAnimating: false
                property real animationProgress: 0
                
                // Dynamic positioning based on menuPosition
                anchors.horizontalCenter: root.menuPosition.includes("center") || root.menuPosition === "center" ? parent.horizontalCenter : undefined
                anchors.left: root.menuPosition.includes("left") ? parent.left : undefined
                anchors.right: root.menuPosition.includes("right") ? parent.right : undefined
                anchors.top: root.menuPosition.includes("top") ? parent.top : undefined
                anchors.bottom: root.menuPosition.includes("bottom") ? parent.bottom : undefined
                anchors.verticalCenter: root.menuPosition === "center" ? parent.verticalCenter : undefined
                
                // Add margins to keep menu away from edges
                anchors.leftMargin: root.menuPosition.includes("left") ? 20 : 0
                anchors.rightMargin: root.menuPosition.includes("right") ? 20 : 0
                anchors.topMargin: root.menuPosition.includes("top") ? 60 : 0  // Space for bar
                anchors.bottomMargin: root.menuPosition.includes("bottom") ? 2 : 0  // Just 2px above dock
                
                width: 800
                height: 600
                radius: 12
                
                // Transform origin for scaling from bottom
                transformOrigin: Item.Bottom
                
                // Scale and opacity for animation
                scale: menuWindow.visible ? 1.0 : 0.8
                opacity: menuWindow.visible ? 1.0 : 0.0
                
                // Y position animation to slide up from bottom
                y: menuWindow.visible ? 0 : 50
                
                // Material 3 dark theme with transparency
                color: Qt.rgba(
                    Appearance.colors.colLayer0.r,
                    Appearance.colors.colLayer0.g,
                    Appearance.colors.colLayer0.b,
                    0.55
                )
                border.color: Qt.rgba(
                    Appearance.colors.colOutline.r,
                    Appearance.colors.colOutline.g,
                    Appearance.colors.colOutline.b,
                    0.9
                )
                border.width: 1
                
                // Animation behaviors
                Behavior on scale {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }
                
                Behavior on y {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }
                
                // Enhanced drop shadow with blur
                layer.enabled: true
                layer.effect: MultiEffect {
                    source: menuContainer
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.7)  // Black shadow
                    shadowVerticalOffset: 8
                    shadowHorizontalOffset: 0
                    shadowBlur: 32
                }
                
                // Material 3 gradient overlay for depth
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(Appearance.colors.colLayer1.r, Appearance.colors.colLayer1.g, Appearance.colors.colLayer1.b, 0.3) }
                        GradientStop { position: 0.5; color: Qt.rgba(Appearance.colors.colLayer0.r, Appearance.colors.colLayer0.g, Appearance.colors.colLayer0.b, 0.2) }
                        GradientStop { position: 1.0; color: Qt.rgba(Appearance.colors.colLayer0.r, Appearance.colors.colLayer0.g, Appearance.colors.colLayer0.b, 0.4) }
                    }
                }
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12
                    
                    // Header with search and view toggle
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        
                        // Search field
                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            radius: 8
                            color: Qt.rgba(0.1, 0.1, 0.1, 0.55)  // Black with transparency
                            border.color: Qt.rgba(0.3, 0.3, 0.3, 0.8)  // Dark gray border
                            border.width: 1
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8
                                
                                MaterialSymbol {
                                    text: "search"
                                    iconSize: 20
                                    color: Qt.rgba(0.9, 0.9, 0.9, 0.9)  // Light gray icon
                                    opacity: 0.8
                                }
                                
                                TextField {
                                    id: searchField
                                    Layout.fillWidth: true
                                    placeholderText: qsTr("Search applications... (F5 to refresh)")
                                    placeholderTextColor: Qt.rgba(0.6, 0.6, 0.6, 0.6)  // Gray placeholder
                                    color: Qt.rgba(0.95, 0.95, 0.95, 0.95)  // Light gray text
                                    background: null
                                    focus: menuWindow.visible
                                    
                                    onTextChanged: {
                                        menuWindow.searchText = text
                                        updateFilteredApps()
                                    }
                                    
                                    Keys.onPressed: (event) => {
                                        if (event.key === Qt.Key_Escape) {
                                            GlobalStates.hyprMenuOpen = false
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                            if (menuWindow.filteredApps.length > 0) {
                                                launchApp(menuWindow.filteredApps[0])
                                            }
                                        } else if (event.key === Qt.Key_F5) {
                                            // F5 to refresh apps manually
                                            root.refreshApps()
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Refresh button
                        Rectangle {
                            width: 40
                            height: 40
                            radius: 8
                            color: refreshArea.containsMouse ? Qt.rgba(Appearance.colors.colLayer2Hover.r, Appearance.colors.colLayer2Hover.g, Appearance.colors.colLayer2Hover.b, 0.8) : Qt.rgba(Appearance.colors.colLayer2.r, Appearance.colors.colLayer2.g, Appearance.colors.colLayer2.b, 0.6)
                            border.color: Qt.rgba(Appearance.colors.colOutline.r, Appearance.colors.colOutline.g, Appearance.colors.colOutline.b, 0.8)
                            border.width: 1
                            opacity: menuWindow.isRefreshing ? 0.6 : 1.0
                            
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "refresh"
                                iconSize: 20
                                color: Appearance.colors.colOnLayer2
                                
                                // Rotation animation when refreshing
                                RotationAnimation on rotation {
                                    running: menuWindow.isRefreshing
                                    from: 0
                                    to: 360
                                    duration: 1000
                                    loops: Animation.Infinite
                                }
                            }
                            
                            MouseArea {
                                id: refreshArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !menuWindow.isRefreshing
                                onClicked: {
                                    // console.log("[HYPRMENU] Manual refresh requested")
                                    root.refreshApps()
                                }
                            }
                            
                            // Tooltip for refresh button
                            ToolTip {
                                visible: refreshArea.containsMouse && !menuWindow.isRefreshing
                                text: qsTr("Refresh app list (F5)")
                                delay: 1000
                            }
                            
                            // Refreshing tooltip
                            ToolTip {
                                visible: refreshArea.containsMouse && menuWindow.isRefreshing
                                text: qsTr("Refreshing...")
                                delay: 100
                            }
                        }
                        
                        // View toggle button
                        Rectangle {
                            width: 40
                            height: 40
                            radius: 8
                            color: viewToggleArea.containsMouse ? Qt.rgba(Appearance.colors.colLayer2Hover.r, Appearance.colors.colLayer2Hover.g, Appearance.colors.colLayer2Hover.b, 0.8) : Qt.rgba(Appearance.colors.colLayer2.r, Appearance.colors.colLayer2.g, Appearance.colors.colLayer2.b, 0.6)
                            border.color: Qt.rgba(Appearance.colors.colOutline.r, Appearance.colors.colOutline.g, Appearance.colors.colOutline.b, 0.8)
                            border.width: 1
                            
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: menuWindow.isGridView ? "view_list" : "grid_view"
                                iconSize: 20
                                color: Appearance.colors.colOnLayer2
                            }
                            
                            MouseArea {
                                id: viewToggleArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: menuWindow.isGridView = !menuWindow.isGridView
                            }
                        }
                    }
                    
                    // Category tabs
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        clip: true
                        
                        RowLayout {
                            spacing: 4
                            
                            Repeater {
                                model: menuWindow.categories
                                
                                Rectangle {
                                    Layout.preferredHeight: 32
                                    Layout.preferredWidth: categoryText.implicitWidth + 24
                                    radius: 6
                                    color: menuWindow.selectedCategory === modelData ? Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.8) : (categoryArea.containsMouse ? Qt.rgba(Appearance.colors.colLayer2Hover.r, Appearance.colors.colLayer2Hover.g, Appearance.colors.colLayer2Hover.b, 0.6) : Qt.rgba(Appearance.colors.colLayer2.r, Appearance.colors.colLayer2.g, Appearance.colors.colLayer2.b, 0.4))
                                    border.color: Qt.rgba(Appearance.colors.colOutline.r, Appearance.colors.colOutline.g, Appearance.colors.colOutline.b, 0.7)
                                    border.width: menuWindow.selectedCategory === modelData ? 0 : 1
                                    
                                    Text {
                                        id: categoryText
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: menuWindow.selectedCategory === modelData ? 
                                               Appearance.colors.colOnLayer2 : 
                                               Appearance.colors.colOnLayer1
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: menuWindow.selectedCategory === modelData ? Font.Medium : Font.Normal
                                    }
                                    
                                    MouseArea {
                                        id: categoryArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            menuWindow.selectedCategory = modelData
                                            updateFilteredApps()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Main content area
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: Qt.rgba(Appearance.colors.colLayer1.r, Appearance.colors.colLayer1.g, Appearance.colors.colLayer1.b, 0.6)
                        border.color: Qt.rgba(Appearance.colors.colOutline.r, Appearance.colors.colOutline.g, Appearance.colors.colOutline.b, 0.8)
                        border.width: 1
                        
                        // Grid view
                        ScrollView {
                            id: gridView
                            anchors.fill: parent
                            anchors.margins: 8
                            visible: menuWindow.isGridView
                            clip: true
                            
                            GridLayout {
                                width: gridView.width
                                columns: Math.floor(gridView.width / 120)
                                rowSpacing: 12
                                columnSpacing: 12
                                
                                Repeater {
                                    model: menuWindow.filteredApps
                                    
                                    Rectangle {
                                        Layout.preferredWidth: 100
                                        Layout.preferredHeight: 100
                                        radius: 8
                                        color: appArea.containsMouse ? Qt.rgba(Appearance.m3colors.m3primary.r, Appearance.m3colors.m3primary.g, Appearance.m3colors.m3primary.b, 0.1) : "transparent"
                                        
                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            
                                            Image {
                                                Layout.alignment: Qt.AlignHCenter
                                                Layout.preferredWidth: 48
                                                Layout.preferredHeight: 48
                                                source: modelData.iconUrl || "image://icon/" + (modelData.icon || "application-x-executable")
                                                fillMode: Image.PreserveAspectFit
                                                onStatusChanged: {
                                                    if (status === Image.Error) {
                                                        source = "image://icon/application-x-executable"
                                                    }
                                                }
                                            }
                                            
                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                Layout.preferredWidth: 90
                                                text: modelData.name
                                                color: Appearance.colors.colOnLayer1
                                                font.pixelSize: Appearance.font.pixelSize.smallest
                                                horizontalAlignment: Text.AlignHCenter
                                                wrapMode: Text.Wrap
                                                maximumLineCount: 2
                                                elide: Text.ElideRight
                                            }
                                        }
                                        
                                        MouseArea {
                                            id: appArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: launchApp(modelData)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // List view
                        ScrollView {
                            id: listView
                            anchors.fill: parent
                            anchors.margins: 8
                            visible: !menuWindow.isGridView
                            clip: true
                            
                            ColumnLayout {
                                width: listView.width
                                spacing: 0
                                
                                Repeater {
                                    model: menuWindow.filteredApps
                                    
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 56
                                            color: listAppArea.containsMouse ? Qt.rgba(Appearance.m3colors.m3primary.r, Appearance.m3colors.m3primary.g, Appearance.m3colors.m3primary.b, 0.1) : "transparent"
                                            
                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 16
                                                anchors.rightMargin: 16
                                                anchors.topMargin: 8
                                                anchors.bottomMargin: 8
                                                spacing: 16
                                                
                                                Image {
                                                    Layout.preferredWidth: 40
                                                    Layout.preferredHeight: 40
                                                    Layout.alignment: Qt.AlignVCenter
                                                    source: modelData.iconUrl || "image://icon/" + (modelData.icon || "application-x-executable")
                                                    fillMode: Image.PreserveAspectFit
                                                    onStatusChanged: {
                                                        if (status === Image.Error) {
                                                            source = "image://icon/application-x-executable"
                                                        }
                                                    }
                                                }
                                                
                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignVCenter
                                                    spacing: 2
                                                    
                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: modelData.name
                                                        color: Appearance.colors.colOnLayer1
                                                        font.pixelSize: Appearance.font.pixelSize.normal
                                                        font.weight: Font.Medium
                                                        horizontalAlignment: Text.AlignLeft
                                                        elide: Text.ElideRight
                                                    }
                                                    
                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: modelData.description || ""
                                                        color: Appearance.colors.colOnLayer1
                                                        opacity: 0.7
                                                        font.pixelSize: Appearance.font.pixelSize.small
                                                        horizontalAlignment: Text.AlignLeft
                                                        elide: Text.ElideRight
                                                        visible: text !== ""
                                                    }
                                                }
                                            }
                                            
                                            MouseArea {
                                                id: listAppArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onClicked: launchApp(modelData)
                                            }
                                        }
                                        
                                        // Separator line (except for last item)
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 1
                                            Layout.leftMargin: 72  // Align with text, not icon
                                            Layout.rightMargin: 16
                                            color: Appearance.colors.colOnLayer1
                                            opacity: 0.1
                                            visible: index < menuWindow.filteredApps.length - 1
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // System controls
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: 8
                        color: Appearance.colors.colLayer2
                        border.color: Appearance.colors.colOnLayer0
                        border.width: 1
                        
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 16
                            
                            // System buttons
                            Repeater {
                                model: [
                                    {icon: "lock", tooltip: qsTr("Lock"), command: "hyprlock"},
                                    {icon: "logout", tooltip: qsTr("Logout"), command: "hyprctl dispatch exit"},
                                    {icon: "restart_alt", tooltip: qsTr("Restart"), command: "systemctl reboot"},
                                    {icon: "power_settings_new", tooltip: qsTr("Shutdown"), command: "systemctl poweroff"}
                                ]
                                
                                Rectangle {
                                    width: 36
                                    height: 36
                                    radius: 6
                                    color: sysArea.containsMouse ? Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, 0.1) : "transparent"
                                    
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: modelData.icon
                                        iconSize: 20
                                        color: Appearance.colors.colOnLayer1
                                    }
                                    
                                    MouseArea {
                                        id: sysArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            Hyprland.dispatch("exec " + modelData.command)
                                            GlobalStates.hyprMenuOpen = false
                                        }
                                    }
                                    
                                    // Tooltip
                                    ToolTip {
                                        visible: sysArea.containsMouse
                                        text: modelData.tooltip
                                        delay: 500
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Functions
            function updateFilteredApps() {
                var apps = AppSearch.list
                var filtered = []
                
                for (var i = 0; i < apps.length; i++) {
                    var app = apps[i]
                    
                    // Filter by search text
                    if (searchText !== "" && 
                        !app.name.toLowerCase().includes(searchText.toLowerCase()) &&
                        !(app.description && app.description.toLowerCase().includes(searchText.toLowerCase()))) {
                        continue
                    }
                    
                    // Filter by category (simplified)
                    if (selectedCategory !== "All") {
                        var categories = app.categories || []
                        var matchesCategory = false
                        
                        for (var j = 0; j < categories.length; j++) {
                            var cat = categories[j].toLowerCase()
                            if ((selectedCategory === "Development" && (cat.includes("development") || cat.includes("programming"))) ||
                                (selectedCategory === "Games" && cat.includes("game")) ||
                                (selectedCategory === "Graphics" && cat.includes("graphics")) ||
                                (selectedCategory === "Internet" && cat.includes("network")) ||
                                (selectedCategory === "Multimedia" && (cat.includes("audio") || cat.includes("video"))) ||
                                (selectedCategory === "Office" && cat.includes("office")) ||
                                (selectedCategory === "System" && cat.includes("system")) ||
                                (selectedCategory === "Utilities" && cat.includes("utility"))) {
                                matchesCategory = true
                                break
                            }
                        }
                        
                        if (!matchesCategory) continue
                    }
                    
                    filtered.push(app)
                }
                
                filteredApps = filtered
            }
            
            function launchApp(app) {
                if (app && app.execute) {
                    app.execute()
                    GlobalStates.hyprMenuOpen = false
                } else if (app && app.desktopId) {
                    // Fallback to the old method if execute is not available
                    Hyprland.dispatch("exec gio launch " + app.desktopId)
                    GlobalStates.hyprMenuOpen = false
                }
            }
            
            Component.onCompleted: {
                updateFilteredApps()
                // Connect to the global signal for manual refresh
                // GlobalSignals.connect(Quickshell, "hyprmenuRefreshApps", () => {
                //     // console.log("[HYPRMENU] Manual refresh requested")
                //     refreshApps()
                // })
            }
            
            // Close on escape key
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    GlobalStates.hyprMenuOpen = false
                }
            }
        }
    }
    
    // IPC handler for external control
    IpcHandler {
        target: "hyprmenu"
        
        function toggle() {
            GlobalStates.hyprMenuOpen = !GlobalStates.hyprMenuOpen
        }
        
        function show() {
            GlobalStates.hyprMenuOpen = true
        }
        
        function hide() {
            GlobalStates.hyprMenuOpen = false
        }
    }
    
    // Global shortcut
    GlobalShortcut {
        name: "hyprMenuToggle"
        description: qsTr("Toggle HyprMenu")
        
        onPressed: {
            GlobalStates.hyprMenuOpen = !GlobalStates.hyprMenuOpen
        }
    }
    
    // Super key release toggle (like Windows key)
    GlobalShortcut {
        name: "hyprMenuToggleRelease"
        description: qsTr("Toggles HyprMenu on Super key release")

        onPressed: {
            GlobalStates.superReleaseMightTrigger = true
        }

        onReleased: {
            if (!GlobalStates.superReleaseMightTrigger) {
                GlobalStates.superReleaseMightTrigger = true
                return
            }
            GlobalStates.hyprMenuOpen = !GlobalStates.hyprMenuOpen   
        }
    }
    
    GlobalShortcut {
        name: "hyprMenuToggleReleaseInterrupt"
        description: qsTr("Interrupts possibility of HyprMenu being toggled on release")

        onPressed: {
            GlobalStates.superReleaseMightTrigger = false
        }
    }
} 
