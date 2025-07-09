import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import "./CalendarDayCell.qml"

Item {
    id: root
    property int monthShift: 0
    property var today: new Date()
    property var viewingDate: (function() {
        var d = new Date(today.getFullYear(), today.getMonth() + monthShift, 1);
        return d;
    })()
    property int year: viewingDate.getFullYear()
    property int month: viewingDate.getMonth()
    property int daysInMonth: (new Date(year, month + 1, 0)).getDate()
    property int firstDayOfWeek: (new Date(year, month, 1).getDay() + 6) % 7 // Monday=0
    property int lastDayOfWeek: (new Date(year, month, daysInMonth).getDay() + 6) % 7
    property int totalCells: Math.ceil((firstDayOfWeek + daysInMonth) / 7) * 7
    property var cellDates: (function() {
        var arr = [];
        var prevMonth = month === 0 ? 11 : month - 1;
        var prevYear = month === 0 ? year - 1 : year;
        var prevMonthDays = (new Date(prevYear, prevMonth + 1, 0)).getDate();
        // Fill prev month
        for (var i = 0; i < firstDayOfWeek; ++i) {
            arr.push({
                date: new Date(prevYear, prevMonth, prevMonthDays - firstDayOfWeek + i + 1),
                outOfMonth: true
            });
        }
        // Fill current month
        for (var d = 1; d <= daysInMonth; ++d) {
            arr.push({
                date: new Date(year, month, d),
                outOfMonth: false
            });
        }
        // Fill next month
        var nextMonth = month === 11 ? 0 : month + 1;
        var nextYear = month === 11 ? year + 1 : year;
        for (var i = arr.length; i < totalCells; ++i) {
            arr.push({
                date: new Date(nextYear, nextMonth, i - arr.length + 1),
                outOfMonth: true
            });
        }
        return arr;
    })()

    // Astronomy data
    property var moonPhaseMap: ({})
    property var solsticeMap: ({})
    property string latitude: "44.65" // Halifax, NS
    property string longitude: "-63.57"

    function fetchAstronomyData() {
        var y = year;
        var m = ("0" + (month + 1)).slice(-2);
        var startDate = y + "-" + m + "-01";
        var endDate = y + "-" + m + "-31";
        var url = "https://api.open-meteo.com/v1/astronomy?latitude=" + latitude + "&longitude=" + longitude + "&start_date=" + startDate + "&end_date=" + endDate + "&timezone=auto";
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var data = JSON.parse(xhr.responseText);
                    var moonMap = {};
                    for (var i = 0; i < data.daily.time.length; ++i) {
                        moonMap[data.daily.time[i]] = data.daily.moon_phase[i];
                    }
                    moonPhaseMap = moonMap;
                    var solstice = {};
                    solstice[y + "-06-21"] = "summerSolstice";
                    solstice[y + "-12-21"] = "winterSolstice";
                    solsticeMap = solstice;
                }
            }
        }
        xhr.open("GET", url);
        xhr.send();
    }
    Component.onCompleted: fetchAstronomyData()
    onMonthShiftChanged: fetchAstronomyData()

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
                text: Qt.formatDate(viewingDate, "MMMM yyyy")
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
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                delegate: Text {
                    text: modelData
                    font.pixelSize: 14
                    color: "#CCFFFFFF"
                    horizontalAlignment: Text.AlignHCenter
                    width: 40
                }
            }
        }
        // Calendar grid
        GridLayout {
            columns: 7
            rowSpacing: 4
            columnSpacing: 4
            Repeater {
                model: cellDates.length
                delegate: CalendarDayCell {
                    property var cell: cellDates[index]
                    day: cell.date.getDate()
                    isToday: cell.date.toDateString() === today.toDateString()
                    isPast: cell.date < today && cell.date.getMonth() === today.getMonth() && cell.date.getFullYear() === today.getFullYear()
                    isFuture: cell.date > today && cell.date.getMonth() === today.getMonth() && cell.date.getFullYear() === today.getFullYear()
                    isOutOfMonth: cell.outOfMonth
                    eventType: (function() {
                        var dateStr = cell.date.getFullYear() + "-" + ("0" + (cell.date.getMonth() + 1)).slice(-2) + "-" + ("0" + cell.date.getDate()).slice(-2);
                        if (moonPhaseMap[dateStr] === "Full moon") return "fullMoon";
                        if (moonPhaseMap[dateStr] === "New moon") return "newMoon";
                        if (solsticeMap[dateStr]) return solsticeMap[dateStr];
                        return "";
                    })()
                    tooltip: (function() {
                        var dateStr = cell.date.getFullYear() + "-" + ("0" + (cell.date.getMonth() + 1)).slice(-2) + "-" + ("0" + cell.date.getDate()).slice(-2);
                        if (moonPhaseMap[dateStr]) return moonPhaseMap[dateStr];
                        if (solsticeMap[dateStr]) return solsticeMap[dateStr] === "summerSolstice" ? "Summer Solstice" : "Winter Solstice";
                        return "";
                    })()
                }
            }
        }
    }
} 