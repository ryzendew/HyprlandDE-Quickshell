import QtQuick
import QtQuick.Shapes
import "../.."

Rectangle {
	property var checkState: Qt.Unchecked;
	implicitHeight: 18
	implicitWidth: 18
	radius: 3
	color: ShellGlobals.colors.widget

	Shape {
		visible: checkState == Qt.Checked
		anchors.fill: parent
		layer.enabled: true
		layer.samples: 10

		ShapePath {
			strokeWidth: 2
			capStyle: ShapePath.RoundCap
			joinStyle: ShapePath.RoundJoin
			fillColor: "transparent"

			startX: start.x
			startY: start.y

			PathLine {
				id: start
				x: width * 0.8
				y: height * 0.2
			}

			PathLine {
				x: width * 0.35
				y: height * 0.8
			}

			PathLine {
				x: width * 0.2
				y: height * 0.6
			}
		}
	}
}
