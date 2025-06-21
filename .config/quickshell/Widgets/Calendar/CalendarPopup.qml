import QtQuick
import QtQuick.Controls
import "root:/Data" as Data

// Calendar popup with animations
Popup {
    id: calendarPopup
    property bool hovered: false
    property bool clickMode: false  // Persistent mode - stays open until clicked again
    property var shell
    property int targetX: 0
    readonly property int targetY: Screen.height - height

    width: 280
    height: 280
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 15

    // Animation state properties
    property bool _visible: false
    property real animX: targetX - 20
    property real animOpacity: 0

    x: animX
    y: targetY
    opacity: animOpacity
    visible: _visible

    // Smooth slide-in animation
    Behavior on animX {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }
    Behavior on animOpacity {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    // Hover mode: show/hide based on mouse state
    onHoveredChanged: {
        if (!clickMode) {
            if (hovered) {
                _visible = true
                animX = targetX
                animOpacity = 1
            } else {
                animX = targetX - 20
                animOpacity = 0
            }
        }
    }

    // Click mode: persistent visibility toggle
    onClickModeChanged: {
        if (clickMode) {
            _visible = true
            animX = targetX
            animOpacity = 1
        } else {
            animX = targetX - 20
            animOpacity = 0
        }
    }

    // Hide when animation completes
    onAnimOpacityChanged: {
        if (animOpacity === 0 && !hovered && !clickMode) {
            _visible = false
        }
    }

    function setHovered(state) {
        hovered = state
    }

    function setClickMode(state) {
        clickMode = state
    }

    // Hover detection
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        anchors.margins: 10 // Larger area to reduce flicker

        onEntered: {
            if (!clickMode) {
                setHovered(true)
            }
        }
        onExited: {
            if (!clickMode) {
                // Delayed exit check to prevent hover flicker
                Qt.callLater(() => {
                    if (!hoverArea.containsMouse) {
                        setHovered(false)
                    }
                })
            }
        }
    }

    // Lazy-loaded calendar content
    Loader {
        anchors.fill: parent
        active: calendarPopup._visible
        source: active ? "Calendar.qml" : ""
        onLoaded: {
            if (item) {
                item.shell = calendarPopup.shell
            }
        }
    }

    background: Rectangle {
        color: Data.Colors.bgColor
        topRightRadius: 20
    }
}
