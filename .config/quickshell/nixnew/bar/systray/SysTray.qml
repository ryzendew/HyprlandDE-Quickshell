pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import ".."

BarWidgetInner {
	id: root
	required property var bar;
	implicitHeight: column.implicitHeight + 10

	ColumnLayout {
		id: column
		implicitHeight: childrenRect.height
		spacing: 5

		anchors {
			fill: parent
			margins: 5
		}

		Repeater {
			model: SystemTray.items;

			Item {
				id: item
				required property SystemTrayItem modelData;

				property bool targetMenuOpen: false;

				Layout.fillWidth: true
				implicitHeight: width

				ClickableIcon {
					id: mouseArea
					anchors {
						top: parent.top
						bottom: parent.bottom
						horizontalCenter: parent.horizontalCenter
					}
					width: height

					acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

					image: item.modelData.icon
					showPressed: item.targetMenuOpen || (pressedButtons & ~Qt.RightButton)
					fillWindowWidth: true
					extraVerticalMargin: column.spacing / 2

					onClicked: event => {
						event.accepted = true;

						if (event.button == Qt.LeftButton) {
							item.modelData.activate();
						} else if (event.button == Qt.MiddleButton) {
							item.modelData.secondaryActivate();
						}
					}

					onPressed: event => {
						if (event.button == Qt.RightButton && item.modelData.hasMenu) {
							item.targetMenuOpen = !item.targetMenuOpen;
						}
					}

					onWheel: event => {
						event.accepted = true;
						const points = event.angleDelta.y / 120
						item.modelData.scroll(points, false);
					}

					property var tooltip: TooltipItem {
						tooltip: root.bar.tooltip
						owner: mouseArea

						show: mouseArea.containsMouse

						Text {
							id: tooltipText
							text: item.modelData.tooltipTitle != "" ? item.modelData.tooltipTitle : item.modelData.id
							color: "white"
						}
					}

					property var rightclickMenu: TooltipItem {
						id: rightclickMenu
						tooltip: root.bar.tooltip
						owner: mouseArea

						isMenu: true
						show: item.targetMenuOpen
						animateSize: !(menuContentLoader?.item?.animating ?? false)

						onClose: item.targetMenuOpen = false;

						Loader {
							id: menuContentLoader
							active: item.targetMenuOpen || rightclickMenu.visible || mouseArea.containsMouse

							sourceComponent: MenuView {
								menu: item.modelData.menu
								onClose: item.targetMenuOpen = false;
							}
						}
					}
				}
			}
		}
	}
}
