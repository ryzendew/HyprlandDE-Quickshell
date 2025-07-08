import Quickshell
import QtQuick

QtObject {
	id: root
	required property Item item;
	property Animation activeAnimation: null;
	signal animationCompleted(self: SlideViewItem);

	property Connections __animConnection: Connections {
		target: activeAnimation

		function onStopped() {
			root.activeAnimation.destroy();
			root.animationCompleted(root);
		}
	}

	function createAnimation(component: Component) {
		this.stopIfRunning();
		this.activeAnimation = component.createObject(this, { target: this.item });
		this.activeAnimation.running = true;
	}

	function stopIfRunning() {
		if (this.activeAnimation) {
			this.activeAnimation.stop();
			this.activeAnimation = null;
		}
	}

	function finishIfRunning() {
		if (this.activeAnimation) {
			// animator types dont handle complete correctly.
			this.activeAnimation.complete();
			this.activeAnimation.stop();
			this.item.x = 0;
			this.item.y = 0;
			this.activeAnimation = null;
		}
	}

	function destroyAll() {
		this.item.destroy();
		this.destroy();
	}
}
