import QtQuick
import QtQuick.Controls
import Quickshell.Services.Pipewire

MixerEntryBase {
	id: root
	required property list<PwNode> nodeList;

	signal selected(node: PwNode);

	headerComponent: ComboBox {
		model: nodeList.map(node => root.getNodeName(node));
		currentIndex: nodeList.findIndex(node => node == root.node)
		onActivated: index => root.selected(nodeList[index])
	}
}
