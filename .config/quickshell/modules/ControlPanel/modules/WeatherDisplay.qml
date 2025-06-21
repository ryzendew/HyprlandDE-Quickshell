import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/Data" as Data

// Weather display widget
Rectangle {
    id: root
    required property var shell
    color: Qt.rgba(
        Qt.darker(Data.Colors.bgColor, 1.15).r,
        Qt.darker(Data.Colors.bgColor, 1.15).g,
        Qt.darker(Data.Colors.bgColor, 1.15).b,
        0.85
    )
    radius: 20

    property bool containsMouse: weatherMouseArea.containsMouse || (forecastPopup.visible && forecastPopup.containsMouse)
    property bool menuJustOpened: false

    signal entered()
    signal exited()

    // Ensure we have weather data to display
    property var safeWeatherData: {
        if (shell && shell.weatherData) {
            return shell.weatherData
        }
        return {
            locationDisplay: "Halifax, Nova Scotia",
            currentTemp: "15°C",
            feelsLike: "15°C",
            currentCondition: "Clear sky",
            forecast: []
        }
    }

    // Debug element to verify component loading
    Rectangle {
        width: 10
        height: 10
        color: "green"
        anchors.top: parent.top
        anchors.right: parent.right
        visible: true
        z: 1000
    }

    Component.onCompleted: {
        console.log("WeatherDisplay component completed")
        if (shell) {
            console.log("Shell is available")
        } else {
            console.warn("Shell is not available")
        }
    }

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
        anchors.fill: parent
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

    // Compact weather display (icon and temperature)
    RowLayout {
        id: weatherLayout
        anchors.centerIn: parent
        spacing: 8

        ColumnLayout {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter

            // Weather condition icon
            Label {
                text: {
                    if (shell && shell.weatherLoading) return "refresh"
                    if (!safeWeatherData) return "help"
                    return root.getWeatherIcon(safeWeatherData.currentCondition)
                }
                font.pixelSize: 28
                font.family: "Material Symbols Outlined"
                color: Data.Colors.accentColor
                Layout.alignment: Qt.AlignHCenter
            }

            // Current temperature
            Label {
                text: {
                    if (shell && shell.weatherLoading) return "Loading..."
                    if (!safeWeatherData) return "No data"
                    return safeWeatherData.currentTemp
                }
                color: Data.Colors.fgColor
                font.pixelSize: 20
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
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
            color: Qt.rgba(
                Qt.darker(Data.Colors.bgColor, 1.15).r,
                Qt.darker(Data.Colors.bgColor, 1.15).g,
                Qt.darker(Data.Colors.bgColor, 1.15).b,
                0.85
            )
            radius: 20
            border.width: 1
            border.color: Qt.rgba(
                Qt.lighter(Data.Colors.bgColor, 1.3).r,
                Qt.lighter(Data.Colors.bgColor, 1.3).g,
                Qt.lighter(Data.Colors.bgColor, 1.3).b,
                0.85
            )
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
            anchors.fill: parent
            hoverEnabled: true
            onExited: {
                if (!weatherMouseArea.containsMouse && !menuJustOpened) {
                    forecastPopup.close()
                }
            }
        }

        ColumnLayout {
            id: forecastColumn
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            // Current weather detailed view
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Large weather icon
                Label {
                    text: safeWeatherData ? root.getWeatherIcon(safeWeatherData.currentCondition) : ""
                    font.pixelSize: 48
                    font.family: "Material Symbols Outlined"
                    color: Data.Colors.accentColor
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    // Weather condition description
                    Label {
                        text: safeWeatherData ? safeWeatherData.currentCondition : ""
                        color: Data.Colors.fgColor
                        font.pixelSize: 14
                        font.bold: true
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    // Weather metrics: temperature, wind, direction
                    RowLayout {
                        spacing: 8
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

                        // Temperature metric
                        RowLayout {
                            spacing: 4
                            Layout.alignment: Qt.AlignVCenter
                            Label {
                                text: "thermostat"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 12
                                color: Data.Colors.accentColor
                            }
                            Label {
                                text: safeWeatherData ? safeWeatherData.currentTemp : ""
                                color: Data.Colors.fgColor
                                font.pixelSize: 12
                            }
                        }

                        Rectangle {
                            width: 1
                            height: 12
                            color: Qt.lighter(Data.Colors.bgColor, 1.3)
                        }

                        // Wind speed metric
                        RowLayout {
                            spacing: 4
                            Layout.alignment: Qt.AlignVCenter
                            Label {
                                text: "air"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 12
                                color: Data.Colors.accentColor
                            }
                            Label {
                                text: {
                                    if (!safeWeatherData || !safeWeatherData.details) return ""
                                    const windInfo = safeWeatherData.details.find(d => d.startsWith("Wind:"))
                                    return windInfo ? windInfo.split(": ")[1] : ""
                                }
                                color: Data.Colors.fgColor
                                font.pixelSize: 12
                            }
                        }

                        Rectangle {
                            width: 1
                            height: 12
                            color: Qt.lighter(Data.Colors.bgColor, 1.3)
                        }

                        // Wind direction metric
                        RowLayout {
                            spacing: 4
                            Layout.alignment: Qt.AlignVCenter
                            Label {
                                text: "explore"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 12
                                color: Data.Colors.accentColor
                            }
                            Label {
                                text: {
                                    if (!safeWeatherData || !safeWeatherData.details) return ""
                                    const dirInfo = safeWeatherData.details.find(d => d.startsWith("Direction:"))
                                    return dirInfo ? dirInfo.split(": ")[1] : ""
                                }
                                color: Data.Colors.fgColor
                                font.pixelSize: 12
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // Section separator
            Rectangle {
                height: 1
                Layout.fillWidth: true
                color: Qt.lighter(Data.Colors.bgColor, 1.3)
            }

            Label {
                text: "3-Day Forecast"
                color: Data.Colors.accentColor
                font.pixelSize: 12
                font.bold: true
            }

            // Three-column forecast cards
            Row {
                spacing: 8
                Layout.fillWidth: true

                Repeater {
                    model: safeWeatherData ? safeWeatherData.forecast : []
                    delegate: Column {
                        width: (parent.width - 16) / 3
                        spacing: 2

                        // Day name
                        Label {
                            text: modelData.dayName
                            color: Data.Colors.fgColor
                            font.pixelSize: 10
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        // Weather icon
                        Label {
                            text: root.getWeatherIcon(modelData.condition)
                            font.pixelSize: 16
                            font.family: "Material Symbols Outlined"
                            color: Data.Colors.accentColor
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        // Temperature range
                        Label {
                            text: modelData.minTemp + "° - " + modelData.maxTemp + "°"
                            color: Data.Colors.fgColor
                            font.pixelSize: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }
        }
    }
}
