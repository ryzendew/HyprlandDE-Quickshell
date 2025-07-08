import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../components"

ShellRoot {
	Component {
		id: demoNotif

		FlickableNotification {
			contentItem: Rectangle {
				color: "white"
				border.color: "blue"
				border.width: 2
				radius: 10
				width: 400
				height: 150
			}

			onLeftViewBounds: this.destroy()
		}
	}

	property Component testComponent: TrackedNotification {
		id: notification

		renderComponent: Rectangle {
			color: "white"
			border.color: "blue"
			border.width: 2
			radius: 10
			width: 400
			height: 150

			ColumnLayout {
				Button {
					text: "dismiss"
					onClicked: notification.dismiss();
				}

				Button {
					text: "discard"
					onClicked: notification.discard();
				}
			}
		}

		function handleDismiss() {
			console.log(`dismiss (sub)`)
		}

		function handleDiscard() {
			console.log(`discard (sub)`)
		}

		Component.onDestruction: console.log(`destroy (sub)`)
	};

	property Component realComponent: DaemonNotification {
		id: dn
	}

	Daemon {
		onNotification: notification => {
			notification.tracked = true;

			const o = realComponent.createObject(null, { notif: notification });
			display.addNotification(o);
		}
	}

	FloatingWindow {
		color: "transparent"

		ColumnLayout {
			x: 5

			Button {
				visible: false
				text: "add notif"

				onClicked: {
					//const notif = demoNotif.createObject(stack);
					//stack.children = [...stack.children, notif];
					const notif = testComponent.createObject(null);
					display.addNotification(notif);
				}
			}

			//ZHVStack { id: stack }
			NotificationDisplay { id: display }
		}
	}
}
