import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Services.SystemTray
import "root:/Data" as Data
import "root:/Widgets/System" as System
import "root:/Widgets/Notifications" as Notifications
import "./modules" as Modules

// Panel content with tab layout
Item {
    id: contentRoot
    
    // Properties passed from parent
    required property var shell
    required property bool isRecording
    property int currentTab: 0
    property var tabIcons: []
    required property var triggerMouseArea
    
    // Signals to forward to parent
    signal recordingRequested()
    signal stopRecordingRequested()
    signal systemActionRequested(string action)
    signal performanceActionRequested(string action)
    
    // Hover detection for auto-hide
    property bool isHovered: {
        const mouseStates = {
            triggerHovered: triggerMouseArea.containsMouse,
            backgroundHovered: backgroundMouseArea.containsMouse,
            tabSidebarHovered: tabSidebar.containsMouse,
            tabColumnHovered: tabColumn.containsMouse,
            userProfileHovered: userProfile ? userProfile.isHovered : false,
            themeToggleHovered: themeToggle ? themeToggle.containsMouse : false,
            weatherDisplayHovered: weatherDisplay ? weatherDisplay.containsMouse : false,
            recordingButtonHovered: recordingButton ? recordingButton.isHovered : false,
            controlsHovered: controls ? controls.containsMouse : false,
            trayHovered: trayBackground ? trayBackground.containsMouse : false,
            systemTrayHovered: systemTrayModule ? systemTrayModule.containsMouse : false,
            trayMenuHovered: inlineTrayMenu ? inlineTrayMenu.containsMouse : false,
            tabContentActive: currentTab !== 0 // Non-main tabs stay open
        }

        return Object.values(mouseStates).some(state => state)
    }

    // Panel background with bottom-only rounded corners
    Rectangle {
        id: panelBackground
        anchors.fill: parent
        color: Qt.rgba(
            Data.Colors.bgColor.r,
            Data.Colors.bgColor.g,
            Data.Colors.bgColor.b,
            0.65
        )
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: 20
        bottomRightRadius: 20
        
        // Border overlay with matching rounded corners
        Rectangle {
            id: borderOverlay
            anchors.fill: parent
            color: "transparent"
            radius: parent.radius
            topLeftRadius: parent.topLeftRadius
            topRightRadius: parent.topRightRadius
            bottomLeftRadius: parent.bottomLeftRadius
            bottomRightRadius: parent.bottomRightRadius
            
            // Use a border instead of separate rectangles to match the rounded corners
            border.width: 1
            border.color: Qt.rgba(0, 0, 0, 0.9)
            
            // Remove top border by covering it with a rectangle
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: panelBackground.color
            }
            
            // Thicker bottom border
            Rectangle {
                anchors.bottom: parent.bottom
                height: 2  // Total height will be 3px (1px from border + 2px from this)
                color: Qt.rgba(0, 0, 0, 0.9)
                
                // Inset from edges to account for rounded corners
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 30  // Inset by 15px on each side
                
                // Match bottom corners but with smaller radius
                radius: 10
            }
        }
    }

    // Shadow effect
    Rectangle {
        id: shadowSource
        anchors.fill: mainContainer
        color: "transparent"
        visible: false
        radius: 20
    }

    DropShadow {
        anchors.fill: shadowSource
        horizontalOffset: 0
        verticalOffset: 4
        radius: 12.0
        samples: 25
        color: "#80000000"
        source: shadowSource
        z: 1
    }

    // Main content container with tab layout
    Rectangle {
        id: mainContainer
        anchors.fill: parent
        anchors.margins: 9
        color: "transparent"
        radius: 12
        
        MouseArea {
            id: backgroundMouseArea
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            property alias containsMouse: backgroundMouseArea.containsMouse
        }

        // Left sidebar with tab navigation buttons
        Item {
            id: tabSidebar
            width: 40
            height: parent.height
            anchors.left: parent.left
            anchors.leftMargin: 9
            anchors.top: parent.top
            anchors.topMargin: 18
            property alias containsMouse: sidebarMouseArea.containsMouse

            MouseArea {
                id: sidebarMouseArea
                anchors.fill: parent
                hoverEnabled: true
                propagateComposedEvents: true
            }

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

            // Tab icon buttons
            Column {
                id: tabColumn
                spacing: 4
                anchors.top: parent.top
                anchors.topMargin: 4
                anchors.horizontalCenter: parent.horizontalCenter
                property bool containsMouse: {
                    for (let i = 0; i < tabRepeater.count; i++) {
                        const tab = tabRepeater.itemAt(i)
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
                        
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                console.log("Tab clicked:", index, "current tab:", contentRoot.currentTab)
                                try {
                                    contentRoot.currentTab = index
                                    console.log("Tab changed successfully to:", contentRoot.currentTab)
                                } catch (e) {
                                    console.error("Error changing tab:", e)
                                }
                            }
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: contentRoot.tabIcons[index]
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            color: currentTab === index ? Data.Colors.bgColor : 
                                   parent.children[0].containsMouse ? Data.Colors.accentColor : Data.Colors.fgColor
                        }
                    }
                }
            }
        }

        // Main content area (positioned right of tabs)
        Column {
            id: mainColumn
            width: parent.width - tabSidebar.width - 45
            anchors.left: tabSidebar.right
            anchors.leftMargin: 9
            anchors.top: parent.top
            anchors.margins: 18
            spacing: 28
            clip: true

            // Tab 0: Main dashboard with profile, controls, and system tray
            Column {
                width: parent.width
                spacing: 28
                visible: contentRoot.currentTab === 0

                // User profile row with theme toggle and weather
                Row {
                    width: parent.width
                    spacing: 18

                    Modules.UserProfile {
                        id: userProfile
                        width: parent.width - themeToggle.width - weatherDisplay.width - (parent.spacing * 2)
                        height: 80
                        shell: contentRoot.shell
                    }

                    Modules.ThemeToggle {
                        id: themeToggle
                        width: 40
                        height: userProfile.height
                    }

                    Modules.WeatherDisplay {
                        id: weatherDisplay
                        width: parent.width * 0.18
                        height: userProfile.height
                        shell: contentRoot.shell
                    }
                }

                // Recording and system controls section
                Column {
                    width: parent.width
                    spacing: 28

                    Modules.RecordingButton {
                        id: recordingButton
                        width: parent.width
                        height: 48
                        shell: contentRoot.shell
                        isRecording: contentRoot.isRecording

                        onRecordingRequested: contentRoot.recordingRequested()
                        onStopRecordingRequested: contentRoot.stopRecordingRequested()
                    }

                    Modules.Controls {
                        id: controls
                        width: parent.width
                        isRecording: contentRoot.isRecording
                        shell: contentRoot.shell
                        onPerformanceActionRequested: function(action) { contentRoot.performanceActionRequested(action) }
                        onSystemActionRequested: function(action) { contentRoot.systemActionRequested(action) }
                    }
                }

                // System tray integration with menu
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
                            shell: contentRoot.shell
                            bar: parent
                            trayMenu: inlineTrayMenu
                        }
                    }
                }

                Modules.TrayMenu {
                    id: inlineTrayMenu
                    parent: mainContainer
                    width: parent.width
                    menu: null
                    systemTrayY: systemTraySection.y
                    systemTrayHeight: systemTraySection.height
                    onHideRequested: trayBackground.isActive = false
                }
            }

            // Tab 1: Calendar with lazy loading
            Column {
                width: parent.width
                height: 310
                visible: contentRoot.currentTab === 1
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
                        active: visible && contentRoot.currentTab === 1
                        source: active ? "root:/Widgets/Calendar/Calendar.qml" : ""
                        onLoaded: {
                            if (item) {
                                item.shell = contentRoot.shell
                            }
                        }
                    }
                }
            }

            // Tab 2: Clipboard history with clear button
            Column {
                width: parent.width
                height: 310
                visible: contentRoot.currentTab === 2
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
                                // Navigate to clipboard component and trigger clear
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
                        active: visible && contentRoot.currentTab === 2
                        sourceComponent: active ? clipboardHistoryComponent : null
                    }
                }
            }

            // Tab 3: Notification history with count and clear
            Column {
                width: parent.width
                height: 310
                visible: contentRoot.currentTab === 3
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
                        text: "(" + (contentRoot.shell.notificationHistory ? contentRoot.shell.notificationHistory.count : 0) + ")"
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
                            onClicked: contentRoot.shell.notificationHistory.clear()
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
                        active: visible && contentRoot.currentTab === 3
                        sourceComponent: active ? notificationHistoryComponent : null
                    }
                }
            }

            // Tab 4: Wallpaper selector
            Column {
                width: parent.width
                height: 310
                visible: contentRoot.currentTab === 4
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
                        active: visible && contentRoot.currentTab === 4
                        sourceComponent: active ? wallpaperSelectorComponent : null
                    }
                }
            }
        }
    }

    // Lazy-loaded tab content components
    Component {
        id: clipboardHistoryComponent
        Item {
            anchors.fill: parent
            
            System.Cliphist {
                id: cliphistComponent
                anchors.fill: parent
                shell: contentRoot.shell
                
                // Hide built-in header (we provide custom header)
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
                shell: contentRoot.shell
                clip: true
                
                // Hide built-in header (we provide custom header)
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
} 