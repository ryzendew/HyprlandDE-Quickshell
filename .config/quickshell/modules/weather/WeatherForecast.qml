import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/modules/common"
import Qt.labs.settings 1.1

Item {
    id: weatherForecast
    width: forecastGrid.width
    height: forecastGrid.height

    property string weatherLocation: "Halifax, Nova Scotia, Canada"
    property var forecastData: []
    property string locationDisplay: ""
    property string currentTemp: ""
    property string feelsLike: ""
    property int cacheDurationMs: 15 * 60 * 1000 // 15 minutes
    
    Settings {
        id: weatherCache
        property string lastWeatherJson: ""
        property double lastWeatherTimestamp: 0
        property string lastLocation: ""
    }

    Component.onCompleted: {
        Qt.application.organizationName = "Quickshell";
        Qt.application.organizationDomain = "quickshell.org";
        Qt.application.name = "Quickshell";
        // Clear cache to ensure fresh 7-day data
        clearCache()
        loadWeather()
    }

    Timer {
        interval: 600000  // Update every 10 minutes
        running: true
        repeat: true
        onTriggered: loadWeather()
    }

    GridLayout {
        id: forecastGrid
        columns: 7
        rowSpacing: 10
        columnSpacing: 10
        Layout.margins: 10

        ColumnLayout {
            Layout.columnSpan: 7
            Layout.alignment: Qt.AlignHCenter
            spacing: 4
            Text {
                text: weatherForecast.locationDisplay
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.normal
                horizontalAlignment: Text.AlignHCenter
                visible: weatherForecast.locationDisplay !== ""
            }
        }

        Repeater {
            model: forecastData
            delegate: Rectangle {
                Layout.preferredWidth: 120
                Layout.preferredHeight: 160
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer1
                border.color: Appearance.colors.colOnLayer0
                border.width: 1

                Item {
                    anchors.fill: parent
                    anchors.leftMargin: 15
                    anchors.rightMargin: 15
                    anchors.topMargin: 10
                    anchors.bottomMargin: 10

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8

                        Text {
                            text: modelData.date
                            color: Appearance.colors.colOnLayer1
                            font.pixelSize: Appearance.font.pixelSize.small
                            Layout.alignment: Qt.AlignHCenter
                            leftPadding: 5
                            rightPadding: 5
                        }

                        Text {
                            text: modelData.emoji
                            font.pixelSize: Appearance.font.pixelSize.larger
                            Layout.alignment: Qt.AlignHCenter
                            leftPadding: 5
                            rightPadding: 5
                        }

                        Text {
                            text: modelData.temp
                            color: Appearance.colors.colOnLayer1
                            font.pixelSize: Appearance.font.pixelSize.normal
                            Layout.alignment: Qt.AlignHCenter
                            leftPadding: 5
                            rightPadding: 5
                        }

                        Text {
                            text: modelData.condition
                            color: Appearance.colors.colOnLayer1
                            font.pixelSize: Appearance.font.pixelSize.small
                            opacity: 0.8
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            leftPadding: 5
                            rightPadding: 5
                        }
                    }
                }
            }
        }
    }

    function getWeatherEmoji(condition) {
        if (!condition) return "❓"
        condition = condition.toLowerCase()

        if (condition.includes("clear")) return "☀️"
        if (condition.includes("mainly clear")) return "🌤️"
        if (condition.includes("partly cloudy")) return "⛅"
        if (condition.includes("cloud") || condition.includes("overcast")) return "☁️"
        if (condition.includes("fog") || condition.includes("mist")) return "🌫️"
        if (condition.includes("drizzle")) return "🌦️"
        if (condition.includes("rain") || condition.includes("showers")) return "🌧️"
        if (condition.includes("freezing rain")) return "🌧️❄️"
        if (condition.includes("snow") || condition.includes("snow grains") || condition.includes("snow showers")) return "❄️"
        if (condition.includes("thunderstorm")) return "⛈️"
        if (condition.includes("wind")) return "🌬️"
        return "❓"
    }

    function mapWeatherCode(code) {
        // WMO Weather interpretation codes (WW)
        // https://open-meteo.com/en/docs
        switch(code) {
            case 0: return "Clear sky";
            case 1: return "Mainly clear";
            case 2: return "Partly cloudy";
            case 3: return "Overcast";
            case 45: return "Fog";
            case 48: return "Depositing rime fog";
            case 51: return "Light drizzle";
            case 53: return "Moderate drizzle";
            case 55: return "Dense drizzle";
            case 56: return "Light freezing drizzle";
            case 57: return "Dense freezing drizzle";
            case 61: return "Slight rain";
            case 63: return "Moderate rain";
            case 65: return "Heavy rain";
            case 66: return "Light freezing rain";
            case 67: return "Heavy freezing rain";
            case 71: return "Slight snow fall";
            case 73: return "Moderate snow fall";
            case 75: return "Heavy snow fall";
            case 77: return "Snow grains";
            case 80: return "Slight rain showers";
            case 81: return "Moderate rain showers";
            case 82: return "Violent rain showers";
            case 85: return "Slight snow showers";
            case 86: return "Heavy snow showers";
            case 95: return "Thunderstorm";
            case 96: return "Thunderstorm with slight hail";
            case 99: return "Thunderstorm with heavy hail";
            default: return "Unknown";
        }
    }

    function loadWeather() {
        var now = Date.now();
        var locationKey = weatherLocation.trim().toLowerCase();
        if (weatherCache.lastWeatherJson && weatherCache.lastLocation === locationKey && (now - weatherCache.lastWeatherTimestamp) < cacheDurationMs) {
            // Use cached data
            parseWeather(JSON.parse(weatherCache.lastWeatherJson));
            return;
        }
        
        // Get coordinates from Open-Meteo geocoding API
        var geoXhr = new XMLHttpRequest();
        var geoUrl = "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(weatherLocation) + "&count=1&language=en&format=json";
        geoXhr.onreadystatechange = function() {
            if (geoXhr.readyState === XMLHttpRequest.DONE) {
                if (geoXhr.status === 200) {
                    try {
                        var geoData = JSON.parse(geoXhr.responseText);
                        var lat = 44.65; // Halifax default
                        var lon = -63.57;
                        
                        if (geoData.results && geoData.results.length > 0) {
                            lat = parseFloat(geoData.results[0].latitude) || lat;
                            lon = parseFloat(geoData.results[0].longitude) || lon;
                            locationDisplay = geoData.results[0].name + ", " + geoData.results[0].admin1 + ", " + geoData.results[0].country;
                        }
                        
                        // Now get 7-day forecast from Open-Meteo
                        var xhr = new XMLHttpRequest();
                        var url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,apparent_temperature,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min,wind_speed_10m_max,relative_humidity_2m_max&timezone=auto&forecast_days=7&temperature_unit=celsius&wind_speed_unit=kmh`;
                        xhr.onreadystatechange = function() {
                            if (xhr.readyState === XMLHttpRequest.DONE) {
                                if (xhr.status === 200) {
                                    try {
                                        var data = JSON.parse(xhr.responseText);
                                        weatherCache.lastWeatherJson = xhr.responseText;
                                        weatherCache.lastWeatherTimestamp = now;
                                        weatherCache.lastLocation = locationKey;
                                        parseWeatherOpenMeteo(data);
                                    } catch (e) {
                                        fallbackWeatherData("Parse error");
                                    }
                                } else {
                                    fallbackWeatherData("Request error");
                                }
                            }
                        };
                        xhr.open("GET", url);
                        xhr.send();
                    } catch (e) {
                        fallbackWeatherData("Location error");
                    }
                } else {
                    fallbackWeatherData("Location error");
                }
            }
        };
        geoXhr.open("GET", geoUrl);
        geoXhr.send();
    }

    function parseWeatherOpenMeteo(data) {
        var forecast = [];
        
        // Extract current weather data
        if (data.current) {
            currentTemp = Math.round(data.current.temperature_2m) + "°C";
            feelsLike = Math.round(data.current.apparent_temperature) + "°C";
        }
        
        if (data.daily && data.daily.time && data.daily.time.length > 0) {
            for (var i = 0; i < Math.min(7, data.daily.time.length); i++) {
                var dateStr = data.daily.time[i];
                var dateParts = dateStr.split('-');
                var date = new Date(parseInt(dateParts[0]), parseInt(dateParts[1]) - 1, parseInt(dateParts[2]));
                var dayName = date.toLocaleDateString(Qt.locale(), "ddd");
                var maxTemp = Math.round(data.daily.temperature_2m_max[i]);
                var minTemp = Math.round(data.daily.temperature_2m_min[i]);
                var weatherCode = data.daily.weather_code[i];
                var condition = mapWeatherCode(weatherCode);
                var wind = Math.round(data.daily.wind_speed_10m_max[i]);
                var humidity = Math.round(data.daily.relative_humidity_2m_max[i]);
                
                forecast.push({
                    date: dayName,
                    emoji: getWeatherEmoji(condition),
                    temp: maxTemp + "°/" + minTemp + "°",
                    condition: condition,
                    wind: wind,
                    humidity: humidity
                });
            }
        }
        forecastData = forecast;
        
        // Set locationDisplay from nearest_area if available
        if (data.nearest_area && data.nearest_area[0]) {
            var area = data.nearest_area[0];
            var city = area.areaName[0]?.value || "";
            var region = area.region[0]?.value || "";
            var country = area.country[0]?.value || "";
            var parts = [];
            if (city) parts.push(city);
            if (region) parts.push(region);
            if (country) parts.push(country);
            locationDisplay = parts.join(", ");
        }
    }

    function parseWeather(data) {
        // Parse wttr.in JSON for 3-day forecast (backup method)
        var forecast = [];
        // console.log("wttr.in API returned weather data with", data.weather ? data.weather.length : 0, "days");
        
        // Extract current weather data from wttr.in
        if (data.current_condition && data.current_condition[0]) {
            var current = data.current_condition[0];
            currentTemp = current.temp_C + "°C";
            feelsLike = current.FeelsLikeC + "°C";
            // console.log("Current weather (wttr.in) - Temp:", currentTemp, "Feels like:", feelsLike);
        }
        
        if (data.weather && data.weather.length > 0) {
            for (var i = 0; i < Math.min(3, data.weather.length); i++) {
                var day = data.weather[i];
                var dateStr = day.date;
                // Fix timezone issue: parse date in local time instead of UTC
                var dateParts = dateStr.split('-');
                var date = new Date(parseInt(dateParts[0]), parseInt(dateParts[1]) - 1, parseInt(dateParts[2]));
                var dayName = date.toLocaleDateString(Qt.locale(), "ddd");
                var maxTemp = day.maxtempC;
                var minTemp = day.mintempC;
                var condition = day.hourly[4]?.weatherDesc[0]?.value || day.hourly[0]?.weatherDesc[0]?.value || "";
                var wind = day.hourly[4]?.windspeedKmph || day.hourly[0]?.windspeedKmph || "";
                var humidity = day.hourly[4]?.humidity || day.hourly[0]?.humidity || "";
                forecast.push({
                    date: dayName,
                    emoji: getWeatherEmoji(condition),
                    temp: maxTemp + "°/" + minTemp + "°",
                    condition: condition,
                    wind: wind,
                    humidity: humidity
                });
            }
        }
        // console.log("Parsed forecast with", forecast.length, "days");
        forecastData = forecast;
        // Set locationDisplay from nearest_area if available
        if (data.nearest_area && data.nearest_area[0]) {
            var area = data.nearest_area[0];
            var city = area.areaName[0]?.value || "";
            var region = area.region[0]?.value || "";
            var country = area.country[0]?.value || "";
            var parts = [];
            if (city) parts.push(city);
            if (region) parts.push(region);
            if (country) parts.push(country);
            locationDisplay = parts.join(", ");
        }
    }

    function fallbackWeatherData(message) {
        forecastData = [{
            date: "Error",
            emoji: "❓",
            temp: "?",
            condition: message
        }];
    }

    function clearCache() {
        weatherCache.lastWeatherJson = ""
        weatherCache.lastWeatherTimestamp = 0
        weatherCache.lastLocation = ""
        // console.log("Weather cache cleared")
    }
} 