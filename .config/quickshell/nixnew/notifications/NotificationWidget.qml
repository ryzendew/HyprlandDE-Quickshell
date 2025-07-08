import QtQuick
import QtQuick.Controls
import "../bar"

BarWidgetInner {
	id: root
	required property var bar;

	property bool controlsOpen: false;
	onControlsOpenChanged: NotificationManager.showTrayNotifs = controlsOpen;

	Connections {
		target: NotificationManager

		function onHasNotifsChanged() {
			if (!NotificationManager.hasNotifs) {
				root.controlsOpen = false;
			}
		}
	}

	implicitHeight: width

	BarButton {
		id: button
		anchors.fill: parent
		baseMargin: 8
		fillWindowWidth: true
		acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
		showPressed: root.controlsOpen || (pressedButtons & ~Qt.RightButton)

		Image {
			anchors.fill: parent

			source: NotificationManager.hasNotifs
				? "root:icons/bell-fill.svg"
				: "root:icons/bell.svg"

			fillMode: Image.PreserveAspectFit

			sourceSize.width: width
			sourceSize.height: height
		}

		onPressed: event => {
			if (event.button == Qt.RightButton && NotificationManager.hasNotifs) {
				root.controlsOpen = !root.controlsOpen;
			}
		}
	}

	property TooltipItem tooltip: TooltipItem {
		tooltip: bar.tooltip
		owner: root
		show: button.containsMouse

		Label {
			anchors.verticalCenter: parent.verticalCenter
			text: {
				const count = NotificationManager.notifications.length;
				return count == 0 ? "No notifications"
					: count == 1 ? "1 notification"
					: `${count} notifications`;
			}
		}
	}

	property TooltipItem rightclickMenu: TooltipItem {
		tooltip: bar.tooltip
		owner: root
		isMenu: true
		grabWindows: [NotificationManager.overlay]
		show: root.controlsOpen
		onClose: root.controlsOpen = false

		Item {
			implicitWidth: 440
			implicitHeight: root.implicitHeight - 10

			MouseArea {
				id: closeArea

				anchors {
					right: parent.right
					rightMargin: 5
					verticalCenter: parent.verticalCenter
				}

				implicitWidth: 30
				implicitHeight: 30

				hoverEnabled: true
				onPressed: {
					NotificationManager.sendDiscardAll()
				}

				Rectangle {
					anchors.fill: parent
					anchors.margins: 5
					radius: width * 0.5
					antialiasing: true
					color: "#60ffffff"
					opacity: closeArea.containsMouse ? 1 : 0
					Behavior on opacity { SmoothedAnimation { velocity: 8 } }
				}

				CloseButton {
					anchors.fill: parent
					ringFill: root.backer.timePercentage
				}
			}
		}
	}
}
