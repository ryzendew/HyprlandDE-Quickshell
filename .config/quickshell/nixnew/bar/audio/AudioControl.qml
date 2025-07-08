import QtQuick
import Quickshell.Services.Pipewire
import ".."

ClickableIcon {
	id: root
	required property var bar;
	required property PwNode node;
	property bool mixerOpen: false;

	PwObjectTracker { objects: [ node ] }

	implicitHeight: width;
	acceptedButtons: Qt.LeftButton | Qt.RightButton;
	fillWindowWidth: true
	showPressed: mixerOpen || (pressedButtons & ~Qt.RightButton)

	onPressed: event => {
		event.accepted = true;
		if (event.button === Qt.RightButton) {
			mixerOpen = !mixerOpen;
		}
	}

	onClicked: event => {
		if (event.button === Qt.LeftButton) {
			event.accepted = true;
			node.audio.muted = !node.audio.muted;
		}
	}

	onWheel: event => {
		event.accepted = true;
		node.audio.volume += (event.angleDelta.y / 120) * 0.05
	}

	property var tooltip: TooltipItem {
		tooltip: bar.tooltip
		owner: root

		show: root.containsMouse || mouseArea.containsMouse
		hoverable: true

		MouseArea {
			id: mouseArea
			hoverEnabled: true
			acceptedButtons: Qt.NoButton

			implicitWidth: childrenRect.width
			implicitHeight: childrenRect.height

			VolumeSlider {
				implicitWidth: 200
				implicitHeight: root.height

				//enabled: !node.audio.muted
				value: node.audio.volume
				onValueChanged: node.audio.volume = value
			}
		}
	}

	property var rightclickMenu: TooltipItem {
		tooltip: bar.tooltip
		owner: root

		isMenu: true
		show: mixerOpen

		onClose: mixerOpen = false
		/*onVisibleChanged: {
			if (!visible) mixerOpen = false;
		}*/

		Loader {
			active: rightclickMenu.visible
			sourceComponent: Mixer {
				width: 550
				trackedNode: node
				nodeList: Pipewire.nodes.values.filter(n => n.audio && !n.isStream && n.isSink == node.isSink)
				nodeImage: root.image

				onSelected: n => {
					if (node.isSink) {
						Pipewire.preferredDefaultAudioSink = n;
					} else {
						Pipewire.preferredDefaultAudioSource = n;
					}
				}
			}
		}
	}
}
