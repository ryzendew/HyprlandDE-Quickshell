import QtQuick
import Quickshell.Services.UPower
import "root:."

Item {
	id: root
	required property UPowerDevice device;
	property real scale: 1;

	readonly property bool isCharging: root.device.state == UPowerDeviceState.Charging;
	readonly property bool isPluggedIn: isCharging || root.device.state == UPowerDeviceState.PendingCharge;
	readonly property bool isLow: root.device.percentage <= 0.20;

	width: 35 * root.scale
	height: 35 * root.scale

	Rectangle {
		anchors {
			horizontalCenter: parent.horizontalCenter
			bottom: parent.bottom
			bottomMargin: 4 * root.scale
		}

		width: 13 * root.scale
		height: 23 * root.device.percentage * root.scale
		radius: 2 * root.scale

		color: root.isPluggedIn ? "#359040"
		     : ShellGlobals.interpolateColors(Math.min(1.0, Math.min(0.5, root.device.percentage) * 2), "red", "white")
	}

	Image {
		id: img
		anchors.fill: parent;

		source: root.isCharging ? "root:icons/battery-charging.svg"
		      : root.isPluggedIn ? "root:icons/battery-plus.svg"
					: root.isLow ? "root:icons/battery-warning.svg"
		      : "root:icons/battery-empty.svg"

		sourceSize.width: parent.width
		sourceSize.height: parent.height
		visible: true
	}
}
