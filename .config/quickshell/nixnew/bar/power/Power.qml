import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Widgets
import ".."
import "root:."
import "root:components"
import "power"

BarWidgetInner {
	id: root
	required property var bar;

	readonly property var chargeState: UPower.displayDevice.state
	readonly property bool isCharging: chargeState == UPowerDeviceState.Charging;
	readonly property bool isPluggedIn: isCharging || chargeState == UPowerDeviceState.PendingCharge;
	readonly property real percentage: UPower.displayDevice.percentage
	readonly property bool isLow: percentage <= 0.20

	readonly property UPowerDevice batteryDevice: UPower.devices.values
		.find(device => device.isLaptopBattery);

	function statusStr() {
		return root.isPluggedIn ? `Plugged in, ${root.isCharging ? "Charging" : "Not Charging"}`
		                        : "Discharging";
	}

	property bool showMenu: false;

	implicitHeight: width
	color: isLow ? "#45ff6060" : ShellGlobals.colors.widget

	BarButton {
		id: button
		anchors.fill: parent
		baseMargin: 5
		fillWindowWidth: true
		acceptedButtons: Qt.RightButton
		directScale: true
		showPressed: root.showMenu

		onPressed: {
			root.showMenu = !root.showMenu
		}

		BatteryIcon {
			device: UPower.displayDevice
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
				text: {
					const status = root.statusStr();

					const percentage = Math.round(root.percentage * 100);

					let str = `${percentage}% - ${status}`;
					return str;
				}
			}
		}
	}

	property TooltipItem rightclickMenu: TooltipItem {
		id: rightclickMenu
		tooltip: bar.tooltip
		owner: root

		isMenu: true
		show: root.showMenu
		onClose: root.showMenu = false

		Loader {
			active: rightclickMenu.visible
			sourceComponent: ColumnLayout {
				spacing: 10

				FontMetrics { id: fm }

				component SmallLabel: Label {
					font.pointSize: fm.font.pointSize * 0.8
					color: "#d0eeffff"
				}
			
				RowLayout {
					IconImage {
						source: "root:icons/gauge.svg"
						implicitSize: 32
					}

					ColumnLayout {
						spacing: 0
						Label { text: "Power Profile" }

						OptionSlider {
							values: ["Power Save", "Balanced", "Performance"]
							index: PowerProfiles.profile
							onIndexChanged: PowerProfiles.profile = this.index;
							implicitWidth: 350
						}
					}
				}

				RowLayout {
					IconImage {
						Layout.alignment: Qt.AlignTop
						source: "root:icons/battery-empty.svg"
						implicitSize: 32
					}

					ColumnLayout {
						spacing: 0

						RowLayout {
							Label { text: "Battery" }
							Item { Layout.fillWidth: true }
							Label {
								text: `${root.statusStr()} -`
								color: "#d0eeffff"
							}
							Label { text: `${Math.round(root.percentage * 100)}%` }
						}

						ProgressBar {
							Layout.topMargin: 5
							Layout.bottomMargin: 5
							Layout.fillWidth: true
							value: UPower.displayDevice.percentage
						}

						RowLayout {
							visible: remainingTimeLbl.text !== ""

							SmallLabel { text: "Time remaining" }
							Item { Layout.fillWidth: true }

				     	SmallLabel {
								id: remainingTimeLbl
				     		text: {
				     			const device = UPower.displayDevice;
				     			const time = device.timeToEmpty || device.timeToFull;

									if (time === 0) return "";
									const minutes = Math.floor(time / 60).toString().padStart(2, '0');
									return `${minutes} minutes`
				     		}
				     	}
						}

						RowLayout {
							visible: root.batteryDevice.healthSupported
							SmallLabel { text: "Health" }
							Item { Layout.fillWidth: true }

				     	SmallLabel {
				     		text: `${Math.floor((root.batteryDevice?.healthPercentage ?? 0))}%`
				     	}
						}
					}
				}

				Repeater {
					model: ScriptModel {
						// external devices
						values: UPower.devices.values.filter(device => !device.powerSupply)
					}

			   	RowLayout {
						required property UPowerDevice modelData;

			   		IconImage {
			   			Layout.alignment: Qt.AlignTop
			   			source: {
								switch (modelData.type) {
								case UPowerDeviceType.Headset: return "root:icons/headset.svg";
								}
								return Quickshell.iconPath(modelData.iconName)
							}
			   			implicitSize: 32
			   		}

			   		ColumnLayout {
			   			spacing: 0

			   			RowLayout {
			   				Label { text: modelData.model }
			   				Item { Layout.fillWidth: true }
			   				Label { text: `${Math.round(modelData.percentage * 100)}%` }
			   			}

			   			ProgressBar {
			   				Layout.topMargin: 5
			   				Layout.bottomMargin: 5
			   				Layout.fillWidth: true
			   				value: modelData.percentage
			   			}

			   			RowLayout {
			   				visible: modelData.healthSupported
			   				SmallLabel { text: "Health" }
			   				Item { Layout.fillWidth: true }

			   	     	SmallLabel {
			   	     		text: `${Math.floor(modelData.healthPercentage)}%`
			   	     	}
			   			}
			   		}
			   	}
				}
			}
		}
	}
}
