pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

TrackedNotification {
	id: root
	required property Notification notif;

	renderComponent: StandardNotificationRenderer {
		notif: root.notif
		backer: root
	}

	function handleDiscard() {
		if (!lock.retained) notif.dismiss();
		root.discarded();
	}

	function handleDismiss() {
		//handleDiscard();
	}

	RetainableLock {
		id: lock
		object: root.notif
		locked: true
		onRetainedChanged: {
			if (retained) root.discard();
		}
	}

	expireTimeout: notif.expireTimeout
}
