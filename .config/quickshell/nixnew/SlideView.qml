import QtQuick

// kind of like a lighter StackView which handles replacement better.
Item {
	id: root

	property Component enterTransition: XAnimator {
		from: root.width
		duration: 3000
	}

	property Component exitTransition: XAnimator {
		to: target.x - target.width
		duration: 3000
	}

	property bool animate: this.visible;

	onAnimateChanged: {
		if (!this.animate) this.finishAnimations();
	}

	property Component itemComponent: SlideViewItem {}
	property SlideViewItem activeItem: null;
	property Item pendingItem: null;
	property bool pendingNoAnim: false;
	property list<SlideViewItem> removingItems;

	readonly property bool animating: activeItem?.activeAnimation != null

	function replace(component: Component, defaults: var, noanim: bool) {
		this.pendingNoAnim = noanim;

		if (component) {
			const props = defaults ?? {};
			props.parent = null;
			props.width = Qt.binding(() => this.width);
			props.height = Qt.binding(() => this.height);

			const item = component.createObject(this, props);
			if (pendingItem) pendingItem.destroy();
			pendingItem = item;
			const ready = item?.svReady ?? true;
			if (ready) finishPending();
		} else {
			finishPending(); // remove
		}
	}

	Connections {
		target: pendingItem

		function onSvReadyChanged() {
			if (pendingItem.svReady) {
				root.finishPending();
			}
		}
	}

	function finishPending() {
		const noanim = this.pendingNoAnim || !this.animate;
		if (this.activeItem) {
			if (noanim) {
				this.activeItem.destroyAll();
				this.activeItem = null;
			} else {
				removingItems.push(this.activeItem);
				this.activeItem.animationCompleted.connect(item => root.removeItem(item));
				this.activeItem.stopIfRunning();
				this.activeItem.createAnimation(exitTransition);
				this.activeItem = null;
			}
		}

		if (!this.animate) finishAnimations();

		if (this.pendingItem) {
			pendingItem.parent = this;
			this.activeItem = itemComponent.createObject(this, { item: this.pendingItem });
			this.pendingItem = null;
			if (!noanim) {
				this.activeItem.createAnimation(enterTransition);
			}
		}
	}

	function removeItem(item: SlideViewItem) {
		item.destroyAll();

		for (const i = 0; i !== this.removingItems.length; i++) {
			if (this.removingItems[i] === item) {
				removingItems.splice(i, 1);
				break;
			}
		}
	}

	function finishAnimations() {
		this.removingItems.forEach(item => item.destroyAll())
		this.removingItems = [];

		if (this.activeItem) {
			this.activeItem.finishIfRunning();
		}
	}

	Component.onDestruction: {
		this.removingItems.forEach(item => item.destroyAll());
		this.activeItem?.destroyAll();
		this.pendingItem?.destroy();
	}
}
