import QtQuick
import Quickshell

Scope {
	id: root

	required property MouseArea target;

	property real velocityX: 0;
	property real velocityY: 0;

	signal flickStarted();
	signal flickCompleted();

	property real dragStartX: 0;
	property real dragStartY: 0;
	property real dragDeltaX: 0;
	property real dragDeltaY: 0;
	property real dragEndX: 0;
	property real dragEndY: 0;

	property var sampleIdx: -1
	property var tSamples: []
	property var xSamples: []
	property var ySamples: []

	ElapsedTimer { id: velocityTimer }

	function resetSamples() {
		velocityTimer.restart();
		sampleIdx = -1;
		tSamples = [];
		xSamples = [];
		ySamples = [];
	}

	function sample() {
		const deltaT = velocityTimer.elapsed();

		sampleIdx++;
		if (sampleIdx > 5) {
			sampleIdx = 0;
		}

		tSamples[sampleIdx] = deltaT;
		xSamples[sampleIdx] = dragDeltaX;
		ySamples[sampleIdx] = dragDeltaY;
	}

	function updateVelocity() {
		let firstIdx = sampleIdx + 1;
		if (firstIdx > tSamples.length - 1) firstIdx = 0;

		const deltaT = tSamples[sampleIdx] - tSamples[firstIdx];
		const deltaX = xSamples[sampleIdx] - xSamples[firstIdx];
		const deltaY = ySamples[sampleIdx] - ySamples[firstIdx];

		root.velocityX = deltaX / deltaT;
		root.velocityY = deltaY / deltaT;
	}

	Connections {
		target: root.target;

		function onPressed(event: MouseEvent) {
			root.resetSamples();
			root.dragDeltaX = 0;
			root.dragDeltaY = 0;
			root.dragStartX = event.x;
			root.dragStartY = event.y;
			root.flickStarted();
		}

		function onReleased(event: MouseEvent) {
			root.dragDeltaX = event.x - root.dragStartX;
			root.dragDeltaY = event.y - root.dragStartY;
			root.dragEndX = event.x;
			root.dragEndY = event.y;
			root.sample();
			root.updateVelocity();
			root.flickCompleted();
		}

		function onPositionChanged(event: MouseEvent) {
			root.dragDeltaX = event.x - root.dragStartX;
			root.dragDeltaY = event.y - root.dragStartY;
			root.sample();
		}
	}
}
