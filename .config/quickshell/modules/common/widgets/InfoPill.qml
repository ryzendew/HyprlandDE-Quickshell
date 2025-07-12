import QtQuick
import QtQuick.Layouts
import "root:/modules/common/widgets"
import "root:/modules/common"

Rectangle {
    id: root
    property string text: ""
    property bool pillVisible: text.length > 0
    
    height: pillVisible ? 28 : 0
    radius: Appearance.rounding.full
    color: Qt.rgba(Appearance.colors.colLayer1.r, Appearance.colors.colLayer1.g, Appearance.colors.colLayer1.b, 0.2)
    border.color: Qt.rgba(1, 1, 1, 0.08)
    border.width: 1
    
    Layout.alignment: Qt.AlignHCenter
    Layout.fillWidth: false
    Layout.preferredWidth: Math.min(implicitWidth, 200)
    
    StyledText {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        text: root.text
        font.pixelSize: Appearance.font.pixelSize.tiny
        color: "white"
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideMiddle
    }
    
    Behavior on height {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
        }
    }
} 