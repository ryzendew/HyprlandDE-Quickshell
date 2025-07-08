import QtQuick
import QtQuick.Shapes

Item {
	id: root
	property real from: 0.0
	property real to: 1.5
	property real warning: 1.0
	property real value: 0.0

	implicitWidth: groove.implicitWidth
	implicitHeight: 20

	property real __valueOffset: ((value - from) / (to - from)) * groove.width
	property real __wheelValue: -1

	MouseArea {
		id: mouseArea
		anchors.fill: parent

		Rectangle {
			id: grooveWarning

			anchors {
				left: groove.left
				leftMargin: ((warning - from) / (to - from)) * groove.width
				right: groove.right
				top: groove.top
				bottom: groove.bottom
			}

			color: "#60ffa800"
			topRightRadius: 5
			bottomRightRadius: 5
		}

		Rectangle {
			anchors {
				top: groove.bottom
				horizontalCenter: grooveWarning.left
			}

			color: "#60eeffff"
			width: 1
			height: groove.height
		}

		Rectangle {
			id: grooveFill

			anchors {
				left: groove.left
				top: groove.top
				bottom: groove.bottom
			}

			radius: 5
			color: "#80ceffff"
			width: __valueOffset
		}

		Rectangle {
			id: groove

			anchors {
				left: parent.left
				right: parent.right
				verticalCenter: parent.verticalCenter
			}

			implicitHeight: 7
			color: "transparent"
			border.color: "#20050505"
			border.width: 1
			radius: 5
		}

		Rectangle {
			id: handle
			anchors.verticalCenter: groove.verticalCenter
			height: 15
			width: height
			radius: height * 0.5
			x: __valueOffset - width * 0.5
		}

		onWheel: event => {
			event.accepted = true;
			__wheelValue = value + (event.angleDelta.y / 120) * 0.05
			__wheelValue = -1
		}
	}

	Binding {
		when: mouseArea.pressed
		target: root
		property: "value"
		value: (mouseArea.mouseX / width) * (to - from) + from
		restoreMode: Binding.RestoreBinding
	}

	Binding {
		when: __wheelValue != -1
		target: root
		property: "value"
		value: __wheelValue
		restoreMode: Binding.RestoreBinding
	}
}
