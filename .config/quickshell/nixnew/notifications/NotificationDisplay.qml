import QtQuick
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import "../components"
import "../shaders" as Shaders

Item {
	id: root
	property list<Item> notifications: [];
	property list<Item> heightStack: [];

	property alias stack: stack;
	property alias topNotification: stack.topNotification;

	function addNotificationInert(notification: TrackedNotification): Item {
		const harness = stack._harnessComponent.createObject(stack, {
			backer: notification,
			view: root,
		});

		harness.contentItem = notification.renderComponent.createObject(harness);

		notifications = [...notifications, harness];
		heightStack = [harness, ...heightStack];

		return harness;
	}

	function addNotification(notification: TrackedNotification) {
		const harness = root.addNotificationInert(notification);
		harness.playEntry(0);
	}

	function dismissAll() {
		let delay = 0;

		for (const notification of root.notifications) {
			if (!notification.canDismiss) continue;
			notification.playDismiss(delay);
			notification.dismissed();
			delay += 0.025;
		}
	}

	function discardAll() {
		let delay = 0;

		for (const notification of root.notifications) {
			if (!notification.canDismiss) continue;
			notification.playDismiss(delay);
			notification.discarded();
			delay += 0.025;
		}
	}

	function addSet(notifications: list<TrackedNotification>) {
		let delay = 0;

		for (const notification of notifications) {
			if (notification.visualizer) {
				notification.visualizer.playReturn(delay);
			} else {
				const harness = root.addNotificationInert(notification);
				harness.playEntry(delay);
			}

			delay += 0.025;
		}
	}

	Item {
		anchors.fill: parent

		layer.enabled: stack.topNotification != null
		layer.effect: Shaders.MaskedOverlay {
			overlayItem: stack.topNotification?.displayContainer ?? null
			overlayPos: Qt.point(stack.x + stack.topNotification.x + overlayItem.x, stack.y + stack.topNotification.y + overlayItem.y)
		}

		ZHVStack {
			id: stack

			property Item topNotification: {
				if (root.heightStack.length < 2) return null;
				const top = root.heightStack[0] ?? null;
				return top && top.canOverlap ? top : null;
			};

			property Component _harnessComponent: FlickableNotification {
				id: notification
				required property TrackedNotification backer;

				edgeXOffset: -stack.x

				onDismissed: backer.handleDismiss();
				onDiscarded: backer.handleDiscard();

				onLeftViewBounds: {
					root.notifications = root.notifications.filter(n => n != this);
					root.heightStack = root.heightStack.filter(n => n != this);
					this.destroy();
				}

				onStartedFlick: {
					root.heightStack = [this, ...root.heightStack.filter(n => n != this)];
				}

				Component.onCompleted: backer.visualizer = this;

				Connections {
					target: backer

					function onDismiss() {
						notification.playDismiss(0);
						notification.dismissed();
					}

					function onDiscard() {
						notification.playDismiss(0);
						notification.discarded();
					}
				}
			}
		}
	}
}
