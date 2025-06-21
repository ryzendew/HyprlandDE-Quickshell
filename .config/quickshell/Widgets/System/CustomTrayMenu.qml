pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "root:/Data/" as Data

// Custom system tray menu
Rectangle {
    id: trayMenu
    implicitWidth: 360
    implicitHeight: Math.max(40, listView.contentHeight + 12 + 16)
    clip: true
    color: Data.Colors.bgColor
    border.color: Data.Colors.accentColor
    border.width: 3
    radius: 20
    visible: false
    enabled: visible

    property QsMenuHandle menu
    property point triggerPoint: Qt.point(0, 0)
    property Item originalParent

    // Menu opener handles native menu integration
    QsMenuOpener {
        id: opener
        menu: trayMenu.menu
    }

    // Full-screen overlay to capture outside clicks
    Rectangle {
        id: overlay
        x: -trayMenu.x
        y: -trayMenu.y
        width: Screen.width
        height: Screen.height
        color: "transparent"
        visible: trayMenu.visible
        z: -1

        MouseArea {
            anchors.fill: parent
            enabled: trayMenu.visible
            acceptedButtons: Qt.AllButtons
            onPressed: {
                trayMenu.hide()
            }
        }
    }

    // Flatten hierarchical menu structure into single list
    function flattenMenuItems(menuHandle) {
        var result = [];
        if (!menuHandle || !menuHandle.children) {
            return result;
        }

        var childrenArray = [];
        for (var i = 0; i < menuHandle.children.length; i++) {
            childrenArray.push(menuHandle.children[i]);
        }

        for (var i = 0; i < childrenArray.length; i++) {
            var item = childrenArray[i];

            if (item.isSeparator) {
                result.push(item);
            } else if (item.menu) {
                // Add parent item and its submenu items
                result.push(item);
                var submenuItems = flattenMenuItems(item.menu);
                result = result.concat(submenuItems);
            } else {
                result.push(item);
            }
        }
        return result;
    }

    // Menu item list
    ListView {
        id: listView
        anchors.fill: parent
        anchors.margins: 6
        anchors.topMargin: 3
        anchors.bottomMargin: 9
        model: ScriptModel {
            values: flattenMenuItems(opener.menu)
        }
        interactive: false

        delegate: Rectangle {
            id: entry
            required property var modelData

            width: listView.width - 12
            height: modelData.isSeparator ? 10 : 28
            color: modelData.isSeparator ? Data.Colors.bgColor : (mouseArea.containsMouse ? Data.Colors.highlightBg : "transparent")
            radius: modelData.isSeparator ? 0 : 4

            // Separator line rendering
            Item {
                anchors.fill: parent
                visible: modelData.isSeparator

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.85
                    height: 1
                    color: Data.Colors.accentColor
                    opacity: 0.3
                }
            }

            // Menu item content (text and icon)
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6
                visible: !modelData.isSeparator

                Text {
                    Layout.fillWidth: true
                    color: (modelData?.enabled ?? true) ? Data.Colors.fgColor : Qt.darker(Data.Colors.fgColor, 1.8)
                    text: modelData?.text ?? ""
                    font.pixelSize: 12
                    font.family: "FiraCode Nerd Font"
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Image {
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    source: modelData?.icon ?? ""
                    visible: (modelData?.icon ?? "") !== ""
                    fillMode: Image.PreserveAspectFit
                }
            }

            // Click handling
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                enabled: (modelData?.enabled ?? true) && trayMenu.visible && !modelData.isSeparator

                onClicked: {
                    if (modelData) {
                        modelData.triggered()
                        trayMenu.hide()
                    }
                }
            }
        }
    }
}
