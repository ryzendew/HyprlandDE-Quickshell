import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import ".."

Item {
	id: root
	required property LockState state;

	property real focusAnim: focusAnimInternal * 0.001
	property int focusAnimInternal: Window.active ? 1000 : 0
	Behavior on focusAnimInternal { SmoothedAnimation { velocity: 5000 } }

	MouseArea {
		anchors.fill: parent
		hoverEnabled: true

		property real startMoveX: 0
		property real startMoveY: 0

		// prevents wakeups from bumping the mouse
		onPositionChanged: event => {
			if (root.state.fadedOut) {
				if (root.state.mouseMoved()) {
					const xOffset = Math.abs(event.x - startMoveX);
					const yOffset = Math.abs(event.y - startMoveY);
					const distanceSq = (xOffset * xOffset) + (yOffset * yOffset);
					if (distanceSq > (100 * 100)) root.state.fadeIn();
				} else {
					startMoveX = event.x;
					startMoveY = event.y;
				}
			}
		}

		Item {
			id: content
			width: parent.width
			height: parent.height
			y: root.state.fadeOutMul * (height / 2 + childrenRect.height)

			Rectangle {
				anchors.horizontalCenter: parent.horizontalCenter
				y: parent.height / 2 + textBox.height
				id: sep

				implicitHeight: 6
				implicitWidth: 800
				radius: height / 2
				color: ShellGlobals.colors.widget
			}

			ColumnLayout {
				implicitWidth: sep.implicitWidth
				anchors.horizontalCenter: parent.horizontalCenter
				anchors.bottom: sep.top
				spacing: 0

				SystemClock {
					id: clock
					precision: SystemClock.Minutes
				}

				Text {
					id: timeText
					Layout.alignment: Qt.AlignHCenter

					font {
						pointSize: 120
						hintingPreference: Font.PreferFullHinting
						family: "Noto Sans"
					}

					color: "white"
					renderType: Text.NativeRendering

					text: {
						const hours = clock.hours.toString().padStart(2, '0');
						const minutes = clock.minutes.toString().padStart(2, '0');
						return `${hours}:${minutes}`;
					}
				}

				Item {
					Layout.alignment: Qt.AlignHCenter
					implicitHeight: textBox.height * focusAnim
					implicitWidth: sep.implicitWidth
					clip: true

					TextInput {
						id: textBox
						focus: true
						width: parent.width

						color: enabled ?
							root.state.failed ? "#ffa0a0" : "white"
							: "#80ffffff";

						font.pointSize: 24
						horizontalAlignment: TextInput.AlignHCenter
						echoMode: TextInput.Password
						inputMethodHints: Qt.ImhSensitiveData

						cursorVisible: text != ""
						onCursorVisibleChanged: cursorVisible = text != ""

						onTextChanged: {
							root.state.currentText = text;
							cursorVisible = text != ""
						}

						Window.onActiveChanged: {
							if (Window.active) {
								text = root.state.currentText;
							}
						}

						Connections {
							target: root.state

							function onCurrentTextChanged() {
								textBox.text = root.state.currentText;
							}
						}

						onAccepted: {
							if (text != "") root.state.tryPasswordUnlock();
						}

						enabled: !root.state.isUnlocking;
					}

					Text {
						anchors.fill: textBox
						font: textBox.font
						color: root.state.failed ? "#ffa0a0" : "#80ffffff";
						horizontalAlignment: TextInput.AlignHCenter
						visible: !textBox.cursorVisible
						text: root.state.failed ? root.state.error
							: root.state.fprintAvailable ? "Touch sensor or enter password" : "Enter password";
					}

					Rectangle {
						Layout.fillHeight: true
						implicitWidth: height
						color: "transparent"
						visible: root.state.fprintAvailable

						anchors {
							right: textBox.right
							top: textBox.top
							bottom: textBox.bottom
						}

						Image {
							anchors.fill: parent
							anchors.margins: 5
							source: "root:icons/fingerprint.svg"
							sourceSize.width: width
							sourceSize.height: height
						}
					}
				}
			}

			Item {
				anchors.horizontalCenter: parent.horizontalCenter
				anchors.top: sep.bottom
				implicitHeight: (75 + 30) * focusAnim
				implicitWidth: sep.implicitWidth
				clip: true

				RowLayout {
					anchors.horizontalCenter: parent.horizontalCenter
					anchors.bottom: parent.bottom
					anchors.topMargin: 50
					spacing: 0

					LockButton {
						icon: "root:icons/monitor.svg"
						onClicked: root.state.fadeOut();
					}

					LockButton {
						icon: "root:icons/pause.svg"
						show: root.state.mediaPlaying;
						onClicked: root.state.pauseMedia();
					}
				}
			}
		}
	}

	Rectangle {
		id: darkenOverlay
		anchors.fill: parent
		color: "black"
		opacity: root.state.fadeOutMul
		visible: opacity != 0
	}
}
