import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Widgets

TabButton {
    id: button
    property string buttonText
    property string buttonIcon
    property real minimumWidth: 110
    property bool selected: false
    property int tabContentWidth: contentItem.children[0].implicitWidth
    property int rippleDuration: 1200
    height: buttonBackground.height
    implicitWidth: Math.max(tabContentWidth, buttonBackground.implicitWidth, minimumWidth)

    property color colBackground: Qt.rgba(Appearance?.colors.colLayer1Hover.r, Appearance?.colors.colLayer1Hover.g, Appearance?.colors.colLayer1Hover.b, 0.6) || "transparent"
    property color colBackgroundHover: Qt.rgba(Appearance?.colors.colLayer1Hover.r, Appearance?.colors.colLayer1Hover.g, Appearance?.colors.colLayer1Hover.b, 0.8) ?? "#E5DFED"
    property color colRipple: Qt.rgba(Appearance?.colors.colLayer1Active.r, Appearance?.colors.colLayer1Active.g, Appearance?.colors.colLayer1Active.b, 0.8) ?? "#D6CEE2"
    property color colActive: Appearance?.colors.colPrimary ?? "#65558F"
    property color colInactive: Appearance?.colors.colOnLayer1 ?? "#45464F"

    component RippleAnim: NumberAnimation {
        duration: rippleDuration
        easing.type: Appearance?.animation.elementMoveEnter.type
        easing.bezierCurve: Appearance?.animationCurves.standardDecel
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: (event) => { 
            const {x,y} = event
            const stateY = buttonBackground.y;
            rippleAnim.x = x;
            rippleAnim.y = y - stateY;

            const dist = (ox,oy) => ox*ox + oy*oy
            const stateEndY = stateY + buttonBackground.height
            rippleAnim.radius = Math.sqrt(Math.max(dist(0, stateY), dist(0, stateEndY), dist(width, stateY), dist(width, stateEndY)))

            rippleFadeAnim.complete();
            rippleAnim.restart();
        }
        onReleased: (event) => {
            button.click() // Because the MouseArea already consumed the event
            rippleFadeAnim.restart();
        }
    }

    RippleAnim {
        id: rippleFadeAnim
        target: ripple
        property: "opacity"
        to: 0
    }

    SequentialAnimation {
        id: rippleAnim

        property real x
        property real y
        property real radius

        PropertyAction {
            target: ripple
            property: "x"
            value: rippleAnim.x
        }
        PropertyAction {
            target: ripple
            property: "y"
            value: rippleAnim.y
        }
        PropertyAction {
            target: ripple
            property: "opacity"
            value: 1
        }
        ParallelAnimation {
            RippleAnim {
                target: ripple
                properties: "implicitWidth,implicitHeight"
                from: 0
                to: rippleAnim.radius * 2
            }
        }
    }

    background: Item {
        id: buttonBackground
        implicitHeight: 50
        
        // Professional selected tab background with top-only rounded corners
        Item {
            anchors.centerIn: parent
            width: Math.max(button.tabContentWidth + 24, button.minimumWidth * 0.85)
            height: parent.height + 3
            visible: button.selected
            
            Rectangle {
                anchors.fill: parent
                topLeftRadius: (Appearance?.rounding.medium ?? 8) + 2
                topRightRadius: (Appearance?.rounding.medium ?? 8) + 2
                bottomLeftRadius: 0
                bottomRightRadius: 0
                
                // Clean gradient background
                gradient: Gradient {
                    GradientStop { 
                        position: 0.0
                        color: Qt.rgba(
                            Appearance?.colors.colPrimary.r ?? 0.4,
                            Appearance?.colors.colPrimary.g ?? 0.3,
                            Appearance?.colors.colPrimary.b ?? 0.6,
                            0.12
                        )
                    }
                    GradientStop { 
                        position: 1.0
                        color: Qt.rgba(
                            Appearance?.colors.colPrimary.r ?? 0.4,
                            Appearance?.colors.colPrimary.g ?? 0.3,
                            Appearance?.colors.colPrimary.b ?? 0.6,
                            0.08
                        )
                    }
                }
            }
            
            // Border outline with rounded top corners
            Rectangle {
                anchors.fill: parent
                topLeftRadius: (Appearance?.rounding.medium ?? 8) + 2
                topRightRadius: (Appearance?.rounding.medium ?? 8) + 2
                bottomLeftRadius: 0
                bottomRightRadius: 0
                color: "transparent"
                border.color: Qt.rgba(1, 1, 1, 0.15)
                border.width: 1
            }
            
            // Hide bottom border by covering it
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 1
                anchors.rightMargin: 1
                height: 4
                color: Qt.rgba(
                    Appearance?.colors.colPrimary.r ?? 0.4,
                    Appearance?.colors.colPrimary.g ?? 0.3,
                    Appearance?.colors.colPrimary.b ?? 0.6,
                    0.08
                )
            }
            
            // Smooth transitions
            Behavior on opacity {
                NumberAnimation { 
                    duration: 200
                    easing.type: Easing.OutQuart
                }
            }
        }
        
        // Minimal hover background with top-only rounded corners
        Rectangle {
            anchors.centerIn: parent
            width: Math.max(button.tabContentWidth + 16, button.minimumWidth * 0.8)
            height: parent.height - 10
            topLeftRadius: (Appearance?.rounding.medium ?? 8) + 2
            topRightRadius: (Appearance?.rounding.medium ?? 8) + 2
            bottomLeftRadius: 0
            bottomRightRadius: 0
            visible: button.hovered && !button.selected
            color: Qt.rgba(
                Appearance?.colors.colOnLayer1.r ?? 0.3,
                Appearance?.colors.colOnLayer1.g ?? 0.3,
                Appearance?.colors.colOnLayer1.b ?? 0.3,
                0.06
            )
            
            Behavior on opacity {
                NumberAnimation { 
                    duration: 150
                    easing.type: Easing.OutQuart
                }
            }
        }

        Item {
            id: ripple
            width: ripple.implicitWidth
            height: ripple.implicitHeight
            opacity: 0

            property real implicitWidth: 0
            property real implicitHeight: 0
            visible: width > 0 && height > 0

            Behavior on opacity {
                animation: Appearance?.animation.elementMoveFast.colorAnimation.createObject(this)
            }

            RadialGradient {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: button.colRipple }
                    GradientStop { position: 0.3; color: button.colRipple }
                    GradientStop { position: 0.5 ; color: Qt.rgba(button.colRipple.r, button.colRipple.g, button.colRipple.b, 0) }
                }
            }

            transform: Translate {
                x: -ripple.width / 2
                y: -ripple.height / 2
            }
        }
    }
    
    contentItem: Item {
        anchors.centerIn: buttonBackground
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0
            MaterialSymbol {
                visible: buttonIcon?.length > 0
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                text: buttonIcon
                iconSize: Appearance?.font.pixelSize.hugeass ?? 25
                fill: selected ? 1 : 0
                color: selected ? button.colActive : button.colInactive
                Behavior on color {
                    animation: Appearance?.animation.elementMoveFast.colorAnimation.createObject(this)
                }
            }
            StyledText {
                id: buttonTextWidget
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Appearance?.font.pixelSize.small
                color: selected ? button.colActive : button.colInactive
                text: buttonText
                Behavior on color {
                    animation: Appearance?.animation.elementMoveFast.colorAnimation.createObject(this)
                }
            }
        }
    }
}