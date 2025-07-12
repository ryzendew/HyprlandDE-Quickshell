import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Layouts

Rectangle {
    property bool borderless: ConfigOptions.bar?.borderless ?? false
    property bool showSeconds: ConfigOptions.clock?.showSeconds ?? false
    implicitWidth: colLayout.implicitWidth + 2.1
    implicitHeight: 28
    color: "transparent"

    ColumnLayout {
        id: colLayout
        anchors.centerIn: parent
        spacing: 0

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.small - 1  // Make the time text smaller
            color: Appearance.colors.colOnLayer0
            text: DateTime.time
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.tiny - 0.5  // Make the date text smaller
            color: Appearance.colors.colOnLayer0
            text: DateTime.date
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }
    }
}
