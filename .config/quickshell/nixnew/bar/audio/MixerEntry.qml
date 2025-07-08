import QtQuick

MixerEntryBase {
	id: root

	headerComponent: Text {
		color: "white"
		elide: Text.ElideRight
		text: root.getNodeName(root.node)
	}
}
