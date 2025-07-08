import QtQuick

Item {
	id: root
	onChildrenChanged: recalc();

	Instantiator {
		model: root.children

		Connections {
			required property Item modelData;
			target: modelData;

			function onImplicitHeightChanged() {
				root.recalc();
			}

			function onImplicitWidthChanged() {
				root.recalc();
			}
		}
	}

	function recalc() {
		let y = 0
		let w = 0
		for (const child of this.children) {
			child.y = y;
			y += child.implicitHeight
			if (child.implicitWidth > w) w = child.implicitWidth;
		}

		this.implicitHeight = y;
		this.implicitWidth = w;
	}
}
