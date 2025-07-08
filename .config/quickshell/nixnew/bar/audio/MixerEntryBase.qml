import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import ".."

RowLayout {
	id: root

	required property PwNode node;
	required property string image;
	required property Item headerComponent;

	property int state: PwLinkState.Unlinked;

	function getNodeName(node: PwNode): string {
		const name = node.properties["application.name"] ?? (node.description == "" ? node.name : node.description);
		const mediaName = node.properties["media.name"];

		return mediaName != undefined ? `${name} - ${mediaName}` : name + node.id;
	}

	PwObjectTracker { objects: [ node ] }

	ClickableIcon {
		image: root.image
		asynchronous: true
		implicitHeight: 40
		implicitWidth: height
	}

	ColumnLayout {
		Item {
			id: container

			Layout.fillWidth: true
			implicitWidth: headerComponent.implicitWidth
			implicitHeight: headerComponent.implicitHeight

			children: [ headerComponent ]
			Binding { root.headerComponent.anchors.fill: container }
		}

		VolumeSlider {
			Layout.fillWidth: true

			value: node.audio.volume
			onValueChanged: node.audio.volume = value
		}
	}
}
