import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "root:/modules/common"
import "root:/modules/common/widgets"
import "../todo"

Item {
    id: root
    anchors.fill: parent

    property int currentYear: (new Date()).getFullYear()
    property int currentMonth: (new Date()).getMonth() // 0-indexed
    property var daysOfWeek: [qsTr("Mo"), qsTr("Tu"), qsTr("We"), qsTr("Th"), qsTr("Fr"), qsTr("Sa"), qsTr("Su")]
    property var monthNames: [qsTr("January"), qsTr("February"), qsTr("March"), qsTr("April"), qsTr("May"), qsTr("June"), qsTr("July"), qsTr("August"), qsTr("September"), qsTr("October"), qsTr("November"), qsTr("December")]
    property var daysInMonth: (function(year, month) {
        return new Date(year, month + 1, 0).getDate();
    })(currentYear, currentMonth)
    property int firstDayOfWeek: (function(year, month) {
        let d = new Date(year, month, 1).getDay();
        return d === 0 ? 6 : d - 1; // Make Monday=0, Sunday=6
    })(currentYear, currentMonth)
    property var today: (function() {
        let d = new Date();
        return { year: d.getFullYear(), month: d.getMonth(), day: d.getDate() };
    })()
    property var moonPhases: ({}) // { 'YYYY-MM-DD': {phase: 'Full Moon', icon: 'full_moon'} }
    // In-memory cache for lunar phases by month
    property var moonPhaseCache: ({}) // { 'YYYY-MM': { 'YYYY-MM-DD': {phase, icon} } }

    // --- Holiday support ---
    property string userCountry: "US" // Default fallback
    property var holidays: ({}) // { 'YYYY-MM-DD': {localName, name, countryCode, type} }
    property var holidayCache: ({}) // { 'CC-YYYY': { 'YYYY-MM-DD': {localName, ...} } }

    function fetchMoonPhases(year, month) {
        let monthKey = `${year}-${(month+1).toString().padStart(2, '0')}`;
        if (moonPhaseCache[monthKey]) {
            moonPhases = Object.assign({}, moonPhaseCache[monthKey]);
            console.log('Loaded moon phases from cache for', monthKey);
            return;
        }
        moonPhases = {};
        for (let day = 1; day <= daysInMonth; day++) {
            let dateStr = `${year}-${(month+1).toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}`;
            let url = `https://api.farmsense.net/v1/moonphases/?d=${Math.floor(new Date(year, month, day).getTime()/1000)}`;
            let xhr = new XMLHttpRequest();
            xhr.open('GET', url);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        try {
                            let data = JSON.parse(xhr.responseText);
                            if (data && data[0] && data[0].Phase) {
                                let illum = data[0].Illumination;
                                moonPhases[dateStr] = { phase: data[0].Phase, emoji: getMoonEmoji(data[0].Phase, illum) };
                                moonPhases = Object.assign({}, moonPhases); // QML reactivity fix
                                // Save to cache
                                if (!moonPhaseCache[monthKey]) moonPhaseCache[monthKey] = {};
                                moonPhaseCache[monthKey][dateStr] = moonPhases[dateStr];
                                console.log('Moon phase for', dateStr, ':', data[0].Phase, 'illum:', illum, 'icon:', getMoonEmoji(data[0].Phase, illum));
                            }
                        } catch (e) { console.log('Moon phase parse error', e); }
                    } else {
                        console.log('Moon phase API error', xhr.status, url);
                    }
                }
            }
            xhr.send();
        }
    }

    function getMoonEmoji(phase, illum) {
        // Use illumination for full/new moon
        if (illum !== undefined) {
            if (illum >= 0.98) return '🌕'; // Full moon
            if (illum <= 0.02) return '🌑'; // New moon
        }
        if (phase.indexOf('First Quarter') !== -1) return '🌓';
        if (phase.indexOf('Last Quarter') !== -1) return '🌗';
        if (phase.indexOf('Waxing Crescent') !== -1) return '🌒';
        if (phase.indexOf('Waning Crescent') !== -1) return '🌘';
        if (phase.indexOf('Waxing Gibbous') !== -1) return '🌔';
        if (phase.indexOf('Waning Gibbous') !== -1) return '🌖';
        return '';
    }

    function getHolidayEmoji(holiday) {
        if (!holiday) return '';
        
        let name = (holiday.localName || '').toLowerCase();
        let englishName = (holiday.name || '').toLowerCase();
        let type = (holiday.type || '').toLowerCase();
        let countryCode = (holiday.countryCode || '').toLowerCase();
        
        // Country-specific flags
        if (name.includes('canada day') || englishName.includes('canada day')) return '🇨🇦';
        if (name.includes('australia day') || englishName.includes('australia day')) return '🇦🇺';
        if (name.includes('bastille day') || englishName.includes('bastille day')) return '🇫🇷';
        if (name.includes('german unity day') || englishName.includes('german unity day')) return '🇩🇪';
        if (name.includes('constitution day') || englishName.includes('constitution day')) return '🇯🇵';
        if (name.includes('queen') || englishName.includes('queen')) return '👑';
        
        // Christmas and New Year
        if (name.includes('christmas') || englishName.includes('christmas')) return '🎄';
        if (name.includes('new year') || englishName.includes('new year') || name.includes('new year')) return '🎆';
        
        // Independence Day / National Day
        if (name.includes('independence') || englishName.includes('independence')) {
            // Country-specific independence flags
            if (countryCode === 'us') return '🇺🇸';
            if (countryCode === 'mx') return '🇲🇽';
            if (countryCode === 'br') return '🇧🇷';
            if (countryCode === 'ar') return '🇦🇷';
            if (countryCode === 'in') return '🇮🇳';
            if (countryCode === 'pk') return '🇵🇰';
            if (countryCode === 'bd') return '🇧🇩';
            if (countryCode === 'ng') return '🇳🇬';
            if (countryCode === 'ke') return '🇰🇪';
            if (countryCode === 'za') return '🇿🇦';
            return '🏛️'; // Generic for other countries
        }
        
        if (name.includes('national day') || englishName.includes('national day')) return '🏛️';
        
        // Easter
        if (name.includes('easter') || englishName.includes('easter')) return '🐰';
        
        // Labor Day / Workers Day
        if (name.includes('labor') || englishName.includes('labor') || name.includes('workers')) return '👷';
        
        // Thanksgiving
        if (name.includes('thanksgiving') || englishName.includes('thanksgiving')) return '🦃';
        
        // Halloween
        if (name.includes('halloween') || englishName.includes('halloween')) return '🎃';
        
        // Valentine's Day
        if (name.includes('valentine') || englishName.includes('valentine')) return '💝';
        
        // Mother's Day / Father's Day
        if (name.includes('mother') || englishName.includes('mother')) return '🌷';
        if (name.includes('father') || englishName.includes('father')) return '👔';
        
        // Memorial Day / Veterans Day
        if (name.includes('memorial') || englishName.includes('memorial')) return '🕊️';
        if (name.includes('veterans') || englishName.includes('veterans')) return '🎖️';
        
        // Religious holidays
        if (name.includes('good friday') || englishName.includes('good friday')) return '✝️';
        if (name.includes('ascension') || englishName.includes('ascension')) return '⛪';
        if (name.includes('pentecost') || englishName.includes('pentecost')) return '🕊️';
        if (name.includes('corpus christi') || englishName.includes('corpus christi')) return '⛪';
        if (name.includes('assumption') || englishName.includes('assumption')) return '🙏';
        if (name.includes('all saints') || englishName.includes('all saints')) return '👼';
        if (name.includes('immaculate') || englishName.includes('immaculate')) return '⛪';
        
        // Bank holidays / Public holidays
        if (type === 'public' || type === 'bank') return '🏦';
        
        // Observance
        if (type === 'observance') return '📅';
        
        // Default for other holidays
        return '🎉';
    }

    function formatMoonPhase(phase) {
        if (!phase) return '';
        
        // Make the phase names more readable and user-friendly
        let formatted = phase;
        
        // Replace technical terms with more readable ones
        formatted = formatted.replace('First Quarter', 'First Quarter Moon');
        formatted = formatted.replace('Last Quarter', 'Last Quarter Moon');
        formatted = formatted.replace('Waxing Crescent', 'Waxing Crescent');
        formatted = formatted.replace('Waning Crescent', 'Waning Crescent');
        formatted = formatted.replace('Waxing Gibbous', 'Waxing Gibbous');
        formatted = formatted.replace('Waning Gibbous', 'Waning Gibbous');
        formatted = formatted.replace('Full Moon', '🌕 Full Moon');
        formatted = formatted.replace('New Moon', '🌑 New Moon');
        
        return formatted;
    }

    function fetchUserCountry() {
        let xhr = new XMLHttpRequest();
        xhr.open('GET', 'https://ipapi.co/json/');
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    let data = JSON.parse(xhr.responseText);
                    if (data && data.country) {
                        userCountry = data.country;
                        console.log('Detected country:', userCountry);
                        fetchHolidays(currentYear, userCountry);
                    }
                } catch (e) { console.log('Country parse error', e); }
            }
        }
        xhr.send();
    }

    function fetchHolidays(year, country) {
        let cacheKey = `${country}-${year}`;
        if (holidayCache[cacheKey]) {
            holidays = Object.assign({}, holidayCache[cacheKey]);
            console.log('Loaded holidays from cache for', cacheKey);
            return;
        }
        holidays = {};
        let xhr = new XMLHttpRequest();
        xhr.open('GET', `https://date.nager.at/api/v3/PublicHolidays/${year}/${country}`);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    let data = JSON.parse(xhr.responseText);
                    if (Array.isArray(data)) {
                        for (let i = 0; i < data.length; i++) {
                            let d = data[i];
                            holidays[d.date] = d;
                        }
                        holidayCache[cacheKey] = Object.assign({}, holidays);
                        holidays = Object.assign({}, holidays);
                        console.log('Fetched holidays for', country, year, holidays);
                    }
                } catch (e) { console.log('Holiday parse error', e); }
            }
        }
        xhr.send();
    }

    // Refetch when month/year changes
    onCurrentMonthChanged: fetchMoonPhases(currentYear, currentMonth)
    onCurrentYearChanged: fetchMoonPhases(currentYear, currentMonth)
    onUserCountryChanged: fetchHolidays(currentYear, userCountry)
    Component.onCompleted: {
        fetchUserCountry();
        fetchMoonPhases(currentYear, currentMonth);
        fetchHolidays(currentYear, userCountry);
    }

    // --- Modern background and header ---
    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.13)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.topMargin: 6
        anchors.bottomMargin: 12
        spacing: 6
        // Calendar section (top, 60%)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: parent ? parent.height * 0.6 : 320
            radius: 14
            color: Qt.rgba(1, 1, 1, 0.13)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.18)
            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.topMargin: 10
                anchors.bottomMargin: 8
                spacing: 10
                // Calendar header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    MaterialSymbol {
                        text: "calendar_month"
                        iconSize: 22
                        color: "#fff"
                        opacity: 0.7
                    }
                    Text {
                        text: monthNames[currentMonth] + " " + currentYear
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                        color: "#fff"
                        verticalAlignment: Text.AlignVCenter
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Item { Layout.fillWidth: true }
                    // Left navigation button
                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: "transparent"
                        border.width: 0
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "chevron_left"
                            iconSize: 22
                            color: "#fff"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (currentMonth === 0) {
                                    currentMonth = 11; currentYear--;
                                } else {
                                    currentMonth--;
                                }
                            }
                        }
                    }
                    // Right navigation button
                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: "transparent"
                        border.width: 0
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "chevron_right"
                            iconSize: 22
                            color: "#fff"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (currentMonth === 11) {
                                    currentMonth = 0; currentYear++;
                                } else {
                                    currentMonth++;
                                }
                            }
                        }
                    }
                }
                // Weekday headers
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Repeater {
                        model: daysOfWeek
                        delegate: Text {
                            text: modelData
                            font.pixelSize: 15
                            font.weight: Font.Medium
                            color: "#fff"
                            opacity: 0.7
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }
                    }
                }
                // Calendar grid
                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 7
                    rowSpacing: 6
                    columnSpacing: 6
                    Layout.topMargin: 8 // Move grid closer to header
                    // Empty cells before first day
                    Repeater {
                        model: firstDayOfWeek
                        delegate: Item { Layout.fillWidth: true; Layout.fillHeight: true }
                    }
                    // Days of month
                    Repeater {
                        model: daysInMonth
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 10
                            color: (today.year === currentYear && today.month === currentMonth && today.day === (index+1)) ? Qt.rgba(1,0,0,0.85) : Qt.rgba(1,1,1,0.16)
                            border.width: 1
                            border.color: Qt.rgba(1,1,1,0.22)
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {/* future: show day details */}
                            }
                            // Day number (top left)
                            Text {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.leftMargin: 6
                                anchors.topMargin: 6
                                text: (index+1).toString()
                                font.pixelSize: 18
                                font.weight: Font.Medium
                                color: "#fff"
                            }
                            // Moon phase emoji (bottom right)
                            Text {
                                id: moonEmoji
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.rightMargin: 6
                                anchors.bottomMargin: 6
                                font.pixelSize: 18
                                color: "#fff"
                                text: root.moonPhases[`${currentYear}-${(currentMonth+1).toString().padStart(2, '0')}-${(index+1).toString().padStart(2, '0')}`]?.emoji || ""
                                visible: !!root.moonPhases[`${currentYear}-${(currentMonth+1).toString().padStart(2, '0')}-${(index+1).toString().padStart(2, '0')}`]
                                opacity: 0.5
                                
                                property var moonData: root.moonPhases[`${currentYear}-${(currentMonth+1).toString().padStart(2, '0')}-${(index+1).toString().padStart(2, '0')}`]
                                
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: {
                                        if (moonEmoji.moonData) {
                                            moonTooltip.visible = true;
                                        }
                                    }
                                    onExited: {
                                        moonTooltip.visible = false;
                                    }
                                }
                                
                                // Moon phase tooltip
                                Rectangle {
                                    id: moonTooltip
                                    anchors.bottom: parent.top
                                    anchors.right: parent.right
                                    anchors.bottomMargin: 8
                                    width: moonTooltipText.width + 16
                                    height: moonTooltipText.height + 12
                                    radius: 8
                                    color: "black"
                                    border.width: 1
                                    border.color: "white"
                                    visible: false
                                    z: 1000
                                    opacity: 1.0
                                    
                                    Text {
                                        id: moonTooltipText
                                        anchors.centerIn: parent
                                        text: moonEmoji.moonData ? formatMoonPhase(moonEmoji.moonData.phase) : ""
                                        font.pixelSize: 13
                                        font.weight: Font.Medium
                                        color: "#fff"
                                        horizontalAlignment: Text.AlignHCenter
                                        lineHeight: 1.3
                                    }
                                    
                                    // Arrow pointing down to the moon emoji
                                    Rectangle {
                                        anchors.top: parent.bottom
                                        anchors.right: parent.right
                                        anchors.rightMargin: 4
                                        width: 8
                                        height: 4
                                        color: "black"
                                        border.width: 1
                                        border.color: "white"
                                        
                                        Rectangle {
                                            anchors.top: parent.top
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            height: 4
                                            color: "black"
                                        }
                                    }
                                }
                            }
                            // Holiday emoji/flag (bottom left)
                            Text {
                                id: holidayEmoji
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom
                                anchors.leftMargin: 6
                                anchors.bottomMargin: 6
                                font.pixelSize: 16
                                text: getHolidayEmoji(holidays[`${currentYear}-${(currentMonth+1).toString().padStart(2, '0')}-${(index+1).toString().padStart(2, '0')}`])
                                visible: !!holidays[`${currentYear}-${(currentMonth+1).toString().padStart(2, '0')}-${(index+1).toString().padStart(2, '0')}`]
                                opacity: 0.9
                                
                                property var holidayData: holidays[`${currentYear}-${(currentMonth+1).toString().padStart(2, '0')}-${(index+1).toString().padStart(2, '0')}`]
                                
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: {
                                        if (holidayEmoji.holidayData) {
                                            holidayTooltip.visible = true;
                                        }
                                    }
                                    onExited: {
                                        holidayTooltip.visible = false;
                                    }
                                }
                                
                                // Custom tooltip
                                Rectangle {
                                    id: holidayTooltip
                                    anchors.bottom: parent.top
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottomMargin: 8
                                    width: tooltipText.width + 16
                                    height: tooltipText.height + 12
                                    radius: 8
                                    color: "#000000"
                                    border.width: 1
                                    border.color: "#ffffff"
                                    visible: false
                                    z: 1000
                                    opacity: 1.0
                                    
                                    Text {
                                        id: tooltipText
                                        anchors.centerIn: parent
                                        text: holidayEmoji.holidayData ? 
                                            holidayEmoji.holidayData.localName + 
                                            (holidayEmoji.holidayData.name && holidayEmoji.holidayData.name !== holidayEmoji.holidayData.localName ? 
                                                `\n(${holidayEmoji.holidayData.name})` : "") +
                                            (holidayEmoji.holidayData.type ? `\nType: ${holidayEmoji.holidayData.type}` : "") : ""
                                        font.pixelSize: 12
                                        color: "#fff"
                                        horizontalAlignment: Text.AlignHCenter
                                        lineHeight: 1.2
                                    }
                                    
                                    // Arrow pointing down to the dot
                                    Rectangle {
                                        anchors.top: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 8
                                        height: 4
                                        color: "#000000"
                                        border.width: 1
                                        border.color: "#ffffff"
                                        
                                        Rectangle {
                                            anchors.top: parent.top
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            height: 4
                                            color: "#000000"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        // Todo section (bottom, 40%)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: parent ? parent.height * 0.4 : 220
            radius: 14
            color: Qt.rgba(1, 1, 1, 0.10)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.15)
            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 2
                anchors.rightMargin: 2
                anchors.topMargin: 2
                anchors.bottomMargin: 2
                spacing: 4
                // Removed duplicate header row for 'Tasks'
                TodoWidget {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
} 