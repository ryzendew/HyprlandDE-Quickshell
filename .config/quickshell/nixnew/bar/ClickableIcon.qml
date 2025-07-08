import QtQuick

BarButton {
	id: root
	required property string image;
	property alias cache: imageComponent.cache;
	property alias asynchronous: imageComponent.asynchronous;
	property bool scaleIcon: !asynchronous

	Image {
		id: imageComponent
		anchors.fill: parent

		source: root.image
		sourceSize.width: scaleIcon ? width : (root.width - baseMargin)
		sourceSize.height: scaleIcon ? height : (root.height - baseMargin)
		cache: false
	}
}
