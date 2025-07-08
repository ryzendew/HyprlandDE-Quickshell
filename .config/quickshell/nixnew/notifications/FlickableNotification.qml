import QtQuick
import Quickshell
import "../components"

Item {
	id: root

	readonly property Region mask: Region { item: displayContainer }

	enum FlingState {
		Inert,
		Returning,
		Flinging,
		Dismissing
	}

	implicitWidth: display.implicitWidth

	// note: can be 0, use ZHVStack
	implicitHeight: (display.implicitHeight + padding * 2) * display.meshFactor

	z: 1.0 - display.meshFactor

	property var view;
	property Item contentItem;
	property real padding: 5;
	property real edgeXOffset;
	property bool canOverlap: display.rotation > 2 || Math.abs(display.displayY) > 10 || display.displayX < -60
	property bool canDismiss: display.state != FlickableNotification.Dismissing && display.state != FlickableNotification.Flinging;

	property alias displayContainer: displayContainer;

	signal leftViewBounds();
	signal dismissed();
	signal discarded();
	signal startedFlick();

	function playEntry(delay: real) {
		if (display.state != FlickableNotification.Flinging) {
			display.displayX = -display.width + edgeXOffset
			root.playReturn(delay);
		}
	}

	function playDismiss(delay: real) {
		if (display.state != FlickableNotification.Flinging && display.state != FlickableNotification.Dismissing) {
			display.state = FlickableNotification.Dismissing;
			display.animationDelay = delay;
		}
	}

	function playDiscard(delay: real) {
		if (display.state != FlickableNotification.Flinging && display.state != FlickableNotification.Dismissing) {
			display.velocityX = 500;
			display.velocityY = 1500;
			display.state = FlickableNotification.Flinging;
			display.animationDelay = delay;
		}
	}

	function playReturn(delay: real) {
		if (display.state != FlickableNotification.Flinging) {
			display.state = FlickableNotification.Returning;
			display.animationDelay = delay;
		}
	}

	MouseArea {
		id: mouseArea
		width: display.width
		height: display.height
		enabled: display.state == FlickableNotification.Inert || display.state == FlickableNotification.Returning

		FlickMonitor {
			id: flickMonitor
			target: mouseArea

			onDragDeltaXChanged: {
				const delta = dragDeltaX;
				display.displayX = delta < 0 ? delta : Math.pow(delta, 0.8);
				display.updateMeshFactor(true);
				updateDragY();
			}

			onDragDeltaYChanged: {
				updateDragY();
				display.state = FlickableNotification.Inert;
			}

			function updateDragY() {
				//const xMul = 1//dragDeltaX < 0 ? 0 : Math.min(1, Math.pow(dragDeltaX / 200, 0.8));
				const d = Math.max(0, Math.min(5000, display.displayX)) / 2000;
				const xMul = d
				const targetY = dragDeltaY;
				display.displayY = root.padding + targetY * xMul;
			}

			onFlickStarted: {
				display.initialAnimComplete = true;
				root.startedFlick();
			}

			onFlickCompleted: {
				display.releaseY = dragEndY;

				if (velocityX > 1000 || (velocityX > -100 && display.displayX > display.width * 0.4)) {
					display.velocityX = Math.max(velocityX * 0.8, 1000);
					display.velocityY = velocityY * 0.6;
					display.state = FlickableNotification.Flinging;
					root.discarded();
				} else if (velocityX < -1500 || (velocityX < 100 && display.displayX < -(display.width * 0.4))) {
					display.velocityX = Math.min(velocityX * 0.8, -700)
					display.velocityY = 0
					display.state = FlickableNotification.Dismissing;
					root.dismissed();
				} else {
					display.velocityX = 0;
					display.velocityY = 0;
					display.state = FlickableNotification.Returning;
				}
			}
		}

		Item {
			id: displayContainer
			layer.enabled: view && view.topNotification == root
			opacity: layer.enabled ? 0 : 1 // shader ignores it
			width: Math.ceil(display.width + display.xPadding * 2)
			height: Math.ceil(display.height + display.yPadding * 2)

			x: Math.floor(display.targetContainmentX)
			y: Math.floor(display.targetContainmentY)

			Item {
				id: display
				//anchors.centerIn: parent
				x: xPadding + (targetContainmentX - displayContainer.x)
				y: yPadding + (targetContainmentY - displayContainer.y)
				//visible: meshFactor > 0.95

				children: [root.contentItem]
				implicitWidth: root.contentItem?.width ?? 0
				implicitHeight: root.contentItem?.height ?? 0

				property var state: FlickableNotification.Inert;
				property real meshFactor: 1;
				property real velocityX;
				property real velocityY;
				property real releaseY;
				property real animationDelay;
				property bool initialAnimComplete;

				property real displayX;
				property real displayY;

				property real tiltSize: Math.max(width, height) * 1.2;
				property real xPadding: (tiltSize - width) / 2;
				property real yPadding: (tiltSize - height) / 2;

				property real targetContainmentX: display.displayX - display.xPadding
				property real targetContainmentY: root.padding + display.displayY - display.yPadding

				function updateMeshFactor(canRemesh: bool) {
					let meshFactor = (display.implicitWidth - Math.abs(display.displayX)) / display.implicitWidth;
					meshFactor = 0.8 + (meshFactor * 0.2);
					meshFactor = Math.max(0, meshFactor);

					if (canRemesh) this.meshFactor = meshFactor;
					else this.meshFactor = Math.min(this.meshFactor, meshFactor);
				}

				function unmesh(delta: real) {
					if (meshFactor > 0) {
						this.meshFactor = Math.max(0, this.meshFactor - delta * 5);
					}
				}

				rotation: display.displayX < 0 ? 0 : display.displayX * (initialAnimComplete ? 0.1 : 0.02)

				property real lastX;

				FrameAnimation {
					function dampingVelocity(currentVelocity, delta) {
						const spring = 1.0;
						const damping = 0.1;
						const springForce = spring * delta;
						const dampingForce = -damping * currentVelocity;
						return currentVelocity + (springForce + dampingForce);
					}

					running: display.state != FlickableNotification.Inert
					onTriggered: {
						let frameTime = this.frameTime;
						if (display.animationDelay != 0) {
							const usedDelay = Math.min(display.animationDelay, frameTime);
							frameTime -= usedDelay;
							display.animationDelay -= usedDelay;
							if (frameTime == 0) return;
						}

						if (display.state == FlickableNotification.Flinging) {
							display.velocityY += frameTime * 100000 * (1 / display.velocityX * 100);
							//display.velocityX -= display.velocityX * 0.98 * frameTime
							display.unmesh(frameTime);
						} else if (display.state == FlickableNotification.Dismissing) {
							const d = Math.max(0, Math.min(5000, display.displayX)) / 2000;
							display.displayY = root.padding + display.releaseY * d;
							display.velocityY = 0;

							display.velocityX += frameTime * -20000;

							if (display.displayX + display.width > 0) display.updateMeshFactor(false);
							else display.unmesh(frameTime);
						} else {
							const deltaX = 0 - display.displayX;
							const deltaY = root.padding - display.displayY;

							display.velocityX = dampingVelocity(display.velocityX, deltaX);
							display.velocityY = dampingVelocity(display.velocityY, deltaY);

							if (Math.abs(display.velocityX) < 0.01 && Math.abs(deltaX) < 1
								&& Math.abs(display.velocityY) < 0.01 && Math.abs(deltaY) < 1) {
									display.state = FlickableNotification.Inert;
									display.displayX = 0;
									display.displayY = root.padding;
									display.velocityX = 0;
									display.velocityY = 0;
									display.initialAnimComplete = true;
								}

							display.updateMeshFactor(true);
						}

						display.displayX += display.velocityX * frameTime;
						display.displayY += display.velocityY * frameTime;


						// todo: actually base this on the viewport
						if (display.displayX > 10000 || display.displayY > 10000 || (display.displayX + display.width < root.edgeXOffset && display.meshFactor == 0) || display.displayY < -10000) root.leftViewBounds();
					}
				}
			}
		}
	}
}
