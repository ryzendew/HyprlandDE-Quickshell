import "root:/"
import "root:/services/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

Item {
    required property var bar
    property bool borderless: ConfigOptions.bar?.borderless ?? false
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(bar.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    
    readonly property int workspaceGroup: Math.floor((monitor.activeWorkspace?.id - 1) / (ConfigOptions.bar?.workspaces?.shown || 1))
    property list<bool> workspaceOccupied: []
    property int widgetPadding: 4
    property int workspaceButtonWidth: 26
    property real workspaceIconSize: workspaceButtonWidth * 0.69
    property real workspaceIconSizeShrinked: workspaceButtonWidth * 0.55
    property real workspaceIconOpacityShrinked: 1
    property real workspaceIconMarginShrinked: -4
    property int workspaceIndexInGroup: (monitor.activeWorkspace?.id - 1) % (ConfigOptions.bar?.workspaces?.shown || 1)

    // Function to update workspaceOccupied
    function updateWorkspaceOccupied() {
        var shown = ConfigOptions.bar?.workspaces?.shown || 1
        workspaceOccupied = Array.from({ length: shown }, (_, i) => {
            return Hyprland.workspaces.values.some(ws => ws.id === workspaceGroup * shown + i + 1);
        })
    }

    // Initialize workspaceOccupied when the component is created
    Component.onCompleted: updateWorkspaceOccupied()

    // Listen for changes in Hyprland.workspaces.values
    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() {
            updateWorkspaceOccupied();
        }
    }

    Layout.fillHeight: true
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: 40

    // Background
    Rectangle {
        z: 0
        anchors.centerIn: parent
        implicitHeight: 32
        implicitWidth: rowLayout.implicitWidth + widgetPadding * 2
        radius: Appearance.rounding.small
        color: borderless ? "transparent" : Qt.rgba(
            Appearance.colors.colLayer1.r,
            Appearance.colors.colLayer1.g,
            Appearance.colors.colLayer1.b,
            0.65
        )
    }

    // Scroll to switch workspaces
    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y < 0)
                Hyprland.dispatch(`workspace r+1`);
            else if (event.angleDelta.y > 0)
                Hyprland.dispatch(`workspace r-1`);
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton
        onPressed: (event) => {
            if (event.button === Qt.BackButton) {
                Hyprland.dispatch(`togglespecialworkspace`);
            } 
        }
    }

    // Workspaces - background
    RowLayout {
        id: rowLayout
        z: 1

        spacing: 0
        anchors.fill: parent
        implicitHeight: 40

        Repeater {
            model: ConfigOptions.bar?.workspaces?.shown || 1

            Rectangle {
                z: 1
                implicitWidth: workspaceButtonWidth
                implicitHeight: workspaceButtonWidth
                radius: Appearance.rounding.full
                property var leftOccupied: (workspaceOccupied[index-1] && !(!activeWindow?.activated && monitor.activeWorkspace?.id === index))
                property var rightOccupied: (workspaceOccupied[index+1] && !(!activeWindow?.activated && monitor.activeWorkspace?.id === index+2))
                property var radiusLeft: leftOccupied ? 0 : Appearance.rounding.full
                property var radiusRight: rightOccupied ? 0 : Appearance.rounding.full

                topLeftRadius: radiusLeft
                bottomLeftRadius: radiusLeft
                topRightRadius: radiusRight
                bottomRightRadius: radiusRight
                
                color: Qt.rgba(
                    Appearance.m3colors.m3secondaryContainer.r,
                    Appearance.m3colors.m3secondaryContainer.g,
                    Appearance.m3colors.m3secondaryContainer.b,
                    0.65
                )
                opacity: (workspaceOccupied[index] && !(!activeWindow?.activated && monitor.activeWorkspace?.id === index+1)) ? 1 : 0

                Behavior on opacity {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }
                Behavior on radiusLeft {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }

                Behavior on radiusRight {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }

            }

        }

    }

    // Active workspace
    Rectangle {
        z: 2
        // Make active ws indicator, which has a brighter color, smaller to look like it is of the same size as ws occupied highlight
        property real activeWorkspaceMargin: 2
        implicitHeight: workspaceButtonWidth - activeWorkspaceMargin * 2
        radius: Appearance.rounding.full
        color: Qt.rgba(
            Appearance.colors.colPrimary.r,
            Appearance.colors.colPrimary.g,
            Appearance.colors.colPrimary.b,
            0.85
        )
        anchors.verticalCenter: parent.verticalCenter

        property real idx1: workspaceIndexInGroup
        property real idx2: workspaceIndexInGroup
        x: Math.min(idx1, idx2) * workspaceButtonWidth + activeWorkspaceMargin
        implicitWidth: Math.abs(idx1 - idx2) * workspaceButtonWidth + workspaceButtonWidth - activeWorkspaceMargin * 2

        Behavior on activeWorkspaceMargin {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on idx1 { // Leading anim
            NumberAnimation {
                duration: 100
                easing.type: Easing.OutSine
            }
        }
        Behavior on idx2 { // Following anim
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutSine
            }
        }
    }

    // Workspaces - numbers
    RowLayout {
        id: rowLayoutNumbers
        z: 3

        spacing: 0
        anchors.fill: parent
        implicitHeight: 40

        Repeater {
            model: ConfigOptions.bar?.workspaces?.shown || 1

            Button {
                id: button
                property int workspaceValue: workspaceGroup * ConfigOptions.bar?.workspaces?.shown + index + 1
                Layout.fillHeight: true
                onPressed: Hyprland.dispatch(`workspace ${workspaceValue}`)
                width: workspaceButtonWidth
                
                background: Item {
                    id: workspaceButtonBackground
                    implicitWidth: workspaceButtonWidth
                    implicitHeight: workspaceButtonWidth
                    property var biggestWindow: {
                        const windowsInThisWorkspace = HyprlandData.windowList.filter(w => w.workspace.id == button.workspaceValue)
                        return windowsInThisWorkspace.reduce((maxWin, win) => {
                            const maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0)
                            const winArea = (win?.size?.[0] ?? 0) * (win?.size?.[1] ?? 0)
                            return winArea > maxArea ? win : maxWin
                        }, null)
                    }
                    property var mainAppIconSource: Quickshell.iconPath(AppSearch.guessIcon(biggestWindow?.class), "image-missing")

                    StyledText {
                        opacity: (ConfigOptions.bar?.workspaces?.alwaysShowNumbers || false) || GlobalStates.workspaceShowNumbers || !workspaceButtonBackground.biggestWindow ? 1 : 0
                        z: 3

                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: Appearance.font.pixelSize.small - ((text.length - 1) * (text !== "10") * 2)
                        text: `${button.workspaceValue}`
                        elide: Text.ElideRight
                        color: (monitor.activeWorkspace?.id == button.workspaceValue) ? 
                            Appearance.m3colors.m3onPrimary : 
                            (workspaceOccupied[index] ? Appearance.m3colors.m3onSecondaryContainer : 
                                Appearance.colors.colOnLayer1Inactive)

                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }

                    }
                    Item {
                        anchors.centerIn: parent
                        width: workspaceButtonWidth
                        height: workspaceButtonWidth
                        IconImage {
                            id: mainAppIcon
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.bottomMargin: (!GlobalStates.workspaceShowNumbers && !(ConfigOptions.bar?.workspaces?.alwaysShowNumbers || false)) ? 
                                (workspaceButtonWidth - workspaceIconSize) / 2 : workspaceIconMarginShrinked
                            anchors.rightMargin: (!GlobalStates.workspaceShowNumbers && !(ConfigOptions.bar?.workspaces?.alwaysShowNumbers || false)) ? 
                                (workspaceButtonWidth - workspaceIconSize) / 2 : workspaceIconMarginShrinked

                            opacity: (workspaceButtonBackground.biggestWindow && !GlobalStates.workspaceShowNumbers && !(ConfigOptions.bar?.workspaces?.alwaysShowNumbers || false)) ? 
                                1 : workspaceButtonBackground.biggestWindow ? workspaceIconOpacityShrinked : 0
                            visible: opacity > 0
                            source: workspaceButtonBackground.mainAppIconSource
                            implicitSize: (!GlobalStates.workspaceShowNumbers && !(ConfigOptions.bar?.workspaces?.alwaysShowNumbers || false)) ? workspaceIconSize : workspaceIconSizeShrinked

                            Behavior on opacity {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                            Behavior on anchors.bottomMargin {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                            Behavior on anchors.rightMargin {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                            Behavior on implicitSize {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                        }
                    }
                }
                

            }

        }

    }

}
