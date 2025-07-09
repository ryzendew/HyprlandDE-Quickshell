import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "./calendar/ModernCalendar.qml" as ModernCalendarComponent
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root
    radius: Appearance.rounding.normal
    color: Qt.rgba(
        Appearance.colors.colLayer1.r,
        Appearance.colors.colLayer1.g,
        Appearance.colors.colLayer1.b,
        0.55
    )
    border.color: Qt.rgba(1, 1, 1, 0.12)
    border.width: 1
    clip: true
    implicitHeight: calendarWidget.implicitHeight
    
    // Property to control visibility - will be set by parent
    property bool hideCalendar: false
    
    visible: !hideCalendar

    ModernCalendarComponent.ModernCalendar {
        id: calendarWidget
        anchors.fill: parent
    }
}