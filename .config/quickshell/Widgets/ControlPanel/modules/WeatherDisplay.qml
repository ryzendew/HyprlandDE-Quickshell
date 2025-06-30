import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/Data" as Data

// Weather display widget
Rectangle {
    id: root
    required property var shell
    color: Qt.darker(Appearance.colors.colLayer0, 1.15)
    radius: 20

    property bool containsMouse: weatherMouseArea.containsMouse || (forecastPopup.visible && forecastPopup.containsMouse)
    property bool menuJustOpened: false

    signal entered()
    signal exited()

    // Hover state management for parent components
    onContainsMouseChanged: {
        if (containsMouse) {
            entered()
        } else if (!menuJustOpened && !forecastPopup.visible) {
            exited()
        }
    }

    // Maps WMO weather condition codes and text descriptions to Material Design icons
    function getWeatherIcon(condition) {
        if (!condition) return "light_mode"

        const c = condition.toString()

        // WMO weather interpretation codes to Material Design icons
        const iconMap = {
            "0": "light_mode",     // Clear sky
            "1": "light_mode",     // Mainly clear
            "2": "cloud",          // Partly cloudy
            "3": "cloud",          // Overcast
            "45": "foggy",         // Fog
            "48": "foggy",         // Depositing rime fog
            "51": "water_drop",    // Light drizzle
            "53": "water_drop",    // Moderate drizzle
            "55": "water_drop",    // Dense drizzle
            "61": "water_drop",    // Slight rain
            "63": "water_drop",    // Moderate rain
            "65": "water_drop",    // Heavy rain
            "71": "ac_unit",       // Slight snow
            "73": "ac_unit",       // Moderate snow
            "75": "ac_unit",       // Heavy snow
            "80": "water_drop",    // Slight rain showers
            "81": "water_drop",    // Moderate rain showers
            "82": "water_drop",    // Violent rain showers
            "95": "thunderstorm",  // Thunderstorm
            "96": "thunderstorm",  // Thunderstorm with light hail
            "99": "thunderstorm"   // Thunderstorm with heavy hail
        }

        if (iconMap[c]) return iconMap[c]

        // Fallback text matching for non-WMO weather APIs
        const textMap = {
            "clear sky": "light_mode",
            "mainly clear": "light_mode",
            "partly cloudy": "cloud",
            "overcast": "cloud",
            "fog": "foggy",
            "drizzle": "water_drop",
            "rain": "water_drop",
            "snow": "ac_unit",
            "thunderstorm": "thunderstorm"
        }

        const lower = condition.toLowerCase()
        for (let key in textMap) {
            if (lower.includes(key)) return textMap[key]
        }

        return "help"  // Unknown condition fallback
    }

    // Hover trigger for forecast popup
    MouseArea {
        id: weatherMouseArea
        width: parent.width
        height: parent.height
        hoverEnabled: true
        onEntered: {
            menuJustOpened = true
            forecastPopup.open()
            Qt.callLater(() => menuJustOpened = false)
        }
        onExited: {
            if (!forecastPopup.containsMouse && !menuJustOpened) {
                forecastPopup.close()
            }
        }
    }

    // Weather display
    RowLayout {
        id: weatherComponent
        anchors.centerIn: parent
        spacing: 8

        // Weather icon
        Text {
            text: shell.weatherData && shell.weatherData.forecast && shell.weatherData.forecast[0] ? 
                  shell.weatherData.forecast[0].emoji || "❓" : "❓"
            font.pixelSize: 24
            color: Appearance.colors.colOnLayer0
        }

        // Temperature
        Text {
            text: shell.weatherData ? shell.weatherData.currentTemp || "?" : "?"
            font.pixelSize: 16
            color: Appearance.colors.colOnLayer0
        }
    }

    // Forecast popup
    Popup {
        id: forecastPopup
        y: parent.height + 28
        x: Math.min(0, parent.width - width)
        width: 300
        height: 226
        padding: 12
        background: Rectangle {
            color: Qt.darker(Appearance.colors.colLayer0, 1.15)
            radius: 20
            border.width: 1
            border.color: Qt.lighter(Appearance.colors.colLayer0, 1.3)
        }

        property bool containsMouse: forecastMouseArea.containsMouse

        onVisibleChanged: {
            if (visible) {
                entered()
            } else if (!weatherMouseArea.containsMouse && !menuJustOpened) {
                exited()
            }
        }

        // Hover area for popup persistence
        MouseArea {
            id: forecastMouseArea
            width: parent.width
            height: parent.height
            hoverEnabled: true
            onExited: {
                if (!weatherMouseArea.containsMouse && !menuJustOpened) {
                    forecastPopup.close()
                }
            }
        }

        ColumnLayout {
            id: forecastColumn
            width: parent.width - 20
            height: parent.height - 20
            x: 10
            y: 10
            spacing: 8

            // Current weather detailed view
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Large weather icon
                Text {
                    text: shell.weatherData && shell.weatherData.forecast && shell.weatherData.forecast[0] ?
                          shell.weatherData.forecast[0].emoji || "❓" : "❓"
                    font.pixelSize: 48
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    // Weather condition description
                    Label {
                        text: shell.weatherData ? shell.weatherData.currentCondition || "Weather" : "Weather"
                        color: Appearance.colors.colOnLayer0
                        font.pixelSize: 16
                        font.bold: true
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    // Location
                    Label {
                        text: shell.weatherData ? shell.weatherData.locationDisplay || "" : ""
                        color: Appearance.colors.colOnLayer0
                        opacity: 0.7
                        font.pixelSize: 12
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    // Temperature and feels like
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: shell.weatherData ? shell.weatherData.currentTemp || "?" : "?"
                            color: Appearance.colors.colOnLayer0
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Label {
                            text: shell.weatherData && shell.weatherData.feelsLike ? 
                                  "Feels like " + shell.weatherData.feelsLike : ""
                            color: Appearance.colors.colOnLayer0
                            opacity: 0.7
                            font.pixelSize: 12
                            visible: shell.weatherData && shell.weatherData.feelsLike
                        }
                    }
                }
            }
        }
    }
}
