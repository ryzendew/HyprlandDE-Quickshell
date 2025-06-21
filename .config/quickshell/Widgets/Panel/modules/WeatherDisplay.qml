import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/Data" as Data

Rectangle {
    id: root
    required property var shell
    color: Qt.darker(Data.Colors.bgColor, 1.15)
    radius: 20

    property bool containsMouse: weatherMouseArea.containsMouse || (forecastPopup.visible && forecastPopup.containsMouse)
    property bool menuJustOpened: false

    signal entered()
    signal exited()

    onContainsMouseChanged: {
        if (containsMouse) {
            entered()
        } else if (!menuJustOpened && !forecastPopup.visible) {
            exited()
        }
    }

    function getWeatherIcon(condition) {
        if (!condition) return "light_mode"

        const c = condition.toString()

        const iconMap = {
            "0": "light_mode",
            "1": "light_mode",
            "2": "cloud",
            "3": "cloud",
            "45": "foggy",
            "48": "foggy",
            "51": "water_drop",
            "53": "water_drop",
            "55": "water_drop",
            "61": "water_drop",
            "63": "water_drop",
            "65": "water_drop",
            "71": "ac_unit",
            "73": "ac_unit",
            "75": "ac_unit",
            "80": "water_drop",
            "81": "water_drop",
            "82": "water_drop",
            "95": "thunderstorm",
            "96": "thunderstorm",
            "99": "thunderstorm"
        }

        if (iconMap[c]) return iconMap[c]

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

        return "help"
    }

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

    RowLayout {
        id: weatherLayout
        anchors.centerIn: parent
        spacing: 8

        ColumnLayout {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter

            Label {
                text: {
                    if (shell.weatherLoading) return "refresh"
                    if (!shell.weatherData) return "help"
                    return root.getWeatherIcon(shell.weatherData.currentCondition)
                }
                font.pixelSize: 28
                font.family: "Material Symbols Outlined"
                color: Data.Colors.accentColor
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: {
                    if (shell.weatherLoading) return "Loading..."
                    if (!shell.weatherData) return "No weather data"
                    return shell.weatherData.currentTemp
                }
                color: Data.Colors.fgColor
                font.pixelSize: 20
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    Popup {
        id: forecastPopup
        y: parent.height + 28
        x: Math.min(0, parent.width - width)
        width: 300
        height: 226
        padding: 12
        background: Rectangle {
            color: Qt.darker(Data.Colors.bgColor, 1.15)
            radius: 20
            border.width: 1
            border.color: Qt.lighter(Data.Colors.bgColor, 1.3)
        }

        property bool containsMouse: forecastMouseArea.containsMouse

        onVisibleChanged: {
            if (visible) {
                entered()
            } else if (!weatherMouseArea.containsMouse && !menuJustOpened) {
                exited()
            }
        }

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

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Label {
                    text: shell.weatherData ? root.getWeatherIcon(shell.weatherData.currentCondition) : ""
                    font.pixelSize: 48
                    font.family: "Material Symbols Outlined"
                    color: Data.Colors.accentColor
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: shell.weatherData ? shell.weatherData.currentCondition : ""
                        color: Data.Colors.fgColor
                        font.pixelSize: 14
                        font.bold: true
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    RowLayout {
                        spacing: 8
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

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
                                text: shell.weatherData ? shell.weatherData.currentTemp : ""
                                color: Data.Colors.fgColor
                                font.pixelSize: 12
                            }
                        }

                        Rectangle {
                            width: 1
                            height: 12
                            color: Qt.lighter(Data.Colors.bgColor, 1.3)
                        }

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
                                    if (!shell.weatherData || !shell.weatherData.details) return ""
                                    const windInfo = shell.weatherData.details.find(d => d.startsWith("Wind:"))
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
                                    if (!shell.weatherData || !shell.weatherData.details) return ""
                                    const dirInfo = shell.weatherData.details.find(d => d.startsWith("Direction:"))
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

            Row {
                spacing: 8
                Layout.fillWidth: true

                Repeater {
                    model: shell.weatherData ? shell.weatherData.forecast : []
                    delegate: Column {
                        width: (parent.width - 16) / 3
                        spacing: 2

                        Label {
                            text: modelData.dayName
                            color: Data.Colors.fgColor
                            font.pixelSize: 10
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Label {
                            text: root.getWeatherIcon(modelData.condition)
                            font.pixelSize: 16
                            font.family: "Material Symbols Outlined"
                            color: Data.Colors.accentColor
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

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
