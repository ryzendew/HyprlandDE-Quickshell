import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.SystemTray
import "root:/Data" as Data
import "root:/Core" as Core
import "root:/Widgets/System" as System
import "root:/Widgets/Notifications" as Notifications
import "." as Modules

// Main tabbed panel
Item {
    id: root

    // Size calculation
    width: mainContainer.implicitWidth + 18
    height: mainContainer.implicitHeight + 18

    required property var shell

    property bool isShown: false
    property int currentTab: 0 // 0=main, 1=calendar, 2=clipboard, 3=notifications, 4=wallpapers
    property real bgOpacity: 0.0
    property bool isRecording: false

    property var tabIcons: ["widgets", "calendar_month", "content_paste", "notifications", "wallpaper"]

    signal recordingRequested()
    signal stopRecordingRequested()
    signal systemActionRequested(string action)
    signal performanceActionRequested(string action)

    // Animation state management
    visible: opacity > 0
    opacity: 0
    x: width

    property var tabNames: ["Main", "Calendar", "Clipboard", "Notifications", "Wallpapers"]

    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    Behavior on x {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    // Background with bottom-only rounded corners
    Rectangle {
        anchors.fill: parent
        color: Data.Colors.bgColor
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: 20
        bottomRightRadius: 20
    }

    // Shadow effect preparation
    Rectangle {
        id: shadowSource
        anchors.fill: mainContainer
        color: "transparent"
        visible: false
        bottomLeftRadius: 20
        bottomRightRadius: 20
    }

    DropShadow {
        anchors.fill: shadowSource
        horizontalOffset: 0
        verticalOffset: 2
        radius: 8.0
        samples: 17
        color: "#80000000"
        source: shadowSource
        z: 1
    }

    // Main container with tab-based content layout
    Rectangle {
        id: mainContainer
        anchors.fill: parent
        anchors.margins: 9
        color: "transparent"
        radius: 12
        
        implicitWidth: 600  // Fixed width for consistency
        implicitHeight: 360

        Behavior on height {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        MouseArea {
            id: backgroundMouseArea
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
        }

        // Left sidebar with tab navigation
        Item {
            id: tabSidebar
            width: 40
            height: parent.height
            anchors.left: parent.left
            anchors.leftMargin: 9
            anchors.top: parent.top
            anchors.topMargin: 54

            property bool containsMouse: sidebarMouseArea.containsMouse || tabColumn.containsMouse

            // Tab button background
            Rectangle {
                width: 36
                height: tabColumn.height + 8
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                color: Qt.darker(Data.Colors.bgColor, 1.05)
                radius: 18
                border.color: Qt.darker(Data.Colors.bgColor, 1.2)
                border.width: 1
            }

            MouseArea {
                id: sidebarMouseArea
                anchors.fill: parent
                hoverEnabled: true
                propagateComposedEvents: true
                onEntered: hideTimer.stop()
                onExited: {
                    if (!root.isHovered) {
                        hideTimer.restart()
                    }
                }
            }

            // Tab icon buttons
            Column {
                id: tabColumn
                spacing: 4
                anchors.top: parent.top
                anchors.topMargin: 4
                anchors.horizontalCenter: parent.horizontalCenter

                property bool containsMouse: {
                    for (let i = 0; i < tabRepeater.count; i++) {
                        let tab = tabRepeater.itemAt(i)
                        if (tab && tab.children[0] && tab.children[0].containsMouse) {
                            return true
                        }
                    }
                    return false
                }

                Repeater {
                    id: tabRepeater
                    model: 5
                    delegate: Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: currentTab === index ? Data.Colors.accentColor : Qt.darker(Data.Colors.bgColor, 1.15)
                        
                        property bool isHovered: tabMouseArea.containsMouse
                        
                        MouseArea {
                            id: tabMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.currentTab = index
                            onEntered: hideTimer.stop()
                            onExited: {
                                if (!root.isHovered) {
                                    hideTimer.restart()
                                }
                            }
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: root.tabIcons[index]
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            color: currentTab === index ? Data.Colors.bgColor : 
                                   parent.isHovered ? Data.Colors.accentColor : Data.Colors.fgColor
                        }
                    }
                }
            }
        }

        // Main content area (positioned right of tab sidebar)
        Column {
            id: mainColumn
            width: parent.width - tabSidebar.width - 45
            anchors.left: tabSidebar.right
            anchors.leftMargin: 9
            anchors.top: parent.top
            anchors.margins: 18
            spacing: 28
            clip: true

            // Tab 0: Main dashboard content
            Column {
                width: parent.width
                spacing: 28
                visible: root.currentTab === 0

                // User profile row with theme toggle and weather
                Row {
                    width: parent.width
                    spacing: 18

                    UserProfile {
                        id: userProfile
                        width: parent.width - themeToggle.width - weatherDisplay.width - (parent.spacing * 2)
                        height: 80
                        shell: root.shell
                    }

                    ThemeToggle {
                        id: themeToggle
                        width: 40
                        height: userProfile.height
                    }

                    WeatherDisplay {
                        id: weatherDisplay
                        width: parent.width * 0.18
                        height: userProfile.height
                        shell: root.shell
                        onEntered: hideTimer.stop()
                        onExited: hideTimer.restart()
                        visible: root.visible
                        enabled: visible
                    }
                }

                // Controls section
                Row {
                    width: parent.width
                    spacing: 18

                    Column {
                        width: parent.width
                        spacing: 28

                        RecordingButton {
                            id: recordingButton
                            width: parent.width
                            height: 48
                            shell: root.shell
                            isRecording: root.isRecording

                            onRecordingRequested: root.recordingRequested()
                            onStopRecordingRequested: root.stopRecordingRequested()
                        }

                        Controls {
                            id: controls
                            width: parent.width
                            isRecording: root.isRecording
                            shell: root.shell
                            onPerformanceActionRequested: function(action) { root.performanceActionRequested(action) }
                            onSystemActionRequested: function(action) { root.systemActionRequested(action) }
                            onMouseChanged: function(containsMouse) {
                                if (containsMouse) {
                                    hideTimer.stop()
                                } else if (!root.isHovered) {
                                    hideTimer.restart()
                                }
                            }
                        }
                    }
                }

                // System tray section with inline menu
                Column {
                    id: systemTraySection
                    width: parent.width
                    spacing: 8

                    property bool containsMouse: trayMouseArea.containsMouse || systemTrayModule.containsMouse

                    Rectangle {
                        id: trayBackground
                        width: parent.width
                        height: 40
                        radius: 20
                        color: Qt.darker(Data.Colors.bgColor, 1.15)

                        property bool isActive: false

                        MouseArea {
                            id: trayMouseArea
                            anchors.fill: parent
                            anchors.margins: -10
                            hoverEnabled: true
                            propagateComposedEvents: true
                            preventStealing: false
                            onEntered: trayBackground.isActive = true
                            onExited: {
                                if (!inlineTrayMenu.visible) {
                                    Qt.callLater(function() {
                                        if (!systemTrayModule.containsMouse) {
                                            trayBackground.isActive = false
                                        }
                                    })
                                }
                            }
                        }

                        System.SystemTray {
                            id: systemTrayModule
                            anchors.centerIn: parent
                            shell: root.shell
                            bar: parent
                            trayMenu: inlineTrayMenu
                        }
                    }
                }

                TrayMenu {
                    id: inlineTrayMenu
                    parent: mainContainer
                    width: parent.width
                    menu: null
                    systemTrayY: systemTraySection.y
                    systemTrayHeight: systemTraySection.height
                    onHideRequested: trayBackground.isActive = false
                }
            }

            // Tab 1: Calendar content with lazy loading
            Column {
                width: parent.width
                height: 310
                visible: root.currentTab === 1
                spacing: 16

                Text {
                    text: "Calendar"
                    color: Data.Colors.accentColor
                    font.pixelSize: 18
                    font.bold: true
                    font.family: "FiraCode Nerd Font"
                }

                Rectangle {
                    width: parent.width
                    height: parent.height - parent.children[0].height - parent.spacing
                    color: Qt.lighter(Data.Colors.bgColor, 1.2)
                    radius: 20
                    clip: true

                    Loader {
                        anchors.fill: parent
                        anchors.margins: 20
                        active: visible && root.currentTab === 1
                        source: active ? "root:/Widgets/Calendar/Calendar.qml" : ""
                        onLoaded: {
                            if (item) {
                                item.shell = root.shell
                            }
                        }
                    }
                }
            }

            // Tab 2: Clipboard history with clear button
            Column {
                width: parent.width
                height: 310
                visible: root.currentTab === 2
                spacing: 16

                RowLayout {
                    width: parent.width
                    spacing: 16

                    Text {
                        text: "Clipboard History"
                        color: Data.Colors.accentColor
                        font.pixelSize: 18
                        font.bold: true
                        font.family: "FiraCode Nerd Font"
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: clearClipText.implicitWidth + 16
                        height: 24
                        radius: 12
                        color: clearClipMouseArea.containsMouse ? Qt.rgba(Data.Colors.accentColor.r, Data.Colors.accentColor.g, Data.Colors.accentColor.b, 0.2) : "transparent"
                        border.color: Data.Colors.accentColor
                        border.width: 1

                        Text {
                            id: clearClipText
                            anchors.centerIn: parent
                            text: "Clear All"
                            color: Data.Colors.accentColor
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: clearClipMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                // Navigate to clipboard component and call clear
                                let clipLoader = parent.parent.parent.children[1].children[0]
                                if (clipLoader && clipLoader.item && clipLoader.item.children[0]) {
                                    let clipComponent = clipLoader.item.children[0]
                                    if (clipComponent.clearClipboardHistory) {
                                        clipComponent.clearClipboardHistory()
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: parent.height - parent.children[0].height - parent.spacing
                    color: Qt.lighter(Data.Colors.bgColor, 1.2)
                    radius: 20
                    clip: true

                    Loader {
                        anchors.fill: parent
                        anchors.margins: 20
                        active: visible && root.currentTab === 2
                        sourceComponent: active ? clipboardHistoryComponent : null
                    }
                }
            }

            // Tab 3: Notification history with clear button
            Column {
                width: parent.width
                height: 310
                visible: root.currentTab === 3
                spacing: 16

                RowLayout {
                    width: parent.width
                    spacing: 16

                    Text {
                        text: "Notification History"
                        color: Data.Colors.accentColor
                        font.pixelSize: 18
                        font.bold: true
                        font.family: "FiraCode Nerd Font"
                    }

                    Text {
                        text: "(" + (root.shell.notificationHistory ? root.shell.notificationHistory.count : 0) + ")"
                        color: Data.Colors.fgColor
                        font.pixelSize: 12
                        opacity: 0.7
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: clearNotifText.implicitWidth + 16
                        height: 24
                        radius: 12
                        color: clearNotifMouseArea.containsMouse ? Qt.rgba(Data.Colors.accentColor.r, Data.Colors.accentColor.g, Data.Colors.accentColor.b, 0.2) : "transparent"
                        border.color: Data.Colors.accentColor
                        border.width: 1

                        Text {
                            id: clearNotifText
                            anchors.centerIn: parent
                            text: "Clear All"
                            color: Data.Colors.accentColor
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: clearNotifMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.shell.notificationHistory.clear()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: parent.height - parent.children[0].height - parent.spacing
                    color: Qt.lighter(Data.Colors.bgColor, 1.2)
                    radius: 20
                    clip: true

                    Loader {
                        anchors.fill: parent
                        anchors.margins: 20
                        active: visible && root.currentTab === 3
                        sourceComponent: active ? notificationHistoryComponent : null
                    }
                }
            }

            // Tab 4: Wallpaper selector
            Column {
                width: parent.width
                height: 310
                visible: root.currentTab === 4
                spacing: 16

                Text {
                    text: "Wallpapers"
                    color: Data.Colors.accentColor
                    font.pixelSize: 18
                    font.bold: true
                    font.family: "FiraCode Nerd Font"
                }

                Rectangle {
                    width: parent.width
                    height: parent.height - parent.children[0].height - parent.spacing
                    color: Qt.lighter(Data.Colors.bgColor, 1.2)
                    radius: 20
                    clip: true

                    Loader {
                        anchors.fill: parent
                        anchors.margins: 20
                        active: visible && root.currentTab === 4
                        sourceComponent: active ? wallpaperSelectorComponent : null
                    }
                }
            }
        }
    }

    // Lazy-loaded components for tab content
    Component {
        id: clipboardHistoryComponent
        Item {
            anchors.fill: parent
            
            System.Cliphist {
                id: cliphistComponent
                anchors.fill: parent
                shell: root.shell
                
                // Hide built-in header (we provide our own)
                Component.onCompleted: {
                    for (let i = 0; i < children.length; i++) {
                        let child = children[i]
                        if (child.objectName === "contentColumn" || child.toString().includes("ColumnLayout")) {
                            if (child.children && child.children.length > 0) {
                                child.children[0].visible = false
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: notificationHistoryComponent  
        Item {
            anchors.fill: parent
            
            Notifications.NotificationHistory {
                anchors.fill: parent
                shell: root.shell
                clip: true
                
                // Hide built-in header (we provide our own)
                Component.onCompleted: {
                    for (let i = 0; i < children.length; i++) {
                        let child = children[i]
                        if (child.objectName === "contentColumn" || child.toString().includes("ColumnLayout")) {
                            if (child.children && child.children.length > 0) {
                                child.children[0].visible = false
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: wallpaperSelectorComponent
        Modules.WallpaperSelector {
            isVisible: parent && parent.parent && parent.parent.visible
        }
    }

    // Complex hover state calculation for auto-hide behavior
    property bool isHovered: {
        const menuStates = {
            inlineMenuActive: inlineTrayMenu.menuJustOpened || inlineTrayMenu.visible,
            trayActive: trayBackground.isActive,
            tabContentActive: currentTab !== 0
        }
        
        if (menuStates.inlineMenuActive || menuStates.trayActive || menuStates.tabContentActive) return true

        const mouseStates = {
            backgroundHovered: backgroundMouseArea.containsMouse,
            recordingHovered: recordingButton.containsMouse,
            controlsHovered: controls.containsMouse,
            profileHovered: userProfile.isHovered,
            themeToggleHovered: themeToggle.containsMouse,
            systemTrayHovered: systemTraySection.containsMouse || 
                             trayMouseArea.containsMouse || 
                             systemTrayModule.containsMouse,
            menuHovered: inlineTrayMenu.containsMouse,
            weatherHovered: weatherDisplay.containsMouse,
            tabSidebarHovered: tabSidebar.containsMouse,
            mainContentHovered: mainColumn.children[0].visible && backgroundMouseArea.containsMouse
        }

        return Object.values(mouseStates).some(state => state)
    }

    // Auto-hide timer
    Timer {
        id: hideTimer
        interval: 500
        repeat: false
        onTriggered: hide()
    }

    onIsHoveredChanged: {
        if (isHovered) {
            hideTimer.stop()
        } else if (!inlineTrayMenu.visible && !trayBackground.isActive && !tabSidebar.containsMouse && !tabColumn.containsMouse) {
            hideTimer.restart()
        }
    }

    function show() {
        if (isShown) return
        isShown = true
        hideTimer.stop()
        opacity = 1
        x = 0
    }

    function hide() {
        if (!isShown || inlineTrayMenu.menuJustOpened || inlineTrayMenu.visible) return
        // Only hide on main tab when nothing is hovered
        if (currentTab === 0 && !isHovered) {
            isShown = false
            x = width
            opacity = 0
            
            // Hide parent TopPanel as well
            if (parent && parent.parent && parent.parent.hide) {
                parent.parent.hide()
            }
        }
    }

    Component.onCompleted: {
        Qt.callLater(function() {
            mainColumn.visible = true
        })
    }
    
    // Border integration corners
    Core.Corners {
        id: topLeftCorner
        position: "bottomright"
        size: 1.3
        fillColor: Data.Colors.bgColor
        offsetX: 0
        offsetY: 0
    }

    Core.Corners {
        id: topRightCorner
        position: "bottomleft"
        size: 1.3
        fillColor: Data.Colors.bgColor
        offsetX: root.width
        offsetY: 0
    }
}