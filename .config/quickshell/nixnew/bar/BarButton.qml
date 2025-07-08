import QtQuick
import QtQuick.Effects

FullwidthMouseArea {
	id: root
	property bool showPressed: mouseArea.pressed;
	property real baseMargin: 0;
	property bool directScale: false;

	readonly property Item contentItem: mContentItem;
	default property alias contentItemData: mContentItem.data;

	property real targetBrightness: root.showPressed ? -25 : root.mouseArea.containsMouse && root.enabled ? 75 : 0
	Behavior on targetBrightness { SmoothedAnimation { velocity: 600 } }

	property real targetMargins: root.showPressed ? 3 : 0;
	Behavior on targetMargins { SmoothedAnimation { velocity: 25 } }

	hoverEnabled: true

	Item {
		id: mContentItem
		anchors.fill: parent;

		anchors.margins: root.baseMargin + (root.directScale ? 0 : root.targetMargins);
		scale: root.directScale ? (width - root.targetMargins * 2) / width : 1.0;

		opacity: root.enabled ? 1.0 : 0.5;
		Behavior on opacity { SmoothedAnimation { velocity: 5 } }

		layer.enabled: root.targetBrightness != 0
		layer.effect: MultiEffect { brightness: root.targetBrightness / 1000 }
	}
}
