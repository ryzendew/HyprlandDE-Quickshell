import QtQuick

Item {
	id: root

	property real from: 0.0
	property real to: 1.0
	property real value: 0.0

	implicitHeight: 7
	implicitWidth: 200

	Rectangle {
		id: grooveFill

		anchors {
			left: groove.left
			top: groove.top
			bottom: groove.bottom
		}

		radius: 5
		color: "#80ceffff"
		width: root.width * ((root.value - root.from) / (root.to - root.from))
	}

	Rectangle {
		id: groove

		anchors {
			left: parent.left
			right: parent.right
			verticalCenter: parent.verticalCenter
		}

		height: 7
		color: "transparent"
		border.color: "#20eeffff"
		border.width: 1
		radius: 5
	}
}
