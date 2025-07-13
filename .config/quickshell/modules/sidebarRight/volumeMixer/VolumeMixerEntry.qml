import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"

import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire

Item {
    id: root
    required property PwNode node;
	PwObjectTracker { objects: [ node ] }

    implicitHeight: rowLayout.implicitHeight

    signal requestMoveToDevice(var node)

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 10

        // Only show the icon if not sd_dummy or fallback
        Item {
            Layout.preferredWidth: (root.node.properties["application.name"] === "sd_dummy" || root.node.properties["application.process.binary"] === "sd_dummy") ? 0 : 38
            Layout.preferredHeight: 38
            visible: !(root.node.properties["application.name"] === "sd_dummy" || root.node.properties["application.process.binary"] === "sd_dummy")
        Image {
                anchors.fill: parent
            sourceSize.width: 38
            sourceSize.height: 38
            source: {
                    let appName = root.node.properties["application.name"];
                    let process = root.node.properties["application.process.binary"];
                    let winClass = root.node.properties["window.class"];
                    let icon = root.node.properties["application.icon-name"];
                    let iconIdentifier = icon;
                    if (process && process !== "chromium" && process !== "electron") {
                        appName = process;
                        if (!icon || icon === "chromium-browser") {
                            iconIdentifier = process;
                        }
                    }
                    if (process === "Cider" || winClass === "Cider") {
                        appName = "Cider";
                        iconIdentifier = "cider";
                    }
                    if (appName === "sd_dummy" || process === "sd_dummy" || iconIdentifier === "application-x-executable" || iconIdentifier === "settings") {
                        return "";
                    }
                    var desktopEntry = DesktopEntries.byId(iconIdentifier);
                    if (desktopEntry && desktopEntry.iconUrl) {
                        return desktopEntry.iconUrl;
                    }
                    var guessedIcon = AppSearch.guessIcon(iconIdentifier);
                    var finalIcon = "image://icon/" + (guessedIcon || "application-x-executable");
                    return finalIcon;
                }
                opacity: (root.node.properties["application.name"] === "sd_dummy" || root.node.properties["application.process.binary"] === "sd_dummy" || source === "" ) ? 0 : 1
                visible: opacity > 0
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            RowLayout {
                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.normal
                    elide: Text.ElideRight
                    text: {
                        // Use application.process.binary for better app name detection
                        let app = root.node.properties["application.name"] ?? (root.node.description != "" ? root.node.description : root.node.name);
                        let process = root.node.properties["application.process.binary"];
                        let winClass = root.node.properties["window.class"];
                        
                        // If we have a process binary, prefer it over application.name for better detection
                        if (process && process !== "chromium" && process !== "electron") {
                            app = process;
                        }
                        
                        // Special case for Cider (Apple Music)
                        if (process === "Cider" || winClass === "Cider") {
                            app = "Cider";
                        }
                        
                        const media = root.node.properties["media.name"];
                        return media != undefined ? `${app} • ${media}` : app;
                    }
                    color: "#fff"
                    opacity: 0
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }

                    Component.onCompleted: {
                        opacity = 1
                    }
                }
            }

            RowLayout {
                StyledSlider {
                    id: slider
                    Layout.fillWidth: true
                    scale: 0.45
                    from: 0
                    to: 1.0
                    value: root.node.audio.volume
                    onValueChanged: root.node.audio.volume = value
                    opacity: 0
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }

                    Component.onCompleted: {
                        opacity = 1
                    }
                }
                
                // Volume percentage display
                StyledText {
                    text: Math.round(root.node.audio.volume * 100) + "%"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    opacity: 0.7
                    Layout.preferredWidth: 35
                    horizontalAlignment: Text.AlignRight
                }
                
                // Settings cog for device assignment
                Rectangle {
                    width: 28; height: 28; radius: 14
                    color: cogMouseArea.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                    border.color: Qt.rgba(1,1,1,0.12)
                    border.width: 1
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "settings"
                        iconSize: 18
                        color: "#fff"
                        opacity: 0.7
                    }
                    MouseArea {
                        id: cogMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.requestMoveToDevice(root.node)
                    }
                }
            }
        }
    }
}