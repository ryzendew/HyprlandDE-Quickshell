import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import ".."
import "../.."

BarWidgetInner {
	id: root
	border.color: "transparent"

	property real renderWidth: width
	property real renderHeight: height

	property real blurRadius: 20;
	property real blurSamples: 41;

	property bool reverse: false;

	function setArt(art: string, reverse: bool, immediate: bool) {
		this.reverse = reverse;

		if (art.length == 0) {
			stack.replace(null);
		} else {
			stack.replace(component, { uri: art }, immediate)
		}
	}

	property var component: Component {
		Item {
			id: componentRoot
			property var uri: null;
			readonly property bool svReady: image.status === Image.Ready;

			Image {
				id: image
				anchors.centerIn: parent;
				source: uri;
				cache: false;
				asynchronous: true;

				fillMode: Image.PreserveAspectCrop;
				sourceSize.width: width;
				sourceSize.height: height;
				width: stack.width + blurRadius * 2;
				height: stack.height + blurRadius * 2;
			}

			property Component blurComponent: Item {
				id: blur
				//parent: blurContainment
				// blur into the neighboring elements if applicable
				x: componentRoot.x - blurRadius * 4
				y: componentRoot.y + image.y
				width: componentRoot.width + blurRadius * 8
				height: image.height

				onVisibleChanged: {
					if (visible) blurSource.scheduleUpdate();
				}

				Connections {
					target: image
					function onStatusChanged() {
						if (image.status == Image.Ready) {
							blurSource.scheduleUpdate();
						}
					}
				}

				ShaderEffectSource {
					id: blurSource
					sourceItem: stack
					sourceRect: Qt.rect(blur.x, blur.y, blur.width, blur.height);
					live: false
					anchors.fill: parent
					visible: false
				}

				Item {
					x: blurRadius
					width: blur.width - blurRadius * 2
					height: blur.height

					GaussianBlur {
						source: blurSource
						x: -parent.x
						width: blur.width
						height: blur.height
						radius: root.blurRadius
						samples: root.blurSamples
						visible: true
					}
				}
			}

			// Weird crash if the blur is not owned by its visual parent,
			// so it has to be a component.
			property Item blur: blurComponent.createObject(blurContainment);
			Component.onDestruction: blur.destroy();
		}
	}

	SlideView {
		id: stack;
		height: renderHeight
		width: renderWidth
		anchors.centerIn: parent;
		visible: false;
		animate: root.visible;

		readonly property real fromPos: (stack.width + blurRadius * 2) * (reverse ? -1 : 1);

		enterTransition: PropertyAnimation {
			property: "x"
			from: stack.fromPos
			to: 0
			duration: 400
			easing.type: Easing.OutExpo;
		}

		exitTransition: PropertyAnimation {
			property: "x"
			to: -stack.fromPos
			duration: 400
			easing.type: Easing.OutExpo;
		}
	}

	Item {
		id: blurContainment
		x: stack.x
		y: stack.y
		width: stack.width
		height: stack.height
	}

	readonly property Rectangle overlay: overlayItem;
	Rectangle {
		id: overlayItem
		visible: true
		anchors.fill: parent
		radius: root.radius
		color: "transparent"

		Rectangle {
			anchors.fill: parent
			radius: root.radius
			color: "transparent"
			border.color: ShellGlobals.colors.widgetOutlineSeparate;
			border.width: 1
		}
	}

	// slightly offset on the corners :/
	layer.enabled: true
	layer.effect: OpacityMask {
		maskSource: Rectangle {
			width: root.width
			height: root.height
			radius: root.radius
		}
	}
}
