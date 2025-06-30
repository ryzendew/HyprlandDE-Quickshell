import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "./calendar"
import "./notifications"
import "./todo"
import "./volumeMixer"
import "./performance"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root
    radius: Appearance.rounding.normal
    color: Qt.rgba(
        Appearance.colors.colLayer1.r,
        Appearance.colors.colLayer1.g,
        Appearance.colors.colLayer1.b,
        0.55
    )

    // Debug mode - prevent closing
    property bool debugMode: false  // Set to true to prevent closing

    // Block ALL closing attempts while in debug mode
    Connections {
        target: Quickshell
        function onSidebarRightCloseRequested() {
            if (debugMode) {
                console.log("Sidebar closing prevented (debug mode)")
                return
            }
            Hyprland.dispatch("global quickshell:sidebarRightClose")
        }
    }

    // Block escape key
    Keys.onEscapePressed: {
        if (debugMode) {
            console.log("Escape key blocked (debug mode)")
            event.accepted = true
        }
    }

    // Block clicking outside
    MouseArea {
        anchors.fill: parent
        onClicked: mouse.accepted = debugMode
    }

    property int selectedTab: 0
    property var tabButtonList: [
        {"icon": "notifications", "name": qsTr("Notifications")},
        {"icon": "volume_up", "name": qsTr("Volume mixer")},
        {"icon": "cloud", "name": qsTr("Weather")}
    ]

    // Intercept the close signal
    Connections {
        target: Quickshell
        function onSidebarRightCloseRequested() {
            if (!root.preventClosing) {
                Hyprland.dispatch("global quickshell:sidebarRightClose")
            }
        }
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) {
            if (event.key === Qt.Key_PageDown) {
                root.selectedTab = Math.min(root.selectedTab + 1, root.tabButtonList.length - 1)
            } else if (event.key === Qt.Key_PageUp) {
                root.selectedTab = Math.max(root.selectedTab - 1, 0)
            }
            event.accepted = true;
        }
        if (event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_Tab) {
                root.selectedTab = (root.selectedTab + 1) % root.tabButtonList.length
            } else if (event.key === Qt.Key_Backtab) {
                root.selectedTab = (root.selectedTab - 1 + root.tabButtonList.length) % root.tabButtonList.length
            }
            event.accepted = true;
        }
    }

    ColumnLayout {
        anchors.margins: 5
        anchors.fill: parent
        spacing: 0

        PrimaryTabBar {
            id: tabBar
            tabButtonList: root.tabButtonList
            externalTrackedTab: root.selectedTab
            
            function onCurrentIndexChanged(currentIndex) {
                root.selectedTab = currentIndex
            }
        }

        // Isolate each tab using a Loader
        Loader {
            id: tabLoader
            Layout.topMargin: 5
            Layout.fillWidth: true
            Layout.fillHeight: true
            sourceComponent: {
                switch(root.selectedTab) {
                    case 0: return notificationComponent;
                    case 1: return volumeMixerComponent;
                    case 2: return weatherComponent;
                    default: return notificationComponent;
                }
            }
        }

        Component { id: notificationComponent; NotificationList {} }
        Component { id: volumeMixerComponent; VolumeMixer {} }
        Component { id: weatherComponent; WeatherSidebarPage {} }
    }
}