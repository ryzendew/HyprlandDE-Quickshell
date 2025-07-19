import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore

// Enhanced Weather service (WeatherAPI.com + Open-Meteo backup)
Item {
    id: service
    
    property var shell
    
    // Public properties
    property bool loading: false
    property var weatherData: null
    property string location: "auto" // "auto" for IP-based detection, or specify a location
    property var detectedLocation: null
    property int cacheDurationMs: 15 * 60 * 1000 // 15 minutes
    
    // Enhanced weather data structure
    property var enhancedWeatherData: ({
        current: {
            temp: "",
            feelsLike: "",
            condition: "",
            humidity: "",
            wind: "",
            pressure: "",
            visibility: "",
            uv: "",
            dewPoint: "",
            airQuality: "",
            cloudCover: "",
            precipitation: "",
            lastUpdated: ""
        },
        forecast: {
            hourly: [],
            daily: [],
            alerts: []
        },
        astronomy: {
            sunrise: "",
            sunset: "",
            moonPhase: "",
            moonrise: "",
            moonset: ""
        },
        location: {
            name: "",
            region: "",
            country: "",
            lat: 0,
            lon: 0,
            timezone: ""
        }
    })
    
    // Private properties
    property var _xhr: null
    property var _geoXhr: null
    property var _airQualityXhr: null
    
    // Settings for caching
    Settings {
        id: weatherSettings
        category: "weather"
        property string weatherApiKey: "" // WeatherAPI.com key
        property string city: ""
        property string units: "metric"
        property int updateInterval: 1800000 // 30 minutes
        property bool enabled: true
        property string lastWeatherJson: ""
        property string lastLocation: ""
        property int lastWeatherTimestamp: 0
        property bool useWeatherApi: true // Toggle between WeatherAPI.com and Open-Meteo
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
    
    // Initialize on component completion
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
        
        console.log("Enhanced Weather service initialized with location:", location)
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
        console.log("Loading enhanced weather for location:", location)
        var now = Date.now();
        var locationKey = location ? location.trim().toLowerCase() : "auto";
        
        // Use cached data if available and fresh
        if (weatherSettings.lastWeatherJson && 
            weatherSettings.lastLocation === locationKey && 
            (now - weatherSettings.lastWeatherTimestamp) < cacheDurationMs) {
            try {
                parseEnhancedWeather(JSON.parse(weatherSettings.lastWeatherJson));
                console.log("Using cached enhanced weather data")
                return;
            } catch (e) {
                console.error("Failed to parse cached enhanced weather data:", e)
            }
        }
        
        loading = true;
        
        // Auto-detect location using IP or use specified location
        if (location === "auto") {
            detectLocationFromIP();
        } else {
            geocodeLocation(location);
        }
    }
    
    function detectLocationFromIP() {
        console.log("Auto-detecting location from IP address...")
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
                        console.log("IP geolocation response:", JSON.stringify(ipData, null, 2));
                        
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
                            
                            console.log("Auto-detected location:", locationDisplay, "at", lat, lon);
                            fetchEnhancedWeatherData(lat, lon, locationDisplay);
                        } else {
                            console.log("IP geolocation failed, no location data available");
                            loading = false;
                            createDefaultWeatherData();
                        }
                    } catch (e) {
                        console.error("Error parsing IP geolocation response:", e);
                        loading = false;
                        createDefaultWeatherData();
                    }
                } else {
                    console.error("IP geolocation request failed with status:", _geoXhr.status);
                    loading = false;
                    createDefaultWeatherData();
                }
            }
        };
        
        _geoXhr.open("GET", ipUrl);
        _geoXhr.send();
    }
    
    function geocodeLocation(locationName) {
        console.log("Geocoding location:", locationName);
        if (_geoXhr) {
            _geoXhr.abort();
        }
        
        _geoXhr = new XMLHttpRequest();
        var geoUrl = "https://geocoding-api.open-meteo.com/v1/search?name=" + 
                    encodeURIComponent(locationName) + 
                    "&count=1&language=en&format=json";
                    
        console.log("Fetching geocoding data from:", geoUrl)
                    
        _geoXhr.onreadystatechange = function() {
            if (_geoXhr.readyState === XMLHttpRequest.DONE) {
                if (_geoXhr.status === 200) {
                    try {
                        var geoData = JSON.parse(_geoXhr.responseText);
                        console.log("Geocoding API response:", JSON.stringify(geoData, null, 2));
                        
                        if (geoData.results && geoData.results.length > 0) {
                            var lat = geoData.results[0].latitude;
                            var lon = geoData.results[0].longitude;
                            
                            // Update location display with full name
                            var locationParts = [];
                            if (geoData.results[0].name) locationParts.push(geoData.results[0].name);
                            if (geoData.results[0].admin1) locationParts.push(geoData.results[0].admin1);
                            if (geoData.results[0].country) locationParts.push(geoData.results[0].country);
                            
                            var locationDisplay = locationParts.join(", ");
                            console.log("Location resolved to:", locationDisplay, "at", lat, lon)
                            
                            // Get weather data for these coordinates
                            fetchEnhancedWeatherData(lat, lon, locationDisplay);
                        } else {
                            console.log("No geocoding results found for location:", locationName);
                            loading = false;
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
        enhancedWeatherData = {
            current: {
                temp: "?",
                feelsLike: "?",
                condition: "No location data",
                humidity: "?",
                wind: "?",
                pressure: "?",
                visibility: "?",
                uv: "?",
                dewPoint: "?",
                airQuality: "?",
                cloudCover: "?",
                precipitation: "?",
                lastUpdated: new Date().toLocaleTimeString()
            },
            forecast: {
                hourly: [],
                daily: [],
                alerts: []
            },
            astronomy: {
                sunrise: "?",
                sunset: "?",
                moonPhase: "?",
                moonrise: "?",
                moonset: "?"
            },
            location: {
                name: "Location unavailable",
                region: "",
                country: "",
                lat: 0,
                lon: 0,
                timezone: ""
            }
        };
        
        // Also set legacy weatherData for compatibility
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
        
        loading = false;
    }
    
    function fetchEnhancedWeatherData(lat, lon, locationDisplay) {
        if (_xhr) {
            _xhr.abort();
        }
        
        // Try WeatherAPI.com first if API key is available
        if (weatherSettings.useWeatherApi && weatherSettings.weatherApiKey) {
            fetchWeatherApiData(lat, lon, locationDisplay);
        } else {
            // Fallback to Open-Meteo
            fetchOpenMeteoData(lat, lon, locationDisplay);
        }
    }
    
    function fetchWeatherApiData(lat, lon, locationDisplay) {
        console.log("Fetching data from WeatherAPI.com...")
        
        _xhr = new XMLHttpRequest();
        var weatherUrl = `https://api.weatherapi.com/v1/forecast.json?` +
                        `key=${weatherSettings.weatherApiKey}&` +
                        `q=${lat},${lon}&` +
                        `days=14&` +
                        `aqi=yes&` +
                        `alerts=yes&` +
                        `hour=24`;
                        
        _xhr.onreadystatechange = function() {
            if (_xhr.readyState === XMLHttpRequest.DONE) {
                if (_xhr.status === 200) {
                    try {
                        var data = JSON.parse(_xhr.responseText);
                        
                        // Cache the response
                        weatherSettings.lastWeatherJson = _xhr.responseText;
                        weatherSettings.lastWeatherTimestamp = Date.now();
                        weatherSettings.lastLocation = location.trim().toLowerCase();
                        
                        // Parse the enhanced weather data
                        parseWeatherApiData(data, locationDisplay);
                    } catch (e) {
                        console.error("Error parsing WeatherAPI.com data:", e);
                        // Fallback to Open-Meteo
                        fetchOpenMeteoData(lat, lon, locationDisplay);
                    }
                } else {
                    console.error("WeatherAPI.com request failed with status:", _xhr.status);
                    // Fallback to Open-Meteo
                    fetchOpenMeteoData(lat, lon, locationDisplay);
                }
            }
        };
        
        _xhr.open("GET", weatherUrl);
        _xhr.send();
    }
    
    function fetchOpenMeteoData(lat, lon, locationDisplay) {
        console.log("Fetching data from Open-Meteo...")
        
        _xhr = new XMLHttpRequest();
        var weatherUrl = "https://api.open-meteo.com/v1/forecast?" +
                        "latitude=" + lat +
                        "&longitude=" + lon +
                        "&current=temperature_2m,apparent_temperature,weather_code,relative_humidity_2m,wind_speed_10m,wind_direction_10m,pressure_msl,visibility,cloud_cover,precipitation" +
                        "&hourly=temperature_2m,apparent_temperature,weather_code,relative_humidity_2m,wind_speed_10m,precipitation_probability,precipitation" +
                        "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,relative_humidity_2m_max" +
                        "&timezone=auto" +
                        "&forecast_days=14";
                        
        _xhr.onreadystatechange = function() {
            if (_xhr.readyState === XMLHttpRequest.DONE) {
                if (_xhr.status === 200) {
                    try {
                        var data = JSON.parse(_xhr.responseText);
                        
                        // Cache the response
                        weatherSettings.lastWeatherJson = _xhr.responseText;
                        weatherSettings.lastWeatherTimestamp = Date.now();
                        weatherSettings.lastLocation = location.trim().toLowerCase();
                        
                        // Parse the Open-Meteo data
                        parseOpenMeteoData(data, locationDisplay);
                    } catch (e) {
                        console.error("Error parsing Open-Meteo data:", e);
                        loading = false;
                    }
                } else {
                    console.error("Open-Meteo request failed with status:", _xhr.status);
                    loading = false;
                }
            }
        };
        
        _xhr.open("GET", weatherUrl);
        _xhr.send();
    }
    
    function parseWeatherApiData(data, locationDisplay) {
        if (!data || !data.current) {
            console.error("Invalid WeatherAPI.com data format");
            loading = false;
            return;
        }
        
        // Parse current weather
        var current = data.current;
        enhancedWeatherData.current = {
            temp: Math.round(current.temp_c) + "°C",
            feelsLike: Math.round(current.feelslike_c) + "°C",
            condition: current.condition.text,
            humidity: current.humidity + "%",
            wind: Math.round(current.wind_kph) + " km/h",
            pressure: Math.round(current.pressure_mb) + " mb",
            visibility: Math.round(current.vis_km) + " km",
            uv: current.uv,
            dewPoint: Math.round(current.dewpoint_c) + "°C",
            airQuality: data.current.air_quality ? data.current.air_quality["us-epa-index"] : "?",
            cloudCover: current.cloud + "%",
            precipitation: current.precip_mm + " mm",
            lastUpdated: new Date(current.last_updated_epoch * 1000).toLocaleTimeString()
        };
        
        // Parse location
        enhancedWeatherData.location = {
            name: data.location.name,
            region: data.location.region,
            country: data.location.country,
            lat: data.location.lat,
            lon: data.location.lon,
            timezone: data.location.tz_id
        };
        
        // Parse astronomy
        if (data.forecast && data.forecast.forecastday && data.forecast.forecastday.length > 0) {
            var today = data.forecast.forecastday[0];
            enhancedWeatherData.astronomy = {
                sunrise: today.astro.sunrise,
                sunset: today.astro.sunset,
                moonPhase: today.astro.moon_phase,
                moonrise: today.astro.moonrise,
                moonset: today.astro.moonset
            };
        }
        
        // Parse hourly forecast
        enhancedWeatherData.forecast.hourly = [];
        if (data.forecast && data.forecast.forecastday) {
            for (var i = 0; i < Math.min(3, data.forecast.forecastday.length); i++) {
                var day = data.forecast.forecastday[i];
                for (var j = 0; j < day.hour.length; j++) {
                    var hour = day.hour[j];
                    enhancedWeatherData.forecast.hourly.push({
                        time: new Date(hour.time_epoch * 1000).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}),
                        temp: Math.round(hour.temp_c) + "°C",
                        feelsLike: Math.round(hour.feelslike_c) + "°C",
                        condition: hour.condition.text,
                        humidity: hour.humidity + "%",
                        wind: Math.round(hour.wind_kph) + " km/h",
                        precipitation: hour.chance_of_rain + "%",
                        icon: getWeatherEmoji(hour.condition.text)
                    });
                }
            }
        }
        
        // Parse daily forecast
        enhancedWeatherData.forecast.daily = [];
        if (data.forecast && data.forecast.forecastday) {
            for (var i = 0; i < data.forecast.forecastday.length; i++) {
                var day = data.forecast.forecastday[i];
                var date = new Date(day.date);
                var dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
                var dayName = dayNames[date.getDay()];
                
                enhancedWeatherData.forecast.daily.push({
                    date: dayName,
                    condition: day.day.condition.text,
                    tempMax: Math.round(day.day.maxtemp_c) + "°",
                    tempMin: Math.round(day.day.mintemp_c) + "°",
                    precipitation: day.day.daily_chance_of_rain + "%",
                    wind: Math.round(day.day.maxwind_kph) + " km/h",
                    humidity: day.day.avghumidity + "%",
                    icon: getWeatherEmoji(day.day.condition.text)
                });
            }
        }
        
        // Parse alerts
        enhancedWeatherData.forecast.alerts = [];
        if (data.alerts && data.alerts.alert) {
            for (var i = 0; i < data.alerts.alert.length; i++) {
                var alert = data.alerts.alert[i];
                enhancedWeatherData.forecast.alerts.push({
                    headline: alert.headline,
                    severity: alert.severity,
                    areas: alert.areas,
                    desc: alert.desc,
                    effective: alert.effective,
                    expires: alert.expires
                });
            }
        }
        
        // Set legacy weatherData for compatibility
        weatherData = {
            locationDisplay: locationDisplay || enhancedWeatherData.location.name,
            currentTemp: enhancedWeatherData.current.temp,
            feelsLike: enhancedWeatherData.current.feelsLike,
            currentCondition: enhancedWeatherData.current.condition,
            forecast: enhancedWeatherData.forecast.daily.slice(0, 7).map(function(day) {
                return {
                    date: day.date,
                    condition: day.condition,
                    temp: day.tempMax + " / " + day.tempMin,
                    emoji: day.icon
                };
            })
        };
        
        loading = false;
        console.log("Enhanced weather data parsed successfully");
    }
    
    function parseOpenMeteoData(data, locationDisplay) {
        if (!data || !data.current) {
            console.error("Invalid Open-Meteo data format");
            loading = false;
            return;
        }
        
        // Parse current weather
        var current = data.current;
        enhancedWeatherData.current = {
            temp: Math.round(current.temperature_2m) + "°C",
            feelsLike: Math.round(current.apparent_temperature) + "°C",
            condition: mapWeatherCode(current.weather_code),
            humidity: Math.round(current.relative_humidity_2m) + "%",
            wind: Math.round(current.wind_speed_10m) + " km/h",
            pressure: Math.round(current.pressure_msl) + " mb",
            visibility: current.visibility ? Math.round(current.visibility / 1000) + " km" : "?",
            uv: "?", // Not available in Open-Meteo
            dewPoint: "?", // Not available in Open-Meteo
            airQuality: "?", // Will be fetched separately
            cloudCover: current.cloud_cover ? current.cloud_cover + "%" : "?",
            precipitation: current.precipitation ? current.precipitation + " mm" : "0 mm",
            lastUpdated: new Date().toLocaleTimeString()
        };
        
        // Parse location
        enhancedWeatherData.location = {
            name: locationDisplay.split(", ")[0] || "Unknown",
            region: locationDisplay.split(", ")[1] || "",
            country: locationDisplay.split(", ")[2] || "",
            lat: data.latitude || 0,
            lon: data.longitude || 0,
            timezone: data.timezone || ""
        };
        
        // Parse hourly forecast
        enhancedWeatherData.forecast.hourly = [];
        if (data.hourly && data.hourly.time) {
            for (var i = 0; i < Math.min(24, data.hourly.time.length); i++) {
                var time = new Date(data.hourly.time[i]);
                enhancedWeatherData.forecast.hourly.push({
                    time: time.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}),
                    temp: Math.round(data.hourly.temperature_2m[i]) + "°C",
                    feelsLike: Math.round(data.hourly.apparent_temperature[i]) + "°C",
                    condition: mapWeatherCode(data.hourly.weather_code[i]),
                    humidity: Math.round(data.hourly.relative_humidity_2m[i]) + "%",
                    wind: Math.round(data.hourly.wind_speed_10m[i]) + " km/h",
                    precipitation: data.hourly.precipitation_probability ? data.hourly.precipitation_probability[i] + "%" : "0%",
                    icon: getWeatherEmoji(mapWeatherCode(data.hourly.weather_code[i]))
                });
            }
        }
        
        // Parse daily forecast
        enhancedWeatherData.forecast.daily = [];
        if (data.daily && data.daily.time) {
            for (var i = 0; i < data.daily.time.length; i++) {
                var date = new Date(data.daily.time[i]);
                var dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
                var dayName = dayNames[date.getDay()];
                
                enhancedWeatherData.forecast.daily.push({
                    date: dayName,
                    condition: mapWeatherCode(data.daily.weather_code[i]),
                    tempMax: Math.round(data.daily.temperature_2m_max[i]) + "°",
                    tempMin: Math.round(data.daily.temperature_2m_min[i]) + "°",
                    precipitation: data.daily.precipitation_probability_max ? data.daily.precipitation_probability_max[i] + "%" : "0%",
                    wind: Math.round(data.daily.wind_speed_10m_max[i]) + " km/h",
                    humidity: Math.round(data.daily.relative_humidity_2m_max[i]) + "%",
                    icon: getWeatherEmoji(mapWeatherCode(data.daily.weather_code[i]))
                });
            }
        }
        
        // Set legacy weatherData for compatibility
        weatherData = {
            locationDisplay: locationDisplay || enhancedWeatherData.location.name,
            currentTemp: enhancedWeatherData.current.temp,
            feelsLike: enhancedWeatherData.current.feelsLike,
            currentCondition: enhancedWeatherData.current.condition,
            forecast: enhancedWeatherData.forecast.daily.slice(0, 7).map(function(day) {
                return {
                    date: day.date,
                    condition: day.condition,
                    temp: day.tempMax + " / " + day.tempMin,
                    emoji: day.icon
                };
            })
        };
        
        loading = false;
        console.log("Open-Meteo weather data parsed successfully");
    }
    
    function parseEnhancedWeather(data, locationDisplay) {
        // This function handles cached data parsing
        if (data.current && data.current.temp) {
            // WeatherAPI.com format
            parseWeatherApiData(data, locationDisplay);
        } else if (data.current && data.current.temperature_2m) {
            // Open-Meteo format
            parseOpenMeteoData(data, locationDisplay);
        } else {
            console.error("Unknown weather data format");
            loading = false;
        }
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
    
    // Function to set WeatherAPI.com API key
    function setWeatherApiKey(key) {
        weatherSettings.weatherApiKey = key;
        weatherSettings.useWeatherApi = true;
        console.log("WeatherAPI.com key set, will use enhanced weather data");
    }
    
    // Function to toggle between APIs
    function toggleApi(useWeatherApi) {
        weatherSettings.useWeatherApi = useWeatherApi;
        console.log("Switched to", useWeatherApi ? "WeatherAPI.com" : "Open-Meteo");
        clearCache();
        loadWeather();
    }
} 