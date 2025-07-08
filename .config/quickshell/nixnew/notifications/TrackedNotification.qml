import QtQuick
import Quickshell

Scope {
	id: root

	required property Component renderComponent;

	property bool inTray: false;
	property bool destroyOnInvisible: false;
	property int visualizerCount: 0;
	property FlickableNotification visualizer;

	signal dismiss();
	signal discard();
	signal discarded();

	function handleDismiss() {}
	function handleDiscard() {}

	onVisualizerChanged: {
		if (!visualizer) {
			expireAnim.stop();
			timePercentage = 1;
		}

		if (!visualizer && destroyOnInvisible) this.destroy();
	}

	function untrack() {
		destroyOnInvisible = true;
		if (!visualizer) this.destroy();
	}

	property int expireTimeout: -1
	property real timePercentage: 1
	property int pauseCounter: 0
	readonly property bool shouldPause: root.pauseCounter != 0 || (NotificationManager.lastHoveredNotif?.pauseCounter ?? 0) != 0

	onPauseCounterChanged: {
		if (pauseCounter > 0) {
			NotificationManager.lastHoveredNotif = this;
		}
	}

	NumberAnimation on timePercentage {
		id: expireAnim
		running: expireTimeout != 0
		paused: running && root.shouldPause && to == 0
		duration: expireTimeout == -1 ? 10000 : expireTimeout
		to: 0
		onFinished: {
			if (!inTray) root.dismiss();
		}
	}

	onInTrayChanged: {
		if (inTray) {
			expireAnim.stop();
			expireAnim.duration = 300 * (1 - timePercentage);
			expireAnim.to = 1;
			expireAnim.start();
		}
	}
}
