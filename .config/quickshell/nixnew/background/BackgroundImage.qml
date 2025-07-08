import QtQuick
import Quickshell
import "../lock" as Lock

Item {
	id: root

	required property ShellScreen screen;
	property real slideAmount: 1.0 - Lock.Controller.bkgSlide
	property alias asynchronous: image.asynchronous;

	readonly property real remainingSize: image.sourceSize.height - root.height

	Image {
		id: image
		source: Qt.resolvedUrl((screen?.name == "DP-1" ?? false) ? "5120x1728.png" : "1920x1296.png")
		y: -(root.slideAmount * root.remainingSize)
	}
}
