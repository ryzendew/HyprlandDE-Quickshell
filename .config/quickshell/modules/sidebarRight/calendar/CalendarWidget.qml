import "root:/modules/common"
import "root:/modules/common/widgets"
import "./calendar_layout.js" as CalendarLayout
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import "./CalendarDayCell.qml"

Item {
    // Layout.topMargin: 10
    anchors.topMargin: 10
    property int monthShift: 0
    property var viewingDate: CalendarLayout.getDateInXMonthsTime(monthShift)
    property var calendarLayout: CalendarLayout.getCalendarLayout(viewingDate, monthShift === 0)
    width: calendarColumn.width
    implicitHeight: calendarColumn.height + 20

    // Astronomy data
    property var astronomyData: ({})
    property var moonPhaseMap: ({})
    property var solsticeMap: ({})
    property string latitude: "44.65" // Halifax, NS
    property string longitude: "-63.57"

    function fetchAstronomyData() {
        var year = viewingDate.getFullYear();
        var month = ("0" + (viewingDate.getMonth() + 1)).slice(-2);
        var startDate = year + "-" + month + "-01";
        var endDate = year + "-" + month + "-31";
        var url = "https://api.open-meteo.com/v1/astronomy?latitude=" + latitude + "&longitude=" + longitude + "&start_date=" + startDate + "&end_date=" + endDate + "&timezone=auto";
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var data = JSON.parse(xhr.responseText);
                    astronomyData = data;
                    // Map moon phases to date strings
                    var moonMap = {};
                    for (var i = 0; i < data.daily.time.length; ++i) {
                        moonMap[data.daily.time[i]] = data.daily.moon_phase[i];
                    }
                    moonPhaseMap = moonMap;
                    // Mark solstices (approximate, for demo)
                    var solstice = {};
                    solstice[year + "-06-21"] = "summerSolstice";
                    solstice[year + "-12-21"] = "winterSolstice";
                    solsticeMap = solstice;
                } else {
                    // Astronomy API error
                }
            }
        }
        xhr.open("GET", url);
        xhr.send();
    }

    // Fetch data when month changes
    onViewingDateChanged: fetchAstronomyData()
    Component.onCompleted: fetchAstronomyData()

    Keys.onPressed: (event) => {
        if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp)
            && event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageDown) {
                monthShift++;
            } else if (event.key === Qt.Key_PageUp) {
                monthShift--;
            }
            event.accepted = true;
        }
    }
    MouseArea {
        anchors.fill: parent
        onWheel: (event) => {
            if (event.angleDelta.y > 0) {
                monthShift--;
            } else if (event.angleDelta.y < 0) {
                monthShift++;
            }
        }
    }

    // Glassy calendar background
    Rectangle {
        id: glassBg
        anchors.centerIn: parent
        width: 340
        radius: 24
        color: "#1A22242A"
        border.color: "#33FFFFFF"
        border.width: 1
        layer.enabled: true
        layer.effect: FastBlur {
            radius: 32
            transparentBorder: true
        }
        z: 0
    }

    ColumnLayout {
        id: calendarColumn
        anchors.centerIn: parent
        spacing: 10
        z: 1
        // Header
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            Button {
                text: "<"
                onClicked: monthShift--
                background: Rectangle { color: "transparent" }
            }
            Text {
                text: viewingDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                font.pixelSize: 20
                font.bold: true
                color: "#FFF"
            }
            Button {
                text: ">"
                onClicked: monthShift++
                background: Rectangle { color: "transparent" }
            }
        }
        // Weekdays
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4
            Repeater {
                model: CalendarLayout.weekDays
                delegate: Text {
                    text: modelData.day
                    font.pixelSize: 14
                    color: "#CCFFFFFF"
                    horizontalAlignment: Text.AlignHCenter
                    width: 40
                }
            }
        }
        // Calendar grid
        ColumnLayout {
            spacing: 4
            Repeater {
                model: 6
                delegate: RowLayout {
                    spacing: 4
                    Repeater {
                        model: 7
                        delegate: CalendarDayCell {
                            // Calculate date info
                            property var cell: calendarLayout[modelData][index]
                            day: cell.day
                            isToday: cell.today === 1
                            isPast: (function() {
                                var d = new Date(viewingDate.getFullYear(), viewingDate.getMonth(), cell.day);
                                var now = new Date();
                                return d < new Date(now.getFullYear(), now.getMonth(), now.getDate());
                            })()
                            isFuture: (function() {
                                var d = new Date(viewingDate.getFullYear(), viewingDate.getMonth(), cell.day);
                                var now = new Date();
                                return d > new Date(now.getFullYear(), now.getMonth(), now.getDate());
                            })()
                            isOutOfMonth: cell.today === -1
                            eventType: (function() {
                                var dateStr = viewingDate.getFullYear() + "-" + ("0" + (viewingDate.getMonth() + 1)).slice(-2) + "-" + ("0" + cell.day).slice(-2);
                                if (moonPhaseMap[dateStr] === "Full moon") return "fullMoon";
                                if (moonPhaseMap[dateStr] === "New moon") return "newMoon";
                                if (solsticeMap[dateStr]) return solsticeMap[dateStr];
                                return "";
                            })()
                            tooltip: (function() {
                                var dateStr = viewingDate.getFullYear() + "-" + ("0" + (viewingDate.getMonth() + 1)).slice(-2) + "-" + ("0" + cell.day).slice(-2);
                                if (moonPhaseMap[dateStr]) return moonPhaseMap[dateStr];
                                if (solsticeMap[dateStr]) return solsticeMap[dateStr] === "summerSolstice" ? "Summer Solstice" : "Winter Solstice";
                                return "";
                            })()
                        }
                    }
                }
            }
        }
    }
}