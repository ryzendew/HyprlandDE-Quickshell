import QtQuick 2.15

Item {
    id: root
    property real percentage: 1.0 // 0.0 to 1.0
    property bool charging: false
    property bool critical: false
    property bool low: false
    property bool fullyCharged: false
    property color fillColor: "white"
    property color outlineColor: "#888"
    // Remove width_ and height_ properties, use implicitWidth/implicitHeight for defaults
    // property int width_: 28
    // property int height_: 14

    // Set default size to match indicator icon size
    implicitWidth: 28
    implicitHeight: 14

    // Use parent-set width/height, otherwise fall back to implicit
    // width and height are already properties of Item
    // So just remove the explicit width/height assignments

    // Battery body outline
    Rectangle {
        x: 0; y: 3
        width: root.width - 4
        height: root.height - 3
        radius: 3
        color: "transparent"
        border.color: root.outlineColor
        border.width: 2
    }

    // Battery fill (white, grows with percentage)
    Rectangle {
        x: 2
        y: 5
        width: Math.max(2, (root.width - 8) * Math.max(0, Math.min(1, root.percentage)))
        height: root.height - 7
        radius: 2
        color: root.fillColor
        z: 1
        
        // Battery percentage text
        Text {
            anchors.centerIn: parent
            text: Math.round(root.percentage * 100) + "%"
            font.pixelSize: Math.max(8, parent.height * 0.6)
            font.bold: true
            color: "black"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    // Battery tip
    Rectangle {
        x: root.width - 4
        y: root.height / 4
        width: 4
        height: root.height / 2
        radius: 1
        color: root.outlineColor
        border.width: 0
    }

    // Optional: Charging bolt overlay (yellow)
    /*
    Item {
        visible: root.charging
        anchors.centerIn: parent
        width: root.width
        height: root.height
        Rectangle {
            anchors.centerIn: parent
            width: root.width / 3
            height: root.height / 2
            color: "yellow"
            rotation: 20
            opacity: 0.7
        }
        // You can replace this with a Path or SVG for a real bolt
    }
    */
} 