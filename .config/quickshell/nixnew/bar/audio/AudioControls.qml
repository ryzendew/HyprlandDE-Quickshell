import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import ".."

BarWidgetInner {
	id: root
	required property var bar;
	implicitHeight: column.implicitHeight + 10;

	ColumnLayout {
		anchors {
			fill: parent;
			margins: 5;
		}

		id: column;
		spacing: 5;

		Loader {
			Layout.fillWidth: true;
			active: Pipewire.defaultAudioSink != null;

			sourceComponent: AudioControl {
				bar: root.bar;
				node: Pipewire.defaultAudioSink;
				image: `image://icon/${node.audio.muted ? "audio-volume-muted-symbolic" : "audio-volume-high-symbolic"}`
			}
		}

		Loader {
			Layout.fillWidth: true;
			active: Pipewire.defaultAudioSource != null;

			sourceComponent: AudioControl {
				bar: root.bar;
				node: Pipewire.defaultAudioSource;
				image: `image://icon/${node.audio.muted ? "microphone-sensitivity-muted-symbolic" : "microphone-sensitivity-high-symbolic"}`
			}
		}
	}
}
