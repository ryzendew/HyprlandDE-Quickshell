import QtQuick 2.15 // Import Qt Quick module
import QtQuick.Controls 2.15 // Import Qt Quick Controls
import QtQuick.Layouts 1.15 // Import Qt Quick Layouts
import "root:/modules/common" // Import common QML modules
import "root:/modules/common/widgets" // Import common widgets
import "root:/modules/weather" // Import weather-related QML modules

Item { // Root container for the weather sidebar page
    id: root // Set the id for this Item
    anchors.fill: parent // Fill the parent container

    Rectangle { // Modern gradient background for the whole sidebar
        anchors.fill: parent
        radius: Appearance.rounding.large
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(
                Appearance.colors.colLayer1.r,
                Appearance.colors.colLayer1.g,
                Appearance.colors.colLayer1.b,
                0.85
            )}
            GradientStop { position: 1.0; color: Qt.rgba(
                Appearance.colors.colLayer1.r,
                Appearance.colors.colLayer1.g,
                Appearance.colors.colLayer1.b,
                0.75
            )}
        }
        border.color: Qt.rgba(Appearance.colors.colOnLayer0.r, Appearance.colors.colOnLayer0.g, Appearance.colors.colOnLayer0.b, 0.08)
        border.width: 1
        z: 0 // Ensure it's at the back
        
        // Subtle inner shadow effect
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius - 1
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
        }
    }

    // --- Weather data properties ---
    property var forecastData: [] // Holds 10-day forecast data
    property string locationDisplay: "Halifax, Nova Scotia" // Displayed location
    property string lastUpdated: Qt.formatDateTime(new Date(), "hh:mm AP") // Last updated time
    property string currentTemp: "--" // Current temperature
    property string feelsLike: "--" // Feels like temperature
    property string airQuality: "--" // Air quality index
    property real latitude: 44.65 // Halifax default latitude
    property real longitude: -63.57 // Halifax default longitude
    
    // --- Temperature range calculation properties ---
    property real globalTempMin: 999 // Global minimum temperature across all days
    property real globalTempMax: -999 // Global maximum temperature across all days
    property real tempRange: globalTempMax - globalTempMin // Temperature range
    
    // --- Function to calculate temperature range ---
    function calculateTempRange() {
        if (!forecastData || forecastData.length === 0) return
        
        var minTemp = 999
        var maxTemp = -999
        
        for (var i = 0; i < forecastData.length; i++) {
            var dayMin = parseFloat(forecastData[i].tempMin)
            var dayMax = parseFloat(forecastData[i].tempMax)
            
            if (!isNaN(dayMin) && dayMin < minTemp) minTemp = dayMin
            if (!isNaN(dayMax) && dayMax > maxTemp) maxTemp = dayMax
        }
        
        globalTempMin = minTemp
        globalTempMax = maxTemp
        tempRange = maxTemp - minTemp
    }
    
    // --- Function to calculate bar width based on temperature variance ---
    function calculateBarWidth(tempMin, tempMax) {
        if (tempRange <= 0) return 36 // Default width if no range
        
        var dayRange = parseFloat(tempMax) - parseFloat(tempMin)
        var minWidth = 16 // Minimum bar width
        var maxWidth = 56 // Maximum bar width
        
        // Calculate width based on temperature variance (larger variance = wider bar)
        var normalizedRange = dayRange / tempRange
        var width = minWidth + (normalizedRange * (maxWidth - minWidth))
        
        return Math.max(minWidth, Math.min(maxWidth, width))
    }

    // --- Weather data refresh function ---
    function refreshWeather() { // Function to refresh weather and air quality
        root.lastUpdated = Qt.formatDateTime(new Date(), "hh:mm AP") // Update last updated time
        if (weatherLoader.item) { // If weatherLoader is loaded
            weatherLoader.item.clearCache() // Clear weather cache
            weatherLoader.item.loadWeather() // Load new weather data
        }
        airQualityLoader.active = false // Deactivate air quality loader
        airQualityLoader.active = true // Reactivate to trigger reload
    }

    // --- Loader: Hidden weather data provider ---
    Loader { // Loader for weather data
        id: weatherLoader // Set id
        source: "../weather/WeatherForecast.qml" // QML file to load
        visible: false // Keep loader hidden
        onLoaded: { // When loaded
            if (item) { // If item is loaded
                root.forecastData = item.forecastData // Set forecast data
                root.locationDisplay = item.locationDisplay // Set location
                root.currentTemp = item.currentTemp // Set current temp
                root.feelsLike = item.feelsLike // Set feels like temp
                item.forecastDataChanged.connect(function() { 
                    root.forecastData = item.forecastData
                    root.calculateTempRange() // Calculate temperature range when data changes
                }) // Update forecast data on change
                item.locationDisplayChanged.connect(function() { root.locationDisplay = item.locationDisplay }) // Update location on change
                item.currentTempChanged.connect(function() { root.currentTemp = item.currentTemp }) // Update temp on change
                item.feelsLikeChanged.connect(function() { root.feelsLike = item.feelsLike }) // Update feels like on change
                item.clearCache() // Clear cache
                item.loadWeather() // Load weather
                root.calculateTempRange() // Calculate initial temperature range
            }
        }
    }

    // --- Loader: Fetch air quality from Open-Meteo ---
    Loader { // Loader for air quality data
        id: airQualityLoader // Set id
        active: true // Loader is active
        asynchronous: true // Load asynchronously
        sourceComponent: QtObject { // Inline QML object
            Component.onCompleted: { // When component is ready
                var xhr = new XMLHttpRequest(); // Create XHR
                var url = `https://air-quality-api.open-meteo.com/v1/air-quality?latitude=${root.latitude}&longitude=${root.longitude}&hourly=us_aqi&timezone=auto`; // API URL
                xhr.onreadystatechange = function() { // On XHR state change
                    if (xhr.readyState === XMLHttpRequest.DONE) { // If done
                        if (xhr.status === 200) { // If success
                            try {
                                var data = JSON.parse(xhr.responseText); // Parse response
                                if (data.hourly && data.hourly.us_aqi && data.hourly.us_aqi.length > 0) { // If AQI data exists
                                    var aqiValue = data.hourly.us_aqi[0]; // Get AQI value
                                    root.airQuality = (aqiValue !== undefined && aqiValue !== null) ? String(aqiValue) : "--"; // Set AQI
                                } else {
                                    root.airQuality = "--"; // No AQI
                                }
                            } catch (e) { root.airQuality = "--"; } // Error parsing
                        } else { root.airQuality = "--"; } // HTTP error
                    }
                };
                xhr.open("GET", url); // Open GET request
                xhr.send(); // Send request
            }
        }
    }

    // --- Main vertical layout for the sidebar ---
    ColumnLayout { // Main vertical layout for sidebar
        anchors.fill: parent // Fill the sidebar vertically
        anchors.margins: 16 // Increased margins for better spacing
        spacing: 12 // Professional spacing between sections

        // --- Modern Header: Location, last updated, refresh button ---
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 56 // Taller header for better proportions
            spacing: 12
            
            Item { Layout.fillWidth: true } // Left spacer
            
            Column {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4 // Better spacing between title and subtitle
                
                Text {
                    text: root.locationDisplay && root.locationDisplay.length > 0 ? root.locationDisplay : qsTr("Halifax, Nova Scotia")
                    font.pixelSize: Appearance.font.pixelSize.large + 2 // Slightly larger for hierarchy
                    font.weight: Font.DemiBold // Professional weight
                    color: Appearance.colors.colOnLayer1
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    text: root.lastUpdated ? qsTr("Updated ") + root.lastUpdated : ""
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Normal
                    color: Appearance.colors.colOnLayer1
                    opacity: 0.65 // Slightly more subtle
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            
            Item { Layout.fillWidth: true } // Right spacer to push refresh button to the right
            
            RippleButton {
                Layout.preferredWidth: 40 // Refined size
                Layout.preferredHeight: 40
                buttonRadius: Appearance.rounding.full
                onClicked: root.refreshWeather()
                
                // Subtle hover effect background
                Rectangle {
                    anchors.fill: parent
                    radius: parent.buttonRadius
                    color: Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, 0.1)
                    opacity: parent.hovered ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "refresh"
                    iconSize: 20 // Refined icon size
                    color: Appearance.colors.colOnLayer1
                }
            }
        }

        Rectangle { // Modern separator after header
            Layout.fillWidth: true
            height: 1
            radius: 0.5
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.2; color: Qt.rgba(Appearance.colors.colOnLayer0.r, Appearance.colors.colOnLayer0.g, Appearance.colors.colOnLayer0.b, 0.15) }
                GradientStop { position: 0.8; color: Qt.rgba(Appearance.colors.colOnLayer0.r, Appearance.colors.colOnLayer0.g, Appearance.colors.colOnLayer0.b, 0.15) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // --- Modern current weather info card ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 84 // Taller for better proportions
            radius: Appearance.rounding.large
            color: Qt.rgba(Appearance.colors.colLayer1.r, Appearance.colors.colLayer1.g, Appearance.colors.colLayer1.b, 0.15)
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 16 // Professional margins
                spacing: 24 // Better spacing between columns
                
                // Current
                Column {
                    spacing: 8 // Better spacing within column
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    Text {
                        text: qsTr("Current")
                        color: Appearance.colors.colOnLayer1
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        opacity: 0.7
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        text: root.currentTemp + (root.feelsLike ? ("  " + qsTr("feels ") + root.feelsLike) : "")
                        color: Appearance.colors.colOnLayer1
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                
                Rectangle { // Subtle vertical separator
                    width: 1
                    height: 40
                    color: Qt.rgba(Appearance.colors.colOnLayer0.r, Appearance.colors.colOnLayer0.g, Appearance.colors.colOnLayer0.b, 0.15)
                    radius: 0.5
                }
                
                // Wind
                Column {
                    spacing: 8 // Better spacing within column
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    Text {
                        text: qsTr("Wind")
                        color: Appearance.colors.colOnLayer1
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        opacity: 0.7
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        text: root.forecastData.length > 0 && root.forecastData[0].wind ? root.forecastData[0].wind + " km/h" : "--"
                        color: Appearance.colors.colOnLayer1
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                Rectangle { // Subtle vertical separator
                    width: 1
                    height: 40
                    color: Qt.rgba(Appearance.colors.colOnLayer0.r, Appearance.colors.colOnLayer0.g, Appearance.colors.colOnLayer0.b, 0.15)
                    radius: 0.5
                }

                // Humidity
                Column {
                    spacing: 8 // Better spacing within column
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    Text {
                        text: qsTr("Humidity")
                        color: Appearance.colors.colOnLayer1
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        opacity: 0.7
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        text: root.forecastData.length > 0 && root.forecastData[0].humidity ? root.forecastData[0].humidity + "%" : "--"
                        color: Appearance.colors.colOnLayer1
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }

        Rectangle { // Modern separator after current weather
            Layout.fillWidth: true
            height: 1
            radius: 0.5
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.2; color: Qt.rgba(Appearance.colors.colOnLayer0.r, Appearance.colors.colOnLayer0.g, Appearance.colors.colOnLayer0.b, 0.15) }
                GradientStop { position: 0.8; color: Qt.rgba(Appearance.colors.colOnLayer0.r, Appearance.colors.colOnLayer0.g, Appearance.colors.colOnLayer0.b, 0.15) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // --- Modern 10-day forecast section ---
        ColumnLayout { // Container for the forecast section
            Layout.fillWidth: true // Fill the width of the parent
            Layout.fillHeight: true // Fill all remaining vertical space
            spacing: 12 // Professional spacing

            Text { // Section header: '10-Day Forecast'
                text: qsTr("10-Day Forecast") // Display section title
                font.pixelSize: Appearance.font.pixelSize.large + 1 // Slightly larger for hierarchy
                font.weight: Font.DemiBold // Professional weight
                color: Appearance.colors.colOnLayer1 // Use theme color for text
                opacity: 0.95 // Less faded for better readability
                horizontalAlignment: Text.AlignHCenter // Center text
                Layout.alignment: Qt.AlignHCenter // Center in layout
            }

            Flickable { // Scrollable area for forecast cards
                Layout.fillWidth: true // Fill width
                Layout.fillHeight: true // Fill all remaining height
                contentHeight: forecastColumn.height // Set content height to column height
                clip: true // Clip content to bounds
                interactive: contentHeight > height // Enable scrolling if content is taller than view
                
                Column {
                    id: forecastColumn // ID for column
                    width: parent.width // Match parent width
                    spacing: 8 // Professional spacing between forecast cards
                    
                    Repeater {
                        model: Math.min(10, root.forecastData.length) // Show up to 10 days
                        delegate: Rectangle { // Modern forecast card
                            width: parent.width // Fill width
                            height: 68 // Taller for better proportions
                            radius: Appearance.rounding.large // Consistent with other elements
                            color: Qt.rgba(Appearance.colors.colLayer1.r, Appearance.colors.colLayer1.g, Appearance.colors.colLayer1.b, 0.12) // Subtle card background
                            border.color: Qt.rgba(Appearance.colors.colOnLayer0.r, Appearance.colors.colOnLayer0.g, Appearance.colors.colOnLayer0.b, 0.08) // Subtle border
                            border.width: 1 // Border width
                            
                            // Subtle hover effect
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: parent.color = Qt.rgba(Appearance.colors.colLayer1.r, Appearance.colors.colLayer1.g, Appearance.colors.colLayer1.b, 0.18)
                                onExited: parent.color = Qt.rgba(Appearance.colors.colLayer1.r, Appearance.colors.colLayer1.g, Appearance.colors.colLayer1.b, 0.12)
                            }
                            
                            RowLayout { // Card content row
                                anchors.fill: parent // Fill card
                                anchors.margins: 16 // Professional margins inside card
                                spacing: 16 // Better spacing between elements
                                
                                ColumnLayout {
                                    spacing: 4 // Increase spacing between date/icon
                                    Layout.alignment: Qt.AlignVCenter
                                    
                                    RowLayout {
                                        spacing: 8 // Increase spacing between date, icon, and precip
                                        Layout.alignment: Qt.AlignVCenter
                                        
                                        Text { // Day label
                                            text: root.forecastData[index].date // Day of week
                                            font.pixelSize: Appearance.font.pixelSize.large // Larger font size
                                            font.weight: Font.DemiBold // Professional weight
                                            color: Appearance.colors.colOnLayer1 // Text color
                                            verticalAlignment: Text.AlignVCenter // Centered vertically
                                        }
                                        
                                        Item {
                                            width: 24; height: 24 // Larger icon container
                                            Image {
                                                anchors.centerIn: parent // Center icon
                                                source: root.forecastData[index].condition && root.forecastData[index].condition.toLowerCase().indexOf("fog") !== -1 ? "root:/assets/weather/fog.svg" : "" // Show fog icon if needed
                                                visible: root.forecastData[index].condition && root.forecastData[index].condition.toLowerCase().indexOf("fog") !== -1 // Only show if fog
                                                width: 20; height: 20 // Larger icon size
                                                fillMode: Image.PreserveAspectFit // Keep aspect ratio
                                            }
                                            Text {
                                                anchors.centerIn: parent // Center emoji
                                                text: (!root.forecastData[index].condition || root.forecastData[index].condition.toLowerCase().indexOf("fog") === -1) ? root.forecastData[index].emoji : "" // Show emoji if not fog
                                                font.pixelSize: 20 // Larger emoji size
                                                horizontalAlignment: Text.AlignCenter // Centered
                                                visible: !root.forecastData[index].condition || root.forecastData[index].condition.toLowerCase().indexOf("fog") === -1 // Only show if not fog
                                            }
                                        }
                                        
                                        Text { // Precipitation %
                                            text: root.forecastData[index].precip > 0 ? root.forecastData[index].precip + "%" : "" // Show if >0%
                                            font.pixelSize: Appearance.font.pixelSize.small // Larger font
                                            color: "#2196F3" // Blue color
                                            visible: root.forecastData[index].precip > 0 // Only show if >0%
                                            font.weight: Font.Bold // Bold font
                                            verticalAlignment: Text.AlignVCenter // Centered
                                        }
                                    }
                                }
                                
                                Item { Layout.fillWidth: true } // Spacer
                                
                                ColumnLayout {
                                    Layout.alignment: Qt.AlignVCenter // Center condition text
                                    spacing: 0 // No spacing
                                    Text { // Condition text
                                        text: root.forecastData[index].condition // Weather condition
                                        font.pixelSize: Appearance.font.pixelSize.small // Larger font
                                        color: Appearance.colors.colOnLayer1 // Text color
                                        opacity: 0.92 // Slightly faded
                                        wrapMode: Text.WordWrap // Wrap if needed
                                        maximumLineCount: 2 // Max 2 lines
                                        elide: Text.ElideRight // Elide if too long
                                        Layout.preferredWidth: 100 // Increase preferred width
                                        horizontalAlignment: Text.AlignLeft // Left aligned
                                    }
                                }
                                
                                ColumnLayout {
                                    Layout.alignment: Qt.AlignVCenter // Center temp range
                                    spacing: 4 // Increase spacing between temp range elements
                                    RowLayout {
                                        spacing: 8 // Increase spacing between min temp, bar, and max temp
                                        Text { // Min temp
                                            text: root.forecastData[index].tempMin + "°" // Min temp value
                                            font.pixelSize: Appearance.font.pixelSize.large // Larger font size
                                            color: Appearance.colors.colOnLayer1 // Text color
                                            verticalAlignment: Text.AlignVCenter // Centered
                                        }
                                        Rectangle { // Temp bar
                                            width: calculateBarWidth(root.forecastData[index].tempMin, root.forecastData[index].tempMax)
                                            height: 10; radius: 5 // Larger bar size and rounding
                                            color: "#2196F3" // Blue color
                                            anchors.verticalCenter: parent.verticalCenter // Centered
                                        }
                                        Text { // Max temp
                                            text: root.forecastData[index].tempMax + "°" // Max temp value
                                            font.pixelSize: Appearance.font.pixelSize.large // Larger font size
                                            color: Appearance.colors.colOnLayer1 // Text color
                                            verticalAlignment: Text.AlignVCenter // Centered
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // --- Placeholder if no forecast data ---
            Item { // Placeholder for no forecast data
                visible: !root.forecastData || root.forecastData.length === 0 // Show if no data
                Layout.fillWidth: true // Fill width
                Layout.fillHeight: true // Fill all remaining height
                ColumnLayout {
                    anchors.centerIn: parent // Center placeholder
                    spacing: 16 // Increase spacing between placeholder elements
                    Text {
                        Layout.alignment: Qt.AlignHCenter // Centered
                        font.pixelSize: 48 // Larger font
                        color: Appearance.colors.colOnLayer1 // Text color
                        opacity: 0.3 // Faded
                        horizontalAlignment: Text.AlignHCenter // Centered
                        text: "☁️" // Cloud emoji
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter // Centered
                        font.pixelSize: Appearance.font.pixelSize.normal // Larger font
                        color: Appearance.colors.colOnLayer1 // Text color
                        opacity: 0.5 // Faded
                        horizontalAlignment: Text.AlignHCenter // Centered
                        text: qsTr("No forecast data") // Placeholder text
                    }
                }
            }
        }
    }
} 