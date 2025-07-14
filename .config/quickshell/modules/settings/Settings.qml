import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import "root:/services/"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
// import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)

    Loader {
        id: settingsLoader
        active: false

        sourceComponent: PanelWindow {
            id: settingsRoot
            visible: settingsLoader.active
            
            function hide() {
                settingsLoader.active = false
            }

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:settings"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
            }

            implicitWidth: root.focusedScreen?.width ?? 0
            implicitHeight: root.focusedScreen?.height ?? 0

            // Backdrop blur effect
            Rectangle {
                anchors.fill: parent
                color: ColorUtils.transparentize(Appearance.m3colors.m3scrim, 0.4)
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: settingsRoot.hide()
                }
            }

            // Main settings window
            Rectangle {
                id: settingsWindow
                anchors.centerIn: parent
                width: Math.min(parent.width - 80, 1920)
                height: Math.min(parent.height - 80, 1080)
                anchors.margins: 24
                clip: false
                radius: Appearance.rounding.verylarge
                // Sidebar style: gradient, border, blur
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(
                            Appearance.colors.colLayer1.r,
                            Appearance.colors.colLayer1.g,
                            Appearance.colors.colLayer1.b,
                            0.75
                        )
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(
                            Appearance.colors.colLayer1.r,
                            Appearance.colors.colLayer1.g,
                            Appearance.colors.colLayer1.b,
                            0.65
                        )
                    }
                }
                border.width: 1
                border.color: Qt.rgba(
                    Appearance.colors.colOutline.r,
                    Appearance.colors.colOutline.g,
                    Appearance.colors.colOutline.b,
                    0.3
                )
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: parent.radius - 1
                    color: "transparent"
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                }
                
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        settingsRoot.hide();
                    } else if (event.key === Qt.Key_S && (event.modifiers & Qt.ControlModifier)) {
                        if (ConfigLoader.hasPendingChanges) {
                            ConfigLoader.savePendingChanges();
                            Hyprland.dispatch(`exec notify-send "${qsTr("Settings saved")}" "${qsTr("Configuration changes have been saved")}"`);
                        }
                    }
                }

                // Background for content (allows blur to show through)
                Rectangle {
                    anchors.fill: parent
                    color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.9)
                    radius: parent.radius
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 0
                    spacing: 0

                    // Sidebar navigation
                    Rectangle {
                        Layout.preferredWidth: 300
                        Layout.fillHeight: true
                        color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.95)
                        radius: Appearance.rounding.verylarge
                        
                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.radius
                            color: parent.color
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 32
                            spacing: 24

                            // Header
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                StyledText {
                                    text: "QuickShell Settings"
                                    font.family: Appearance.font.family.title
                                    font.pixelSize: 26
                                    font.weight: Font.Bold
                                    color: Appearance.colors.colOnLayer0
                                }

                                StyledText {
                                    text: "Customize your desktop experience"
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                    opacity: 0.9
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.2)
                            }

                            // Navigation items
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Repeater {
                                    model: [
                                        {
                                            "id": "appearance",
                                            "icon": "palette",
                                            "title": "Appearance",
                                            "subtitle": "Colors, bar & dock",
                                            "index": 0
                                        },
                                        {
                                            "id": "system",
                                            "icon": "settings",
                                            "title": "System",
                                            "subtitle": "Audio, battery, time & keyboard",
                                            "index": 1
                                        },
                                        {
                                            "id": "apps",
                                            "icon": "apps",
                                            "title": "Apps",
                                            "subtitle": "Default apps & handlers",
                                            "index": 2
                                        },
                                        {
                                            "id": "about",
                                            "icon": "info",
                                            "title": "About",
                                            "subtitle": "About QuickShell",
                                            "index": 3
                                        }
                                    ]

                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 80
                                        radius: Appearance.rounding.normal
                                        color: settingsWindow.selectedTab === modelData.index ? 
                                               Appearance.colors.colPrimaryContainer :
                                               navMouseArea.containsMouse ? 
                                               Appearance.colors.colLayer1Hover : 
                                               "transparent"
                                        
                                        border.width: settingsWindow.selectedTab === modelData.index ? 2 : 0
                                        border.color: Appearance.colors.colPrimary

                                        MouseArea {
                                            id: navMouseArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: settingsWindow.selectedTab = modelData.index
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 20
                                            spacing: 16

                                            Rectangle {
                                                Layout.preferredWidth: 44
                                                Layout.preferredHeight: 44
                                                radius: Appearance.rounding.normal
                                                color: settingsWindow.selectedTab === modelData.index ?
                                                       Appearance.colors.colPrimary :
                                                       ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)

                                                MaterialSymbol {
                                                    anchors.centerIn: parent
                                                    text: modelData.icon
                                                    iconSize: 22
                                                    color: "#000"
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 4

                                                StyledText {
                                                    text: modelData.title
                                                    font.pixelSize: Appearance.font.pixelSize.normal
                                                    font.weight: Font.Medium
                                                    color: settingsWindow.selectedTab === modelData.index ?
                                                           Appearance.colors.colPrimary :
                                                           Appearance.colors.colOnLayer0
                                                }

                                                StyledText {
                                                    text: modelData.subtitle
                                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                                    color: Appearance.colors.colSubtext
                                                    opacity: 0.9
                                                    wrapMode: Text.WordWrap
                                                    Layout.fillWidth: true
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }

                            // Footer with save and close buttons
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                // Save button
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 48
                                    radius: Appearance.rounding.normal
                                    color: saveMouseArea.pressed ? 
                                           Appearance.colors.colPrimaryActive :
                                           saveMouseArea.containsMouse ? 
                                           Appearance.colors.colPrimaryHover : 
                                           Appearance.colors.colPrimary
                                    opacity: ConfigLoader.hasPendingChanges ? 1.0 : 0.5
                                    enabled: ConfigLoader.hasPendingChanges

                                    MouseArea {
                                        id: saveMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        enabled: ConfigLoader.hasPendingChanges
                                        onClicked: {
// console.log("[Settings] Save button clicked");
// console.log("[Settings] Has pending changes:", ConfigLoader.hasPendingChanges);
// console.log("[Settings] Pending changes count:", ConfigLoader.getPendingChangesCount());
                                            
                                            if (ConfigLoader.hasPendingChanges) {
                                                const saved = ConfigLoader.savePendingChanges();
                                                if (saved) {
                                                    Hyprland.dispatch(`exec notify-send "${qsTr("Settings saved")}" "${qsTr("Configuration changes have been saved")}"`);
// console.log("[Settings] Save completed and notification sent");
                                                } else {
                                                    Hyprland.dispatch(`exec notify-send "${qsTr("Save failed")}" "${qsTr("Failed to save configuration changes")}"`);
// console.log("[Settings] Save failed");
                                                }
                                            } else {
// console.log("[Settings] No changes to save");
                                                Hyprland.dispatch(`exec notify-send "${qsTr("No changes")}" "${qsTr("No settings changes to save")}"`);
                                            }
                                        }
                                    }

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 12

                                        MaterialSymbol {
                                            text: "save"
                                            iconSize: 20
                                            color: "#000"
                                        }

                                        StyledText {
                                            text: ConfigLoader.hasPendingChanges ? 
                                                  `Save Changes (${ConfigLoader.getPendingChangesCount()})` : 
                                                  "No Changes"
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                            font.weight: Font.Medium
                                            color: "#000"
                                            
                                            // Debug: force update when hasPendingChanges changes
                                            property bool debugHasChanges: ConfigLoader.hasPendingChanges
                                            onDebugHasChangesChanged: {
// console.log("[Settings] UI updated - hasPendingChanges:", ConfigLoader.hasPendingChanges);
                                            }
                                        }
                                    }
                                }

                                // Close button
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 48
                                radius: Appearance.rounding.normal
                                color: closeMouseArea.containsMouse ? 
                                       Appearance.colors.colLayer2Hover : 
                                       Appearance.colors.colLayer2
                                border.width: 1
                                border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.2)

                                MouseArea {
                                    id: closeMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                        onClicked: {
// console.log("[Settings] Close button clicked");
// console.log("[Settings] Has pending changes:", ConfigLoader.hasPendingChanges);
                                            if (ConfigLoader.hasPendingChanges) {
                                                // Auto-save changes before closing
// console.log("[Settings] Auto-saving changes before close");
                                                const saved = ConfigLoader.savePendingChanges();
                                                if (saved) {
                                                    Hyprland.dispatch(`exec notify-send "${qsTr("Settings saved")}" "${qsTr("Configuration changes have been saved")}"`);
                                                } else {
                                                    Hyprland.dispatch(`exec notify-send "${qsTr("Save failed")}" "${qsTr("Failed to save configuration changes")}"`);
                                                }
                                            }
                                            settingsRoot.hide();
                                        }
                                }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 12

                                    MaterialSymbol {
                                        text: "close"
                                        iconSize: 20
                                        color: Appearance.colors.colOnLayer0
                                    }

                                    StyledText {
                                        text: "Close Settings"
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        font.weight: Font.Medium
                                        color: Appearance.colors.colOnLayer0
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Content area
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.95)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 40
                            spacing: 32

                            // Page header
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 20

                                Rectangle {
                                    Layout.preferredWidth: 56
                                    Layout.preferredHeight: 56
                                    radius: Appearance.rounding.normal
                                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: {
                                            switch(settingsWindow.selectedTab) {
                                                case 0: return "palette";
                                                case 1: return "settings";
                                                case 2: return "apps";
                                                case 3: return "info";
                                                default: return "palette";
                                            }
                                        }
                                        iconSize: 28
                                        color: Appearance.colors.colPrimary
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    StyledText {
                                        text: {
                                            switch(settingsWindow.selectedTab) {
                                                case 0: return "Appearance Settings";
                                                case 1: return "System Settings";
                                                case 2: return "Apps Settings";
                                                case 3: return "About QuickShell";
                                                default: return "Appearance Settings";
                                            }
                                        }
                                        font.family: Appearance.font.family.title
                                        font.pixelSize: 32
                                        font.weight: Font.Bold
                                        color: Appearance.colors.colOnLayer0
                                    }

                                    StyledText {
                                        text: {
                                            switch(settingsWindow.selectedTab) {
                                                case 0: return "Customize colors, bar and dock appearance";
                                                case 1: return "Manage system services, time, keyboard and hardware settings";
                                                case 2: return "Configure default applications and handlers";
                                                case 3: return "System information and help resources";
                                                default: return "Customize colors, bar and dock appearance";
                                            }
                                        }
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        color: Appearance.colors.colSubtext
                                        opacity: 0.9
                                    }
                                }
                            }

                            // Content area with modern scroll view
                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                contentWidth: availableWidth
                                clip: true

                                ScrollBar.vertical: ScrollBar {
                                    policy: ScrollBar.AsNeeded
                                    width: 12
                                    background: Rectangle {
                                        color: "transparent"
                                        radius: 6
                                    }
                                    contentItem: Rectangle {
                                        radius: 6
                                        color: parent.pressed ? 
                                               Appearance.colors.colPrimary :
                                               ColorUtils.transparentize(Appearance.colors.colSubtext, 0.4)
                                    }
                                }

                                Loader {
                                    width: parent.width
                                    sourceComponent: {
                                        switch(settingsWindow.selectedTab) {
                                            case 0: return appearanceConfigComponent;
                                            case 1: return systemConfigComponent;
                                            case 2: return appsConfigComponent;
                                            case 3: return aboutComponent;
                                            default: return appearanceConfigComponent;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                property int selectedTab: 0
            }

            // Components for each settings page
            Component { id: appearanceConfigComponent; AppearanceConfig {} }
            Component { id: systemConfigComponent; SystemConfig {} }
            Component { id: aboutComponent; About {} }
            Component { id: appsConfigComponent; AppsConfig {} }
        }
    }

    IpcHandler {
        target: "settings"

        function toggle(): void {
            settingsLoader.active = !settingsLoader.active;
        }

        function close(): void {
            settingsLoader.active = false;
        }

        function open(): void {
            settingsLoader.active = true;
        }
    }

    GlobalShortcut {
        name: "settingsToggle"
        description: qsTr("Toggles settings dialog on press")

        onPressed: {
            settingsLoader.active = !settingsLoader.active;
        }
    }

    GlobalShortcut {
        name: "settingsOpen"
        description: qsTr("Opens settings dialog on press")

        onPressed: {
            settingsLoader.active = true;
        }
    }

    GlobalShortcut {
        name: "settingsSave"
        description: qsTr("Saves pending settings changes")

        onPressed: {
            if (ConfigLoader.hasPendingChanges) {
                ConfigLoader.savePendingChanges();
                Hyprland.dispatch(`exec notify-send "${qsTr("Settings saved")}" "${qsTr("Configuration changes have been saved")}"`);
            }
        }
    }
} 