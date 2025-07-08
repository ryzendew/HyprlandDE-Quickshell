import QtQuick
import QtQuick.Templates as T

T.Slider {
	id: control

  implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
    implicitHandleWidth + leftPadding + rightPadding)
  implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
    implicitHandleHeight + topPadding + bottomPadding)

	property color barColor: "#80ceffff"
	property color grooveColor: "#30ceffff"

	background: Rectangle {
		x: control.leftPadding
		y: control.topPadding + control.availableHeight / 2 - height / 2
		implicitWidth: 200
		implicitHeight: 7
		width: control.availableWidth
		height: implicitHeight

		radius: 5
		color: control.grooveColor
		border.width: 0

		Rectangle {
			anchors {
				top: parent.top
				bottom: parent.bottom
			}

			width: control.handle.x + (control.handle.width / 2) - parent.x
			radius: parent.radius
			color: control.barColor
		}
	}

	handle: Rectangle {
		x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
		y: control.topPadding + control.availableHeight / 2 - height / 2
		implicitWidth: 16
		implicitHeight: 16
		radius: 8
	}
}
