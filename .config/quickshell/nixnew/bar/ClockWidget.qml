import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import ".."

BarWidgetInner {
	id: root
	required property var bar;

	implicitHeight: layout.implicitHeight

	SystemClock {
		id: clock
		precision: tooltip.visible ? SystemClock.Seconds : SystemClock.Minutes;
	}

	BarButton {
		id: button
		anchors.fill: parent
		fillWindowWidth: true
		acceptedButtons: Qt.NoButton

   	ColumnLayout {
   		id: layout
   		spacing: 0

   		anchors {
   			right: parent.right
   			left: parent.left
   		}

   		Text {
   			Layout.alignment: Qt.AlignHCenter
   			text: Qt.formatDateTime(clock.date, "hh\nmm")
   			font.pointSize: 18
   			color: "white"
   		}
   	}
	}

	property TooltipItem tooltip: TooltipItem {
		id: tooltip
		tooltip: bar.tooltip
		owner: root
		show: button.containsMouse

		Loader {
			active: tooltip.visible
			sourceComponent: Label {
				text: Qt.formatDateTime(clock.date, "hh:mm:ss\ndddd, MMMM d, yyyy");
			}
		}
	}
}
