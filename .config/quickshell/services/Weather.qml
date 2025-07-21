import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import Quickshell
import Quickshell.Hyprland

// Weather service (Open-Meteo API)
Item {
    id: service
    

    
    property var shell
    
    // Public properties
    property bool loading: false
    property var weatherData: null
    property string location: "auto" // "auto" for IP-based detection, or specify a location
    property var detectedLocation: null
    property int cacheDurationMs: 15 * 60 * 1000 // 15 minutes
    
    // Private properties
    property var _xhr: null
    property var _geoXhr: null
    property int _retryCount: 0
    property int _maxRetries: 3
    property int _baseDelay: 1000 // 1 second base delay for exponential backoff
    
    // Settings for caching
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
        property string cachedLatitude: ""
        property string cachedLongitude: ""
        property string cachedLocationDisplay: ""
        property int lastLocationDetection: 0 // Timestamp of last location detection
    }
    

    
    // Initialize on component completion
    Component.onCompleted: {
        // console.log("Weather service initialized with location:", location)
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
        var now = Date.now();
        var locationKey = location ? location.trim().toLowerCase() : "auto";
        
        // Use cached data if available and fresh
        if (weatherSettings.lastWeatherJson && 
            weatherSettings.lastLocation === locationKey && 
            (now - weatherSettings.lastWeatherTimestamp) < cacheDurationMs) {
            try {
                parseWeather(JSON.parse(weatherSettings.lastWeatherJson));
                return;
            } catch (e) {
                // console.error("Failed to parse cached weather data:", e)
            }
        }
        
        loading = true;
        
        // Auto-detect location using IP or use specified location
        if (location === "auto") {
            // Check if we have a cached location from this session (within last 24 hours)
            if (weatherSettings.cachedLatitude && weatherSettings.cachedLongitude && 
                (now - weatherSettings.lastLocationDetection) < (24 * 60 * 60 * 1000)) {
                // Use cached location
                fetchWeatherData(parseFloat(weatherSettings.cachedLatitude), 
                               parseFloat(weatherSettings.cachedLongitude), 
                               weatherSettings.cachedLocationDisplay);
            } else {
                // Detect location only if not cached or cache is old
            detectLocationFromIP();
            }
        } else {
            geocodeLocation(location);
        }
    }
    
    function detectLocationFromIP() {
        // console.log("Auto-detecting location from IP address...")
        if (_geoXhr) {
            _geoXhr.abort();
        }
        
        _geoXhr = new XMLHttpRequest();
        // Using ipapi.co for IP-based geolocation (free, no API key required)
        var ipUrl = "https://ipapi.co/json/";
        
        _geoXhr.onreadystatechange = function() {
            if (_geoXhr.readyState === XMLHttpRequest.DONE) {
                if (_geoXhr.status === 200) {
                    try {
                        var ipData = JSON.parse(_geoXhr.responseText);
                        // console.log("IP geolocation response:", JSON.stringify(ipData, null, 2));
                        
                        if (ipData.latitude && ipData.longitude) {
                            var lat = parseFloat(ipData.latitude);
                            var lon = parseFloat(ipData.longitude);
                            var locationDisplay = [ipData.city, ipData.region, ipData.country_name].filter(x => x).join(", ");
                            
                            detectedLocation = {
                                latitude: lat,
                                longitude: lon,
                                city: ipData.city || "",
                                region: ipData.region || "",
                                country: ipData.country_name || "",
                                display: locationDisplay
                            };
                            
                            // Cache the location for future use
                            weatherSettings.cachedLatitude = lat.toString();
                            weatherSettings.cachedLongitude = lon.toString();
                            weatherSettings.cachedLocationDisplay = locationDisplay;
                            weatherSettings.lastLocationDetection = Date.now();

                            _retryCount = 0; // Reset retry count on success
                            fetchWeatherData(lat, lon, locationDisplay);
                        } else {
                            // console.log("IP geolocation failed, no location data available");
                            loading = false;
                            createDefaultWeatherData();
                        }
                    } catch (e) {
                        // console.error("Error parsing IP geolocation response:", e);
                        loading = false;
                        createDefaultWeatherData();
                    }
                } else if (_geoXhr.status === 429) {
                    // Rate limited - immediately try fallback service
                    detectLocationFromIPFallback();
                } else {
                    // Any other error - immediately try fallback service
                    detectLocationFromIPFallback();
                }
            }
        };
        
        _geoXhr.open("GET", ipUrl);
        _geoXhr.send();
    }

    function detectLocationFromIPFallback() {
        if (_geoXhr) {
            _geoXhr.abort();
        }
        
        _geoXhr = new XMLHttpRequest();
        // Using ip-api.com as fallback (free, no API key required)
        var ipUrl = "http://ip-api.com/json/";
        
        _geoXhr.onreadystatechange = function() {
            if (_geoXhr.readyState === XMLHttpRequest.DONE) {
                if (_geoXhr.status === 200) {
                    try {
                        var ipData = JSON.parse(_geoXhr.responseText);
                        console.log("Fallback IP geolocation response:", JSON.stringify(ipData, null, 2));
                        
                        if (ipData.lat && ipData.lon) {
                            var lat = parseFloat(ipData.lat);
                            var lon = parseFloat(ipData.lon);
                            var locationDisplay = [ipData.city, ipData.regionName, ipData.country].filter(x => x).join(", ");
                            
                            detectedLocation = {
                                latitude: lat,
                                longitude: lon,
                                city: ipData.city || "",
                                region: ipData.regionName || "",
                                country: ipData.country || "",
                                display: locationDisplay
                            };
                            
                            // Cache the location for future use
                            weatherSettings.cachedLatitude = lat.toString();
                            weatherSettings.cachedLongitude = lon.toString();
                            weatherSettings.cachedLocationDisplay = locationDisplay;
                            weatherSettings.lastLocationDetection = Date.now();

                            fetchWeatherData(lat, lon, locationDisplay);
                        } else {
                            console.log("Fallback IP geolocation failed, no location data available");
                            loading = false;
                            createDefaultWeatherData();
                            Hyprland.dispatch(`exec notify-send "Weather Location Error" "Unable to detect your location automatically. Please set a manual location in settings." -u normal -a "Shell"`);
                        }
                    } catch (e) {
                        console.error("Error parsing fallback IP geolocation response:", e);
                        loading = false;
                        createDefaultWeatherData();
                        Hyprland.dispatch(`exec notify-send "Weather Location Error" "Unable to detect your location automatically. Please set a manual location in settings." -u normal -a "Shell"`);
                    }
                } else {
                    console.error("Fallback IP geolocation request failed with status:", _geoXhr.status);
                    loading = false;
                    createDefaultWeatherData();
                    Hyprland.dispatch(`exec notify-send "Weather Location Error" "Unable to detect your location automatically. Please set a manual location in settings." -u normal -a "Shell"`);
                }
            }
        };
        
        _geoXhr.open("GET", ipUrl);
        _geoXhr.send();
    }
    
    function geocodeLocation(locationName) {
        // console.log("Geocoding location:", locationName);
        if (_geoXhr) {
            _geoXhr.abort();
        }
        
        _geoXhr = new XMLHttpRequest();
        var geoUrl = "https://geocoding-api.open-meteo.com/v1/search?name=" + 
                    encodeURIComponent(locationName) + 
                    "&count=1&language=en&format=json";
                    
        // console.log("Fetching geocoding data from:", geoUrl)
                    
        _geoXhr.onreadystatechange = function() {
            if (_geoXhr.readyState === XMLHttpRequest.DONE) {
                if (_geoXhr.status === 200) {
                    try {
                        var geoData = JSON.parse(_geoXhr.responseText);
                        // console.log("Geocoding API response:", JSON.stringify(geoData, null, 2));
                        
                        if (geoData.results && geoData.results.length > 0) {
                            var lat = geoData.results[0].latitude;
                            var lon = geoData.results[0].longitude;
                            
                            // Update location display with full name
                            var locationParts = [];
                            if (geoData.results[0].name) locationParts.push(geoData.results[0].name);
                            if (geoData.results[0].admin1) locationParts.push(geoData.results[0].admin1);
                            if (geoData.results[0].country) locationParts.push(geoData.results[0].country);
                            
                            var locationDisplay = locationParts.join(", ");
                            // console.log("Location resolved to:", locationDisplay, "at", lat, lon)
                            
                            // Get weather data for these coordinates
                            fetchWeatherData(lat, lon, locationDisplay);
                        } else {
                            // console.log("No geocoding results found for location:", locationName);
                            loading = false;
                            createDefaultWeatherData();
                        }
                    } catch (e) {
                        // console.error("Error parsing geocoding response:", e);
                        loading = false;
                        createDefaultWeatherData();
                    }
                } else {
                    // console.error("Geocoding request failed with status:", _geoXhr.status);
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
            locationDisplay: "Location unavailable",
            currentTemp: "?",
            feelsLike: "?",
            currentCondition: "No location data",
            forecast: [
                { date: "Today", condition: "No data", temp: "? / ?", emoji: "❓" },
                { date: "Tomorrow", condition: "No data", temp: "? / ?", emoji: "❓" }
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
                        weatherSettings.lastWeatherJson = _xhr.responseText;
                        weatherSettings.lastWeatherTimestamp = Date.now();
                        weatherSettings.lastLocation = location.trim().toLowerCase();
                        
                        // Parse the weather data
                        parseWeather(data, locationDisplay);
                    } catch (e) {
                        // console.error("Error parsing weather data:", e);
                        loading = false;
                    }
                } else {
                    // console.error("Weather request failed with status:", _xhr.status);
                    loading = false;
                }
            }
        };
        
        _xhr.open("GET", weatherUrl);
        _xhr.send();
    }
    
    function parseWeather(data, locationDisplay) {
        if (!data || !data.current) {
            // console.error("Invalid weather data format");
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
        weatherSettings.lastWeatherJson = "";
        weatherSettings.lastWeatherTimestamp = 0;
        weatherSettings.lastLocation = "";
    }
} 