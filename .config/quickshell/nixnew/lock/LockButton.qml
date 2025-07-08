import QtQuick
import "root:."

Item {
	id: root
	implicitHeight: 75
	implicitWidth: showProgress * 0.1

	signal clicked();
	property string icon;
	property bool show: true;

	property int showProgress: show ? 1000 : 0
	Behavior on showProgress {
		NumberAnimation {
			duration: 100
			easing.type: Easing.OutQuad
		}
	}

	MouseArea {
		id: mouseArea
		implicitWidth: 75
		implicitHeight: 75
		hoverEnabled: true

		y: -(height + 30) * (1.0 - showProgress * 0.001)
		x: 12.5 - 50 * (1.0 - showProgress * 0.001)

		Component.onCompleted: clicked.connect(root.clicked);

		Rectangle {
			anchors.fill: parent
			radius: 5
			color: ShellGlobals.interpolateColors(hoverColorInterp * 0.001, ShellGlobals.colors.widget, ShellGlobals.colors.widgetActive);
			border.width: 1
			border.color: ShellGlobals.colors.widgetOutline

			property int hoverColorInterp: mouseArea.containsMouse || mouseArea.pressed ? 1000 : 0;
			Behavior on hoverColorInterp { SmoothedAnimation { velocity: 10000 } }

			Image {
				anchors.fill: parent
				anchors.margins: 15

				source: root.icon
				sourceSize.width: width
				sourceSize.height: height
			}
		}
	}
}
