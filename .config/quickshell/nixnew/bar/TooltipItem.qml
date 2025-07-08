import QtQuick
import Quickshell

Item {
	id: root
	required property var tooltip;
	required property Item owner;
	property bool isMenu: false;
	property list<QtObject> grabWindows;
	property bool hoverable: isMenu;
	property bool animateSize: true;
	property bool show: false;
	property bool preloadBackground: root.visible;

	property real targetRelativeY: owner.height / 2;
	property real hangTime: isMenu ? 0 : 200;

	signal close();

	readonly property alias contentItem: contentItem;
	default property alias data: contentItem.data;

	property Component backgroundComponent: null

	onShowChanged: {
		if (show) tooltip.setItem(this);
		else tooltip.removeItem(this);
	}

	property bool targetVisible: false
	property real targetOpacity: 0
	opacity: root.targetOpacity * (tooltip.scaleMul == 0 ? 0 : (1.0 / tooltip.scaleMul))

	Behavior on targetOpacity {
		id: opacityAnimation
		SmoothedAnimation { velocity: 5 }
	}

	function snapOpacity(opacity: real) {
		opacityAnimation.enabled = false;
		targetOpacity = opacity;
		opacityAnimation.enabled = true;
	}

	onTargetVisibleChanged: {
		if (targetVisible) {
			visible = true;
			targetOpacity = 1;
		} else {
			close()
			targetOpacity = 0;
		}
	}

	onTargetOpacityChanged: {
		if (!targetVisible && targetOpacity == 0) {
			visible = false;
			this.parent = null;
			if (tooltip) tooltip.onHidden(this);
		}
	}

	anchors.fill: parent
	visible: false
	//clip: true
	implicitHeight: contentItem.implicitHeight + contentItem.anchors.leftMargin + contentItem.anchors.rightMargin
	implicitWidth: contentItem.implicitWidth + contentItem.anchors.leftMargin + contentItem.anchors.rightMargin

	readonly property Item item: contentItem;

	Loader {
		anchors.fill: parent
		active: root.backgroundComponent && (root.visible || root.preloadBackground)
		asynchronous: !root.visible && root.preloadBackground
		sourceComponent: backgroundComponent
	}

	Item {
		id: contentItem
		anchors.fill: parent
		anchors.margins: 5

		implicitHeight: children[0].implicitHeight
		implicitWidth: children[0].implicitWidth
	}
}
