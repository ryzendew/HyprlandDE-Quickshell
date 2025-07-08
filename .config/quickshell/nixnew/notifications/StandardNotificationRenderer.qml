import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Notifications
import ".."

Rectangle {
	id: root
	required property Notification notif;
	required property var backer;

	color: notif.urgency == NotificationUrgency.Critical ? "#30ff2030" : "#30c0ffff"
	radius: 5
	implicitWidth: 450
	implicitHeight: c.implicitHeight

	HoverHandler {
		onHoveredChanged: {
			backer.pauseCounter += hovered ? 1 : -1;
		}
	}

	Rectangle {
		id: border
		anchors.fill: parent
		color: "transparent"
		border.width: 2
		border.color: ShellGlobals.colors.widgetOutline
		radius: root.radius
	}

	ColumnLayout {
		id: c
		anchors.fill: parent
		spacing: 0

		ColumnLayout {
			Layout.margins: 10

			RowLayout {
				Image {
					visible: source != ""
					source: notif.appIcon ? Quickshell.iconPath(notif.appIcon) : ""
					fillMode: Image.PreserveAspectFit
					antialiasing: true
					sourceSize.width: 30
					sourceSize.height: 30
					Layout.preferredWidth: 30
					Layout.preferredHeight: 30
				}

				Label {
					visible: text != ""
					text: notif.summary
					font.pointSize: 20
					elide: Text.ElideRight
					Layout.maximumWidth: root.implicitWidth - 100 // QTBUG-127649
				}

				Item { Layout.fillWidth: true }

				MouseArea {
					id: closeArea
					Layout.preferredWidth: 30
					Layout.preferredHeight: 30

					hoverEnabled: true
					onPressed: root.backer.discard();

					Rectangle {
						anchors.fill: parent
						anchors.margins: 5
						radius: width * 0.5
						antialiasing: true
						color: "#60ffffff"
						opacity: closeArea.containsMouse ? 1 : 0
						Behavior on opacity { SmoothedAnimation { velocity: 8 } }
					}

					CloseButton {
						anchors.fill: parent
						ringFill: root.backer.timePercentage
					}
				}
			}

			Item {
				Layout.topMargin: 3
				visible: bodyLabel.text != "" || notifImage.visible
				implicitWidth: bodyLabel.width
				implicitHeight: Math.max(notifImage.size, bodyLabel.implicitHeight)

				Image {
					id: notifImage
					readonly property int size: visible ? 14 * 8 : 0
					y: bodyLabel.y + bodyLabel.topPadding

					visible: source != ""
					source: notif.image
					fillMode: Image.PreserveAspectFit
					cache: false
					antialiasing: true

					width: size
					height: size
					sourceSize.width: size
					sourceSize.height: size
				}

				Label {
					id: bodyLabel
					width: root.implicitWidth - 20
					text: notif.body
					wrapMode: Text.Wrap

					onLineLaidOut: line => {
						if (!notifImage.visible) return;

						const isize = notifImage.size + 6;
						if (line.y + line.height <= notifImage.y + isize) {
							line.x += isize;
							line.width -= isize;
						}
					}
				}
			}
		}

		ColumnLayout {
			Layout.fillWidth: true
			Layout.margins: root.border.width
			spacing: 0
			visible: notif.actions.length != 0

			Rectangle {
				height: border.border.width
				Layout.fillWidth: true
				color: border.border.color
				antialiasing: true
			}

			RowLayout {
				spacing: 0

				Repeater {
					model: notif.actions

					Item {
						required property NotificationAction modelData;
						required property int index;

						Layout.fillWidth: true
						implicitHeight: 35

						Rectangle {
							anchors {
								top: parent.top
								bottom: parent.bottom
								left: parent.left
								leftMargin: -implicitWidth * 0.5
							}

							visible: index != 0
							implicitWidth: root.border.width
							color: ShellGlobals.colors.widgetOutline
							antialiasing: true
						}

						MouseArea {
							id: actionArea
							anchors.fill: parent

							onClicked: {
								modelData.invoke();
							}

							Rectangle {
								anchors.fill: parent
								color: actionArea.pressed && actionArea.containsMouse ? "#20000000" : "transparent"
							}

							RowLayout {
								anchors.centerIn: parent

								Image {
									visible: notif.hasActionIcons
									source: Quickshell.iconPath(modelData.identifier)
									fillMode: Image.PreserveAspectFit
									antialiasing: true
									sourceSize.height: 25
									sourceSize.width: 25
								}

								Label { text: modelData.text }
							}
						}
					}
				}
			}
		}
	}
}
