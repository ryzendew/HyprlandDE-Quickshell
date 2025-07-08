// very bad code DO NOT COPY
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".."

Scope {
	id: root
	property bool shooting: false;
	property bool shootingComplete: false;
	property bool visible: false;
	readonly property string path: `${ShellGlobals.rtpath}/screenshot.png`;

	onShootingChanged: {
		if (shooting) {
			grimProc.running = true
		} else {
			visible = false
			shootingComplete = false
			cleanupProc.running = true
		}
	}

	Process {
		id: grimProc
		command: ["grim", "-l", "0", root.path]
		onExited: code => {
			if (code == 0) {
				root.visible = true
			} else {
				console.log("screenshot failed")
				cleanupProc.running = true
			}
		}
	}

	Process {
		id: magickProc
		command: [
			"magick",
			root.path,
			"-crop", `${selection.w}x${selection.h}+${selection.x}+${selection.y}`,
			"-quality", "70",
			"-page", "0x0+0+0", // removes page size and shot position
			root.path,
		]

		onExited: wlCopy.running = true;
	}

	Process {
		id: wlCopy
		command: ["sh", "-c", `wl-copy < '${root.path}'`]

		onExited: root.shootingComplete = true;
	}

	Process {
		id: cleanupProc
		command: ["rm", root.path]
	}

	QtObject {
		id: selection
		property real x1;
		property real y1;
		property real x2;
		property real y2;

		readonly property real x: Math.min(x1, x2)
		readonly property real y: Math.min(y1, y2)
		readonly property real w: Math.max(x1, x2) - x
		readonly property real h: Math.max(y1, y2) - y
	}

	LazyLoader {
		loading: root.shooting
		active: root.visible

		Variants {
			model: Quickshell.screens

			property bool selectionComplete: false

			Component.onCompleted: {
				selection.x1 = 0
				selection.y1 = 0
				selection.x2 = 0
				selection.y2 = 0
			}

			PanelWindow {
				required property var modelData;
				screen: modelData
				visible: root.visible
				exclusionMode: ExclusionMode.Ignore
				WlrLayershell.namespace: "shell:screenshot"
				WlrLayershell.layer: WlrLayer.Overlay
				WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

				anchors {
					top: true
					left: true
					right: true
					bottom: true
				}

				MouseArea {
					id: area
					anchors.fill: parent
					cursorShape: selectionComplete ? Qt.WaitCursor : Qt.CrossCursor
					enabled: !selectionComplete

					onPressed: {
						selection.x1 = mouseX + screen.x;
						selection.x2 = selection.x1;
						selection.y1 = mouseY + screen.y;
						selection.y2 = selection.y1;
					}

					onPositionChanged: {
						selection.x2 = mouseX + screen.x;
						selection.y2 = mouseY + screen.y;
					}

					onReleased: {
						if (selection.w > 0 && selection.h > 0) {
							magickProc.running = true
							selectionComplete = true
						} else {
							root.shooting = false
						}
					}

					Image {
						parent: area
						anchors.fill: parent
						source: root.visible ? root.path : ""
						sourceClipRect: Qt.rect(screen.x, screen.y, screen.width, screen.height)
					}

					CutoutRect {
						id: cutoutRect
						anchors.fill: parent
						innerX: selection.x - screen.x
						innerY: selection.y - screen.y
						innerW: selection.w
						innerH: selection.h

						NumberAnimation {
							id: rectFlashIn
							target: cutoutRect
							property: "opacity"
							duration: 200
							easing.type: Easing.OutExpo
							from: 0.0
							to: 1.0
						}

						PropertyAnimation {
							running: selectionComplete
							target: cutoutRect
							property: "innerBorderColor"
							duration: 200
							to: "#00ff20"
						}

						NumberAnimation {
							running: selectionComplete
							target: cutoutRect
							property: "backgroundOpacity"
							duration: 200
							to: 0.0
						}

						NumberAnimation {
							running: shootingComplete
							target: cutoutRect
							property: "opacity"
							easing.type: Easing.OutCubic
							duration: 150
							to: 0.0
							onStopped: root.shooting = false
						}
					}

					Connections {
						target: root

						function onVisibleChanged() {
							if (root.visible) {
								rectFlashIn.start();
							}
						}
					}
				}
			}
		}
	}
}
