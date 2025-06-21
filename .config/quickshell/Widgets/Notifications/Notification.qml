// System notification manager
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "root:/Data" as Data

Item {
    id: root
    required property var shell
    required property var notificationServer

    // Queue and display configuration
    property var notificationQueue: []
    property var activeTimers: ({})
    property int lastNotificationTime: 0
    property int maxWidth: 400
    property int maxNotifications: 5
    property int notificationSpacing: 0
    property int baseNotificationHeight: 62

    // Dynamic height calculation
    property int calculatedHeight: {
        let total = 0;
        let count = Math.min(notificationQueue.length, maxNotifications);
        for (let i = 0; i < count; i++) {
            total += calculateIndividualHeight(notificationQueue[i]);
            if (i < count - 1) total += notificationSpacing;
        }
        return Math.max(total + 20, 0);
    }

    // Calculate height based on content (summary, body, actions)
    function calculateIndividualHeight(notification) {
        let h = 52;
        h += 18;
        if (notification?.summary?.trim()) h += 20;
        if (notification?.body?.trim()) {
            let body = notification.body.trim();
            let lines = Math.max((body.match(/\n/g) || []).length + 1, Math.ceil(body.length / 60));
            h += Math.min(lines * 18, 80);
        }
        if (notification?.actions?.length > 0) h += 35;
        return h;
    }

    // Auto-dismiss timer component
    Component {
        id: expiryTimerComponent
        Timer {
            property var targetNotification
            interval: Data.Settings.displayTime
            running: true
            onTriggered: {
                if (targetNotification?.tracked)
                    dismissNotification(targetNotification)
                destroy()
            }
        }
    }

    // Handle incoming notifications
    Connections {
        target: notificationServer

        function onNotification(notification) {
            if (!notification) return

            notification.tracked = true
            notification.arrivalTime = Date.now()
            lastNotificationTime = notification.arrivalTime

            // Add to front of queue
            notificationQueue.unshift(notification)
            notificationQueueChanged()

            // Create auto-dismiss timer
            let timer = expiryTimerComponent.createObject(root, {
                "targetNotification": notification
            });
            if (timer && notification.id)
                activeTimers[notification.id] = timer;

            // Handle manual dismissal
            if (notification.closed) {
                notification.closed.connect(function(reason) {
                    removeFromQueue(notification.id)
                })
            }
        }
    }

    function removeFromQueue(notificationId) {
        if (activeTimers[notificationId]) {
            activeTimers[notificationId].destroy();
            delete activeTimers[notificationId];
        }

        for (let i = 0; i < notificationQueue.length; i++) {
            if (notificationQueue[i]?.id === notificationId) {
                notificationQueue.splice(i, 1)
                notificationQueueChanged()
                break
            }
        }
    }

    function dismissNotification(notification) {
        if (!notification) return

        if (notification.id && activeTimers[notification.id]) {
            activeTimers[notification.id].destroy()
            delete activeTimers[notification.id]
        }

        removeFromQueue(notification.id)

        try {
            if (typeof notification.dismiss === 'function') notification.dismiss()
            else if (typeof notification.expire === 'function') notification.expire()
        } catch (e) {}
    }

    Component.onDestruction: {
        for (let id in activeTimers) {
            activeTimers[id]?.destroy()
        }
        activeTimers = {}
    }

    // Scrollable notification display
    ScrollView {
        id: notificationScrollView
        anchors.fill: parent
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        Column {
            id: notificationColumn
            width: maxWidth
            spacing: notificationSpacing
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.rightMargin: -12
            Behavior on y { PropertyAnimation { duration: 200; easing.type: Easing.OutQuart } }

            Repeater {
                model: notificationQueue.length > 0 ? Math.min(notificationQueue.length, maxNotifications) : 0

                delegate: Rectangle {
                    id: notificationContainer
                    property var notification: index < notificationQueue.length ? notificationQueue[index] : null
                    property bool isNewest: notification?.arrivalTime === lastNotificationTime
                    property bool isLastVisible: index === Math.min(notificationQueue.length, maxNotifications) - 1
                    visible: notification !== null

                    width: maxWidth
                    height: notification ? calculateIndividualHeight(notification) : 0
                    radius: 0
                    topLeftRadius: 0
                    topRightRadius: 0
                    bottomRightRadius: 0
                    bottomLeftRadius: isLastVisible ? 20 : 0
                    color: Data.Colors.bgColor

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: parent.border.width
                        radius: 0
                        topLeftRadius: parent.topLeftRadius - parent.border.width
                        topRightRadius: parent.topRightRadius - parent.border.width
                        bottomRightRadius: parent.bottomRightRadius - parent.border.width
                        bottomLeftRadius: parent.bottomLeftRadius - parent.border.width
                        color: Data.Colors.bgColor
                    }

                    // Initial state
                    opacity: isNewest ? 0 : 1
                    scale: isNewest ? 0.95 : 1

                    Component.onCompleted: {
                        if (isNewest) slideInAnimation.start()
                    }

                    // Slide-in animation
                    ParallelAnimation {
                        id: slideInAnimation
                        NumberAnimation { target: notificationContainer; property: "opacity"; from: 0; to: 0.92; duration: 300; easing.type: Easing.OutCubic }
                        NumberAnimation { target: notificationContainer; property: "scale"; from: 0.95; to: 1; duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
                    }

                    // Click to dismiss and hover effects
                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: { if (notification) dismissNotification(notification) }
                        z: -1
                        onEntered: hoverAnimation.start()
                        onExited: unhoverAnimation.start()
                    }

                    NumberAnimation { id: hoverAnimation; target: notificationContainer; property: "scale"; to: 1.02; duration: 150; easing.type: Easing.OutCubic }
                    NumberAnimation { id: unhoverAnimation; target: notificationContainer; property: "scale"; to: 1.0; duration: 150; easing.type: Easing.OutCubic }

                    // Notification content layout
                    Item {
                        id: contentArea
                        anchors.fill: parent
                        anchors.margins: 12
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        clip: true

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 6

                            // Header
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                // App icon
                                Rectangle {
                                    width: 28; height: 28; radius: 14
                                    color: Qt.rgba(255, 255, 255, 0.05)
                                    border.width: 1; border.color: Data.Colors.accentColor
                                    Layout.alignment: Qt.AlignTop; Layout.topMargin: 6

                                    Image {
                                        id: appImage
                                        source: notification ? (notification.image || notification.appIcon || "") : ""
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        fillMode: Image.PreserveAspectFit
                                        visible: source.toString() !== ""
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: notification?.appName?.charAt(0).toUpperCase() || "!"
                                        color: Data.Colors.accentColor
                                        font.pixelSize: 12
                                        font.bold: true
                                        visible: !appImage.visible
                                    }
                                }

                                // App name, summary, and controls
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            text: notification?.appName || "Notification"
                                            color: Data.Colors.accentColor
                                            font.bold: true
                                            font.pixelSize: 13
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: Qt.formatDateTime(new Date(), "hh:mm")
                                            color: Qt.lighter(Data.Colors.fgColor, 1.6)
                                            font.pixelSize: 10
                                            opacity: 0.8
                                        }

                                        Button {
                                            width: 18; height: 18; flat: true
                                            onClicked: { if (notification) dismissNotification(notification) }
                                            background: Rectangle {
                                                radius: 9
                                                color: parent.pressed ? Qt.rgba(255, 255, 255, 0.15) :
                                                       parent.hovered ? Qt.rgba(255, 255, 255, 0.1) : 
                                                       Qt.rgba(255, 255, 255, 0.05)
                                                border.width: 1
                                                border.color: Qt.rgba(255, 255, 255, 0.08)
                                            }
                                            contentItem: Text {
                                                text: "×"
                                                color: Data.Colors.fgColor
                                                font.pixelSize: 11
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                                opacity: 0.8
                                            }
                                        }
                                    }

                                    // Notification summary
                                    Text {
                                        text: notification?.summary || ""
                                        color: Data.Colors.fgColor
                                        font.bold: true
                                        font.pixelSize: 12
                                        wrapMode: Text.Wrap
                                        Layout.fillWidth: true
                                        visible: text.trim() !== ""
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            // Notification body text
                            Text {
                                text: notification?.body || ""
                                color: Qt.lighter(Data.Colors.fgColor, 1.2)
                                font.pixelSize: 14
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                                maximumLineCount: 4
                                elide: Text.ElideRight
                                visible: text.trim() !== ""
                                lineHeight: 1.2
                                Layout.preferredHeight: visible ? implicitHeight : 0
                            }
                        }
                    }
                }
            }
        }
    }
}
