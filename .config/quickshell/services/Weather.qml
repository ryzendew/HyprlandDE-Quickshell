import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.settings 1.1
import "root:/Data" as Data

// Weather service (Open-Meteo API)
Item {
    id: service
    
    property var shell
    
    // Public properties
    property bool loading: false
    property var weatherData: null
    property string location: Data.Settings.weatherLocation || "Halifax, Nova Scotia, Canada"
    property int cacheDurationMs: 15 * 60 * 1000 // 15 minutes
    
    // Private properties
    property var _xhr: null
    property var _geoXhr: null
    
    // Settings for caching
    Settings {
        id: weatherCache
        property string lastWeatherJson: ""
        property double lastWeatherTimestamp: 0
        property string lastLocation: ""
        
        Component.onCompleted: {
            Qt.application.organizationName = "Quickshell";
            Qt.application.organizationDomain = "quickshell.org";
            Qt.application.name = "Quickshell";
        }
    }
    
    // Initialize on component completion
    Component.onCompleted: {
        console.log("Weather service initialized with location:", location)
        loadWeather()
        updateTimer.start()
    }
    
    // Regular update timer
    Timer {
        id: updateTimer
        interval: 600000  // Update every 10 minutes
        running: false
        repeat: true
        onTriggered: loadWeather()
    }
    
    // Methods
    function loadWeather() {
        console.log("Loading weather for location:", location)
        var now = Date.now();
        var locationKey = location ? location.trim().toLowerCase() : "halifax, nova scotia, canada";
        
        // Use cached data if available and fresh
        if (weatherCache.lastWeatherJson && 
            weatherCache.lastLocation === locationKey && 
            (now - weatherCache.lastWeatherTimestamp) < cacheDurationMs) {
            try {
                parseWeather(JSON.parse(weatherCache.lastWeatherJson));
                console.log("Using cached weather data")
                return;
            } catch (e) {
                console.error("Failed to parse cached weather data:", e)
            }
        }
        
        loading = true;
        
        // Get coordinates from Open-Meteo geocoding API
        if (_geoXhr) {
            _geoXhr.abort();
        }
        
        _geoXhr = new XMLHttpRequest();
        var geoUrl = "https://geocoding-api.open-meteo.com/v1/search?name=" + 
                    encodeURIComponent(locationKey) + 
                    "&count=1&language=en&format=json";
                    
        console.log("Fetching geocoding data from:", geoUrl)
                    
        _geoXhr.onreadystatechange = function() {
            if (_geoXhr.readyState === XMLHttpRequest.DONE) {
                if (_geoXhr.status === 200) {
                    try {
                        var geoData = JSON.parse(_geoXhr.responseText);
                        var lat = 44.65; // Halifax default
                        var lon = -63.57;
                        
                        if (geoData.results && geoData.results.length > 0) {
                            lat = geoData.results[0].latitude;
                            lon = geoData.results[0].longitude;
                            
                            // Update location display with full name
                            var locationParts = [];
                            if (geoData.results[0].name) locationParts.push(geoData.results[0].name);
                            if (geoData.results[0].admin1) locationParts.push(geoData.results[0].admin1);
                            if (geoData.results[0].country) locationParts.push(geoData.results[0].country);
                            
                            var locationDisplay = locationParts.join(", ");
                            console.log("Location resolved to:", locationDisplay, "at", lat, lon)
                            
                            // Get weather data for these coordinates
                            fetchWeatherData(lat, lon, locationDisplay);
                        } else {
                            console.error("No location found for:", location);
                            loading = false;
                            
                            // Create default weather data
                            createDefaultWeatherData();
                        }
                    } catch (e) {
                        console.error("Error parsing geocoding response:", e);
                        loading = false;
                        createDefaultWeatherData();
                    }
                } else {
                    console.error("Geocoding request failed with status:", _geoXhr.status);
                    loading = false;
                    createDefaultWeatherData();
                }
            }
        };
        
        _geoXhr.open("GET", geoUrl);
        _geoXhr.send();
    }
    
    function createDefaultWeatherData() {
        weatherData = {
            locationDisplay: location || "Halifax, Nova Scotia",
            currentTemp: "15°C",
            feelsLike: "15°C",
            currentCondition: "Clear sky",
            forecast: [
                { date: "Today", condition: "Clear sky", temp: "15° / 10°", emoji: "☀️" },
                { date: "Tomorrow", condition: "Partly cloudy", temp: "17° / 12°", emoji: "⛅" }
            ]
        };
    }
    
    function fetchWeatherData(lat, lon, locationDisplay) {
        if (_xhr) {
            _xhr.abort();
        }
        
        _xhr = new XMLHttpRequest();
        var weatherUrl = "https://api.open-meteo.com/v1/forecast?" +
                        "latitude=" + lat +
                        "&longitude=" + lon +
                        "&current=temperature_2m,apparent_temperature,weather_code" +
                        "&daily=weather_code,temperature_2m_max,temperature_2m_min" +
                        "&timezone=auto" +
                        "&forecast_days=7";
                        
        _xhr.onreadystatechange = function() {
            if (_xhr.readyState === XMLHttpRequest.DONE) {
                if (_xhr.status === 200) {
                    try {
                        var data = JSON.parse(_xhr.responseText);
                        
                        // Cache the response
                        weatherCache.lastWeatherJson = _xhr.responseText;
                        weatherCache.lastWeatherTimestamp = Date.now();
                        weatherCache.lastLocation = location.trim().toLowerCase();
                        
                        // Parse the weather data
                        parseWeather(data, locationDisplay);
                    } catch (e) {
                        console.error("Error parsing weather data:", e);
                        loading = false;
                    }
                } else {
                    console.error("Weather request failed with status:", _xhr.status);
                    loading = false;
                }
            }
        };
        
        _xhr.open("GET", weatherUrl);
        _xhr.send();
    }
    
    function parseWeather(data, locationDisplay) {
        if (!data || !data.current) {
            console.error("Invalid weather data format");
            loading = false;
            return;
        }
        
        // Create weather data object
        weatherData = {
            locationDisplay: locationDisplay || "",
            currentTemp: Math.round(data.current.temperature_2m) + "°" + data.current_units.temperature_2m,
            feelsLike: Math.round(data.current.apparent_temperature) + "°" + data.current_units.temperature_2m,
            currentCondition: mapWeatherCode(data.current.weather_code),
            forecast: []
        };
        
        // Parse forecast data if available
        if (data.daily) {
            for (var i = 0; i < data.daily.time.length; i++) {
                var date = new Date(data.daily.time[i]);
                var dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
                var day = dayNames[date.getDay()];
                
                weatherData.forecast.push({
                    date: day,
                    condition: mapWeatherCode(data.daily.weather_code[i]),
                    temp: Math.round(data.daily.temperature_2m_max[i]) + "° / " + 
                          Math.round(data.daily.temperature_2m_min[i]) + "°",
                    emoji: getWeatherEmoji(mapWeatherCode(data.daily.weather_code[i]))
                });
            }
        }
        
        loading = false;
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
    
    function clearCache() {
        weatherCache.lastWeatherJson = "";
        weatherCache.lastWeatherTimestamp = 0;
        weatherCache.lastLocation = "";
    }
} 