import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

Item {
    id: root
    property list<NotificationWidget> notificationWidgetList: []

    // Signal handlers to add/remove notifications
    Connections {
        target: Notifications
        function onInitDone() {
            console.log("[NotificationList] onInitDone called, notifications count:", Notifications.list.length)
            // Filter out any null notifications before processing
            const validNotifications = Notifications.list.filter(notification => notification != null);
            console.log("[NotificationList] Valid notifications count:", validNotifications.length)
            validNotifications.slice().reverse().forEach((notification) => {
                if (!notification) return; // Skip null notifications
                console.log("[NotificationList] Creating widget for notification:", notification.summary)
                try {
                    const notif = notificationComponent.createObject(columnLayout, { notificationObject: notification });
                    if (notif) {
                        notificationWidgetList.push(notif)
                        console.log("[NotificationList] Successfully created widget, total widgets:", notificationWidgetList.length)
                    } else {
                        console.error("[NotificationList] Failed to create notification widget - createObject returned null")
                    }
                } catch (error) {
                    console.error("[NotificationList] Error creating notification widget:", error)
                }
            })
        }

        function onNotify(notification) {
            if (!notification) return; // Skip null notifications
            console.log("[NotificationList] onNotify called for:", notification.summary)
            try {
                const notif = notificationComponent.createObject(columnLayout, { notificationObject: notification });
                if (notif) {
                    notificationWidgetList.unshift(notif)
                    console.log("[NotificationList] Successfully created widget for new notification, total widgets:", notificationWidgetList.length)
                } else {
                    console.error("[NotificationList] Failed to create notification widget for new notification - createObject returned null")
                }
            } catch (error) {
                console.error("[NotificationList] Error creating notification widget for new notification:", error)
            }

            // Remove stuff from the column, add back
            for (let i = 0; i < notificationWidgetList.length; i++) {
                if (notificationWidgetList[i].parent === columnLayout) {
                    notificationWidgetList[i].parent = null;
                }
            }

            // Add notification widgets to the column
            for (let i = 0; i < notificationWidgetList.length; i++) {
                if (notificationWidgetList[i].parent === null) {
                    notificationWidgetList[i].parent = columnLayout;
                }
            }
        }

        function onDiscard(id) {
            console.log("[NotificationList] onDiscard called for ID:", id)
            for (let i = notificationWidgetList.length - 1; i >= 0; i--) {
                const widget = notificationWidgetList[i];
                if (widget && widget.notificationObject && widget.notificationObject.id === id) {
                    widget.destroyWithAnimation();
                    notificationWidgetList.splice(i, 1);
                    console.log("[NotificationList] Discarded notification, remaining widgets:", notificationWidgetList.length)
                    break;
                }
            }
        }

        function onDiscardAll() {
            console.log("[NotificationList] onDiscardAll called")
            for (let i = notificationWidgetList.length - 1; i >= 0; i--) {
                const widget = notificationWidgetList[i];
                if (widget) {
                    widget.destroyWithAnimation();
                }
            }
            notificationWidgetList = [];
            console.log("[NotificationList] All notifications discarded")
        }

        function onTimeout(id) {
            console.log("[NotificationList] onTimeout called for ID:", id)
            for (let i = notificationWidgetList.length - 1; i >= 0; i--) {
                const widget = notificationWidgetList[i];
                if (widget && widget.notificationObject && widget.notificationObject.id === id) {
                    widget.destroyWithAnimation();
                    notificationWidgetList.splice(i, 1);
                    console.log("[NotificationList] Timed out notification, remaining widgets:", notificationWidgetList.length)
                    break;
                }
            }
        }
    }

    Component {
        id: notificationComponent
        NotificationWidget {}
    }

    Component.onCompleted: {
        console.log("[NotificationList] Component completed, notificationComponent valid:", notificationComponent ? "yes" : "no")
    }

    Flickable { // Scrollable window
        id: flickable
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: statusRow.top
        contentHeight: columnLayout.height

        clip: true
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: flickable.width
                height: flickable.height
                radius: Appearance.rounding.normal
            }
        }

        ColumnLayout { // Scrollable window content
            id: columnLayout
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0 // The widgets themselves have margins for spacing

            // Notifications are added by the above signal handlers
        }
    }

    // Placeholder when list is empty
    Item {
        anchors.fill: flickable

        visible: opacity > 0
        opacity: (root.notificationWidgetList.length === 0) ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animation.menuDecel.duration
                easing.type: Appearance.animation.menuDecel.type
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 5

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                iconSize: 55
                color: "#FFFFFF"
                text: "notifications_active"
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.normal
                color: "#FFFFFF"
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("No notifications")
            }
        }
    }

    RowLayout {
        id: statusRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        StyledText {
            Layout.margins: 10
            Layout.bottomMargin: 5
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: `${notificationWidgetList.length} notification${notificationWidgetList.length > 1 ? "s" : ""}`

            opacity: notificationWidgetList.length > 0 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }
        }

        Item { Layout.fillWidth: true }

        NotificationStatusButton {
            Layout.alignment: Qt.AlignVCenter
            Layout.margins: 5
            Layout.topMargin: 10
            buttonIcon: "clear_all"
            buttonText: qsTr("Clear")
            onClicked: () => {
                Notifications.discardAllNotifications()
            }
        }
    }
}