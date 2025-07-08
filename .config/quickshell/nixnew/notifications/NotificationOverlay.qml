import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
	WlrLayershell.namespace: "shell:notifications"
	exclusionMode: ExclusionMode.Ignore
	color: "transparent"
	//color: "#30606000"

	anchors {
		left: true
		top: true
		bottom: true
		right: true
	}

	property Component notifComponent: DaemonNotification {}

	NotificationDisplay {
		id: display

		anchors.fill: parent

		stack.y: 5 + 55//(NotificationManager.showTrayNotifs ? 55 : 0)
		stack.x: 72
	}

	visible: display.stack.children.length != 0

	mask: Region { item: display.stack }
	HyprlandWindow.visibleMask: Region {
		regions: display.stack.children.map(child => child.mask)
	}

	Component.onCompleted: {
		NotificationManager.overlay = this;
		NotificationManager.notif.connect(display.addNotification);
		NotificationManager.showAll.connect(display.addSet);
		NotificationManager.dismissAll.connect(display.dismissAll);
		NotificationManager.discardAll.connect(display.discardAll);
	}
}
