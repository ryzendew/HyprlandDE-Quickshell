import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
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
    
    SystemTray {
        id: sysTray
        bar: parent.bar
        shell: parent.bar
        trayMenu: customTrayMenu
        anchors.fill: parent
    }
    
    CustomTrayMenu {
        id: customTrayMenu
    }
} 