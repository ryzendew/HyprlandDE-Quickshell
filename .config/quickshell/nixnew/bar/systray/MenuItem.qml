import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.DBusMenu
import "../.."

MouseArea {
	id: root
	required property QsMenuEntry entry;
	property alias expanded: childrenRevealer.expanded;
	property bool animating: childrenRevealer.animating || (childMenuLoader?.item?.animating ?? false);
	// appears it won't actually create the handler when only used from MenuItemList.
	onExpandedChanged: {}
	onAnimatingChanged: {}

	signal close();

	implicitWidth: row.implicitWidth + 4
	implicitHeight: row.implicitHeight + 4

	hoverEnabled: true
	onClicked: {
		if (entry.hasChildren) childrenRevealer.expanded = !childrenRevealer.expanded
		else {
			entry.triggered();
			if (entry.toggleType == ToggleButtonType.None) close();
		}
	}

	ColumnLayout {
		id: row
		anchors.fill: parent
		anchors.margins: 2
		spacing: 0

		RowLayout {
			id: innerRow

			Item {
				implicitWidth: 22
				implicitHeight: 22

				MenuCheckBox {
					anchors.centerIn: parent
					visible: entry.buttonType == QsMenuButtonType.CheckBox
					checkState: entry.checkState
				}

				MenuRadioButton {
					anchors.centerIn: parent
					visible: entry.buttonType == QsMenuButtonType.RadioButton
					checkState: entry.checkState
				}

				MenuChildrenRevealer {
					id: childrenRevealer
					anchors.centerIn: parent
					visible: entry.hasChildren
					onOpenChanged: entry.showChildren = open
				}
			}

			Text {
				text: entry.text
				color: entry.enabled ? "white" : "#bbbbbb"
			}

			Item {
				Layout.fillWidth: true
				implicitWidth: 22
				implicitHeight: 22

				IconImage {
					anchors.right: parent.right
					anchors.verticalCenter: parent.verticalCenter
					source: entry.icon
					visible: source != ""
					implicitSize: parent.height
				}
			}
		}

		Loader {
			id: childMenuLoader
			Layout.fillWidth: true
			Layout.preferredHeight: active ? item.implicitHeight * childrenRevealer.progress : 0

			readonly property real widthDifference: {
				Math.max(0, (item?.implicitWidth ?? 0) - innerRow.implicitWidth);
			}
			Layout.preferredWidth: active ? innerRow.implicitWidth + (widthDifference * childrenRevealer.progress) : 0

			active: root.expanded || root.animating
			clip: true

			sourceComponent: MenuView {
				id: childrenList
				menu: entry
				onClose: root.close()

				anchors {
					top: parent.top
					left: parent.left
					right: parent.right
				}
			}
		}
	}

	Rectangle {
		anchors.fill: parent
		visible: root.containsMouse || childrenRevealer.expanded

		color: ShellGlobals.colors.widget
		border.width: 1
		border.color: ShellGlobals.colors.widgetOutline
		radius: 5
	}
}
