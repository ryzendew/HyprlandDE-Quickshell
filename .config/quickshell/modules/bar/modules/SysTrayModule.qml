import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "root:/modules/common"
import "../"

Item {
    Layout.alignment: Qt.AlignCenter | Qt.AlignVCenter
    Layout.fillWidth: false
    Layout.fillHeight: true
    Layout.rightMargin: 4
    Layout.leftMargin: 4
    implicitWidth: sysTray.implicitWidth
    implicitHeight: sysTray.implicitHeight
    
    property var bar: null // Will be set by parent
    
    SysTray {
        id: sysTray
        bar: parent.bar
        anchors.fill: parent
    }
} 