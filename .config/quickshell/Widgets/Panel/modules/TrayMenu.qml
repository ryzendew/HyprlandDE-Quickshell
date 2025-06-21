import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "root:/Data" as Data

Rectangle {
    id: root
    width: parent.width
    height: visible ? calculatedHeight : 0
    visible: false
    enabled: visible
    clip: true
    color: Data.Colors.bgColor
    radius: 20

    required property var menu
    required property var systemTrayY
    required property var systemTrayHeight

    property bool containsMouse: trayMenuMouseArea.containsMouse
    property bool menuJustOpened: false
    property point triggerPoint: Qt.point(0, 0)
    property Item originalParent
    property int totalCount: opener.children ? opener.children.values.length : 0

    signal hideRequested()

    MouseArea {
        id: trayMenuMouseArea
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        propagateComposedEvents: false
    }

    onVisibleChanged: {
        if (visible) {
            menuJustOpened = true
            Qt.callLater(function() {
                menuJustOpened = false
            })
        }
    }

    function toggle() { 
        visible = !visible
        if (visible) {
            menuJustOpened = true
            Qt.callLater(function() {
                menuJustOpened = false
            })
        }
    }

    function show(point, parentItem) { 
        visible = true
        menuJustOpened = true
        Qt.callLater(function() {
            menuJustOpened = false
        })
    }

    function hide() { 
        visible = false 
        menuJustOpened = false
        hideRequested()
    }

    y: {
        var preferredY = systemTrayY + systemTrayHeight + 10
        var availableSpace = parent.height - preferredY - 20
        if (calculatedHeight > availableSpace) {
            return systemTrayY - height - 10
        }
        return preferredY
    }

    Behavior on height {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    property int calculatedHeight: {
        if (totalCount === 0) return 40
        var separatorCount = 0
        var regularItemCount = 0

        if (opener.children && opener.children.values) {
            for (var i = 0; i < opener.children.values.length; i++) {
                if (opener.children.values[i].isSeparator) {
                    separatorCount++
                } else {
                    regularItemCount++
                }
            }
        }

        var separatorHeight = separatorCount * 12
        var regularItemRows = Math.ceil(regularItemCount / 2)
        var regularItemHeight = regularItemRows * 32
        return Math.max(80, 35 + separatorHeight + regularItemHeight + 40)
    }

    QsMenuOpener {
        id: opener
        menu: root.menu
    }

    GridView {
        id: gridView
        anchors.fill: parent
        anchors.margins: 20
        cellWidth: width / 2
        cellHeight: 32
        interactive: false
        flow: GridView.FlowLeftToRight
        layoutDirection: Qt.LeftToRight

        model: ScriptModel {
            values: opener.children ? [...opener.children.values] : []
        }

        delegate: Item {
            id: entry
            required property var modelData
            required property int index

            width: gridView.cellWidth - 4
            height: modelData.isSeparator ? 12 : 30

            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.topMargin: 4
                anchors.bottomMargin: 4
                visible: modelData.isSeparator
                color: "transparent"

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    height: 1
                    color: Qt.darker(Data.Colors.accentColor, 1.5)
                    opacity: 0.6
                }
            }

            Rectangle {
                id: itemBackground
                anchors.fill: parent
                anchors.margins: 2
                visible: !modelData.isSeparator
                color: "transparent"
                radius: 6

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6

                    Image {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        source: modelData?.icon ?? ""
                        visible: (modelData?.icon ?? "") !== ""
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        Layout.fillWidth: true
                        color: mouseArea.containsMouse ? Data.Colors.accentColor : Data.Colors.fgColor
                        text: modelData?.text ?? ""
                        font.pixelSize: 11
                        font.family: "FiraCode Nerd Font"
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: (modelData?.enabled ?? true) && root.visible && !modelData.isSeparator

                    onEntered: itemBackground.color = Qt.rgba(Data.Colors.accentColor.r, Data.Colors.accentColor.g, Data.Colors.accentColor.b, 0.15)
                    onExited: itemBackground.color = "transparent"
                    onClicked: {
                        modelData.triggered()
                        root.hide()
                    }
                }
            }
        }
    }

    Item {
        anchors.centerIn: gridView
        visible: gridView.count === 0

        Label {
            anchors.centerIn: parent
            text: "No tray items available"
            color: Qt.darker(Data.Colors.fgColor, 2)
            font.pixelSize: 14
            font.family: "FiraCode Nerd Font"
        }
    }
} 