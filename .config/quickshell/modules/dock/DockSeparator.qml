import "root:/"
import "root:/modules/common"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    Layout.topMargin: Appearance.sizes.elevationMargin + (dockRow ? dockRow.padding : 0) + Appearance.rounding.normal
    Layout.bottomMargin: Appearance.sizes.hyprlandGapsOut + (dockRow ? dockRow.padding : 0) + Appearance.rounding.normal
    Layout.fillHeight: true
    implicitWidth: 1
    color: Appearance.m3colors.m3outlineVariant
    property var dockRow: null
}
