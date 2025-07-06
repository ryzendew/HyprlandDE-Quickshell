import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Widgets

/**
 * Material 3 button with expressive bounciness. 
 * See https://m3.material.io/components/button-groups/overview
 */
Button {
    id: root
    property bool toggled
    property string buttonText
    property real buttonRadius: Appearance?.rounding?.small ?? 4
    property real buttonRadiusPressed: buttonRadius
    property var downAction // When left clicking (down)
    property var releaseAction // When left clicking (release)
    property var altAction // When right clicking
    property var middleClickAction // When middle clicking
    property bool bounce: true
    property real baseWidth: contentItem.implicitWidth + padding * 2
    property real baseHeight: contentItem.implicitHeight + padding * 2
    property real clickedWidth: baseWidth + 20
    property real clickedHeight: baseHeight
    property var parentGroup: root.parent
    property int clickIndex: parentGroup?.clickIndex ?? -1

    // --- Button sizing ---
    property int horizontalTextPadding: 12
    property int verticalTextPadding: 8
    implicitWidth: contentItem.implicitWidth + horizontalTextPadding * 2
    implicitHeight: contentItem.implicitHeight + verticalTextPadding * 2
    Layout.fillWidth: false
    Layout.fillHeight: false
    
    Behavior on implicitWidth {
        animation: Appearance.animation.clickBounce.numberAnimation.createObject(this)
    }

    Behavior on implicitHeight {
        animation: Appearance.animation.clickBounce.numberAnimation.createObject(this)
    }

    Behavior on radius {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    // Material 4 (Material You) color logic
    property color colBackground: Appearance.m3colors.m3surfaceContainerLow
    property color colBackgroundHover: Appearance.m3colors.m3surfaceVariant
    property color colBackgroundActive: Appearance.m3colors.m3surfaceVariant
    property color colBackgroundToggled: Appearance.m3colors.m3primaryContainer
    property color colBackgroundToggledHover: Appearance.m3colors.m3primaryContainer
    property color colBackgroundToggledActive: Appearance.m3colors.m3primaryContainer

    property color borderColor: root.toggled ? Appearance.m3colors.m3primary : (root.hovered ? Appearance.m3colors.m3outline : Appearance.m3colors.m3outlineVariant)
    property real borderWidth: root.toggled ? 2 : 1
    property real radius: 12
    property color color: root.enabled ? (root.toggled ? 
        (root.down ? colBackgroundToggledActive : 
            root.hovered ? colBackgroundToggledHover : 
            colBackgroundToggled) :
        (root.down ? colBackgroundActive : 
            root.hovered ? colBackgroundHover : 
            colBackground)) : colBackground

    onDownChanged: {
        if (root.down) {
            if (root.parent.clickIndex !== undefined) {
                root.parent.clickIndex = parent.children.indexOf(root)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: (event) => { 
            if(event.button === Qt.RightButton) {
                if (root.altAction) root.altAction();
                return;
            }
            if(event.button === Qt.MiddleButton) {
                if (root.middleClickAction) root.middleClickAction();
                return;
            }
            root.down = true
            if (root.downAction) root.downAction();
        }
        onReleased: (event) => {
            root.down = false
            if (event.button != Qt.LeftButton) return;
            if (root.releaseAction) root.releaseAction();
            root.click() // Because the MouseArea already consumed the event
        }
        onCanceled: (event) => {
            root.down = false
        }
    }

    // Modern pill button background
    background: Rectangle {
        id: buttonBackground
        anchors.fill: parent
        radius: root.radius
        color: root.color
        border.color: root.borderColor
        border.width: root.borderWidth
        layer.enabled: root.toggled
        layer.effect: DropShadow {
            anchors.fill: parent
            horizontalOffset: 0
            verticalOffset: 2
            radius: 12
            samples: 32
            color: Qt.rgba(Appearance.m3colors.m3shadow.r, Appearance.m3colors.m3shadow.g, Appearance.m3colors.m3shadow.b, root.toggled ? 0.18 : 0.0)
        }
        Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
        Behavior on border.color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
        Behavior on border.width { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
    }

    contentItem: StyledText {
        text: root.buttonText
        font.pixelSize: Appearance.font.pixelSize.normal + 2
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: root.toggled ? Appearance.m3colors.m3onPrimaryContainer : Appearance.m3colors.m3onSurfaceVariant
    }

    // Ripple effect on press
    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: root.clicked()
        onPressedChanged: if (pressed) ripple.start()
    }
    Rectangle {
        id: ripple
        anchors.fill: parent
        radius: parent.radius
        color: Qt.rgba(Appearance.m3colors.m3primary.r, Appearance.m3colors.m3primary.g, Appearance.m3colors.m3primary.b, 0.08)
        opacity: 0
        Behavior on opacity { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
        function start() {
            opacity = 0.5
            Qt.callLater(() => opacity = 0)
        }
    }
}
