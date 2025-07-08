import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import ".."
import "../.."

ColumnLayout {
	id: root

	required property PwNode trackedNode;
	required property string nodeImage;
	required property list<PwNode> nodeList;

	signal selected(node: PwNode);

	PwNodeLinkTracker {
		id: linkTracker
		node: trackedNode
	}

	PwObjectTracker { objects: [ trackedNode, ...linkTracker.linkGroups ] }

	MixerEntry/*WithSelect*/ {
		id: nodeEntry
		node: trackedNode
		//nodeList: root.nodeList
		image: nodeImage

		Component.onCompleted: this.selected.connect(root.selected);
	}

	Rectangle {
		Layout.fillWidth: true
		implicitHeight: 1
		visible: linkTracker.linkGroups.length > 0

		color: ShellGlobals.colors.separator
	}

	Repeater {
		model: linkTracker.linkGroups

		MixerEntry {
			required property PwLinkGroup modelData;
			node: trackedNode.isSink ? modelData.source : modelData.target;
			state: modelData.state;

			image: {
				let icon = "";
				let props = node.properties;
				if (props["application.icon-name"] != undefined) {
					icon = props["application.icon-name"];
				} else if (props["application.process.binary"] != undefined) {
					icon = props["application.process.binary"];
				}

				// special cases :(
				if (icon == "firefox") icon = "firefox-devedition";

				return Quickshell.iconPath(icon)
			}
		}
	}
}
