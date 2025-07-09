import "root:/modules/common"
import "root:/services"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import "./notification_utils.js" as NotificationUtils

Item {
    id: root
    property var notificationObject: ({})
    property bool popup: false
    property bool expanded: false
    property bool enableAnimation: true
    property int notificationListSpacing: 5
    property bool ready: false
    property int defaultTimeoutValue: 5000
    property string groupName: ""
    property int groupCount: 1
    property bool isGrouped: groupCount > 1
    property var iconCache: ({})
    property var imageCache: ({})

    property var notificationXAnimation: Appearance.animation.elementMoveEnter

    Layout.fillWidth: true
    clip: !popup

    implicitHeight: ready ? notificationColumnLayout.implicitHeight + notificationListSpacing : 0
    Behavior on implicitHeight {
        enabled: enableAnimation
        NumberAnimation {
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
        }
    }

    Component.onCompleted: {
        root.ready = true
        if (popup && notificationObject && notificationObject.appName) {
            timeoutTimer.start()
        }
    }

    Timer {
        id: timeoutTimer
        interval: notificationObject && notificationObject.expireTimeout ? notificationObject.expireTimeout : root.defaultTimeoutValue
        repeat: false
        onTriggered: {
            root.notificationXAnimation = Appearance.animation.elementMoveExit
            if (notificationObject && notificationObject.id) {
                Notifications.timeoutNotification(notificationObject.id);
            }
        }
    }

    function destroyWithAnimation(delay = 0) {
        destroyTimer0.interval = delay
        destroyTimer0.start()
    }

    function toggleExpanded() {
        root.enableAnimation = true
        notificationRowWrapper.anchors.bottom = undefined
        root.expanded = !root.expanded
    }

    Timer {
        id: destroyTimer0
        interval: 0
        repeat: false
        onTriggered: {
            notificationRowWrapper.anchors.left = undefined
            notificationRowWrapper.anchors.right = undefined
            notificationRowWrapper.anchors.fill = undefined
            notificationBackground.anchors.left = undefined
            notificationBackground.anchors.right = undefined
            notificationBackground.anchors.fill = undefined
            notificationRowWrapper.x = width + 5 * 2 // Account for shadow
            notificationBackground.x = width + 5 * 2 // Account for shadow
            destroyTimer1.start()
        }
    }

    Timer {
        id: destroyTimer1
        interval: Appearance.animation.elementMoveFast.duration
        repeat: false
        onTriggered: {
            notificationRowWrapper.anchors.top = undefined
            notificationRowWrapper.anchors.bottom = root.bottom
            implicitHeight = 0
            destroyTimer2.start()
        }
    }

    Timer {
        id: destroyTimer2
        interval: Appearance.animation.elementMoveFast.duration
        repeat: false
        onTriggered: {
            root.destroy()
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        
        // Flick right to dismiss/discard
        property real startX: 0
        property real dragStartThreshold: 10
        property real dragConfirmThreshold: 70
        property bool dragStarted: false
        
        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) {
                Notifications.discardNotification(notificationObject.id)
            } else if (mouse.button === Qt.RightButton) {
                root.toggleExpanded()
            } else if (mouse.button === Qt.LeftButton) {
                // Try to focus the application that sent the notification
                if (notificationObject && notificationObject.appName) {
                    // Common app name to window class mappings
                    const appClassMappings = {
                        "Discord": ["vesktop", "discord", "Discord"],
                        "Spotify": ["spotify", "Spotify"],
                        "Firefox": ["firefox", "Firefox"],
                        "Chrome": ["google-chrome", "chromium", "chrome"],
                        "Code": ["code", "Code"],
                        "Telegram": ["telegram-desktop", "telegram"],
                        "Steam": ["steam", "Steam"],
                        "OBS": ["obs", "OBS Studio"],
                        "Thunderbird": ["thunderbird", "Thunderbird"]
                    }
                    
                    const appName = notificationObject.appName
                    let classesToTry = []
                    
                    // Check if we have a mapping for this app
                    if (appClassMappings[appName]) {
                        classesToTry = appClassMappings[appName]
                    } else {
                        // Fallback to original app name and common variations
                        classesToTry = [
                            appName,
                            appName.toLowerCase(),
                            appName.replace(/\s+/g, '-').toLowerCase(),
                            appName.replace(/\s+/g, '').toLowerCase()
                        ]
                    }
                    
                    // Try each class variation
                    let focused = false
                    for (const className of classesToTry) {
                        if (className && className !== "") {
                            Hyprland.dispatch(`focuswindow class:${className}`)
                        }
                    }
                    
                    // Close the sidebar after attempting to focus
                    Hyprland.dispatch("global quickshell:sidebarRightClose")
                }
            }
        }
        
        onPressed: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                startX = mouse.x
            }
        }

        onPressAndHold: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                Hyprland.dispatch(`exec wl-copy '${StringUtils.shellSingleQuoteEscape(notificationObject.body)}'`)
                notificationSummaryText.text = String.format(qsTr("{0} (copied)"), notificationObject.summary)
            }
        }

        onDragStartedChanged: () => {
            // Prevent drag focus being shifted to parent flickable
            if (root.parent.parent.parent.interactive !== undefined) root.parent.parent.parent.interactive = !dragStarted
            root.enableAnimation = !dragStarted
        }

        onPositionChanged: (mouse) => {
            if (mouse.buttons & Qt.LeftButton) {
                let dx = mouse.x - startX
                if (dragStarted || dx > dragStartThreshold) {
                    dragStarted = true
                    notificationRowWrapper.anchors.left = undefined
                    notificationRowWrapper.anchors.right = undefined
                    notificationRowWrapper.anchors.fill = undefined
                    notificationBackground.anchors.left = undefined
                    notificationBackground.anchors.right = undefined
                    notificationBackground.anchors.fill = undefined
                    notificationRowWrapper.x = Math.max(0, dx)
                    notificationBackground.x = Math.max(0, dx)
                }
            }
        }

        onReleased: (mouse) => {
            dragStarted = false
            if (mouse.button === Qt.LeftButton) {
                if (notificationRowWrapper.x > dragConfirmThreshold) {
                    root.notificationXAnimation = Appearance.animation.elementMoveEnter
                    Notifications.discardNotification(notificationObject.id)
                } else {
                    // Animate back if not far enough
                    root.notificationXAnimation = Appearance.animation.elementMoveFast
                    notificationRowWrapper.x = 0
                    notificationBackground.x = 0
                }
            }
        }
    }

    // Background
    Item {
        id: notificationBackgroundWrapper
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: notificationListSpacing
        implicitHeight: notificationColumnLayout.implicitHeight + notificationListSpacing

        Rectangle {
            id: notificationBackground
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: notificationColumnLayout.implicitHeight

            color: (notificationObject && notificationObject.urgency == NotificationUrgency.Critical) ? 
                ColorUtils.mix(Appearance.colors.colLayer2, Appearance.colors.colLayer1, 0.35) : 
                Appearance.colors.colLayer1
            radius: Appearance.rounding.normal

            layer.enabled: true
            layer.effect: MultiEffect {
                source: notificationBackground
                anchors.fill: notificationBackground
                shadowEnabled: popup
                shadowColor: Appearance.colors.colShadow
                shadowVerticalOffset: 1
                shadowBlur: 0.5
            }

            Behavior on x {
                enabled: enableAnimation
                NumberAnimation {
                    duration: root.notificationXAnimation.duration
                    easing.type: root.notificationXAnimation.type
                    easing.bezierCurve: root.notificationXAnimation.bezierCurve
                }
            }
            Behavior on height {
                enabled: enableAnimation
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }
        }
    }

    // Add group indicator if part of a group
    Rectangle {
        visible: isGrouped
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 8
        anchors.rightMargin: 8
        width: groupCountText.width + 12
        height: groupCountText.height + 4
        radius: height / 2
        color: Qt.rgba(Appearance.colors.colLayer1.r, Appearance.colors.colLayer1.g, Appearance.colors.colLayer1.b, 0.8)

        StyledText {
            id: groupCountText
            anchors.centerIn: parent
            text: groupCount.toString()
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
        }
    }

    Item {
        id: notificationRowWrapper
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        implicitHeight: notificationColumnLayout.implicitHeight + notificationListSpacing

        Behavior on x {
            enabled: enableAnimation
            NumberAnimation {
                duration: root.notificationXAnimation.duration
                easing.type: root.notificationXAnimation.type
                easing.bezierCurve: root.notificationXAnimation.bezierCurve
            }
        }

        ColumnLayout {
            id: notificationColumnLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 0
            Item {
                Layout.fillWidth: true
                implicitHeight: notificationRowLayout.implicitHeight
                Behavior on implicitHeight {
                    enabled: enableAnimation
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }

                    RowLayout {
                    id: notificationRowLayout
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Rectangle { // App icon
                        id: iconRectangle
                        implicitWidth: 47
                        implicitHeight: 47
                        Layout.leftMargin: 10
                        Layout.topMargin: 10
                        Layout.bottomMargin: 10
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: false
                        radius: Appearance.rounding.full
                        color: Appearance.m3colors.m3secondaryContainer
                        Loader {
                            id: materialSymbolLoader
                            active: !notificationObject || !notificationObject.appIcon || notificationObject.appIcon == ""
                            anchors.fill: parent
                            sourceComponent: MaterialSymbol {
                                text: {
                                    const defaultIcon = NotificationUtils.findSuitableMaterialSymbol("")
                                    const guessedIcon = notificationObject && notificationObject.summary ? 
                                        NotificationUtils.findSuitableMaterialSymbol(notificationObject.summary) : defaultIcon
                                    return (notificationObject && notificationObject.urgency == NotificationUrgency.Critical && guessedIcon === defaultIcon) ?
                                        "release_alert" : guessedIcon
                                }
                                anchors.fill: parent
                                color: (notificationObject && notificationObject.urgency == NotificationUrgency.Critical) ? 
                                    ColorUtils.mix(Appearance.m3colors.m3onSecondary, Appearance.m3colors.m3onSecondaryContainer, 0.1) :
                                    Appearance.m3colors.m3onSecondaryContainer
                                iconSize: 27
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                        Loader {
                            id: appIconLoader
                            active: notificationObject && notificationObject.appIcon && notificationObject.appIcon != "" && 
                                   (!notificationObject.image || notificationObject.image == "")
                            anchors.centerIn: parent
                            sourceComponent: IconImage {
                                implicitSize: 33
                                asynchronous: true
                                source: {
                                    if (!notificationObject || !notificationObject.appIcon) return ""
                                    const iconPath = Quickshell.iconPath(notificationObject.appIcon, "image-missing")
                                    if (!iconCache[iconPath]) {
                                        iconCache[iconPath] = true
                                    }
                                    return iconPath
                                }
                            }
                        }
                        Loader {
                            id: notifImageLoader
                            active: notificationObject && notificationObject.image && notificationObject.image != ""
                            anchors.fill: parent
                            sourceComponent: Item {
                                anchors.fill: parent
                                property string originalSource: notificationObject ? notificationObject.image || "" : ""
                                property string fallbackIconSource: Quickshell.iconPath("image-missing", "dialog-error")

                                Image {
                                    id: notificationActualImage
                                    anchors.fill: parent
                                    asynchronous: true
                                    source: parent.originalSource
                                    smooth: true
                                    mipmap: true
                                    fillMode: Image.PreserveAspectFit
                                    cache: false  // Disable caching to avoid stride issues

                                    onStatusChanged: {
                                        if (status === Image.Error) {
                                            // console.warn("[NotificationWidget] Failed to load image: " + parent.originalSource + ". Using fallback.");
                                            root.imageCache[parent.originalSource] = { failed: true }; 
                                            source = parent.fallbackIconSource;
                                        } else if (status === Image.Ready) {
                                            root.imageCache[parent.originalSource] = { failed: false }; 
                                        }
                                    }

                                    Component.onCompleted: {
                                        if (root.imageCache[parent.originalSource] && root.imageCache[parent.originalSource].failed) {
                                            source = parent.fallbackIconSource;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout { // Notification content
                        spacing: 0
                        Layout.fillWidth: true

                        RowLayout { // Row of summary, time and expand button
                            Layout.topMargin: 10
                            Layout.leftMargin: 10
                            Layout.rightMargin: 10
                            Layout.fillWidth: true

                            StyledText { // Summary
                                id: notificationSummaryText
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignBottom
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer2
                                text: notificationObject ? notificationObject.summary || "" : ""
                                wrapMode: expanded ? Text.Wrap : Text.NoWrap
                                elide: Text.ElideRight
                            }

                            CircularProgress {
                                id: notificationProgress
                                visible: popup
                                Layout.alignment: Qt.AlignVCenter
                                lineWidth: 2
                                value: popup ? 1 : 0
                                size: 20
                                animationDuration: notificationObject && notificationObject.expireTimeout ? 
                                    notificationObject.expireTimeout : root.defaultTimeoutValue
                                easingType: Easing.Linear

                                Component.onCompleted: {
                                    value = 0
                                }
                        }

                            StyledText { // Time
                                id: notificationTimeText
                                Layout.fillWidth: false
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: 3
                                wrapMode: Text.Wrap
                                horizontalAlignment: Text.AlignLeft
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOnLayer2
                                text: {
                                    if (!notificationObject || notificationObject.time === undefined || notificationObject.time === null) {
                                        return "Just now"
                                    }
                                    return NotificationUtils.getFriendlyNotifTimeString(notificationObject.time)
                                }

                                Connections {
                                    target: DateTime
                                    function onTimeChanged() {
                                        if (notificationObject && notificationObject.time !== undefined && notificationObject.time !== null) {
                                            notificationTimeText.text = NotificationUtils.getFriendlyNotifTimeString(notificationObject.time)
                                        }
                                    }
                                }
                            }

                            Button { // Expand button
                                Layout.alignment: Qt.AlignTop
                                id: expandButton
                                implicitWidth: 22
                                implicitHeight: 22

                                PointingHandInteraction{}
                                onClicked: {
                                    root.toggleExpanded()
                                }

                                background: Rectangle {
                                    anchors.fill: parent
                                    radius: Appearance.rounding.full
                                    color: (expandButton.down) ? Appearance.colors.colLayer2Active : (expandButton.hovered ? Appearance.colors.colLayer2Hover : ColorUtils.transparentize(Appearance.colors.colLayer2, 1))

                                    Behavior on color {
                                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                    }
                                }

                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "keyboard_arrow_down"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer2
                                    rotation: expanded ? 180 : 0
                                    Behavior on rotation {
                                        NumberAnimation {
                                            duration: Appearance.animation.elementMoveFast.duration
                                            easing.type: Appearance.animation.elementMoveFast.type
                                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                                        }
                                    }
                                }
                            }
                        }

                        StyledText { // Notification body
                            id: notificationBodyText
                            Layout.fillWidth: true
                            Layout.leftMargin: 10
                            Layout.rightMargin: 10
                            Layout.bottomMargin: 10
                            clip: true

                            wrapMode: expanded ? Text.Wrap : Text.NoWrap
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.font.pixelSize.small
                            horizontalAlignment: Text.AlignLeft
                            color: Appearance.colors.colOnLayer2
                            textFormat: expanded ? Text.RichText : Text.StyledText
                            text: {
                                if (!notificationObject || !notificationObject.body) return ""
                                
                                if (expanded) {
                                    return `<style>img{max-width:${notificationBodyText.width}px;}</style>` + 
                                           `${notificationObject.body.replace(/\n/g, "<br/>")}` 
                                } else {
                                    return notificationObject.body.replace(/<img/g, "\n <img").split("\n")[0]
                                }
                            }
                            onLinkActivated: (link) => {
                                Qt.openUrlExternally(link)
                                Hyprland.dispatch("global quickshell:sidebarRightClose")
                            }
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.NoButton // Only for hover
                                hoverEnabled: true
                                cursorShape: parent.hoveredLink !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
                    }
                }
            }
                }
            }

            // Actions
            Flickable {
                id: actionsFlickable
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.bottomMargin: expanded ? 10 : 0
                implicitHeight: expanded ? actionRowLayout.implicitHeight : 0
                height: expanded ? actionRowLayout.implicitHeight : 0
                contentWidth: actionRowLayout.implicitWidth

                clip: true
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: actionsFlickable.width
                        height: actionsFlickable.height
                        radius: Appearance.rounding.small
                    }
                }

                opacity: expanded ? 1 : 0
                visible: opacity > 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }
                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }

                RowLayout {
                    id: actionRowLayout
                    Layout.alignment: Qt.AlignBottom

                Repeater {
                        id: actionRepeater
                        model: notificationObject && notificationObject.actions ? notificationObject.actions : []
                        NotificationActionButton {
                            Layout.fillWidth: true
                            buttonText: modelData ? modelData.text || "" : ""
                            urgency: notificationObject ? notificationObject.urgency : NotificationUrgency.Normal
                            onClicked: {
                                if (notificationObject && notificationObject.id && modelData && modelData.identifier) {
                                    Notifications.attemptInvokeAction(notificationObject.id, modelData.identifier);
                                }
                            }
                        }
                    }

                    NotificationActionButton {
                        Layout.fillWidth: true
                        urgency: notificationObject ? notificationObject.urgency : NotificationUrgency.Normal
                        implicitWidth: (notificationObject && notificationObject.actions && notificationObject.actions.length == 0) ? 
                            (actionsFlickable.width / 2) : (contentItem.implicitWidth + leftPadding + rightPadding)

                        onClicked: {
                            if (notificationObject && notificationObject.body) {
                                Hyprland.dispatch(`exec wl-copy '${StringUtils.shellSingleQuoteEscape(notificationObject.body)}'`)
                                copyIcon.text = "inventory"
                                copyIconTimer.stop()
                                copyIconTimer.start()
                            }
                        }

                        Timer {
                            id: copyIconTimer
                            interval: 1500
                            repeat: false
                            onTriggered: {
                                copyIcon.text = "content_copy"
                            }
                        }

                        contentItem: MaterialSymbol {
                            id: copyIcon
                            iconSize: Appearance.font.pixelSize.large
                            horizontalAlignment: Text.AlignHCenter
                            color: (notificationObject && notificationObject.urgency == NotificationUrgency.Critical) ? 
                                Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
                            text: "content_copy"
                        }
                    }

                    NotificationActionButton {
                        Layout.fillWidth: true
                        buttonText: qsTr("Close")
                        urgency: notificationObject ? notificationObject.urgency : NotificationUrgency.Normal
                        implicitWidth: (notificationObject && notificationObject.actions && notificationObject.actions.length == 0) ? 
                            (actionsFlickable.width / 2) : (contentItem.implicitWidth + leftPadding + rightPadding)

                        onClicked: {
                            if (notificationObject && notificationObject.id) {
                                Notifications.discardNotification(notificationObject.id);
                            }
                        }

                        contentItem: MaterialSymbol {
                            iconSize: Appearance.font.pixelSize.large
                            horizontalAlignment: Text.AlignHCenter
                            color: (notificationObject && notificationObject.urgency == NotificationUrgency.Critical) ? 
                                Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
                            text: "close"
                        }
                    }
                }
            }
        }
    }
}
