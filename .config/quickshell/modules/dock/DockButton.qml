import "root:/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RippleButton {
    Layout.fillHeight: true
    Layout.topMargin: Appearance.sizes.elevationMargin - Appearance.sizes.hyprlandGapsOut
    implicitWidth: implicitHeight - topInset - bottomInset
    buttonRadius: Appearance.rounding.normal

    topInset: Appearance.sizes.hyprlandGapsOut + (dockRow ? dockRow.padding : 0)
    bottomInset: Appearance.sizes.hyprlandGapsOut + (dockRow ? dockRow.padding : 0)
    property var dockRow: null
}
