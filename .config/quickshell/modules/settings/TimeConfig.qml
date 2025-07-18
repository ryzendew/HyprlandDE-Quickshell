import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/services/"
import "root:/modules/common/"
import "root:/modules/common/widgets/"
import "root:/modules/common/functions/color_utils.js" as ColorUtils

ColumnLayout {
    spacing: 24 * (root.scaleFactor ?? 1.0)
    anchors.left: parent ? parent.left : undefined
    anchors.leftMargin: 40 * (root.scaleFactor ?? 1.0)

    // Responsive scaling properties
    property real scaleFactor: root.scaleFactor ?? 1.0
    property int baseSectionMargin: 16
    property int baseIconSize: 20
    property int baseSpacing: 12

    // Time & Date Configuration Section
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: childrenRect.height + (40 * scaleFactor)
        Layout.topMargin: baseSectionMargin * scaleFactor
        Layout.bottomMargin: baseSectionMargin * scaleFactor
        radius: Appearance.rounding.large * scaleFactor
        color: Appearance.colors.colLayer1
        border.width: 2
        border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.4)

        ColumnLayout {
            anchors.left: parent.left
            anchors.leftMargin: 40 * scaleFactor
            anchors.right: undefined
            anchors.top: parent.top
            anchors.margins: baseSectionMargin * scaleFactor
            spacing: 24 * scaleFactor

            // Section header
            RowLayout {
                spacing: 16 * scaleFactor
                Layout.topMargin: 24 * scaleFactor

                Rectangle {
                    width: 40 * scaleFactor; height: 40 * scaleFactor
                    radius: Appearance.rounding.normal * scaleFactor
                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "schedule"
                        iconSize: baseIconSize * scaleFactor
                        color: "#000"
                    }
                }
                ColumnLayout {
                    spacing: 4 * scaleFactor
                    StyledText {
                        text: "Time & Date"
                        font.pixelSize: (Appearance.font.pixelSize.large * scaleFactor)
                        font.weight: Font.Bold
                        color: "#fff"
                    }
                    StyledText {
                        text: "Configure time display, timezone, and date formatting"
                        font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                        color: "#fff"
                        opacity: 0.9
                    }
                }
            }

            // Time Zone Settings
            ColumnLayout {
                spacing: 16 * scaleFactor
                anchors.left: parent.left
                anchors.leftMargin: 0

                StyledText {
                    text: "Time Zone"
                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                    font.weight: Font.Medium
                    color: "#fff"
                }

                ColumnLayout {
                    spacing: baseSpacing * scaleFactor

                    RowLayout {
                        spacing: baseSpacing * scaleFactor
                        StyledText {
                            text: "Current timezone:"
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                            color: "#fff"
                        }
                        StyledText {
                            text: DateTime.timeZoneName
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                            color: Appearance.colors.colPrimary
                            font.weight: Font.Medium
                        }
                    }

                    RowLayout {
                        spacing: baseSpacing * scaleFactor
                        StyledText {
                            text: "Time zone:"
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                            color: "#fff"
                        }
                        ComboBox {
                            id: timeZoneComboBox
                            model: timeZoneModel
                            textRole: "display"
                            valueRole: "value"
                            currentIndex: {
                                for (let i = 0; i < timeZoneModel.count; i++) {
                                    if (timeZoneModel.get(i).value === ConfigOptions.time.timeZone) {
                                        return i
                                    }
                                }
                                return 0
                            }
                            onActivated: {
                                const selectedValue = timeZoneModel.get(currentIndex).value
                                ConfigLoader.setConfigValue("time.timeZone", selectedValue)
                            }
                            Layout.preferredWidth: 300 * scaleFactor
                        }
                    }
                }
            }

            // Time Format Settings
            ColumnLayout {
                spacing: 16 * scaleFactor
                anchors.left: parent.left
                anchors.leftMargin: 0

                StyledText {
                    text: "Time Format"
                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                    font.weight: Font.Medium
                    color: "#fff"
                }

                ColumnLayout {
                    spacing: baseSpacing * scaleFactor

                    RowLayout {
                        spacing: 24 * scaleFactor
                        RowLayout {
                            spacing: baseSpacing * scaleFactor
                            StyledRadioButton {
                                id: format12Hour
                                checked: !ConfigOptions.time.use24Hour
                                description: "12-hour (AM/PM)"
                                onCheckedChanged: {
                                    if (checked) {
                                        ConfigLoader.setConfigValue("time.use24Hour", false)
                                    }
                                }
                            }
                        }
                        RowLayout {
                            spacing: baseSpacing * scaleFactor
                            StyledRadioButton {
                                id: format24Hour
                                checked: ConfigOptions.time.use24Hour
                                description: "24-hour"
                                onCheckedChanged: {
                                    if (checked) {
                                        ConfigLoader.setConfigValue("time.use24Hour", true)
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        spacing: baseSpacing * scaleFactor
                        ConfigSwitch {
                            checked: ConfigOptions.time.showSeconds
                            onCheckedChanged: { ConfigLoader.setConfigValue("time.showSeconds", checked); }
                        }
                        StyledText {
                            text: "Show seconds"
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                            color: "#fff"
                        }
                    }

                    ColumnLayout {
                        spacing: 8 * scaleFactor
                        StyledText {
                            text: "Custom time format:"
                            font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                            color: "#fff"
                            opacity: 0.8
                        }
                        MaterialTextField {
                            placeholderText: "e.g., hh:mm:ss AP, HH:mm, h:mm"
                            text: ConfigOptions.time.customTimeFormat
                            onTextChanged: { ConfigLoader.setConfigValue("time.customTimeFormat", text); }
                            Layout.fillWidth: true
                        }
                        StyledText {
                            text: "Leave empty to use default format. See Qt date format documentation for options."
                            font.pixelSize: (Appearance.font.pixelSize.smaller * scaleFactor)
                            color: "#fff"
                            opacity: 0.6
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // Date Format Settings
            ColumnLayout {
                spacing: 16 * scaleFactor
                anchors.left: parent.left
                anchors.leftMargin: 0

                StyledText {
                    text: "Date Format"
                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                    font.weight: Font.Medium
                    color: "#fff"
                }

                ColumnLayout {
                    spacing: baseSpacing * scaleFactor

                    RowLayout {
                        spacing: baseSpacing * scaleFactor
                        ConfigSwitch {
                            checked: ConfigOptions.time.showDate
                            onCheckedChanged: { ConfigLoader.setConfigValue("time.showDate", checked); }
                        }
                        StyledText {
                            text: "Show date"
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                            color: "#fff"
                        }
                    }

                    RowLayout {
                        spacing: baseSpacing * scaleFactor
                        ConfigSwitch {
                            checked: ConfigOptions.time.showDayOfWeek
                            onCheckedChanged: { ConfigLoader.setConfigValue("time.showDayOfWeek", checked); }
                        }
                        StyledText {
                            text: "Show day of week"
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                            color: "#fff"
                        }
                    }

                    RowLayout {
                        spacing: baseSpacing * scaleFactor
                        ConfigSwitch {
                            checked: ConfigOptions.time.showYear
                            onCheckedChanged: { ConfigLoader.setConfigValue("time.showYear", checked); }
                        }
                        StyledText {
                            text: "Show year"
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                            color: "#fff"
                        }
                    }

                    ColumnLayout {
                        spacing: 8 * scaleFactor
                        StyledText {
                            text: "Custom date format:"
                            font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                            color: "#fff"
                            opacity: 0.8
                        }
                        MaterialTextField {
                            placeholderText: "e.g., dddd, dd/MM, MMMM dd yyyy"
                            text: ConfigOptions.time.customDateFormat
                            onTextChanged: { ConfigLoader.setConfigValue("time.customDateFormat", text); }
                            Layout.fillWidth: true
                        }
                        StyledText {
                            text: "Leave empty to use default format. See Qt date format documentation for options."
                            font.pixelSize: (Appearance.font.pixelSize.smaller * scaleFactor)
                            color: "#fff"
                            opacity: 0.6
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // Display Settings
            ColumnLayout {
                spacing: 16 * scaleFactor
                anchors.left: parent.left
                anchors.leftMargin: 0

                StyledText {
                    text: "Display Settings"
                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                    font.weight: Font.Medium
                    color: "#fff"
                }

                ColumnLayout {
                    spacing: baseSpacing * scaleFactor

                    RowLayout {
                        spacing: baseSpacing * scaleFactor
                        ConfigSwitch {
                            checked: ConfigOptions.time.display.showInBar
                            onCheckedChanged: { ConfigLoader.setConfigValue("time.display.showInBar", checked); }
                        }
                        StyledText {
                            text: "Show in top bar"
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                            color: "#fff"
                        }
                    }

                    RowLayout {
                        spacing: baseSpacing * scaleFactor
                        ConfigSwitch {
                            checked: ConfigOptions.time.display.bold
                            onCheckedChanged: { ConfigLoader.setConfigValue("time.display.bold", checked); }
                        }
                        StyledText {
                            text: "Bold text"
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                            color: "#fff"
                        }
                    }

                    RowLayout {
                        spacing: baseSpacing * scaleFactor
                        ConfigSwitch {
                            checked: ConfigOptions.time.display.italic
                            onCheckedChanged: { ConfigLoader.setConfigValue("time.display.italic", checked); }
                        }
                        StyledText {
                            text: "Italic text"
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                            color: "#fff"
                        }
                    }

                    RowLayout {
                        spacing: baseSpacing * scaleFactor
                        StyledText {
                            text: "Font size:"
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                            color: "#fff"
                        }
                        ConfigSpinBox {
                            value: ConfigOptions.time.display.fontSize
                            from: 0
                            to: 48
                            stepSize: 1
                            onValueChanged: { ConfigLoader.setConfigValue("time.display.fontSize", value); }
                        }
                        StyledText {
                            text: "0 = auto"
                            font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                            color: "#fff"
                            opacity: 0.6
                        }
                    }
                }
            }

            // Localization Settings
            ColumnLayout {
                spacing: 16 * scaleFactor
                anchors.left: parent.left
                anchors.leftMargin: 0

                StyledText {
                    text: "Localization"
                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                    font.weight: Font.Medium
                    color: "#fff"
                }

                ColumnLayout {
                    spacing: baseSpacing * scaleFactor

                    RowLayout {
                        spacing: baseSpacing * scaleFactor
                        ConfigSwitch {
                            checked: ConfigOptions.time.localization.useLocalizedNames
                            onCheckedChanged: { ConfigLoader.setConfigValue("time.localization.useLocalizedNames", checked); }
                        }
                        StyledText {
                            text: "Use localized day/month names"
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                            color: "#fff"
                        }
                    }

                    RowLayout {
                        spacing: baseSpacing * scaleFactor
                        StyledText {
                            text: "First day of week:"
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                            color: "#fff"
                        }
                        ComboBox {
                            id: firstDayComboBox
                            model: [
                                { display: "Monday", value: "monday" },
                                { display: "Sunday", value: "sunday" }
                            ]
                            textRole: "display"
                            valueRole: "value"
                            currentIndex: ConfigOptions.time.localization.firstDayOfWeek === "monday" ? 0 : 1
                            onActivated: {
                                const selectedValue = model[currentIndex].value
                                ConfigLoader.setConfigValue("time.localization.firstDayOfWeek", selectedValue)
                            }
                        }
                    }
                }
            }

            // Preview Section
            ColumnLayout {
                spacing: 16 * scaleFactor
                anchors.left: parent.left
                anchors.leftMargin: 0

                StyledText {
                    text: "Preview"
                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                    font.weight: Font.Medium
                    color: "#fff"
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60 * scaleFactor
                    radius: Appearance.rounding.normal * scaleFactor
                    color: Appearance.colors.colLayer2
                    border.width: 1
                    border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.3)

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 16 * scaleFactor

                        ColumnLayout {
                            spacing: 4 * scaleFactor
                            StyledText {
                                text: DateTime.time
                                font.pixelSize: ConfigOptions.time.display.fontSize > 0 ? ConfigOptions.time.display.fontSize * scaleFactor : Appearance.font.pixelSize.normal * scaleFactor
                                font.weight: ConfigOptions.time.display.bold ? Font.Bold : Font.Normal
                                font.italic: ConfigOptions.time.display.italic
                                color: "#fff"
                                horizontalAlignment: Text.AlignHCenter
                            }
                            StyledText {
                                text: DateTime.date
                                font.pixelSize: ConfigOptions.time.display.fontSize > 0 ? ConfigOptions.time.display.fontSize * scaleFactor - 2 : Appearance.font.pixelSize.small * scaleFactor
                                font.weight: ConfigOptions.time.display.bold ? Font.Bold : Font.Normal
                                font.italic: ConfigOptions.time.display.italic
                                color: "#fff"
                                horizontalAlignment: Text.AlignHCenter
                                visible: ConfigOptions.time.showDate && DateTime.date.length > 0
                            }
                        }

                        Rectangle {
                            width: 1 * scaleFactor
                            height: 40 * scaleFactor
                            color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.5)
                        }

                        ColumnLayout {
                            spacing: 4 * scaleFactor
                            StyledText {
                                text: "Current timezone:"
                                font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                                color: "#fff"
                                opacity: 0.7
                            }
                            StyledText {
                                text: DateTime.timeZoneName
                                font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                                color: Appearance.colors.colPrimary
                                font.weight: Font.Medium
                            }
                        }
                    }
                }
            }

            Layout.bottomMargin: 24 * scaleFactor
        }
    }

    // Data models
    ListModel {
        id: timeZoneModel
        Component.onCompleted: {
            // Add system default
            append({ display: "System Default", value: "system" })
            
            // Add all IANA timezones
            const allTimeZones = [
                // UTC and GMT
                "UTC", "GMT",
                
                // North America
                "America/New_York", "America/Chicago", "America/Denver", "America/Los_Angeles",
                "America/Phoenix", "America/Anchorage", "America/Juneau", "America/Sitka",
                "America/Metlakatla", "America/Yakutat", "America/Nome", "America/Adak",
                "America/Atka", "America/Boise", "America/Chihuahua", "America/Creston",
                "America/Dawson", "America/Dawson_Creek", "America/Edmonton", "America/Fort_Nelson",
                "America/Fort_Wayne", "America/Glace_Bay", "America/Goose_Bay", "America/Grand_Turk",
                "America/Guatemala", "America/Guayaquil", "America/Guyana", "America/Halifax",
                "America/Havana", "America/Hermosillo", "America/Indiana/Indianapolis", "America/Indiana/Knox",
                "America/Indiana/Marengo", "America/Indiana/Petersburg", "America/Indiana/Tell_City",
                "America/Indiana/Vevay", "America/Indiana/Vincennes", "America/Indiana/Winamac",
                "America/Inuvik", "America/Iqaluit", "America/Jamaica", "America/Managua",
                "America/Manaus", "America/Martinique", "America/Matamoros", "America/Mazatlan",
                "America/Menominee", "America/Merida", "America/Mexico_City", "America/Miquelon",
                "America/Moncton", "America/Monterrey", "America/Montevideo", "America/New_Salem",
                "America/North_Dakota/Beulah", "America/North_Dakota/Center", "America/North_Dakota/New_Salem",
                "America/Ojinaga", "America/Panama", "America/Pangnirtung", "America/Paramaribo",
                "America/Port-au-Prince", "America/Port_of_Spain", "America/Porto_Velho", "America/Puerto_Rico",
                "America/Punta_Arenas", "America/Rainy_River", "America/Rankin_Inlet", "America/Recife",
                "America/Regina", "America/Resolute", "America/Rio_Branco", "America/Santarem",
                "America/Santiago", "America/Santo_Domingo", "America/Sao_Paulo", "America/Scoresbysund",
                "America/Shiprock", "America/Swift_Current", "America/Tegucigalpa", "America/Thule",
                "America/Thunder_Bay", "America/Tijuana", "America/Toronto", "America/Vancouver",
                "America/Whitehorse", "America/Winnipeg", "America/Yellowknife",
                
                // Europe
                "Europe/London", "Europe/Paris", "Europe/Berlin", "Europe/Moscow", "Europe/Amsterdam",
                "Europe/Andorra", "Europe/Astrakhan", "Europe/Athens", "Europe/Belgrade", "Europe/Bratislava",
                "Europe/Brussels", "Europe/Bucharest", "Europe/Budapest", "Europe/Busingen", "Europe/Chisinau",
                "Europe/Copenhagen", "Europe/Dublin", "Europe/Gibraltar", "Europe/Guernsey", "Europe/Helsinki",
                "Europe/Isle_of_Man", "Europe/Istanbul", "Europe/Jersey", "Europe/Kaliningrad", "Europe/Kiev",
                "Europe/Kirov", "Europe/Lisbon", "Europe/Ljubljana", "Europe/Luxembourg", "Europe/Madrid",
                "Europe/Malta", "Europe/Mariehamn", "Europe/Minsk", "Europe/Monaco", "Europe/Oslo",
                "Europe/Podgorica", "Europe/Prague", "Europe/Riga", "Europe/Rome", "Europe/Samara",
                "Europe/San_Marino", "Europe/Sarajevo", "Europe/Saratov", "Europe/Simferopol", "Europe/Skopje",
                "Europe/Sofia", "Europe/Stockholm", "Europe/Tallinn", "Europe/Tirane", "Europe/Ulyanovsk",
                "Europe/Uzhgorod", "Europe/Vaduz", "Europe/Vatican", "Europe/Vienna", "Europe/Vilnius",
                "Europe/Volgograd", "Europe/Warsaw", "Europe/Zagreb", "Europe/Zaporozhye", "Europe/Zurich",
                
                // Asia
                "Asia/Tokyo", "Asia/Shanghai", "Asia/Kolkata", "Asia/Almaty", "Asia/Amman", "Asia/Anadyr",
                "Asia/Aqtau", "Asia/Aqtobe", "Asia/Ashgabat", "Asia/Atyrau", "Asia/Baghdad", "Asia/Baku",
                "Asia/Bangkok", "Asia/Barnaul", "Asia/Beirut", "Asia/Bishkek", "Asia/Brunei", "Asia/Chita",
                "Asia/Choibalsan", "Asia/Colombo", "Asia/Damascus", "Asia/Dhaka", "Asia/Dili", "Asia/Dubai",
                "Asia/Dushanbe", "Asia/Famagusta", "Asia/Gaza", "Asia/Hebron", "Asia/Ho_Chi_Minh", "Asia/Hong_Kong",
                "Asia/Hovd", "Asia/Irkutsk", "Asia/Jakarta", "Asia/Jayapura", "Asia/Jerusalem", "Asia/Kabul",
                "Asia/Kamchatka", "Asia/Karachi", "Asia/Kathmandu", "Asia/Khandyga", "Asia/Krasnoyarsk",
                "Asia/Kuala_Lumpur", "Asia/Kuching", "Asia/Kuwait", "Asia/Macau", "Asia/Magadan", "Asia/Makassar",
                "Asia/Manila", "Asia/Muscat", "Asia/Nicosia", "Asia/Novokuznetsk", "Asia/Novosibirsk",
                "Asia/Omsk", "Asia/Oral", "Asia/Pontianak", "Asia/Pyongyang", "Asia/Qatar", "Asia/Qostanay",
                "Asia/Qyzylorda", "Asia/Riyadh", "Asia/Sakhalin", "Asia/Samarkand", "Asia/Seoul", "Asia/Shanghai",
                "Asia/Singapore", "Asia/Srednekolymsk", "Asia/Taipei", "Asia/Tashkent", "Asia/Tbilisi",
                "Asia/Tehran", "Asia/Thimphu", "Asia/Tomsk", "Asia/Ulaanbaatar", "Asia/Urumqi", "Asia/Ust-Nera",
                "Asia/Vladivostok", "Asia/Yakutsk", "Asia/Yangon", "Asia/Yekaterinburg", "Asia/Yerevan",
                
                // Australia and Oceania
                "Australia/Sydney", "Australia/Adelaide", "Australia/Brisbane", "Australia/Broken_Hill",
                "Australia/Currie", "Australia/Darwin", "Australia/Eucla", "Australia/Hobart", "Australia/Lindeman",
                "Australia/Lord_Howe", "Australia/Melbourne", "Australia/Perth", "Australia/Queensland",
                "Australia/South", "Australia/Tasmania", "Australia/Victoria", "Australia/West",
                "Pacific/Auckland", "Pacific/Bougainville", "Pacific/Chatham", "Pacific/Chuuk", "Pacific/Easter",
                "Pacific/Efate", "Pacific/Enderbury", "Pacific/Fakaofo", "Pacific/Fiji", "Pacific/Funafuti",
                "Pacific/Galapagos", "Pacific/Gambier", "Pacific/Guadalcanal", "Pacific/Guam", "Pacific/Honolulu",
                "Pacific/Kanton", "Pacific/Kiritimati", "Pacific/Kosrae", "Pacific/Kwajalein", "Pacific/Majuro",
                "Pacific/Marquesas", "Pacific/Midway", "Pacific/Nauru", "Pacific/Niue", "Pacific/Norfolk",
                "Pacific/Noumea", "Pacific/Pago_Pago", "Pacific/Palau", "Pacific/Pitcairn", "Pacific/Pohnpei",
                "Pacific/Port_Moresby", "Pacific/Rarotonga", "Pacific/Saipan", "Pacific/Tahiti", "Pacific/Tarawa",
                "Pacific/Tongatapu", "Pacific/Wake", "Pacific/Wallis",
                
                // Africa
                "Africa/Abidjan", "Africa/Accra", "Africa/Addis_Ababa", "Africa/Algiers", "Africa/Asmara",
                "Africa/Bamako", "Africa/Bangui", "Africa/Banjul", "Africa/Bissau", "Africa/Blantyre",
                "Africa/Brazzaville", "Africa/Bujumbura", "Africa/Cairo", "Africa/Casablanca", "Africa/Ceuta",
                "Africa/Conakry", "Africa/Dakar", "Africa/Dar_es_Salaam", "Africa/Djibouti", "Africa/Douala",
                "Africa/El_Aaiun", "Africa/Freetown", "Africa/Gaborone", "Africa/Harare", "Africa/Johannesburg",
                "Africa/Juba", "Africa/Kampala", "Africa/Khartoum", "Africa/Kigali", "Africa/Kinshasa",
                "Africa/Lagos", "Africa/Libreville", "Africa/Lome", "Africa/Luanda", "Africa/Lubumbashi",
                "Africa/Lusaka", "Africa/Malabo", "Africa/Maputo", "Africa/Maseru", "Africa/Mbabane",
                "Africa/Mogadishu", "Africa/Monrovia", "Africa/Nairobi", "Africa/Ndjamena", "Africa/Niamey",
                "Africa/Nouakchott", "Africa/Ouagadougou", "Africa/Porto-Novo", "Africa/Sao_Tome", "Africa/Tripoli",
                "Africa/Tunis", "Africa/Windhoek",
                
                // South America
                "America/Argentina/Buenos_Aires", "America/Argentina/Catamarca", "America/Argentina/Cordoba",
                "America/Argentina/Jujuy", "America/Argentina/La_Rioja", "America/Argentina/Mendoza",
                "America/Argentina/Rio_Gallegos", "America/Argentina/Salta", "America/Argentina/San_Juan",
                "America/Argentina/San_Luis", "America/Argentina/Tucuman", "America/Argentina/Ushuaia",
                "America/Belem", "America/Boa_Vista", "America/Bogota", "America/Caracas", "America/Cayenne",
                "America/Cordoba", "America/Eirunepe", "America/Fortaleza", "America/La_Paz", "America/Lima",
                "America/Maceio", "America/Manaus", "America/Montevideo", "America/Paramaribo", "America/Recife",
                "America/Rio_Branco", "America/Santarem", "America/Santiago", "America/Sao_Paulo"
            ]
            
            allTimeZones.forEach(tz => {
                const display = tz === "UTC" ? "UTC (Coordinated Universal Time)" :
                               tz === "GMT" ? "GMT (Greenwich Mean Time)" :
                               tz.split('/').pop().replace(/_/g, ' ')
                append({ display: display, value: tz })
            })
        }
    }

    property var commonTimeZones: [
        { display: "UTC", value: "UTC" },
        { display: "New York", value: "America/New_York" },
        { display: "Chicago", value: "America/Chicago" },
        { display: "Denver", value: "America/Denver" },
        { display: "Los Angeles", value: "America/Los_Angeles" },
        { display: "London", value: "Europe/London" },
        { display: "Paris", value: "Europe/Paris" },
        { display: "Berlin", value: "Europe/Berlin" },
        { display: "Moscow", value: "Europe/Moscow" },
        { display: "Tokyo", value: "Asia/Tokyo" },
        { display: "Shanghai", value: "Asia/Shanghai" },
        { display: "Dubai", value: "Asia/Dubai" },
        { display: "Sydney", value: "Australia/Sydney" },
        { display: "Auckland", value: "Pacific/Auckland" },
        { display: "Honolulu", value: "Pacific/Honolulu" },
        { display: "Cairo", value: "Africa/Cairo" },
        { display: "Johannesburg", value: "Africa/Johannesburg" },
        { display: "São Paulo", value: "America/Sao_Paulo" },
        { display: "Buenos Aires", value: "America/Argentina/Buenos_Aires" },
        { display: "Mumbai", value: "Asia/Kolkata" }
    ]
} 