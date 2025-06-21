import QtQuick
import QtQuick.Controls
import "root:/Data" as Data

// Calendar button for the top panel
Rectangle {
    id: calendarButton
    width: 40
    height: 80
    color: Qt.darker(Data.Colors.bgColor, 1.15)
    radius: 20

    property bool containsMouse: calendarMouseArea.containsMouse
    property bool calendarVisible: false
    property var calendarPopup: null
    property var shell: null  // Shell reference from parent

    signal entered()
    signal exited()

    onContainsMouseChanged: {
        if (containsMouse) {
            entered()
        } else {
            exited()
        }
    }

    MouseArea {
        id: calendarMouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            toggleCalendar()
        }
    }

    Label {
        anchors.centerIn: parent
        text: "calendar_month"
        font.pixelSize: 24
        font.family: "Material Symbols Outlined"
        color: calendarButton.containsMouse || calendarButton.calendarVisible ? Data.Colors.accentColor : Data.Colors.fgColor
    }

    function toggleCalendar() {
        if (!calendarPopup) {
            var component = Qt.createComponent("root:/Widgets/Calendar/CalendarPopup.qml")
            if (component.status === Component.Ready) {
                calendarPopup = component.createObject(calendarButton.parent, {
                    "targetX": calendarButton.x + calendarButton.width + 10,
                    "shell": calendarButton.shell
                })
            } else if (component.status === Component.Error) {
                console.log("Error loading calendar:", component.errorString())
                return
            }
        }
        
        if (calendarPopup) {
            calendarVisible = !calendarVisible
            calendarPopup.setClickMode(calendarVisible)
        }
    }

    function hideCalendar() {
        if (calendarPopup) {
            calendarVisible = false
            calendarPopup.setClickMode(false)
        }
    }
} 