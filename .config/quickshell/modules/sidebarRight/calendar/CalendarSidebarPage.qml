import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
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
    property string userCountry: "CA" // Default fallback to Canada
    property var holidays: ({}) // { 'YYYY-MM-DD': {localName, name, countryCode, type} }
    property var holidayCache: ({}) // { 'CC-YYYY': { 'YYYY-MM-DD': {localName, ...} } }
    
    // Cultural holidays not in the API (fixed dates) - Canada-focused
    property var culturalHolidays: ({
        // January
        "01-01": { localName: "New Year's Day", name: "New Year's Day", emoji: "🎆" },
        
        // February
        "02-14": { localName: "Valentine's Day", name: "Valentine's Day", emoji: "💝" },
        
        // March
        "03-08": { localName: "International Women's Day", name: "International Women's Day", emoji: "👩" },
        "03-17": { localName: "Saint Patrick's Day", name: "Saint Patrick's Day", emoji: "☘️" },
        
        // April
        "04-01": { localName: "April Fools' Day", name: "April Fools' Day", emoji: "🤪" },
        "04-22": { localName: "Earth Day", name: "Earth Day", emoji: "🌍" },
        
        // May
        "05-01": { localName: "May Day", name: "May Day", emoji: "🌺" },
        
        // June
        "06-21": { localName: "Summer Solstice", name: "Summer Solstice", emoji: "☀️" },
        "06-24": { localName: "Saint-Jean-Baptiste Day", name: "Saint-Jean-Baptiste Day", emoji: "🇨🇦" },
        
        // July
        "07-01": { localName: "Canada Day", name: "Canada Day", emoji: "🇨🇦" },
        
        // August
        "08-15": { localName: "Assumption Day", name: "Assumption Day", emoji: "🙏" },
        
        // September
        "09-22": { localName: "Autumn Equinox", name: "Autumn Equinox", emoji: "🍂" },
        
        // October
        "10-31": { localName: "Halloween", name: "Halloween", emoji: "🎃" },
        
        // November
        "11-11": { localName: "Remembrance Day", name: "Remembrance Day", emoji: "🕊️" },
        
        // December
        "12-21": { localName: "Winter Solstice", name: "Winter Solstice", emoji: "❄️" },
        "12-24": { localName: "Christmas Eve", name: "Christmas Eve", emoji: "🎄" },
        "12-25": { localName: "Christmas Day", name: "Christmas Day", emoji: "🎄" },
        "12-26": { localName: "Boxing Day", name: "Boxing Day", emoji: "🎁" },
        "12-31": { localName: "New Year's Eve", name: "New Year's Eve", emoji: "🎆" }
    })
    
    // Variable date holidays (calculated each year)
    property var variableHolidays: ({}) // Will be populated with calculated dates
    
    // Todo tasks integration
    property var todoTasks: ({}) // { 'YYYY-MM-DD': [{content, priority, done, ...}] }
    
    function updateTodoTasks() {
        todoTasks = {};
        if (Todo && Todo.list) {
            Todo.list.forEach(function(task, index) {
                if (task.dueDate && !task.done) {
                    // Check if the task is for the current month
                    let taskDate = new Date(task.dueDate);
                    let taskYear = taskDate.getFullYear();
                    let taskMonth = taskDate.getMonth();
                    
                    if (taskYear === currentYear && taskMonth === currentMonth) {
                        if (!todoTasks[task.dueDate]) {
                            todoTasks[task.dueDate] = [];
                        }
                        todoTasks[task.dueDate].push(task);
                    }
                }
            });
        }
    }
    
    // Listen for Todo service changes
    Connections {
        target: Todo
        function onListChanged() {
            updateTodoTasks();
        }
    }
    
    function getTaskEmoji(task) {
        let content = (task.content || '').toLowerCase();
        
        // Work/Office related
        if (content.includes('meeting') || content.includes('call') || content.includes('presentation')) return '📞';
        if (content.includes('email') || content.includes('mail')) return '📧';
        if (content.includes('report') || content.includes('document')) return '📄';
        if (content.includes('deadline') || content.includes('project')) return '📋';
        if (content.includes('work') || content.includes('office')) return '💼';
        
        // Shopping/Errands
        if (content.includes('buy') || content.includes('shop') || content.includes('purchase')) return '🛒';
        if (content.includes('grocery') || content.includes('food')) return '🛒';
        
        // Health/Medical
        if (content.includes('doctor') || content.includes('appointment') || content.includes('medical')) return '🏥';
        if (content.includes('gym') || content.includes('workout') || content.includes('exercise')) return '💪';
        
        // Travel
        if (content.includes('travel') || content.includes('trip') || content.includes('vacation')) return '✈️';
        if (content.includes('flight') || content.includes('airport')) return '✈️';
        
        // Home/Personal
        if (content.includes('clean') || content.includes('laundry') || content.includes('house')) return '🏠';
        if (content.includes('birthday') || content.includes('party')) return '🎉';
        if (content.includes('dinner') || content.includes('lunch') || content.includes('meal')) return '🍽️';
        
        // Study/Education
        if (content.includes('study') || content.includes('homework') || content.includes('exam')) return '📚';
        if (content.includes('class') || content.includes('course') || content.includes('lecture')) return '🎓';
        
        // Default based on priority
        if (task.priority === 'high') return '🔴';
        if (task.priority === 'medium') return '🟡';
        if (task.priority === 'low') return '🟢';
        
        return '📝';
    }

    function calculateEaster(year) {
        // Meeus/Jones/Butcher algorithm
        let a = year % 19;
        let b = Math.floor(year / 100);
        let c = year % 100;
        let d = Math.floor(b / 4);
        let e = b % 4;
        let f = Math.floor((b + 8) / 25);
        let g = Math.floor((b - f + 1) / 3);
        let h = (19 * a + b - d - g + 15) % 30;
        let i = Math.floor(c / 4);
        let k = c % 4;
        let l = (32 + 2 * e + 2 * i - h - k) % 7;
        let m = Math.floor((a + 11 * h + 22 * l) / 451);
        let month = Math.floor((h + l - 7 * m + 114) / 31);
        let day = ((h + l - 7 * m + 114) % 31) + 1;
        return new Date(year, month - 1, day);
    }

    function calculateVariableHolidays(year) {
        let easter = calculateEaster(year);
        let easterDate = easter.getDate();
        let easterMonth = easter.getMonth();
        
        let holidays = {};
        
        // Easter Sunday
        let easterKey = `${year}-${(easterMonth+1).toString().padStart(2, '0')}-${easterDate.toString().padStart(2, '0')}`;
        holidays[easterKey] = { localName: "Easter Sunday", name: "Easter Sunday", emoji: "🐰" };
        
        // Good Friday (2 days before Easter)
        let goodFriday = new Date(easter);
        goodFriday.setDate(easterDate - 2);
        let goodFridayKey = `${year}-${(goodFriday.getMonth()+1).toString().padStart(2, '0')}-${goodFriday.getDate().toString().padStart(2, '0')}`;
        holidays[goodFridayKey] = { localName: "Good Friday", name: "Good Friday", emoji: "✝️" };
        
        // Easter Monday (1 day after Easter)
        let easterMonday = new Date(easter);
        easterMonday.setDate(easterDate + 1);
        let easterMondayKey = `${year}-${(easterMonday.getMonth()+1).toString().padStart(2, '0')}-${easterMonday.getDate().toString().padStart(2, '0')}`;
        holidays[easterMondayKey] = { localName: "Easter Monday", name: "Easter Monday", emoji: "🐰" };
        
        // Mother's Day (2nd Sunday in May)
        let mothersDay = new Date(year, 4, 1); // May 1st
        let dayOfWeek = mothersDay.getDay();
        let daysToAdd = (7 - dayOfWeek + 7) % 7; // Days to next Sunday
        mothersDay.setDate(1 + daysToAdd + 7); // Add 7 more days for 2nd Sunday
        let mothersDayKey = `${year}-05-${mothersDay.getDate().toString().padStart(2, '0')}`;
        holidays[mothersDayKey] = { localName: "Mother's Day", name: "Mother's Day", emoji: "🌷" };
        
        // Father's Day (3rd Sunday in June)
        let fathersDay = new Date(year, 5, 1); // June 1st
        dayOfWeek = fathersDay.getDay();
        daysToAdd = (7 - dayOfWeek + 7) % 7; // Days to next Sunday
        fathersDay.setDate(1 + daysToAdd + 14); // Add 14 more days for 3rd Sunday
        let fathersDayKey = `${year}-06-${fathersDay.getDate().toString().padStart(2, '0')}`;
        holidays[fathersDayKey] = { localName: "Father's Day", name: "Father's Day", emoji: "👔" };
        
        // Memorial Day (Last Monday in May)
        let memorialDay = new Date(year, 4, 31); // May 31st
        dayOfWeek = memorialDay.getDay();
        let memorialDaysToSubtract = (dayOfWeek + 6) % 7; // Days to previous Monday
        memorialDay.setDate(31 - memorialDaysToSubtract);
        let memorialDayKey = `${year}-05-${memorialDay.getDate().toString().padStart(2, '0')}`;
        holidays[memorialDayKey] = { localName: "Memorial Day", name: "Memorial Day", emoji: "🕊️" };
        
        // Labor Day (1st Monday in September)
        let laborDay = new Date(year, 8, 1); // September 1st
        dayOfWeek = laborDay.getDay();
        daysToAdd = (7 - dayOfWeek + 1) % 7; // Days to next Monday
        laborDay.setDate(1 + daysToAdd);
        let laborDayKey = `${year}-09-${laborDay.getDate().toString().padStart(2, '0')}`;
        holidays[laborDayKey] = { localName: "Labor Day", name: "Labor Day", emoji: "👷" };
        
        // Canadian Thanksgiving (2nd Monday in October)
        let thanksgiving = new Date(year, 9, 1); // October 1st
        dayOfWeek = thanksgiving.getDay();
        daysToAdd = (7 - dayOfWeek + 1) % 7; // Days to next Monday
        thanksgiving.setDate(1 + daysToAdd + 7); // Add 7 more days for 2nd Monday
        let thanksgivingKey = `${year}-10-${thanksgiving.getDate().toString().padStart(2, '0')}`;
        holidays[thanksgivingKey] = { localName: "Thanksgiving Day", name: "Thanksgiving Day", emoji: "🦃" };
        
        // Victoria Day (Last Monday before May 25)
        let victoriaDay = new Date(year, 4, 25); // May 25th
        dayOfWeek = victoriaDay.getDay();
        let victoriaDaysToSubtract = (dayOfWeek + 6) % 7; // Days to previous Monday
        victoriaDay.setDate(25 - victoriaDaysToSubtract);
        let victoriaDayKey = `${year}-05-${victoriaDay.getDate().toString().padStart(2, '0')}`;
        holidays[victoriaDayKey] = { localName: "Victoria Day", name: "Victoria Day", emoji: "👑" };
        
        // Labour Day (1st Monday in September)
        let labourDay = new Date(year, 8, 1); // September 1st
        dayOfWeek = labourDay.getDay();
        daysToAdd = (7 - dayOfWeek + 1) % 7; // Days to next Monday
        labourDay.setDate(1 + daysToAdd);
        let labourDayKey = `${year}-09-${labourDay.getDate().toString().padStart(2, '0')}`;
        holidays[labourDayKey] = { localName: "Labour Day", name: "Labour Day", emoji: "👷" };
        
        return holidays;
    }

    function fetchMoonPhases(year, month) {
        let monthKey = `${year}-${(month+1).toString().padStart(2, '0')}`;
        if (moonPhaseCache[monthKey]) {
            moonPhases = Object.assign({}, moonPhaseCache[monthKey]);
            return;
        }
        
        moonPhases = {};
        
        // Use a more reliable moon phase calculation as fallback
        let fallbackMoonPhases = calculateMoonPhasesFallback(year, month);
        
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
                            } else {
                                // Use fallback if API doesn't return valid data
                                if (fallbackMoonPhases[dateStr]) {
                                    moonPhases[dateStr] = fallbackMoonPhases[dateStr];
                                    moonPhases = Object.assign({}, moonPhases);
                                    if (!moonPhaseCache[monthKey]) moonPhaseCache[monthKey] = {};
                                    moonPhaseCache[monthKey][dateStr] = moonPhases[dateStr];
                                }
                            }
                        } catch (e) {
                            // Use fallback on parse error
                            if (fallbackMoonPhases[dateStr]) {
                                moonPhases[dateStr] = fallbackMoonPhases[dateStr];
                                moonPhases = Object.assign({}, moonPhases);
                                if (!moonPhaseCache[monthKey]) moonPhaseCache[monthKey] = {};
                                moonPhaseCache[monthKey][dateStr] = moonPhases[dateStr];
                            }
                        }
                    } else {
                        // Use fallback on API error
                        if (fallbackMoonPhases[dateStr]) {
                            moonPhases[dateStr] = fallbackMoonPhases[dateStr];
                            moonPhases = Object.assign({}, moonPhases);
                            if (!moonPhaseCache[monthKey]) moonPhaseCache[monthKey] = {};
                            moonPhaseCache[monthKey][dateStr] = moonPhases[dateStr];
                        }
                    }
                }
            }
            xhr.send();
        }
    }

    function calculateMoonPhasesFallback(year, month) {
        // Simple moon phase calculation as fallback
        let phases = {};
        let daysInMonth = new Date(year, month + 1, 0).getDate();
        
        // Approximate moon phases (this is a simplified calculation)
        // Full moon cycle is approximately 29.5 days
        let lunarCycle = 29.53058867;
        let knownNewMoon = new Date(2000, 0, 6); // Known new moon date
        let daysSinceKnown = (new Date(year, month, 1) - knownNewMoon) / (1000 * 60 * 60 * 24);
        let phaseAtStart = (daysSinceKnown % lunarCycle) / lunarCycle;
        
        for (let day = 1; day <= daysInMonth; day++) {
            let dateStr = `${year}-${(month+1).toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}`;
            let daysFromStart = day - 1;
            let phase = (phaseAtStart + daysFromStart / lunarCycle) % 1;
            
            let phaseName, emoji;
            if (phase < 0.0625 || phase >= 0.9375) {
                phaseName = "New Moon";
                emoji = "🌑";
            } else if (phase < 0.1875) {
                phaseName = "Waxing Crescent";
                emoji = "🌒";
            } else if (phase < 0.3125) {
                phaseName = "First Quarter";
                emoji = "🌓";
            } else if (phase < 0.4375) {
                phaseName = "Waxing Gibbous";
                emoji = "🌔";
            } else if (phase < 0.5625) {
                phaseName = "Full Moon";
                emoji = "🌕";
            } else if (phase < 0.6875) {
                phaseName = "Waning Gibbous";
                emoji = "🌖";
            } else if (phase < 0.8125) {
                phaseName = "Last Quarter";
                emoji = "🌗";
            } else {
                phaseName = "Waning Crescent";
                emoji = "🌘";
            }
            
            phases[dateStr] = { phase: phaseName, emoji: emoji };
        }
        
        return phases;
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
        
        // If holiday has a pre-defined emoji, use it
        if (holiday.emoji) return holiday.emoji;
        
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
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                try {
                    let data = JSON.parse(xhr.responseText);
                    if (data && data.country) {
                        userCountry = data.country;
                            fetchHolidays(currentYear, userCountry);
                        } else {
                            userCountry = "CA"; // Fallback to Canada
                        fetchHolidays(currentYear, userCountry);
                    }
                } catch (e) {
                        userCountry = "CA"; // Fallback to Canada
                        fetchHolidays(currentYear, userCountry);
                    }
                } else {
                    userCountry = "CA"; // Fallback to Canada
                    fetchHolidays(currentYear, userCountry);
                }
            }
        }
        xhr.send();
    }

    function fetchHolidays(year, country) {
        let cacheKey = `${country}-${year}`;
        
        if (holidayCache[cacheKey]) {
            holidays = Object.assign({}, holidayCache[cacheKey]);
            return;
        }
        
        holidays = {};
        
        // Start with API holidays
        let xhr = new XMLHttpRequest();
        xhr.open('GET', `https://date.nager.at/api/v3/PublicHolidays/${year}/${country}`);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                try {
                    let data = JSON.parse(xhr.responseText);
                    if (Array.isArray(data)) {
                        for (let i = 0; i < data.length; i++) {
                            let d = data[i];
                            holidays[d.date] = d;
                        }
                        }
                    } catch (e) {
                        // Holiday parse error - continue with fallback
                    }
                } else {
                    // Holiday API failed - continue with fallback
                }
                        
                // Always add cultural holidays (fixed dates) as fallback
                        for (let monthDay in culturalHolidays) {
                            let holiday = culturalHolidays[monthDay];
                            let dateKey = `${year}-${monthDay}`;
                            // Only add if not already present from API
                            if (!holidays[dateKey]) {
                                holidays[dateKey] = {
                                    date: dateKey,
                                    localName: holiday.localName,
                                    name: holiday.name,
                                    countryCode: country,
                                    type: "Observance",
                                    emoji: holiday.emoji
                                };
                            }
                        }
                        
                // Always add variable date holidays
                        let variableHolidays = calculateVariableHolidays(year);
                        for (let dateKey in variableHolidays) {
                            let holiday = variableHolidays[dateKey];
                            // Only add if not already present from API
                            if (!holidays[dateKey]) {
                                holidays[dateKey] = {
                                    date: dateKey,
                                    localName: holiday.localName,
                                    name: holiday.name,
                                    countryCode: country,
                                    type: "Observance",
                                    emoji: holiday.emoji
                                };
                            }
                        }
                        
                        holidayCache[cacheKey] = Object.assign({}, holidays);
                        holidays = Object.assign({}, holidays);
            }
        }
        xhr.send();
    }

    // Refetch when month/year changes
    onCurrentMonthChanged: {
        fetchMoonPhases(currentYear, currentMonth);
        fetchHolidays(currentYear, userCountry);
    }
    onCurrentYearChanged: {
        fetchMoonPhases(currentYear, currentMonth);
        fetchHolidays(currentYear, userCountry);
    }
    onUserCountryChanged: fetchHolidays(currentYear, userCountry)
    

    
    Component.onCompleted: {
        fetchUserCountry(); // This will trigger fetchHolidays when country is detected
        fetchMoonPhases(currentYear, currentMonth);
        updateTodoTasks();
    }
    
    // Timer to periodically update todo tasks
    Timer {
        interval: 2000 // Update every 2 seconds
        running: true
        repeat: true
        onTriggered: {
            updateTodoTasks();
        }
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
                            color: (today.year === currentYear && today.month === currentMonth && today.day === (index+1)) ? Qt.rgba(1,0,0,0.45) : Qt.rgba(1,1,1,0.16)
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
                            
                            // Todo emoji indicator (center)
                            Text {
                                anchors.centerIn: parent
                                font.pixelSize: 14
                                text: todoTasks[`${currentYear}-${(currentMonth+1).toString().padStart(2, '0')}-${(index+1).toString().padStart(2, '0')}`] && 
                                      todoTasks[`${currentYear}-${(currentMonth+1).toString().padStart(2, '0')}-${(index+1).toString().padStart(2, '0')}`].length > 0 ? 
                                      getTaskEmoji(todoTasks[`${currentYear}-${(currentMonth+1).toString().padStart(2, '0')}-${(index+1).toString().padStart(2, '0')}`][0]) : ""
                                color: "#fff"
                                opacity: 0.8
                                visible: !!todoTasks[`${currentYear}-${(currentMonth+1).toString().padStart(2, '0')}-${(index+1).toString().padStart(2, '0')}`]
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
                            
                            // Todo task indicators (top right corner)
                            Item {
                                id: todoIndicator
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.rightMargin: 4
                                anchors.topMargin: 4
                                width: todoTasks[`${currentYear}-${(currentMonth+1).toString().padStart(2, '0')}-${(index+1).toString().padStart(2, '0')}`] ? 16 : 0
                                height: width
                                visible: !!todoTasks[`${currentYear}-${(currentMonth+1).toString().padStart(2, '0')}-${(index+1).toString().padStart(2, '0')}`]
                                
                                property var dayTasks: todoTasks[`${currentYear}-${(currentMonth+1).toString().padStart(2, '0')}-${(index+1).toString().padStart(2, '0')}`]
                                

                                
                                // Colored dot based on priority
                                Rectangle {
                                    anchors.fill: parent
                                    radius: width / 2
                                    color: todoIndicator.dayTasks && todoIndicator.dayTasks.length > 0 ? 
                                        (todoIndicator.dayTasks[0].priority === 'high' ? '#FF4444' : 
                                         todoIndicator.dayTasks[0].priority === 'medium' ? '#FFAA00' : '#44FF44') : '#888888'
                                    border.width: 1
                                    border.color: "#fff"
                                    opacity: 0.9
                                }
                                
                                // Show count badge if multiple tasks
                                Rectangle {
                                    visible: todoIndicator.dayTasks && todoIndicator.dayTasks.length > 1
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    width: countText.width + 4
                                    height: countText.height + 2
                                    radius: 6
                                    color: "#FF4444"
                                    border.width: 1
                                    border.color: "#fff"
                                    
                                    Text {
                                        id: countText
                                        anchors.centerIn: parent
                                        text: todoIndicator.dayTasks ? todoIndicator.dayTasks.length.toString() : ""
                                        font.pixelSize: 8
                                        font.weight: Font.Bold
                                        color: "#fff"
                                    }
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: {
                                        if (todoIndicator.dayTasks && todoIndicator.dayTasks.length > 0) {
                                            todoTooltip.visible = true;
                                        }
                                    }
                                    onExited: {
                                        todoTooltip.visible = false;
                                    }
                                }
                                
                                // Todo tooltip
                                Rectangle {
                                    id: todoTooltip
                                    anchors.bottom: parent.top
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottomMargin: 8
                                    width: todoTooltipText.width + 16
                                    height: todoTooltipText.height + 12
                                    radius: 8
                                    color: "#000000"
                                    border.width: 1
                                    border.color: "#ffffff"
                                    visible: false
                                    z: 1000
                                    opacity: 1.0
                                    
                                    Text {
                                        id: todoTooltipText
                                        anchors.centerIn: parent
                                        text: todoIndicator.dayTasks ? 
                                            todoIndicator.dayTasks.map(function(task, index) {
                                                let priorityText = task.priority ? ` (${task.priority})` : "";
                                                let emoji = getTaskEmoji(task);
                                                return `${emoji} ${task.content}${priorityText}`;
                                            }).join('\n') : ""
                                        font.pixelSize: 12
                                        color: "#fff"
                                        horizontalAlignment: Text.AlignLeft
                                        lineHeight: 1.3
                                    }
                                    
                                    // Arrow pointing down to the indicator
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