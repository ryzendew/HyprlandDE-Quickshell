import QtQuick

Canvas {
	id: root
	property real ringFill: 1.0

	onRingFillChanged: requestPaint();

	renderStrategy: Canvas.Cooperative

	onPaint: {
		const ctx = getContext("2d");
		ctx.reset();

		ctx.lineWidth = 2;
		ctx.strokeStyle = "#70ffffff";

		ctx.beginPath();
		const half = Math.round(root.width / 2);
		const start = -Math.PI * 0.5;
		const endM = ringFill == 0.0 || ringFill == 1.0 ? ringFill : 1.0 - ringFill
		ctx.arc(half, half, half - ctx.lineWidth, start, start + 2 * Math.PI * endM, true);
		ctx.stroke();

		const xMin = Math.min(root.width * 0.3);
		const xMax = Math.max(root.width * 0.7);
		ctx.strokeStyle = "white";

		ctx.beginPath();
		ctx.moveTo(xMin, xMin);
		ctx.lineTo(xMax, xMax);
		ctx.stroke();

		ctx.beginPath();
		ctx.moveTo(xMax, xMin);
		ctx.lineTo(xMin, xMax);
		ctx.stroke();
	}
}
