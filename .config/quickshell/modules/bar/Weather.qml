import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/modules/common"
import QtCore
import "root:/services"
import Qt5Compat.GraphicalEffects

Item {
    id: weatherWidget
    width: weatherRow.width
    height: parent.height
    implicitWidth: weatherRow.implicitWidth
    implicitHeight: 40
    




    property string weatherLocation: "auto"
    property var weatherData: ({
        currentTemp: "",
        feelsLike: "",
        currentEmoji: "☀️"
    })
    property int cacheDurationMs: 15 * 60 * 1000 // 15 minutes
    Settings {
        id: weatherSettings
        category: "weather"
        property string apiKey: ""
        property string city: ""
        property string units: "metric"
        property int updateInterval: 1800000 // 30 minutes
        property bool enabled: true
        property string lastWeatherJson: ""
        property string lastLocation: ""
        property int lastWeatherTimestamp: 0
    }
    
    // Set organization properties immediately to prevent QSettings warnings
    Timer {
        running: true
        repeat: false
        interval: 0
        onTriggered: {
            Qt.application.organizationName = "Quickshell"
            Qt.application.organizationDomain = "quickshell.org"
            Qt.application.applicationName = "Quickshell"
        }
    }
    
    Timer {
        interval: 600000  // Update every 10 minutes
        running: true
        repeat: true
        onTriggered: loadWeather()
    }

    Component.onCompleted: {
        // Set organization properties if not already set
        if (!Qt.application.organizationName) {
            Qt.application.organizationName = "Quickshell"
        }
        if (!Qt.application.organizationDomain) {
            Qt.application.organizationDomain = "quickshell.org"
        }
        if (!Qt.application.applicationName) {
            Qt.application.applicationName = "Quickshell"
        }
        
        // Use enhanced weather service if available
        if (typeof Quickshell !== 'undefined' && Quickshell.weatherService && Quickshell.weatherService.enhancedWeatherData) {
            // Connect to enhanced weather service
            Quickshell.weatherService.enhancedWeatherDataChanged.connect(updateFromEnhancedService);
            updateFromEnhancedService();
        } else {
            // Fallback to local weather loading
            loadWeather();
        }
    }
    
    function updateFromEnhancedService() {
        if (Quickshell.weatherService && Quickshell.weatherService.enhancedWeatherData) {
            var enhanced = Quickshell.weatherService.enhancedWeatherData;
            weatherData = {
                currentTemp: enhanced.current.temp,
                feelsLike: enhanced.current.feelsLike,
                currentEmoji: getWeatherEmoji(enhanced.current.condition),
                currentCondition: enhanced.current.condition
            };
        }
    }

    RowLayout {
        id: weatherRow
        spacing: 8
        anchors.centerIn: parent

        // Weather icon container - supports both SVG and emoji
        Item {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignCenter | Qt.AlignVCenter

            // SVG for fog
            Image {
                id: fogIcon
                anchors.centerIn: parent
                source: isFogCondition(weatherData.currentCondition) ? "root:/assets/weather/fog.svg" : ""
                visible: isFogCondition(weatherData.currentCondition)
                width: 28
                height: 28
                fillMode: Image.PreserveAspectFit
            }

            // Emoji for other conditions
        Text {
            id: weatherIcon
                anchors.centerIn: parent
                text: isFogCondition(weatherData.currentCondition) ? "" : (weatherData.currentEmoji || "☀️")
            font.pixelSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colOnLayer0
                visible: !isFogCondition(weatherData.currentCondition)
                
                layer.enabled: true
                layer.smooth: true
                
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 2
                    radius: 4.0
                    samples: 9
                    color: Qt.rgba(0, 0, 0, 0.3)
                }
            }
        }

        RowLayout {
            spacing: 4
            Layout.alignment: Qt.AlignCenter | Qt.AlignVCenter

            Text {
                id: temperature
                text: weatherData.currentTemp || "?"
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer0
                Layout.alignment: Qt.AlignCenter | Qt.AlignVCenter
                
                layer.enabled: true
                layer.smooth: true
                
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 2
                    radius: 4.0
                    samples: 9
                    color: Qt.rgba(0, 0, 0, 0.3)
                }
            }

            Text {
                id: feelsLike
                text: weatherData.feelsLike ? "(" + weatherData.feelsLike + ")" : ""
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer0
                opacity: 0.8
                Layout.alignment: Qt.AlignCenter | Qt.AlignVCenter
                visible: weatherData.feelsLike !== ""
                
                layer.enabled: true
                layer.smooth: true
                
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 2
                    radius: 4.0
                    samples: 9
                    color: Qt.rgba(0, 0, 0, 0.3)
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        
        ToolTip.visible: containsMouse
        ToolTip.text: weatherData.currentCondition || "Weather"
        ToolTip.delay: 500
    }

    // Helper function to check if condition is fog
    function isFogCondition(condition) {
        if (!condition) return false
        const lower = condition.toLowerCase()
        return lower.includes("fog") || lower.includes("mist")
    }

    function getWeatherEmoji(condition) {
        if (!condition) return "☀️"
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
        return "☀️"
    }

    function mapWeatherCode(code) {
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
        if (weatherSettings.lastWeatherJson && weatherSettings.lastLocation === locationKey && (now - weatherSettings.lastWeatherTimestamp) < weatherSettings.updateInterval) {
            // Use cached data
            parseWeatherOpenMeteo(JSON.parse(weatherSettings.lastWeatherJson));
            return;
        }
        
        // Auto-detect location or use specified location
        if (weatherLocation === "auto") {
            detectLocationFromIP();
        } else {
            geocodeLocation(weatherLocation);
        }
    }
    
    function detectLocationFromIP() {
        // console.log("[BAR WEATHER] Auto-detecting location from IP address...")
        var geoXhr = new XMLHttpRequest();
        var ipUrl = "https://ipapi.co/json/";
        
        geoXhr.onreadystatechange = function() {
            if (geoXhr.readyState === XMLHttpRequest.DONE) {
                if (geoXhr.status === 200) {
                    try {
                        var ipData = JSON.parse(geoXhr.responseText);
                        // console.log("[BAR WEATHER] IP geolocation response:", JSON.stringify(ipData, null, 2));
                        
                        if (ipData.latitude && ipData.longitude) {
                            var lat = parseFloat(ipData.latitude);
                            var lon = parseFloat(ipData.longitude);
                            // console.log("[BAR WEATHER] Auto-detected location at", lat, lon);
                            fetchWeatherData(lat, lon);
                        } else {
                            // console.log("[BAR WEATHER] IP geolocation failed, no location data available");
                            fallbackWeatherData("Location unavailable");
                        }
                    } catch (e) {
                        // console.error("[BAR WEATHER] Error parsing IP geolocation response:", e);
                        fallbackWeatherData("Location error");
                    }
                } else {
                    // console.error("[BAR WEATHER] IP geolocation request failed with status:", geoXhr.status);
                    fallbackWeatherData("Location error");
                }
            }
        };
        
        geoXhr.open("GET", ipUrl);
        geoXhr.send();
    }
    
    function geocodeLocation(locationName) {
        // console.log("[BAR WEATHER] Geocoding location:", locationName);
        var geoXhr = new XMLHttpRequest();
        var geoUrl = "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(locationName) + "&count=1&language=en&format=json";
        geoXhr.onreadystatechange = function() {
            if (geoXhr.readyState === XMLHttpRequest.DONE) {
                if (geoXhr.status === 200) {
                    try {
                        var geoData = JSON.parse(geoXhr.responseText);
                        var lat = 44.65; // Halifax default
                        var lon = -63.57;
                        
                        if (geoData.results && geoData.results.length > 0) {
                            lat = geoData.results[0].latitude;
                            lon = geoData.results[0].longitude;
                        }
                        
                        // Get weather data from Open-Meteo
                        var xhr = new XMLHttpRequest();
                        var weatherUrl = "https://api.open-meteo.com/v1/forecast?" +
                                        "latitude=" + lat +
                                        "&longitude=" + lon +
                                        "&current=temperature_2m,apparent_temperature,weather_code" +
                                        "&timezone=auto" +
                                        "&forecast_days=1";
                        xhr.onreadystatechange = function() {
                            if (xhr.readyState === XMLHttpRequest.DONE) {
                                if (xhr.status === 200) {
                                    try {
                                        var data = JSON.parse(xhr.responseText);
                                        var now = Date.now();
                                        var locationKey = weatherLocation.trim().toLowerCase();
                                        weatherSettings.lastWeatherJson = xhr.responseText;
                                        weatherSettings.lastWeatherTimestamp = now;
                                        weatherSettings.lastLocation = locationKey;
                                        parseWeatherOpenMeteo(data);
                                    } catch (e) {
                                        // console.log("[BAR WEATHER] Parse error:", e);
                                        fallbackWeatherData("Parse error");
                                    }
                                } else {
                                    // console.log("[BAR WEATHER] Weather request failed with status:", xhr.status);
                                    fallbackWeatherData("Request error");
                                }
                            }
                        };
                        xhr.open("GET", weatherUrl);
                        xhr.send();
                    } catch (e) {
                        // console.log("[BAR WEATHER] Geocoding parse error:", e);
                        fallbackWeatherData("Geocoding error");
                    }
                } else {
                    // console.log("[BAR WEATHER] Geocoding request failed");
                    fallbackWeatherData("Geocoding failed");
                }
            }
        };
        geoXhr.open("GET", geoUrl);
        geoXhr.send();
    }
    
    function fallbackWeatherData(message) {
        weatherData = {
            currentTemp: "?",
            feelsLike: "",
            currentEmoji: "☀️",
            currentCondition: message
        };
    }
        
    function fetchWeatherData(lat, lon) {
        var xhr = new XMLHttpRequest();
        var weatherUrl = "https://api.open-meteo.com/v1/forecast?" +
                        "latitude=" + lat +
                        "&longitude=" + lon +
                        "&current=temperature_2m,apparent_temperature,weather_code" +
                        "&timezone=auto" +
                        "&forecast_days=1";
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText);
                        var now = Date.now();
                        var locationKey = weatherLocation.trim().toLowerCase();
                        weatherSettings.lastWeatherJson = xhr.responseText;
                        weatherSettings.lastWeatherTimestamp = now;
                        weatherSettings.lastLocation = locationKey;
                        parseWeatherOpenMeteo(data);
                    } catch (e) {
                        // console.log("[BAR WEATHER] Parse error:", e);
                        fallbackWeatherData("Parse error");
                    }
                } else {
                    // console.log("[BAR WEATHER] Weather request failed with status:", xhr.status);
                    fallbackWeatherData("Request error");
                }
            }
        };
        xhr.open("GET", weatherUrl);
        xhr.send();
    }

    function parseWeatherOpenMeteo(data) {
        if (data && data.current) {
            var tempC = Math.round(data.current.temperature_2m);
            var feelsLikeC = Math.round(data.current.apparent_temperature);
            var condition = mapWeatherCode(data.current.weather_code);
            weatherData = {
                currentTemp: tempC + "°C",
                feelsLike: feelsLikeC + "°C",
                currentEmoji: getWeatherEmoji(condition),
                currentCondition: condition
            };
        } else {
            fallbackWeatherData("No data");
        }
    }

    function parseWeather(data) {
        // Parse wttr.in JSON for current conditions (fallback)
        if (data.current_condition && data.current_condition[0]) {
            var current = data.current_condition[0];
            var tempC = current.temp_C;
            var feelsLikeC = current.FeelsLikeC;
            var condition = current.weatherDesc[0]?.value || "";
            weatherData = {
                currentTemp: tempC + "°C",
                feelsLike: feelsLikeC + "°C",
                currentEmoji: getWeatherEmoji(condition),
                currentCondition: condition
            };
        } else {
            fallbackWeatherData("No data");
        }
    }

} 
