import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Layouts

Rectangle {
    property bool borderless: ConfigOptions.bar?.borderless ?? false
    property bool showSeconds: ConfigOptions.time?.showSeconds ?? false
    property bool showDate: ConfigOptions.time?.showDate ?? true
    property int fontSize: ConfigOptions.time?.display?.fontSize ?? 0
    property bool bold: ConfigOptions.time?.display?.bold ?? false
    property bool italic: ConfigOptions.time?.display?.italic ?? false
    
    implicitWidth: colLayout.implicitWidth + 2.1
    implicitHeight: showDate ? 28 : 16
    color: "transparent"

    ColumnLayout {
        id: colLayout
        anchors.centerIn: parent
        spacing: 0

        StyledText {
            font.pixelSize: fontSize > 0 ? fontSize : (Appearance.font.pixelSize.small - 1)
            font.weight: bold ? Font.Bold : Font.Normal
            font.italic: italic
            color: Appearance.colors.colOnLayer0
            text: DateTime.time
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }

        StyledText {
            font.pixelSize: fontSize > 0 ? fontSize - 2 : (Appearance.font.pixelSize.tiny - 0.5)
            font.weight: bold ? Font.Bold : Font.Normal
            font.italic: italic
            color: Appearance.colors.colOnLayer0
            text: DateTime.date
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            visible: showDate && DateTime.date.length > 0
        }
    }
}
