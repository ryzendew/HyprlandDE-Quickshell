import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "root:/modules/common/functions/icons.js" as Icons
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

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 10

        Image {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            sourceSize.width: 38
            sourceSize.height: 38
            source: {
                const icon = Icons.noKnowledgeIconGuess(root.node.properties["application.icon-name"]);
                return Quickshell.iconPath(icon, "image-missing");
            }
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

        ColumnLayout {
            Layout.fillWidth: true
            RowLayout {
                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.normal
                    elide: Text.ElideRight
                    text: {
                        // application.name -> description -> name
                        const app = root.node.properties["application.name"] ?? (root.node.description != "" ? root.node.description : root.node.name);
                        const media = root.node.properties["media.name"];
                        return media != undefined ? `${app} • ${media}` : app;
                    }
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
            }
        }
    }
}