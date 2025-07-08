pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
	id: root

	property list<TrackedNotification> notifications;
	property Component notifComponent: DaemonNotification {}

	property bool showTrayNotifs: false;
	property bool dnd: false;
	property bool hasNotifs: root.notifications.length != 0
	property var lastHoveredNotif;

	property var overlay;

	signal notif(notif: TrackedNotification);
	signal showAll(notifications: list<TrackedNotification>);
	signal dismissAll(notifications: list<TrackedNotification>);
	signal discardAll(notifications: list<TrackedNotification>);

	NotificationServer {
		imageSupported: true
		actionsSupported: true
		actionIconsSupported: true

		onNotification: notification => {
			notification.tracked = true;

			const notif = root.notifComponent.createObject(null, { notif: notification });
			root.notifications = [...root.notifications, notif];

			root.notif(notif);
		}
	}

	Instantiator {
		model: root.notifications

		Connections {
			required property TrackedNotification modelData;
			target: modelData;

			function onDiscarded() {
				root.notifications = root.notifications.filter(n => n != target);
				modelData.untrack();
			}

			function onDiscard() {
				if (!modelData.visualizer) modelData.discarded();
			}
		}
	}

	onShowTrayNotifsChanged: {
		if (showTrayNotifs) {
			for (const notif of root.notifications) {
				notif.inTray = true;
			}

			root.showAll(root.notifications);
		} else {
			root.dismissAll(root.notifications);
		}
	}

	function sendDiscardAll() {
		root.discardAll(root.notifications);
	}
}
