pragma Singleton

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pam
import ".."
import "../background"

Singleton {
	id: root
	function init() {}

	property bool locked: false;
	property bool animState: false;
	property real lockSlide: animState ? 1.0 : 0.0
	property real bkgSlide: animState ? 1.0 : 0.0

	Behavior on lockSlide {
   	NumberAnimation {
   		duration: 500
   		easing.type: Easing.BezierSpline
   		easing.bezierCurve: [0.1, 0.75, 0.15, 1.0, 1.0, 1.0]
   	}
	}

	Behavior on bkgSlide {
		NumberAnimation {
			duration: 500
			easing.type: Easing.OutCirc
		}
	}

	onLockedChanged: {
		if (locked) {
			lockContextLoader.active = true;
			lock.locked = true;
		} else {
			lockClearTimer.start();
			workspaceUnlockAnimation();
		}
	}

	Timer {
		id: lockClearTimer
		interval: 500
		onTriggered: {
			lock.locked = false;
			lockContextLoader.active = false;
		}
	}

	property var oldWorkspaces: ({});

	function workspaceLockAnimation() {
		const focusedMonitor = Hyprland.focusedMonitor.id;

		Hyprland.monitors.values.forEach(monitor => {
			if (monitor.activeWorkspace) {
				root.oldWorkspaces[monitor.id] = monitor.activeWorkspace.id;
			}

			Hyprland.dispatch(`workspace name:lock_${monitor.name}`);
		});

		Hyprland.dispatch(`focusmonitor ${focusedMonitor}`);
	}

	function workspaceUnlockAnimation() {
		const focusedMonitor = Hyprland.focusedMonitor.id;

		Hyprland.monitors.values.forEach(monitor => {
			const workspace = root.oldWorkspaces[monitor.id];
			if (workspace) Hyprland.dispatch(`workspace ${workspace}`);
		});

		Hyprland.dispatch(`focusmonitor ${focusedMonitor}`);

		root.oldWorkspaces = ({});
	}

	IpcHandler {
		target: "lockscreen"
		function lock(): void { root.locked = true; }
	}

	LazyLoader {
		id: lockContextLoader

		SessionLockContext {
			onUnlocked: root.locked = false;
		}
	}

	WlSessionLock {
		id: lock

		onSecureChanged: {
			if (secure) {
				root.workspaceLockAnimation();
			}
		}

		WlSessionLockSurface {
			id: lockSurface
			color: "transparent"

			// Ensure nothing spawns in the workspace behind the transparent lock
			// by filling in the background after animations complete.
			Rectangle {
				anchors.fill: parent
				color: "gray"
				visible: backgroundImage.visible
			}

			BackgroundImage {
				id: backgroundImage
				anchors.fill: parent
				screen: lockSurface.screen
				visible: root.lockSlide == 1.0
				asynchronous: true
			}

			LockContent {
				id: lockContent
				state: lockContextLoader.item.state;

				visible: false
				width: lockSurface.width
				height: lockSurface.height
				y: -lockSurface.height * (1.0 - root.lockSlide)
			}

			onVisibleChanged: {
				if (visible) {
					lockContent.visible = true;
					root.animState = true;
				}
			}

			Connections {
				target: root

				function onLockedChanged() {
					if (!locked) {
						root.animState = false;
					}
				}
			}
		}
	}
}
