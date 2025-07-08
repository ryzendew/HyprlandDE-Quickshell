import QtQuick
import "../.."

Rectangle {
	property var checkState: Qt.Unchecked;
	implicitHeight: 18
	implicitWidth: 18
	radius: width / 2
	color: ShellGlobals.colors.widget

	Rectangle {
		x: parent.width * 0.25
		y: parent.height * 0.25
		visible: checkState == Qt.Checked
		width: parent.width * 0.5
		height: width
		radius: width / 2
	}
}
