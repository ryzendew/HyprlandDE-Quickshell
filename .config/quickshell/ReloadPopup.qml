import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects

Scope {
	id: root
	property bool failed;
	property string errorString;

	// Connect to the Quickshell global to listen for the reload signals.
	Connections {
		target: Quickshell

		function onReloadCompleted() {
			root.failed = false;
			popupLoader.loading = true;
		}

		function onReloadFailed(error: string) {
			// Close any existing popup before making a new one.
			popupLoader.active = false;

			root.failed = true;
			root.errorString = error;
			popupLoader.loading = true;
		}
	}

	// Keep the popup in a loader because it isn't needed most of the time
	LazyLoader {
		id: popupLoader

		PanelWindow {
			id: popup

			exclusionMode: ExclusionMode.Normal
			WlrLayershell.namespace: "quickshell:reloadPopup"
			WlrLayershell.layer: WlrLayer.Overlay
			color: "transparent"

			anchors {
				top: true
				left: true
				right: true
			}
			mask: Region {
				item: modernRect
			}

			implicitWidth: modernRect.width
			implicitHeight: modernRect.height

			// Modern glass effect background
			Rectangle {
				id: modernRect
				anchors.horizontalCenter: parent.horizontalCenter
				anchors.top: parent.top
				anchors.topMargin: 0
				width: Math.max(320, layout.implicitWidth + 60)
				height: layout.implicitHeight + 40
				radius: 20
				color: failed ? Qt.rgba(0.8, 0.2, 0.2, 0.6) : Qt.rgba(0.2, 0.6, 0.3, 0.6)
				border.color: failed ? Qt.rgba(1, 0.4, 0.4, 0.3) : Qt.rgba(0.4, 1, 0.6, 0.3)
				border.width: 1
				
				// Subtle shadow
				layer.enabled: true
				layer.effect: DropShadow {
					horizontalOffset: 0
					verticalOffset: 4
					radius: 16
					samples: 33
					color: Qt.rgba(0, 0, 0, 0.4)
				}

				// Fills the whole area of the rectangle, making any clicks go to it,
				// which dismiss the popup.
				MouseArea {
					id: mouseArea
					anchors.fill: parent
					onClicked: {
						popupLoader.active = false
					}

					// makes the mouse area track mouse hovering, so the hide animation
					// can be paused when hovering.
					hoverEnabled: true
				}

				RowLayout {
					id: layout
					spacing: 16
					anchors.centerIn: parent
					anchors.margins: 20

					// Icon section
					Rectangle {
						Layout.preferredWidth: 48
						Layout.preferredHeight: 48
						Layout.alignment: Qt.AlignTop
						color: Qt.rgba(1, 1, 1, 0.1)
						radius: 12
						
						Text {
							anchors.centerIn: parent
							text: failed ? "⚠" : "✓"
							font.pixelSize: 24
							color: "#ffffff"
							font.weight: Font.Bold
						}
					}

					// Content section
					ColumnLayout {
						Layout.fillWidth: true
						Layout.alignment: Qt.AlignVCenter
						spacing: 8

					Text {
						text: root.failed ? "Quickshell: Reload failed" : "Quickshell reloaded"
							color: "#ffffff"
							font.pixelSize: 16
							font.weight: Font.Medium
							Layout.fillWidth: true
					}

					Text {
							text: root.errorString
							color: "#ffffff"
							font.pixelSize: 12
						font.family: "JetBrains Mono NF"
							opacity: 0.9
							wrapMode: Text.WordWrap
							Layout.fillWidth: true
							Layout.maximumWidth: 250
						visible: root.errorString != ""
						}
					}
				}

				// Modern progress bar at the bottom
				Rectangle {
					anchors.bottom: parent.bottom
					anchors.left: parent.left
					anchors.right: parent.right
					anchors.margins: 1
					height: 4
					radius: 2
					color: Qt.rgba(1, 1, 1, 0.2)

					Rectangle {
						id: progressBar
						anchors.left: parent.left
						anchors.top: parent.top
						anchors.bottom: parent.bottom
						width: parent.width
						radius: 2
						color: "#ffffff"

					PropertyAnimation {
						id: anim
							target: progressBar
						property: "width"
							from: modernRect.width - 2
						to: 0
						duration: failed ? 10000 : 1000
						onFinished: popupLoader.active = false

						// Pause the animation when the mouse is hovering over the popup,
						// so it stays onscreen while reading. This updates reactively
						// when the mouse moves on and off the popup.
						paused: mouseArea.containsMouse
					}
				}
				}

				// Entrance animation
				NumberAnimation on opacity {
					id: entranceAnimation
					running: false
					from: 0
					to: 1
					duration: 250
					easing.type: Easing.OutQuad
				}
				
				NumberAnimation on scale {
					id: scaleAnimation
					running: false
					from: 0.8
					to: 1.0
					duration: 250
					easing.type: Easing.OutBack
				}

				// We could set `running: true` inside the animation, but the width of the
				// rectangle might not be calculated yet, due to the layout.
				// In the `Component.onCompleted` event handler, all of the component's
				// properties and children have been initialized.
				Component.onCompleted: {
					entranceAnimation.start()
					scaleAnimation.start()
					anim.start()
					forceCloseTimer.start()
			}

				// Force close timer to prevent popup from getting stuck
				Timer {
					id: forceCloseTimer
					interval: failed ? 15000 : 5000  // 15s for errors, 5s for success
					repeat: false
					onTriggered: {
						popupLoader.active = false
					}
				}
			}

			// Glass overlay effect
			Rectangle {
				anchors.fill: modernRect
				radius: 20
				color: "transparent"
				border.color: Qt.rgba(1, 1, 1, 0.1)
				border.width: 1
				
				// Subtle inner glow
				Rectangle {
					anchors.fill: parent
					anchors.margins: 1
					radius: 19
					color: "transparent"
					border.color: Qt.rgba(1, 1, 1, 0.05)
					border.width: 1
				}
            }
		}
	}
}
