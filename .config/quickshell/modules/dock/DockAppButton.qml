import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

DockButton {
    id: root
    property var appToplevel
    property var appListRoot
    property int lastFocused: -1
    property real iconSize: ConfigOptions.dock.iconSize
    property real countDotWidth: 10
    property real countDotHeight: 4
    property bool appIsActive: appToplevel.toplevels.find(t => (t.activated == true)) !== undefined
    property real mouseX: 0
    property real mouseY: 0
    property var control: null
    property var dockVisualBackground: null

    property bool isSeparator: appToplevel.appId === "SEPARATOR"
    property var desktopEntry: DesktopEntries.byId(appToplevel.appId)
    Popup {
    id: customMenu
    x: mouseX
    y: Math.max(0, mouseY - customMenu.height + 50)
    width: 180
    modal: false
    focus: true
    background: Rectangle {
    color: Appearance.colors.colLayer0 // this is dark, matches dock
    border.color: "white"
    border.width: 2
    radius: Appearance.rounding.normal
}
    Column {
        spacing: 0
        Button {
            text: root.appToplevel.pinned ? "Unpin from Dock" : "Pin to Dock"
            background: Rectangle {
                color: hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                radius: Appearance.rounding.normal
            }
            font.bold: true
            font.pixelSize: 16
            contentItem: Text {
                text: parent.text
                color: Appearance.colors.colOnLayer0 // Set text color here!
                font.bold: true
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                anchors.fill: parent
            }
            onClicked: {
                if (root.appToplevel.pinned) {
                    dock.removePinnedApp(root.appToplevel.appId)
                } else {
                    ConfigOptions.dock.pinnedApps.push(root.appToplevel.appId)
                }
                customMenu.close()
            }
        }
    }
}
    enabled: !isSeparator
    implicitWidth: isSeparator ? 1 : implicitHeight - topInset - bottomInset

    Loader {
        active: isSeparator
        anchors {
            fill: parent
            topMargin: (dockVisualBackground ? dockVisualBackground.margin : 0) + (dockRow ? dockRow.padding : 0) + Appearance.rounding.normal
            bottomMargin: (dockVisualBackground ? dockVisualBackground.margin : 0) + (dockRow ? dockRow.padding : 0) + Appearance.rounding.normal
        }
        sourceComponent: DockSeparator {}
    }

Menu {
    id: contextMenu
    palette {
        window: Qt.rgba(1, 1, 1, 0.08)      // dark background
        windowText: Qt.rgba(255, 255, 255, 0.08)   // white text
        button: Qt.rgba(1, 1, 1, 0.08)
        buttonText: Qt.rgba(1, 1, 1, 0.08)
        highlight: Qt.rgba(1, 1, 1, 0.08)
    }
    MenuItem {
        text: root.appToplevel.pinned ? "Unpin from Dock" : "Pin to Dock"
        contentItem: Text {
            text: parent.text
            color: "white"
            font.pixelSize: 16
            font.bold: true
        }
        background: Rectangle {
            color: control ? control.highlighted ? Qt.rgba(1, 1, 1, 0.08) : "transparent" : "transparent" // subtle white highlight
            radius: 8 // rounded corners
        }
        // The rest of your onTriggered logic goes here
        onTriggered: {
            if (root.appToplevel.pinned) {
                var index = ConfigOptions.dock.pinnedApps.indexOf(root.appToplevel.appId)
                if (index !== -1) {
                    ConfigOptions.dock.pinnedApps.splice(index, 1)
                }
            } else {
                ConfigOptions.dock.pinnedApps.push(root.appToplevel.appId)
            }
        }
    }
}

MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.RightButton | Qt.LeftButton
    onClicked: (mouse) => {
        if (mouse.button === Qt.RightButton) {
            root.mouseX = mouse.x
            root.mouseY = mouse.y
            customMenu.open()
        }
        // Left-click logic here (if you have any)
    }
}

Loader {
        anchors.fill: parent
        active: appToplevel.toplevels.length > 0
        sourceComponent: MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: {
                appListRoot.lastHoveredButton = root
                appListRoot.buttonHovered = true
                lastFocused = appToplevel.toplevels.length - 1
            }
            onExited: {
                if (appListRoot.lastHoveredButton === root) {
                    appListRoot.buttonHovered = false
                }
            }
        }
    }

    onClicked: {
        if (appToplevel.toplevels.length === 0) {
            root.desktopEntry?.execute();
            return;
        }
        lastFocused = (lastFocused + 1) % appToplevel.toplevels.length
        appToplevel.toplevels[lastFocused].activate()
    }

    middleClickAction: () => {
        root.desktopEntry?.execute();
    }

    contentItem: Loader {
        active: !isSeparator
        sourceComponent: Item {
            anchors.centerIn: parent

            Loader {
                id: iconImageLoader
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                active: !root.isSeparator
                sourceComponent: IconImage {
                    source: {
                        var guessedIcon = AppSearch.guessIcon(appToplevel.appId);
                        var iconPath = Quickshell.iconPath(guessedIcon, "image-missing");
                        return iconPath;
                    }
                    implicitSize: root.iconSize
                }
            }

            RowLayout {
                spacing: 3
                anchors {
                    bottom: parent.bottom
                    bottomMargin: 4
                    horizontalCenter: parent.horizontalCenter
                }
                Repeater {
                    model: Math.min(appToplevel.toplevels.length, 5)
                    delegate: Rectangle {
                        required property int index
                        radius: Appearance.rounding.full
                        implicitWidth: root.countDotWidth
                        implicitHeight: root.countDotHeight
                        color: appIsActive ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.4)
                    }
                }
            }
        }
    }
}
