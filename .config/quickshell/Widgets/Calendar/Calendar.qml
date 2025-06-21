// Calendar.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "root:/Data" as Data

// Calendar widget with navigation
Rectangle {
    id: calendarRoot
    property var shell

    radius: 20
    color: Qt.lighter(Data.Colors.bgColor, 1.2)

    readonly property date currentDate: new Date()
    property int month: currentDate.getMonth()
    property int year: currentDate.getFullYear()
    readonly property int currentDay: currentDate.getDate()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Month/Year header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Reusable navigation button
            component NavButton: AbstractButton {
                property alias buttonText: buttonLabel.text
                implicitWidth: 30
                implicitHeight: 30

                background: Rectangle {
                    radius: 15
                    color: parent.down ? Qt.darker(Data.Colors.accentColor, 1.2) :
                           parent.hovered ? Qt.lighter(Data.Colors.highlightBg, 1.1) : Data.Colors.highlightBg
                }

                Text {
                    id: buttonLabel
                    anchors.centerIn: parent
                    color: Data.Colors.fgColor
                    font.pixelSize: 16
                    font.bold: true
                }
            }

            // Current month and year display
            Text {
                text: Qt.locale("en_US").monthName(calendarRoot.month) + " " + calendarRoot.year
                color: Data.Colors.accentColor
                font.bold: true
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 18
            }
        }

        // Weekday headers (Monday-Sunday)
        Grid {
            columns: 7
            rowSpacing: 4
            columnSpacing: 0
            Layout.leftMargin: 2
            Layout.fillWidth: true

            Repeater {
                model: ["M", "T", "W", "T", "F", "S", "S"]
                delegate: Text {
                    text: modelData
                    color: Data.Colors.fgColor
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    width: parent.width / 7
                    font.pixelSize: 14
                }
            }
        }

        // Calendar grid
        MonthGrid {
            id: monthGrid
            month: calendarRoot.month
            year: calendarRoot.year
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4
            leftPadding: 0
            rightPadding: 0
            locale: Qt.locale("en_US")
            implicitHeight: 400

            delegate: Rectangle {
                width: 30
                height: 30
                radius: 15

                readonly property bool isCurrentMonth: model.month === calendarRoot.month
                readonly property bool isToday: model.day === calendarRoot.currentDay &&
                                               model.month === calendarRoot.currentDate.getMonth() &&
                                               calendarRoot.year === calendarRoot.currentDate.getFullYear() &&
                                               isCurrentMonth

                // Dynamic styling: today = accent color, current month = normal, other months = dimmed
                color: isToday ? Data.Colors.accentColor :
                       isCurrentMonth ? Data.Colors.bgColor : Qt.darker(Data.Colors.bgColor, 1.4)

                Text {
                    text: model.day
                    anchors.centerIn: parent
                    color: isToday ? Data.Colors.bgColor :
                           isCurrentMonth ? Data.Colors.fgColor : Qt.darker(Data.Colors.fgColor, 1.5)
                    font.bold: isToday
                    font.pixelSize: 14
                    font.family: "JetBrains Mono"
                }
            }
        }
    }
}
