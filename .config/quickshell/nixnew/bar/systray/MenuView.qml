import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.DBusMenu
import "../.."

ColumnLayout {
	id: root
	property alias menu: menuView.menu;
	property Item animatingItem: null;
	property bool animating: animatingItem != null;

	signal close();
	signal submenuExpanded(item: var);

	QsMenuOpener { id: menuView }

	spacing: 0

	Repeater {
		model: menuView.children;

		Loader {
			required property var modelData;

			property var item: Component {
				BoundComponent {
					id: itemComponent
					source: "MenuItem.qml"

					property var entry: modelData

					function onClose() {
						root.close()
					}

					function onExpandedChanged() {
						if (item.expanded) root.submenuExpanded(item);
					}

					function onAnimatingChanged() {
						if (item.animating) {
							root.animatingItem = this;
						} else if (root.animatingItem == this) {
							root.animatingItem = null;
						}
					}

					Connections {
						target: root

						function onSubmenuExpanded(expandedItem) {
							if (item != expandedItem) item.expanded = false;
						}
					}
				}
			}

			property var separator: Component {
				Item {
					implicitHeight: seprect.height + 6

					Rectangle {
						id: seprect

						anchors {
							verticalCenter: parent.verticalCenter
							left: parent.left
							right: parent.right
						}

						color: ShellGlobals.colors.separator
						height: 1
					}
				}
			}

			sourceComponent: modelData.isSeparator ? separator : item
			Layout.fillWidth: true
		}
	}
}
