import QtQuick
import QtQuick.Layouts
import "root:/modules/common"

/**
 * Info Row Component
 * Displays a label-value pair with an icon for system information.
 */
RowLayout {
    id: root
    
    property string label: ""
    property string value: ""
    property string icon: ""
    
    Layout.fillWidth: true
    spacing: 8
    
    // Icon
    MaterialSymbol {
        text: root.icon
        iconSize: 16
        color: Qt.rgba(1, 1, 1, 0.7)
    }
    
    // Label
    StyledText {
        text: root.label + ":"
        font.pixelSize: Appearance.font.pixelSize.small
        color: Qt.rgba(1, 1, 1, 0.7)
        Layout.preferredWidth: 80
    }
    
    // Value
    StyledText {
        text: root.value
        font.pixelSize: Appearance.font.pixelSize.small
        color: "white"
        Layout.fillWidth: true
        elide: Text.ElideRight
    }
} 