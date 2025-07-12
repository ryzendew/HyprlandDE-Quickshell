import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root
    
    property string source: ""
    property string iconFolder: "root:/assets/icons"  // The folder to check first
    width: 30
    height: 30
    
    Image {
        id: iconImage
        anchors.fill: parent
        source: {
            if (root.source && root.source.startsWith("/")) {
                return root.source;
            } else if (iconFolder && root.source) {
                return root.source;
            } else {
                return "image://icon/" + (root.source || "application-x-executable");
            }
        }
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }
}
