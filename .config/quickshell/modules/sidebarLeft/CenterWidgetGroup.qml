import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "./wifi"
import "./bluetooth"
import "./SystemStatus.qml"
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
    border.color: Qt.rgba(1, 1, 1, 0.12)
    border.width: 1

    property int selectedTab: 0
    property var tabButtonList: [
        {"icon": "wifi", "name": qsTr("WiFi")},
        {"icon": "bluetooth", "name": qsTr("Bluetooth")},
        {"icon": "settings", "name": qsTr("System Status")}
    ]

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
        anchors.margins: {
            // Responsive margins based on screen size and content
            let baseMargin = Math.max(5, parent.width * 0.008)
            if (Screen.width >= 3840) return Math.max(8, parent.width * 0.006) // 4K
            else if (Screen.width >= 2560) return Math.max(7, parent.width * 0.007) // 2K
            else if (Screen.width >= 1920) return Math.max(6, parent.width * 0.008) // 1080p
            else if (Screen.width >= 1366) return Math.max(5, parent.width * 0.009) // 720p
            else return Math.max(4, parent.width * 0.01) // Small screens
        }
        anchors.fill: parent
        spacing: {
            // Responsive spacing based on screen size
            let baseSpacing = Math.max(0, parent.height * 0.002)
            if (Screen.width >= 3840) return Math.max(6, parent.height * 0.004) // 4K
            else if (Screen.width >= 2560) return Math.max(5, parent.height * 0.005) // 2K
            else if (Screen.width >= 1920) return Math.max(4, parent.height * 0.006) // 1080p
            else if (Screen.width >= 1366) return Math.max(3, parent.height * 0.007) // 720p
            else return Math.max(2, parent.height * 0.008) // Small screens
        }

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
            Layout.topMargin: {
                // Responsive top margin based on screen size
                let baseMargin = Math.max(5, parent.height * 0.008)
                if (Screen.width >= 3840) return Math.max(8, parent.height * 0.006) // 4K
                else if (Screen.width >= 2560) return Math.max(7, parent.height * 0.007) // 2K
                else if (Screen.width >= 1920) return Math.max(6, parent.height * 0.008) // 1080p
                else if (Screen.width >= 1366) return Math.max(5, parent.height * 0.009) // 720p
                else return Math.max(4, parent.height * 0.01) // Small screens
            }
            Layout.fillWidth: true
            Layout.fillHeight: true
            sourceComponent: {
                switch(root.selectedTab) {
                    case 0: return wifiComponent;
                    case 1: return bluetoothComponent;
                    case 2: return systemStatusComponent;
                    default: return wifiComponent;
                }
            }
        }

        Component { id: wifiComponent; WifiPage {} }
        Component { id: bluetoothComponent; BluetoothPage {} }
        Component { id: systemStatusComponent; SystemStatus {} }
    }
} 