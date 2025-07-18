import QtQuick 2.15 // Import Qt Quick module for basic QML functionality
import QtQuick.Controls 2.15 // Import Qt Quick Controls for UI components like buttons and layouts
import QtQuick.Layouts 1.15 // Import Qt Quick Layouts for automatic positioning and sizing
import "root:/modules/common" // Import common QML modules for shared functionality
import "root:/modules/common/widgets" // Import common widgets like RippleButton and MaterialSymbol
import "root:/modules/weather" // Import weather-related QML modules for forecast data

Item { // Root container for the entire weather sidebar page - controls the overall page structure
    id: root // Set the id for this Item so other components can reference it
    anchors.fill: parent // Fill the entire parent container (sidebar) - controls the page size

    Rectangle { // Modern gradient background for the whole sidebar - controls the main background appearance
        anchors.fill: parent // Fill the entire parent container
        radius: Appearance.rounding.large // Apply large border radius for modern rounded corners
        gradient: Gradient { // Create a vertical gradient background - controls the background color transition
            GradientStop { position: 0.0; color: Qt.rgba( // Top gradient stop - controls the top background color
                Appearance.colors.colLayer1.r, // Red component from theme
                Appearance.colors.colLayer1.g, // Green component from theme
                Appearance.colors.colLayer1.b, // Blue component from theme
                0.55 // Alpha transparency (55% opacity) - controls background transparency
            )}
            GradientStop { position: 1.0; color: Qt.rgba( // Bottom gradient stop - controls the bottom background color
                Appearance.colors.colLayer1.r, // Red component from theme
                Appearance.colors.colLayer1.g, // Green component from theme
                Appearance.colors.colLayer1.b, // Blue component from theme
                0.40 // Alpha transparency (40% opacity) - creates gradient fade effect
            )}
        }
        border.color: Qt.rgba(Appearance.colors.colOnLayer0.r, Appearance.colors.colOnLayer0.g, Appearance.colors.colOnLayer0.b, 0.08) // Border color - controls the subtle border around the sidebar
        border.width: 1 // Border width - controls the thickness of the border
        z: 0 // Z-index - ensures this background is behind all other elements
        
        // Subtle inner shadow effect - creates depth and modern appearance
        Rectangle {
            anchors.fill: parent // Fill the parent background
            anchors.margins: 1 // 1px margin from parent edges - controls the shadow offset
            radius: parent.radius - 1 // Slightly smaller radius than parent - controls shadow corner rounding
            color: "transparent" // Transparent fill - allows the border to show
            border.color: Qt.rgba(1, 1, 1, 0.05) // White border with 5% opacity - controls the inner highlight effect
            border.width: 1 // Border width - controls the highlight thickness
        }
    }

    // --- Weather data properties - control the data displayed in the UI ---
    property var forecastData: [] // Holds 10-day forecast data array - controls the forecast cards content
    property string locationDisplay: "Halifax, Nova Scotia" // Displayed location text - controls the header location text
    property string lastUpdated: Qt.formatDateTime(new Date(), "hh:mm AP") // Last updated time - controls the header timestamp
    property string currentTemp: "--" // Current temperature - controls the current temp display
    property string feelsLike: "--" // Feels like temperature - controls the feels like temp display
    property string airQuality: "--" // Air quality index - controls the AQI display
    property real latitude: 44.65 // Halifax default latitude - controls the weather API location
    property real longitude: -63.57 // Halifax default longitude - controls the weather API location
    
    // --- Weather alert properties - control the alert system ---
    property var weatherAlerts: [] // Array to hold weather alerts - controls the alert messages
    property bool hasAlerts: weatherAlerts.length > 0 // Whether there are any alerts - controls alert section visibility
    
    // --- Temperature range calculation properties - control the temperature bar scaling ---
    property real globalTempMin: 999 // Global minimum temperature across all days - controls bar scaling
    property real globalTempMax: -999 // Global maximum temperature across all days - controls bar scaling
    property real tempRange: globalTempMax - globalTempMin // Temperature range - controls bar width calculations
    
    // --- Function to calculate temperature range - controls the temperature bar scaling logic ---
    function calculateTempRange() {
        if (!forecastData || forecastData.length === 0) return // Exit if no data
        
        var minTemp = 999 // Initialize minimum temperature
        var maxTemp = -999 // Initialize maximum temperature
        
        for (var i = 0; i < forecastData.length; i++) { // Loop through all forecast days
            var dayMin = parseFloat(forecastData[i].tempMin) // Get day's minimum temp
            var dayMax = parseFloat(forecastData[i].tempMax) // Get day's maximum temp
            
            if (!isNaN(dayMin) && dayMin < minTemp) minTemp = dayMin // Update global minimum
            if (!isNaN(dayMax) && dayMax > maxTemp) maxTemp = dayMax // Update global maximum
        }
        
        globalTempMin = minTemp // Set global minimum - controls bar scaling
        globalTempMax = maxTemp // Set global maximum - controls bar scaling
        tempRange = maxTemp - minTemp // Calculate range - controls bar width calculations
    }
    
    // --- Function to calculate bar width based on temperature variance - controls the temperature bar appearance ---
    function calculateBarWidth(tempMin, tempMax) {
        if (tempRange <= 0) return 120 // Default width if no range - controls minimum bar width
        
        var dayRange = parseFloat(tempMax) - parseFloat(tempMin) // Calculate day's temperature range
        var trackWidth = 120 // Width of the grey track (scaled down)
        var minWidth = 60 // Minimum bar width - controls the smallest possible bar (scaled down)
        var maxWidth = 100 // Maximum bar width - controls the largest possible bar (scaled down)
        
        // Calculate width based on temperature variance (larger variance = wider bar)
        var normalizedRange = dayRange / tempRange // Normalize to 0-1 range
        var width = minWidth + (normalizedRange * (maxWidth - minWidth)) // Calculate proportional width
        
        return Math.max(minWidth, Math.min(maxWidth, width)) // Clamp to min/max bounds
    }
        
    // --- Function to calculate bar position within the grey track - controls the temperature bar positioning ---
    function calculateBarPosition(tempMin, tempMax) {
        if (tempRange <= 0) return 10 // Default position if no range
        
        var trackWidth = 120 // Width of the grey track (scaled down)
        var barWidth = calculateBarWidth(tempMin, tempMax) // Width of the colored bar
        
        // Calculate where the bar should start based on the minimum temperature
        var normalizedMin = (parseFloat(tempMin) - globalTempMin) / tempRange // Normalize min temp to 0-1
        var availableSpace = trackWidth - barWidth // Available space for positioning
        var startPosition = 10 + (normalizedMin * Math.max(0, availableSpace - 20)) // Calculate start position with padding
        
        return Math.max(10, Math.min(trackWidth - barWidth - 10, startPosition)) // Clamp to track bounds with padding
    }
        
    // --- Function to check for weather alerts - controls the alert system logic ---
        function checkWeatherAlerts() {
        var alerts = [] // Initialize alerts array
            
        if (!forecastData || forecastData.length === 0) { // Check if no forecast data
            weatherAlerts = alerts // Set empty alerts
                return
            }
            
            // Check current and next few days for alerts
        for (var i = 0; i < Math.min(3, forecastData.length); i++) { // Loop through first 3 days
            var day = forecastData[i] // Get current day data
                
            // Heat warning (above 30°C) - controls heat alert display
                if (parseFloat(day.tempMax) > 30) {
                    alerts.push({
                        type: "heat",
                        severity: "warning",
                        message: qsTr("Heat Warning: High temperature of ") + day.tempMax + "°C " + qsTr("expected"),
                        icon: "🌡️",
                    color: "#FF5722" // Orange-red color for heat alerts
                    })
                }
                
            // Extreme heat warning (above 35°C) - controls extreme heat alert display
                if (parseFloat(day.tempMax) > 35) {
                    alerts.push({
                        type: "extreme-heat",
                        severity: "danger",
                        message: qsTr("Extreme Heat Warning: Dangerous temperature of ") + day.tempMax + "°C " + qsTr("expected"),
                        icon: "🔥",
                    color: "#D32F2F" // Red color for extreme heat alerts
                    })
                }
                
            // Cold warning (below -20°C) - controls cold alert display
                if (parseFloat(day.tempMin) < -20) {
                    alerts.push({
                        type: "cold",
                        severity: "warning",
                        message: qsTr("Cold Warning: Low temperature of ") + day.tempMin + "°C " + qsTr("expected"),
                        icon: "❄️",
                    color: "#2196F3" // Blue color for cold alerts
                    })
                }
                
            // Extreme cold warning (below -30°C) - controls extreme cold alert display
                if (parseFloat(day.tempMin) < -30) {
                    alerts.push({
                        type: "extreme-cold",
                        severity: "danger",
                        message: qsTr("Extreme Cold Warning: Dangerous temperature of ") + day.tempMin + "°C " + qsTr("expected"),
                        icon: "🥶",
                    color: "#1976D2" // Dark blue color for extreme cold alerts
                    })
                }
                
            // High precipitation warning (above 80%) - controls rain alert display
                if (parseFloat(day.precip) > 80) {
                    alerts.push({
                        type: "heavy-rain",
                        severity: "warning",
                        message: qsTr("Heavy Rain Warning: ") + day.precip + "% " + qsTr("chance of precipitation"),
                        icon: "🌧️",
                    color: "#1976D2" // Blue color for rain alerts
                    })
                }
                
            // Storm conditions (check condition text) - controls storm alert display
                if (day.condition && (
                    day.condition.toLowerCase().includes("storm") ||
                    day.condition.toLowerCase().includes("thunder") ||
                    day.condition.toLowerCase().includes("severe")
                )) {
                    alerts.push({
                        type: "storm",
                        severity: "danger",
                        message: qsTr("Storm Warning: ") + day.condition,
                        icon: "⛈️",
                    color: "#FF9800" // Orange color for storm alerts
                    })
                }
            }
            
        // Check air quality - controls air quality alert display
            if (airQuality !== "--" && parseInt(airQuality) > 150) {
                alerts.push({
                    type: "air-quality",
                    severity: parseInt(airQuality) > 200 ? "danger" : "warning",
                    message: qsTr("Poor Air Quality: AQI ") + airQuality,
                    icon: "😷",
                color: parseInt(airQuality) > 200 ? "#D32F2F" : "#FF9800" // Red or orange based on severity
                })
            }
            
        weatherAlerts = alerts // Set the alerts - controls alert section content
        }

    // --- Weather data refresh function - controls the refresh button functionality ---
    function refreshWeather() { // Function to refresh weather and air quality
        root.lastUpdated = Qt.formatDateTime(new Date(), "hh:mm AP") // Update last updated time - controls header timestamp
        if (weatherLoader.item) { // If weatherLoader is loaded
            weatherLoader.item.clearCache() // Clear weather cache - controls data freshness
            weatherLoader.item.loadWeather() // Load new weather data - controls forecast content
        }
        airQualityLoader.active = false // Deactivate air quality loader - controls AQI refresh
        airQualityLoader.active = true // Reactivate to trigger reload - controls AQI refresh
    }

    // --- Loader: Hidden weather data provider - controls the weather data source ---
    Loader { // Loader for weather data - controls the weather forecast loading
        id: weatherLoader // Set id for reference
        source: "../weather/WeatherForecast.qml" // QML file to load - controls the weather data source
        visible: false // Keep loader hidden - controls loader visibility
        onLoaded: { // When loaded - controls the data connection
            if (item) { // If item is loaded
                root.forecastData = item.forecastData // Set forecast data - controls forecast cards
                root.locationDisplay = item.locationDisplay // Set location - controls header location
                root.currentTemp = item.currentTemp // Set current temp - controls current temp display
                root.feelsLike = item.feelsLike // Set feels like temp - controls feels like display
                item.forecastDataChanged.connect(function() { // Connect to data changes
                    root.forecastData = item.forecastData // Update forecast data - controls forecast cards
                    root.calculateTempRange() // Calculate temperature range - controls bar scaling
                    root.checkWeatherAlerts() // Check for weather alerts - controls alert system
                })
                item.locationDisplayChanged.connect(function() { root.locationDisplay = item.locationDisplay }) // Update location - controls header
                item.currentTempChanged.connect(function() { root.currentTemp = item.currentTemp }) // Update temp - controls current temp
                item.feelsLikeChanged.connect(function() { root.feelsLike = item.feelsLike }) // Update feels like - controls feels like temp
                item.clearCache() // Clear cache - controls data freshness
                item.loadWeather() // Load weather - controls initial data load
                root.calculateTempRange() // Calculate initial temperature range - controls bar scaling
            }
        }
    }

    // --- Loader: Fetch air quality from Open-Meteo - controls the air quality data source ---
    Loader { // Loader for air quality data - controls AQI loading
        id: airQualityLoader // Set id for reference
        active: true // Loader is active - controls AQI loading state
        asynchronous: true // Load asynchronously - controls loading performance
        sourceComponent: QtObject { // Inline QML object - controls AQI data fetching
            Component.onCompleted: { // When component is ready - controls AQI initialization
                var xhr = new XMLHttpRequest(); // Create XHR - controls HTTP request
                var url = `https://air-quality-api.open-meteo.com/v1/air-quality?latitude=${root.latitude}&longitude=${root.longitude}&hourly=us_aqi&timezone=auto`; // API URL - controls AQI data source
                xhr.onreadystatechange = function() { // On XHR state change - controls AQI response handling
                    if (xhr.readyState === XMLHttpRequest.DONE) { // If done - controls completion check
                        if (xhr.status === 200) { // If success - controls success check
                            try {
                                var data = JSON.parse(xhr.responseText); // Parse response - controls AQI data parsing
                                if (data.hourly && data.hourly.us_aqi && data.hourly.us_aqi.length > 0) { // If AQI data exists
                                    var aqiValue = data.hourly.us_aqi[0]; // Get AQI value - controls AQI display
                                    root.airQuality = (aqiValue !== undefined && aqiValue !== null) ? String(aqiValue) : "--"; // Set AQI - controls AQI text
                                    root.checkWeatherAlerts() // Check for alerts when AQI changes - controls alert system
                                } else {
                                    root.airQuality = "--"; // No AQI - controls AQI fallback
                                    root.checkWeatherAlerts() // Check for alerts when AQI changes - controls alert system
                                }
                            } catch (e) { root.airQuality = "--"; } // Error parsing - controls error handling
                        } else { root.airQuality = "--"; } // HTTP error - controls error handling
                    }
                };
                xhr.open("GET", url); // Open GET request - controls HTTP method
                xhr.send(); // Send request - controls data fetching
            }
        }
    }

    // --- Main vertical layout for the sidebar - controls the overall page layout ---
    ColumnLayout { // Main vertical layout for sidebar - controls the page structure
        anchors.fill: parent // Fill the sidebar vertically - controls layout size
        anchors.margins: Math.max(12, parent.width * 0.02) // Responsive margins
        spacing: Math.max(10, parent.height * 0.015) // Responsive spacing between sections

        // --- Modern Header: Location, last updated, refresh button - controls the header section ---
        RowLayout { // Header row layout - controls header positioning
            Layout.fillWidth: true // Fill the width - controls header width
            Layout.preferredHeight: Math.max(50, parent.height * 0.07) // Responsive header height
            spacing: Math.max(10, parent.width * 0.015) // Responsive spacing between header elements
            
            // Location text on the left
            Text { // Location text - controls the location display
                text: root.locationDisplay && root.locationDisplay.length > 0 ? root.locationDisplay : qsTr("Halifax, Nova Scotia") // Location text - controls location content
                font.pixelSize: Math.max(Appearance.font.pixelSize.large + 2, parent.height * 0.12) // Responsive font size
                font.weight: Font.DemiBold // Professional weight - controls location font weight
                color: Appearance.colors.colOnLayer1 // Text color - controls location text color
                elide: Text.ElideRight // Text elision - controls long text handling
                horizontalAlignment: Text.AlignLeft // Left aligned - controls text alignment
                Layout.alignment: Qt.AlignVCenter // Center vertically - controls vertical alignment
            }
            
            // Flexible spacer to push updated text to the right
            Item { Layout.fillWidth: true }
            
            // Updated text on the right
            Text { // Last updated text - controls the timestamp display
                text: root.lastUpdated ? qsTr("Updated ") + root.lastUpdated : "" // Timestamp text - controls timestamp content
                font.pixelSize: Math.max(Appearance.font.pixelSize.small, parent.height * 0.08) // Responsive font size
                font.weight: Font.Normal // Normal weight - controls timestamp font weight
                color: Appearance.colors.colOnLayer1 // Text color - controls timestamp text color
                opacity: 0.65 // Slightly more subtle - controls timestamp transparency
                elide: Text.ElideRight // Text elision - controls long text handling
                horizontalAlignment: Text.AlignRight // Right aligned - controls text alignment
                Layout.alignment: Qt.AlignVCenter // Center vertically - controls vertical alignment
            }
            
            RippleButton { // Refresh button - controls the refresh functionality
                Layout.preferredWidth: Math.max(36, parent.height * 0.65) // Responsive button width
                Layout.preferredHeight: Math.max(36, parent.height * 0.65) // Responsive button height
                buttonRadius: Appearance.rounding.full // Full radius - controls button corner rounding
                onClicked: root.refreshWeather() // Click handler - controls refresh action
                
                // Subtle hover effect background - controls button hover appearance
                Rectangle {
                    anchors.fill: parent // Fill button - controls hover background size
                    radius: parent.buttonRadius // Match button radius - controls hover corner rounding
                    color: Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, 0.1) // Hover color - controls hover background color
                    opacity: parent.hovered ? 1 : 0 // Show on hover - controls hover visibility
                    Behavior on opacity { NumberAnimation { duration: 150 } } // Smooth transition - controls hover animation
                }
                
                contentItem: MaterialSymbol { // Refresh icon - controls button icon
                    anchors.centerIn: parent // Center icon - controls icon positioning
                    text: "refresh" // Icon name - controls icon type
                    iconSize: Math.max(18, parent.height * 0.35) // Responsive icon size
                    color: Appearance.colors.colOnLayer1 // Icon color - controls icon color
                }
            }
        }

        Rectangle { // Modern separator after header - controls header separator appearance
            Layout.fillWidth: true // Fill width - controls separator width
            height: 1 // Height - controls separator thickness
            radius: 0.5 // Radius - controls separator corner rounding
            gradient: Gradient { // Gradient separator - controls separator color transition
                orientation: Gradient.Horizontal // Horizontal gradient - controls gradient direction
                GradientStop { position: 0.0; color: "transparent" } // Start transparent - controls left edge
                GradientStop { position: 0.2; color: Qt.rgba(Appearance.colors.colOnLayer0.r, Appearance.colors.colOnLayer0.g, Appearance.colors.colOnLayer0.b, 0.15) } // Fade in - controls left fade
                GradientStop { position: 0.8; color: Qt.rgba(Appearance.colors.colOnLayer0.r, Appearance.colors.colOnLayer0.g, Appearance.colors.colOnLayer0.b, 0.15) } // Solid middle - controls center color
                GradientStop { position: 1.0; color: "transparent" } // Fade out - controls right edge
            }
        }

        // --- Modern current weather info card - controls the current weather display ---
        Rectangle { // Current weather card - controls current weather appearance
            Layout.fillWidth: true // Fill width - controls card width
            Layout.preferredHeight: Math.max(75, parent.height * 0.11) // Responsive card height
            radius: Appearance.rounding.large // Large radius - controls card corner rounding
            color: Qt.rgba(Appearance.colors.colLayer1.r, Appearance.colors.colLayer1.g, Appearance.colors.colLayer1.b, 0.15) // Card background - controls card background color
            border.color: Qt.rgba(1, 1, 1, 0.08) // Border color - controls card border color
            border.width: 1 // Border width - controls card border thickness
            
            RowLayout { // Card content row - controls card content layout
                anchors.fill: parent // Fill card - controls content size
                anchors.margins: Math.max(14, parent.width * 0.025) // Responsive margins
                spacing: Math.max(20, parent.width * 0.03) // Responsive spacing between columns
                
                // Current temperature column - controls current temp display
                Column { // Current temp column - controls temp layout
                    spacing: 8 // Better spacing within column - controls temp element spacing
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter // Center alignment - controls temp positioning
                    Text { // "Current" label - controls temp label
                        text: qsTr("Current") // Label text - controls temp label content
                        color: Appearance.colors.colOnLayer1 // Text color - controls temp label color
                        font.pixelSize: Math.max(Appearance.font.pixelSize.small, parent.height * 0.08) // Responsive font size
                        font.weight: Font.Medium // Font weight - controls temp label weight
                        opacity: 0.7 // Transparency - controls temp label opacity
                        horizontalAlignment: Text.AlignHCenter // Center text - controls temp label alignment
                    }
                    Text { // Temperature value - controls temp value display
                        text: root.currentTemp + (root.feelsLike ? ("  " + qsTr("feels ") + root.feelsLike) : "") // Temp text - controls temp content
                        color: Appearance.colors.colOnLayer1 // Text color - controls temp value color
                        font.pixelSize: Math.max(Appearance.font.pixelSize.large, parent.height * 0.12) // Responsive font size
                        font.weight: Font.DemiBold // Font weight - controls temp value weight
                        horizontalAlignment: Text.AlignHCenter // Center text - controls temp value alignment
                    }
                }
                
                Rectangle { // Subtle vertical separator - controls separator appearance
                    width: 1 // Width - controls separator thickness
                    height: Math.max(35, parent.height * 0.5) // Responsive separator height
                    color: Qt.rgba(Appearance.colors.colOnLayer0.r, Appearance.colors.colOnLayer0.g, Appearance.colors.colOnLayer0.b, 0.15) // Color - controls separator color
                    radius: 0.5 // Radius - controls separator corner rounding
                }
                
                // Wind column - controls wind display
                Column { // Wind column - controls wind layout
                    spacing: 8 // Better spacing within column - controls wind element spacing
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter // Center alignment - controls wind positioning
                    Text { // "Wind" label - controls wind label
                        text: qsTr("Wind") // Label text - controls wind label content
                        color: Appearance.colors.colOnLayer1 // Text color - controls wind label color
                        font.pixelSize: Math.max(Appearance.font.pixelSize.small, parent.height * 0.08) // Responsive font size
                        font.weight: Font.Medium // Font weight - controls wind label weight
                        opacity: 0.7 // Transparency - controls wind label opacity
                        horizontalAlignment: Text.AlignHCenter // Center text - controls wind label alignment
                    }
                    Text { // Wind value - controls wind value display
                        text: root.forecastData.length > 0 && root.forecastData[0].wind ? root.forecastData[0].wind + " km/h" : "--" // Wind text - controls wind content
                        color: Appearance.colors.colOnLayer1 // Text color - controls wind value color
                        font.pixelSize: Math.max(Appearance.font.pixelSize.large, parent.height * 0.12) // Responsive font size
                        font.weight: Font.DemiBold // Font weight - controls wind value weight
                        horizontalAlignment: Text.AlignHCenter // Center text - controls wind value alignment
                    }
                }

                Rectangle { // Subtle vertical separator - controls separator appearance
                    width: 1 // Width - controls separator thickness
                    height: Math.max(35, parent.height * 0.5) // Responsive separator height
                    color: Qt.rgba(Appearance.colors.colOnLayer0.r, Appearance.colors.colOnLayer0.g, Appearance.colors.colOnLayer0.b, 0.15) // Color - controls separator color
                    radius: 0.5 // Radius - controls separator corner rounding
                }

                // Humidity column - controls humidity display
                Column { // Humidity column - controls humidity layout
                    spacing: 8 // Better spacing within column - controls humidity element spacing
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter // Center alignment - controls humidity positioning
                    Text { // "Humidity" label - controls humidity label
                        text: qsTr("Humidity") // Label text - controls humidity label content
                        color: Appearance.colors.colOnLayer1 // Text color - controls humidity label color
                        font.pixelSize: Math.max(Appearance.font.pixelSize.small, parent.height * 0.08) // Responsive font size
                        font.weight: Font.Medium // Font weight - controls humidity label weight
                        opacity: 0.7 // Transparency - controls humidity label opacity
                        horizontalAlignment: Text.AlignHCenter // Center text - controls humidity label alignment
                    }
                    Text { // Humidity value - controls humidity value display
                        text: root.forecastData.length > 0 && root.forecastData[0].humidity ? root.forecastData[0].humidity + "%" : "--" // Humidity text - controls humidity content
                        color: Appearance.colors.colOnLayer1 // Text color - controls humidity value color
                        font.pixelSize: Math.max(Appearance.font.pixelSize.large, parent.height * 0.12) // Responsive font size
                        font.weight: Font.DemiBold // Font weight - controls humidity value weight
                        horizontalAlignment: Text.AlignHCenter // Center text - controls humidity value alignment
                    }
                }
                                }
        }
        
        // --- Weather Alerts Section - controls the alert display ---
        Item { // Alerts container - controls alert section positioning
            id: alertsSection // Alert section ID - controls alert section reference
            visible: root.hasAlerts // Show only if alerts exist - controls alert section visibility
            anchors.left: parent.left // Left anchor - controls alert left positioning
            anchors.right: parent.right // Right anchor - controls alert right positioning
            anchors.bottom: parent.bottom // Bottom anchor - controls alert bottom positioning
            height: Math.max(36, Math.min(64, root.weatherAlerts.length * 28 + 20)) // Dynamic height - controls alert section height
            z: 10 // High z-index - controls alert layering
            Rectangle { // Alert background - controls alert appearance
                anchors.fill: parent // Fill parent - controls alert background size
                radius: Appearance.rounding.medium // Medium radius - controls alert corner rounding
                color: Qt.rgba(0.95, 0.2, 0.2, 0.1) // Red background - controls alert background color
                border.color: Qt.rgba(0.95, 0.2, 0.2, 0.3) // Red border - controls alert border color
                border.width: 1 // Border width - controls alert border thickness
                RowLayout { // Alert content row - controls alert content layout
                    anchors.fill: parent // Fill parent - controls alert content size
                    anchors.margins: 8 // Margins - controls alert content padding
                    spacing: 8 // Spacing - controls alert element spacing
                    Text { // Warning emoji - controls alert icon
                        text: "⚠️" // Warning emoji - controls alert icon content
                        font.pixelSize: 16 // Font size - controls alert icon size
                        Layout.alignment: Qt.AlignVCenter // Center alignment - controls alert icon positioning
                    }
                    Repeater { // Alert messages - controls alert message display
                        model: root.weatherAlerts // Alert data - controls alert message source
                        delegate: Text { // Alert message text - controls individual alert display
                            text: modelData.message // Alert message - controls alert message content
                            font.pixelSize: Appearance.font.pixelSize.small - 2 // Font size - controls alert message size
                            color: Appearance.colors.colOnLayer1 // Text color - controls alert message color
                            elide: Text.ElideRight // Text elision - controls long message handling
                            maximumLineCount: 1 // Single line - controls message line limit
                            wrapMode: Text.WordWrap // Word wrap - controls message wrapping
                            Layout.alignment: Qt.AlignVCenter // Center alignment - controls message positioning
                }
                    }
                }
            }
        }

        Rectangle { // Modern separator after current weather - controls separator appearance
            Layout.fillWidth: true // Fill width - controls separator width
            height: 1 // Height - controls separator thickness
            radius: 0.5 // Radius - controls separator corner rounding
            gradient: Gradient { // Gradient separator - controls separator color transition
                orientation: Gradient.Horizontal // Horizontal gradient - controls gradient direction
                GradientStop { position: 0.0; color: "transparent" } // Start transparent - controls left edge
                GradientStop { position: 0.2; color: Qt.rgba(Appearance.colors.colOnLayer0.r, Appearance.colors.colOnLayer0.g, Appearance.colors.colOnLayer0.b, 0.15) } // Fade in - controls left fade
                GradientStop { position: 0.8; color: Qt.rgba(Appearance.colors.colOnLayer0.r, Appearance.colors.colOnLayer0.g, Appearance.colors.colOnLayer0.b, 0.15) } // Solid middle - controls center color
                GradientStop { position: 1.0; color: "transparent" } // Fade out - controls right edge
            }
        }

        // --- Modern 10-day forecast section - controls the forecast display ---
        ColumnLayout { // Container for the forecast section - controls forecast layout
            Layout.fillWidth: true // Fill the width of the parent - controls forecast section width
            Layout.fillHeight: true // Fill all remaining space - controls forecast section height
            spacing: Math.max(10, parent.height * 0.015) // Responsive spacing

            Text { // Section header: '10-Day Forecast' - controls forecast header
                text: qsTr("10-Day Forecast") // Display section title - controls forecast header content
                font.pixelSize: Math.max(Appearance.font.pixelSize.large + 1, parent.height * 0.02) // Responsive font size
                font.weight: Font.DemiBold // Professional weight - controls forecast header weight
                color: Appearance.colors.colOnLayer1 // Use theme color for text - controls forecast header color
                opacity: 0.95 // Less faded for better readability - controls forecast header opacity
                horizontalAlignment: Text.AlignHCenter // Center text - controls forecast header alignment
                Layout.alignment: Qt.AlignHCenter // Center in layout - controls forecast header positioning
            }

            Flickable { // Scrollable area for forecast cards - controls forecast scrolling
                Layout.fillWidth: true // Fill width - controls scroll area width
                Layout.fillHeight: true // Fill the forecast section height - controls scroll area height
                contentHeight: forecastColumn.height // Set content height to column height - controls scroll content size
                clip: true // Clip content to bounds - controls content clipping
                interactive: contentHeight > height // Enable scrolling if content is taller than view - controls scroll behavior
                
                Column { // Forecast cards column - controls forecast card layout
                    id: forecastColumn // ID for column - controls forecast column reference
                    width: parent.width // Match parent width - controls forecast column width
                    spacing: Math.max(6, parent.height * 0.008) // Responsive spacing between forecast cards
                    
                    Repeater { // Forecast cards repeater - controls forecast card generation
                        model: Math.min(10, root.forecastData.length) // Show up to 10 days - controls number of cards
                        delegate: Rectangle { // Modern forecast card - controls individual card appearance
                            width: parent.width // Fill width - controls card width
                            height: Math.max(70, parent.height * 0.08) // Responsive card height
                            radius: Appearance.rounding.large // Consistent with other elements - controls card corner rounding
                            color: Qt.rgba(Appearance.colors.colLayer1.r, Appearance.colors.colLayer1.g, Appearance.colors.colLayer1.b, 0.12) // Subtle card background - controls card background color
                            border.color: Qt.rgba(Appearance.colors.colOnLayer0.r, Appearance.colors.colOnLayer0.g, Appearance.colors.colOnLayer0.b, 0.08) // Subtle border - controls card border color
                            border.width: 1 // Border width - controls card border thickness
                            
                            // Subtle hover effect - controls card hover appearance
                            MouseArea { // Hover area - controls card hover detection
                                anchors.fill: parent // Fill card - controls hover area size
                                hoverEnabled: true // Enable hover - controls hover functionality
                                onEntered: parent.color = Qt.rgba(Appearance.colors.colLayer1.r, Appearance.colors.colLayer1.g, Appearance.colors.colLayer1.b, 0.18) // Hover color - controls hover background
                                onExited: parent.color = Qt.rgba(Appearance.colors.colLayer1.r, Appearance.colors.colLayer1.g, Appearance.colors.colLayer1.b, 0.12) // Normal color - controls normal background
                            }
                            
                            RowLayout { // Card content row - controls card content layout
                                anchors.fill: parent // Fill card - controls content size
                                anchors.margins: Math.max(8, parent.width * 0.015) // Reduced margins
                                spacing: Math.max(2, parent.width * 0.005) // Minimal spacing between columns
                                
                                // Day name column - controls day display
                                Text { // Day label - controls day display
                                    text: root.forecastData[index].date // Day of week - controls day content
                                    font.pixelSize: Math.max(Appearance.font.pixelSize.huge, parent.height * 0.25) // Responsive font size
                                    font.weight: Font.Bold // Bold font for day names
                                    color: Appearance.colors.colOnLayer1 // Text color - controls day text color
                                    verticalAlignment: Text.AlignVCenter // Centered vertically - controls day alignment
                                    Layout.preferredWidth: 80 // Fixed width for consistent day column alignment
                                    horizontalAlignment: Text.AlignLeft // Left aligned for clean column
                                }
                                
                                // Flexible spacer to push weather icon to the right
                                Item { Layout.preferredWidth: 20 }
                                
                                // Weather icon and precipitation column - controls icon and precip display
                                ColumnLayout { // Icon and precip column - controls icon layout
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter // Center alignment
                                    spacing: 2 // Minimal spacing between icon and precip
                                    
                                    Item { // Weather icon container - controls icon positioning
                                        width: Math.max(32, parent.height * 0.45); height: Math.max(32, parent.height * 0.45) // Compact icon container size
                                        Image { // Fog icon - controls fog icon display
                                            anchors.centerIn: parent // Center icon - controls fog icon positioning
                                            source: root.forecastData[index].condition && root.forecastData[index].condition.toLowerCase().indexOf("fog") !== -1 ? "root:/assets/weather/fog.svg" : "" // Show fog icon if needed - controls fog icon source
                                            visible: root.forecastData[index].condition && root.forecastData[index].condition.toLowerCase().indexOf("fog") !== -1 // Only show if fog - controls fog icon visibility
                                            width: Math.max(32, parent.height * 0.45); height: Math.max(32, parent.height * 0.45) // Responsive fog icon size
                                            fillMode: Image.PreserveAspectFit // Keep aspect ratio - controls fog icon scaling
                                            }
                                        Text { // Weather emoji - controls emoji display
                                            anchors.centerIn: parent // Center emoji - controls emoji positioning
                                            text: (!root.forecastData[index].condition || root.forecastData[index].condition.toLowerCase().indexOf("fog") === -1) ? root.forecastData[index].emoji : "" // Show emoji if not fog - controls emoji content
                                            font.pixelSize: Math.max(32, parent.height * 0.45) // Responsive emoji size
                                            horizontalAlignment: Text.AlignCenter // Centered - controls emoji alignment
                                            visible: !root.forecastData[index].condition || root.forecastData[index].condition.toLowerCase().indexOf("fog") === -1 // Only show if not fog - controls emoji visibility
                                            }
                                        }
                                        
                                                                            Text { // Precipitation % - controls precipitation display
                                        text: root.forecastData[index].precip > 0 ? root.forecastData[index].precip + "%" : "" // Show if >0% - controls precipitation content
                                        font.pixelSize: Math.max(Appearance.font.pixelSize.smaller, parent.height * 0.15) // Responsive font size
                                        font.weight: Font.Bold // Bold font for precipitation percentage
                                        color: Appearance.colors.colOnLayer1 // Text color - controls precipitation text color
                                        visible: root.forecastData[index].precip > 0 // Only show if >0% - controls precipitation visibility
                                        horizontalAlignment: Text.AlignHCenter // Center aligned under icon
                                        Layout.alignment: Qt.AlignHCenter // Center in layout
                                        Layout.preferredWidth: contentWidth // Only take up needed width
                                        Layout.preferredHeight: contentHeight // Only take up needed height
                                        }
                                    }
                                
                                // No spacer - direct connection
                                
                                // Temperature range section - controls temperature display (now on the right)
                                RowLayout { // Temperature bar row - controls temperature display layout
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight // Center vertically and align to right
                                    spacing: 4 // Minimal spacing between elements
                                    
                                    Text { // Min temp - controls minimum temperature display
                                        text: root.forecastData[index].tempMin + "°" // Min temp value - controls min temp content
                                        font.pixelSize: Math.max(Appearance.font.pixelSize.large, parent.height * 0.2) // Responsive font size
                                        font.weight: Font.Bold // Bold font for temperatures
                                        color: Appearance.colors.colOnLayer1 // Text color - controls min temp text color
                                        verticalAlignment: Text.AlignVCenter // Centered - controls min temp alignment
                                        Layout.preferredWidth: contentWidth // Only take up needed width
                                        horizontalAlignment: Text.AlignRight // Right aligned for clean column
                                    }
                                    
                                    Item { // Container for the temperature bar system
                                        width: 120; height: 12 // Scaled down width to fit narrower cards
                                        anchors.verticalCenter: parent.verticalCenter // Centered vertically
                                        
                                        Rectangle { // Grey background track
                                            anchors.fill: parent // Fill the container
                                            radius: 6 // Rounded corners
                                            color: Qt.rgba(Appearance.colors.colOnLayer0.r, Appearance.colors.colOnLayer0.g, Appearance.colors.colOnLayer0.b, 0.2) // Light grey background
                                        }
                                        
                                        Rectangle { // Colored temperature bar that fills the track
                                            width: calculateBarWidth(root.forecastData[index].tempMin, root.forecastData[index].tempMax) // Dynamic width based on temperature range
                                            height: 12; radius: 6 // Same height as track
                                            x: calculateBarPosition(root.forecastData[index].tempMin, root.forecastData[index].tempMax) // Dynamic position based on temperature
                                            gradient: Gradient { // Gradient bar like in the reference image
                                                orientation: Gradient.Horizontal // Horizontal gradient
                                                GradientStop { position: 0.0; color: "#4CAF50" } // Green for cool temps
                                                GradientStop { position: 0.5; color: "#FFC107" } // Yellow for moderate temps
                                                GradientStop { position: 1.0; color: "#FF5722" } // Orange-red for warm temps
                                            }
                                        }
                                    }
                                    
                                    Text { // Max temp - controls maximum temperature display
                                        text: root.forecastData[index].tempMax + "°" // Max temp value - controls max temp content
                                        font.pixelSize: Math.max(Appearance.font.pixelSize.large, parent.height * 0.2) // Responsive font size
                                        font.weight: Font.Bold // Bold font for temperatures
                                        color: Appearance.colors.colOnLayer1 // Text color - controls max temp text color
                                        verticalAlignment: Text.AlignVCenter // Centered - controls max temp alignment
                                        Layout.preferredWidth: contentWidth // Only take up needed width
                                        horizontalAlignment: Text.AlignLeft // Left aligned for clean column
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // --- Placeholder if no forecast data - controls empty state display ---
            Item { // Placeholder for no forecast data - controls empty state container
                visible: !root.forecastData || root.forecastData.length === 0 // Show if no data - controls empty state visibility
                Layout.fillWidth: true // Fill width - controls empty state width
                Layout.fillHeight: true // Fill all remaining height - controls empty state height
                ColumnLayout { // Empty state layout - controls empty state positioning
                    anchors.centerIn: parent // Center placeholder - controls empty state centering
                    spacing: 16 // Increase spacing between placeholder elements - controls empty state spacing
                    Text { // Cloud emoji - controls empty state icon
                        Layout.alignment: Qt.AlignHCenter // Centered - controls emoji positioning
                        font.pixelSize: 48 // Larger font - controls emoji size
                        color: Appearance.colors.colOnLayer1 // Text color - controls emoji color
                        opacity: 0.3 // Faded - controls emoji opacity
                        horizontalAlignment: Text.AlignHCenter // Centered - controls emoji alignment
                        text: "☁️" // Cloud emoji - controls emoji content
                    }
                    Text { // No data message - controls empty state text
                        Layout.alignment: Qt.AlignHCenter // Centered - controls text positioning
                        font.pixelSize: Appearance.font.pixelSize.normal // Larger font - controls text size
                        color: Appearance.colors.colOnLayer1 // Text color - controls text color
                        opacity: 0.5 // Faded - controls text opacity
                        horizontalAlignment: Text.AlignHCenter // Centered - controls text alignment
                        text: qsTr("No forecast data") // Placeholder text - controls text content
                    }
                }
            }
        }
    }
} 