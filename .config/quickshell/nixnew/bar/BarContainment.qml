import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import ".."
import "../lock" as Lock

PanelWindow {
	id: root

	default property alias barItems: containment.data;

	anchors {
		left: true
		top: true
		bottom: true
	}

	property real baseWidth: 55
	property real leftMargin: root.compactState * 10
	width: baseWidth + 15
	exclusiveZone: baseWidth + (isFullscreenWorkspace ? 0 : 15) - margins.left

	mask: Region {
		height: root.height
		width: root.exclusiveZone
	}

	color: "transparent"

	WlrLayershell.namespace: "shell:bar"

	readonly property Tooltip tooltip: tooltip;
	Tooltip {
		id: tooltip
		bar: root
	}

	readonly property real tooltipXOffset: root.baseWidth + root.leftMargin + 5;

	function boundedY(targetY: real, height: real): real {
		return Math.max(barRect.anchors.topMargin + height, Math.min(barRect.height + barRect.anchors.topMargin - height, targetY))
	}

	readonly property bool isFullscreenWorkspace: Hyprland.monitorFor(screen).activeWorkspace.hasFullscreen
	property real compactState: isFullscreenWorkspace ? 0 : 1
	Behavior on compactState {
		NumberAnimation {
			duration: 600
			easing.type: Easing.BezierSpline
			easing.bezierCurve: [0.0, 0.75, 0.15, 1.0, 1.0, 1.0]
		}
	}

	Rectangle {
		id: barRect

		x: root.leftMargin - Lock.Controller.lockSlide * (barRect.width + root.leftMargin)
		width: parent.width - 15

		anchors {
			top: parent.top
			bottom: parent.bottom
			margins: root.compactState * 10
		}

		color: ShellGlobals.colors.bar
		radius: root.compactState * 5
		border.color: ShellGlobals.colors.barOutline
		border.width: root.compactState

		Item {
			id: containment

			anchors {
				fill: parent
				margins: 5
			}
		}
	}
}
