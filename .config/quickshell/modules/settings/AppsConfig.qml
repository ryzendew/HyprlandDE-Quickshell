import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import "root:/services"

ColumnLayout {
    id: appsTab
    spacing: 24 * (root.scaleFactor ?? 1.0)

    // Responsive scaling properties
    property real scaleFactor: root.scaleFactor ?? 1.0
    property int baseTabHeight: 56
    property int baseTabWidth: 240
    property int baseIconSize: 16
    property int baseSpacing: 10

    // Horizontal tab navigation with responsive sizing
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: baseTabHeight * scaleFactor
        radius: Appearance.rounding.large * scaleFactor
        color: Appearance.colors.colLayer1
        border.width: 1
        border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.12)

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8 * scaleFactor
            spacing: 12 * scaleFactor

            Repeater {
                model: [
                    { "id": "web", "title": "Web & Email", "icon": "language", "subtitle": "Browser, email & web apps" },
                    { "id": "media", "title": "Media", "icon": "movie", "subtitle": "Music, video & photos" },
                    { "id": "productivity", "title": "Productivity", "icon": "edit", "subtitle": "Text editor & file manager" },
                    { "id": "system", "title": "System", "icon": "settings", "subtitle": "Terminal & system tools" }
                ]

                delegate: Rectangle {
                    Layout.preferredWidth: baseTabWidth * scaleFactor
                    Layout.fillHeight: true
                    radius: Appearance.rounding.normal * scaleFactor
                    color: appsTab.selectedSubTab === modelData.id ? Appearance.colors.colPrimaryContainer : "transparent"
                    border.width: appsTab.selectedSubTab === modelData.id ? 2 : 0
                    border.color: Appearance.colors.colPrimary
                    z: appsTab.selectedSubTab === modelData.id ? 1 : 0
                    antialiasing: true
                    opacity: subTabMouseArea.containsMouse || appsTab.selectedSubTab === modelData.id ? 1.0 : 0.85
                    
                    MouseArea {
                        id: subTabMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: appsTab.selectedSubTab = modelData.id
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: baseSpacing * scaleFactor
                        spacing: baseSpacing * scaleFactor

                        Rectangle {
                            Layout.preferredWidth: 28 * scaleFactor
                            Layout.preferredHeight: 28 * scaleFactor
                            Layout.alignment: Qt.AlignVCenter
                            radius: 8 * scaleFactor
                            color: appsTab.selectedSubTab === modelData.id ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colPrimary, 0.08)
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: modelData.icon
                                iconSize: baseIconSize * scaleFactor
                                color: appsTab.selectedSubTab === modelData.id ? "#000" : Appearance.colors.colPrimary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 0

                            StyledText {
                                text: modelData.title
                                font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                                font.weight: Font.Medium
                                color: appsTab.selectedSubTab === modelData.id ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                            }

                            StyledText {
                                text: modelData.subtitle
                                font.pixelSize: (Appearance.font.pixelSize.smaller * scaleFactor)
                                color: Appearance.colors.colSubtext
                                opacity: appsTab.selectedSubTab === modelData.id ? 0.9 : 0.6
                                visible: true
                            }
                        }
                    }
                }
            }
        }
    }

    // Content area
    Loader {
        Layout.fillWidth: true
        Layout.fillHeight: true
        sourceComponent: {
            switch(appsTab.selectedSubTab) {
                case "web": return webAppsComponent;
                case "media": return mediaAppsComponent;
                case "productivity": return productivityAppsComponent;
                case "system": return systemAppsComponent;
                default: return webAppsComponent;
            }
        }
    }

    // Web & Email Apps tab content
    Component {
        id: webAppsComponent
        ColumnLayout {
            spacing: 24 * scaleFactor
            Layout.fillWidth: true

            // Set Default button for this tab
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60 * scaleFactor
                radius: Appearance.rounding.normal * scaleFactor
                color: Appearance.colors.colLayer2
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)
                visible: webTabHasChanges

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16 * scaleFactor
                    spacing: 12 * scaleFactor

                    MaterialSymbol {
                        text: "check_circle"
                        iconSize: 20 * scaleFactor
                        color: Appearance.colors.colPrimary
                    }

                    StyledText {
                        text: "Set Default Apps"
                        font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer0
                    }

                    StyledText {
                        text: "Apply your web & email app selections to the system"
                        font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                        color: Appearance.colors.colSubtext
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: 140 * scaleFactor
                        Layout.preferredHeight: 36 * scaleFactor
                        radius: Appearance.rounding.small * scaleFactor
                        color: Appearance.colors.colPrimary
                        opacity: webSetDefaultMouseArea.containsMouse ? 0.9 : 1.0

                        MouseArea {
                            id: webSetDefaultMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[AppsConfig] Setting web & email defaults...")
                                // Use a timer to ensure ComboBoxes are ready
                                webDefaultsTimer.start()
                            }
                        }

                        StyledText {
                            anchors.centerIn: parent
                            text: "Set Default"
                            font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                            font.weight: Font.Medium
                            color: "#000"
                        }
                    }
                }
            }

            // Test button for debugging
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60 * scaleFactor
                radius: Appearance.rounding.normal * scaleFactor
                color: Appearance.colors.colLayer2
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)
                visible: true

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16 * scaleFactor
                    spacing: 12 * scaleFactor

                    MaterialSymbol {
                        text: "bug_report"
                        iconSize: 20 * scaleFactor
                        color: Appearance.colors.colPrimary
                    }

                    StyledText {
                        text: "Debug: Test Default Apps"
                        font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer0
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: 120 * scaleFactor
                        Layout.preferredHeight: 36 * scaleFactor
                        radius: Appearance.rounding.small * scaleFactor
                        color: Appearance.colors.colPrimary
                        opacity: testButtonMouseArea.containsMouse ? 0.9 : 1.0

                        MouseArea {
                            id: testButtonMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[AppsConfig] Testing Python script directly...")
                                DefaultApps.testPythonScript()
                            }
                        }

                        StyledText {
                            anchors.centerIn: parent
                            text: "Test Script"
                            font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                            font.weight: Font.Medium
                            color: "#000"
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 120 * scaleFactor
                        Layout.preferredHeight: 36 * scaleFactor
                        radius: Appearance.rounding.small * scaleFactor
                        color: Appearance.colors.colPrimary
                        opacity: testManualButtonMouseArea.containsMouse ? 0.9 : 1.0

                        MouseArea {
                            id: testManualButtonMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[AppsConfig] Testing MPV as video player...")
                                DefaultApps.testSetAnyDefault("video", "MPV")
                            }
                        }

                        StyledText {
                            anchors.centerIn: parent
                            text: "Test MPV"
                            font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                            font.weight: Font.Medium
                            color: "#000"
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 120 * scaleFactor
                        Layout.preferredHeight: 36 * scaleFactor
                        radius: Appearance.rounding.small * scaleFactor
                        color: Appearance.colors.colPrimary
                        opacity: debugButtonMouseArea.containsMouse ? 0.9 : 1.0

                        MouseArea {
                            id: debugButtonMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[AppsConfig] Debug: Checking detected apps and defaults...")
                                console.log("[AppsConfig] Detected apps:", DefaultApps.detectedApps)
                                console.log("[AppsConfig] Current defaults:", DefaultApps.currentDefaults)
                                
                                // Check what's in the web browser ComboBox (only one accessible from this scope)
                                if (webBrowserComboBox) {
                                    console.log("[AppsConfig] Web browser ComboBox availableApps:", webBrowserComboBox.availableApps)
                                    console.log("[AppsConfig] Web browser ComboBox currentIndex:", webBrowserComboBox.currentIndex)
                                }
                                
                                // Show available apps for each category
                                console.log("[AppsConfig] Available web apps:", DefaultApps.getAvailableApps("web"))
                                console.log("[AppsConfig] Available video apps:", DefaultApps.getAvailableApps("video"))
                                console.log("[AppsConfig] Available music apps:", DefaultApps.getAvailableApps("music"))
                                console.log("[AppsConfig] Available terminal apps:", DefaultApps.getAvailableApps("terminal"))
                            }
                        }

                        StyledText {
                            anchors.centerIn: parent
                            text: "Debug Info"
                            font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                            font.weight: Font.Medium
                            color: "#000"
                        }
                    }
                }
            }

            // Loading indicator
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60 * scaleFactor
                radius: Appearance.rounding.normal * scaleFactor
                color: Appearance.colors.colLayer2
                visible: DefaultApps.isLoading
                
                RowLayout {
                    Layout.alignment: Qt.AlignCenter
                    spacing: 12 * scaleFactor
                    
                    Rectangle {
                        width: 20 * scaleFactor
                        height: 20 * scaleFactor
                        radius: 10 * scaleFactor
                        color: Appearance.colors.colPrimary
                        opacity: 0.8
                        
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.2; duration: 1000 }
                            NumberAnimation { to: 0.8; duration: 1000 }
                        }
                    }

                StyledText {
                        text: "Loading available applications..."
                        font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                        color: Appearance.colors.colOnLayer0
                    }
                }
            }

            // Web Browser Setting
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: childrenRect.height + (32 * scaleFactor)
                radius: Appearance.rounding.large * scaleFactor
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)
                visible: !DefaultApps.isLoading

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 24 * scaleFactor
                    spacing: 20 * scaleFactor

                    // Section header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12 * scaleFactor

                        Rectangle {
                            Layout.preferredWidth: 32 * scaleFactor
                            Layout.preferredHeight: 32 * scaleFactor
                            radius: Appearance.rounding.small * scaleFactor
                            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "language"
                                iconSize: 18 * scaleFactor
                                color: Appearance.colors.colPrimary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2 * scaleFactor

                            StyledText {
                                text: "Web Browser"
                                font.pixelSize: (Appearance.font.pixelSize.large * scaleFactor)
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer0
                }

                StyledText {
                                text: "Set your default web browser for opening web pages and links"
                                font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                    color: Appearance.colors.colSubtext
                            }
                        }
                    }

                    // Dropdown
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12 * scaleFactor

                        StyledText {
                            text: "Default Application:"
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer0
                        }

                        Rectangle {
                    Layout.fillWidth: true
                            Layout.preferredHeight: 44 * scaleFactor
                            radius: Appearance.rounding.normal * scaleFactor
                            color: Appearance.colors.colLayer2
                            border.width: 1
                            border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.18)

                            ComboBox {
                                id: webBrowserComboBox
                                anchors.fill: parent
                                anchors.margins: 6 * scaleFactor
                                
                                property var availableApps: []
                                
                                model: availableApps.length > 0 ? availableApps : ["No apps found"]
                                currentIndex: 0
                                
                                background: Rectangle {
                                    color: "transparent"
                                }
                                
                                contentItem: Text {
                                    text: webBrowserComboBox.displayText
                                    color: Appearance.colors.colOnLayer0
                                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                                
                                onCurrentIndexChanged: {
                                    if (availableApps.length > 0 && currentIndex >= 0 && currentIndex < availableApps.length) {
                                        const selectedApp = availableApps[currentIndex]
                                        DefaultApps.setDefaultApp("web", selectedApp)
                                        checkWebTabChanges()
                                    }
                                }
                                
                                Component.onCompleted: {
                                    webBrowserComboBox.availableApps = DefaultApps.getAvailableApps("web")
                                    webBrowserComboBox.model = webBrowserComboBox.availableApps.length > 0 ? webBrowserComboBox.availableApps : ["No apps found"]
                                    
                                    const currentDefault = DefaultApps.getCurrentDefault("web")
                                    const index = webBrowserComboBox.availableApps.indexOf(currentDefault)
                                    webBrowserComboBox.currentIndex = index >= 0 ? index : 0
                                }
                                
                                Connections {
                                    target: DefaultApps
                                    function onAppsLoaded() {
                                        webBrowserComboBox.availableApps = DefaultApps.getAvailableApps("web")
                                        webBrowserComboBox.model = webBrowserComboBox.availableApps.length > 0 ? webBrowserComboBox.availableApps : ["No apps found"]
                                        
                                        const currentDefault = DefaultApps.getCurrentDefault("web")
                                        const index = webBrowserComboBox.availableApps.indexOf(currentDefault)
                                        webBrowserComboBox.currentIndex = index >= 0 ? index : 0
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Email Client Setting
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: childrenRect.height + (32 * scaleFactor)
                radius: Appearance.rounding.large * scaleFactor
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)
                visible: !DefaultApps.isLoading

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 24 * scaleFactor
                    spacing: 20 * scaleFactor

                    // Section header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12 * scaleFactor

                        Rectangle {
                            Layout.preferredWidth: 32 * scaleFactor
                            Layout.preferredHeight: 32 * scaleFactor
                            radius: Appearance.rounding.small * scaleFactor
                            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "mail"
                                iconSize: 18 * scaleFactor
                                color: Appearance.colors.colPrimary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2 * scaleFactor

                            StyledText {
                                text: "Email Client"
                                font.pixelSize: (Appearance.font.pixelSize.large * scaleFactor)
                                font.weight: Font.Bold
                                color: Appearance.colors.colOnLayer0
                            }

                            StyledText {
                                text: "Set your default email client for composing and reading emails"
                                font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }

                    // Dropdown
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12 * scaleFactor

                        StyledText {
                            text: "Default Application:"
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer0
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44 * scaleFactor
                            radius: Appearance.rounding.normal * scaleFactor
                            color: Appearance.colors.colLayer2
                            border.width: 1
                            border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.18)

                            ComboBox {
                                id: emailClientComboBox
                    anchors.fill: parent
                                anchors.margins: 6 * scaleFactor
                                
                                property var availableApps: []
                                
                                model: availableApps.length > 0 ? availableApps : ["No apps found"]
                                currentIndex: 0
                                
                                background: Rectangle {
                                    color: "transparent"
                                }
                                
                                contentItem: Text {
                                    text: emailClientComboBox.displayText
                                    color: Appearance.colors.colOnLayer0
                                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                                
                                onCurrentIndexChanged: {
                                    if (availableApps.length > 0 && currentIndex >= 0 && currentIndex < availableApps.length) {
                                        const selectedApp = availableApps[currentIndex]
                                        DefaultApps.setDefaultApp("mail", selectedApp)
                                        checkWebTabChanges()
                                    }
                                }
                                
                                Component.onCompleted: {
                                    emailClientComboBox.availableApps = DefaultApps.getAvailableApps("mail")
                                    emailClientComboBox.model = emailClientComboBox.availableApps.length > 0 ? emailClientComboBox.availableApps : ["No apps found"]
                                    
                                    const currentDefault = DefaultApps.getCurrentDefault("mail")
                                    const index = emailClientComboBox.availableApps.indexOf(currentDefault)
                                    emailClientComboBox.currentIndex = index >= 0 ? index : 0
                                }
                                
                                Connections {
                                    target: DefaultApps
                                    function onAppsLoaded() {
                                        emailClientComboBox.availableApps = DefaultApps.getAvailableApps("mail")
                                        emailClientComboBox.model = emailClientComboBox.availableApps.length > 0 ? emailClientComboBox.availableApps : ["No apps found"]
                                        
                                        const currentDefault = DefaultApps.getCurrentDefault("mail")
                                        const index = emailClientComboBox.availableApps.indexOf(currentDefault)
                                        emailClientComboBox.currentIndex = index >= 0 ? index : 0
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Calendar Setting
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: childrenRect.height + (32 * scaleFactor)
                radius: Appearance.rounding.large * scaleFactor
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)
                visible: !DefaultApps.isLoading

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 24 * scaleFactor
                    spacing: 20 * scaleFactor

                    // Section header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12 * scaleFactor

                        Rectangle {
                            Layout.preferredWidth: 32 * scaleFactor
                            Layout.preferredHeight: 32 * scaleFactor
                            radius: Appearance.rounding.small * scaleFactor
                            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "event"
                                iconSize: 18 * scaleFactor
                                color: Appearance.colors.colPrimary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2 * scaleFactor

                            StyledText {
                                text: "Calendar"
                                font.pixelSize: (Appearance.font.pixelSize.large * scaleFactor)
                                font.weight: Font.Bold
                                color: Appearance.colors.colOnLayer0
                            }

                            StyledText {
                                text: "Set your default calendar application for events and scheduling"
                                font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }

                    // Dropdown
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12 * scaleFactor

                        StyledText {
                            text: "Default Application:"
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer0
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44 * scaleFactor
                            radius: Appearance.rounding.normal * scaleFactor
                            color: Appearance.colors.colLayer2
                            border.width: 1
                            border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.18)

                            ComboBox {
                                id: calendarComboBox
                                anchors.fill: parent
                                anchors.margins: 6 * scaleFactor
                                
                                property var availableApps: []
                                
                                model: availableApps.length > 0 ? availableApps : ["No apps found"]
                                currentIndex: 0
                                
                                background: Rectangle {
                                    color: "transparent"
                                }
                                
                                contentItem: Text {
                                    text: calendarComboBox.displayText
                                    color: Appearance.colors.colOnLayer0
                                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                                
                                onCurrentIndexChanged: {
                                    if (availableApps.length > 0 && currentIndex >= 0 && currentIndex < availableApps.length) {
                                        const selectedApp = availableApps[currentIndex]
                                        DefaultApps.setDefaultApp("calendar", selectedApp)
                                        checkWebTabChanges()
                                    }
                                }
                                
                                Component.onCompleted: {
                                    calendarComboBox.availableApps = DefaultApps.getAvailableApps("calendar")
                                    calendarComboBox.model = calendarComboBox.availableApps.length > 0 ? calendarComboBox.availableApps : ["No apps found"]
                                    
                                    const currentDefault = DefaultApps.getCurrentDefault("calendar")
                                    const index = calendarComboBox.availableApps.indexOf(currentDefault)
                                    calendarComboBox.currentIndex = index >= 0 ? index : 0
                                }
                                
                                Connections {
                                    target: DefaultApps
                                    function onAppsLoaded() {
                                        calendarComboBox.availableApps = DefaultApps.getAvailableApps("calendar")
                                        calendarComboBox.model = calendarComboBox.availableApps.length > 0 ? calendarComboBox.availableApps : ["No apps found"]
                                        
                                        const currentDefault = DefaultApps.getCurrentDefault("calendar")
                                        const index = calendarComboBox.availableApps.indexOf(currentDefault)
                                        calendarComboBox.currentIndex = index >= 0 ? index : 0
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

        // Media Apps tab content
    Component {
        id: mediaAppsComponent
        ColumnLayout {
            spacing: 24 * scaleFactor
            Layout.fillWidth: true

            // Music Player Setting
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: childrenRect.height + (32 * scaleFactor)
                radius: Appearance.rounding.large * scaleFactor
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)
                visible: !DefaultApps.isLoading

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 24 * scaleFactor
                    spacing: 20 * scaleFactor

                    // Section header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12 * scaleFactor

                            Rectangle {
                            Layout.preferredWidth: 32 * scaleFactor
                            Layout.preferredHeight: 32 * scaleFactor
                            radius: Appearance.rounding.small * scaleFactor
                            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                text: "music_note"
                                iconSize: 18 * scaleFactor
                                    color: Appearance.colors.colPrimary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2 * scaleFactor

                            StyledText {
                                text: "Music Player"
                                font.pixelSize: (Appearance.font.pixelSize.large * scaleFactor)
                                font.weight: Font.Bold
                                color: Appearance.colors.colOnLayer0
                            }

                            StyledText {
                                text: "Set your default music player for playing audio files and music"
                                font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }

                    // Dropdown
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12 * scaleFactor

                        StyledText {
                            text: "Default Application:"
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer0
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44 * scaleFactor
                            radius: Appearance.rounding.normal * scaleFactor
                            color: Appearance.colors.colLayer2
                            border.width: 1
                            border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.18)

                            ComboBox {
                                id: musicPlayerComboBox
                                anchors.fill: parent
                                anchors.margins: 6 * scaleFactor
                                
                                property var availableApps: []
                                
                                model: availableApps.length > 0 ? availableApps : ["No apps found"]
                                currentIndex: 0
                                
                                background: Rectangle {
                                    color: "transparent"
                                }
                                
                                contentItem: Text {
                                    text: musicPlayerComboBox.displayText
                                    color: Appearance.colors.colOnLayer0
                                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                                
                                onCurrentIndexChanged: {
                                    if (availableApps.length > 0 && currentIndex >= 0 && currentIndex < availableApps.length) {
                                        const selectedApp = availableApps[currentIndex]
                                        DefaultApps.setDefaultApp("music", selectedApp)
                                        checkMediaTabChanges()
                                    }
                                }
                                
                                Component.onCompleted: {
                                    musicPlayerComboBox.availableApps = DefaultApps.getAvailableApps("music")
                                    musicPlayerComboBox.model = musicPlayerComboBox.availableApps.length > 0 ? musicPlayerComboBox.availableApps : ["No apps found"]
                                    
                                    const currentDefault = DefaultApps.getCurrentDefault("music")
                                    const index = musicPlayerComboBox.availableApps.indexOf(currentDefault)
                                    musicPlayerComboBox.currentIndex = index >= 0 ? index : 0
                                }
                                
                                Connections {
                                    target: DefaultApps
                                    function onAppsLoaded() {
                                        musicPlayerComboBox.availableApps = DefaultApps.getAvailableApps("music")
                                        musicPlayerComboBox.model = musicPlayerComboBox.availableApps.length > 0 ? musicPlayerComboBox.availableApps : ["No apps found"]
                                        
                                        const currentDefault = DefaultApps.getCurrentDefault("music")
                                        const index = musicPlayerComboBox.availableApps.indexOf(currentDefault)
                                        musicPlayerComboBox.currentIndex = index >= 0 ? index : 0
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Video Player Setting
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: childrenRect.height + (32 * scaleFactor)
                radius: Appearance.rounding.large * scaleFactor
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)
                visible: !DefaultApps.isLoading

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 24 * scaleFactor
                    spacing: 20 * scaleFactor

                    // Section header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12 * scaleFactor

                        Rectangle {
                            Layout.preferredWidth: 32 * scaleFactor
                            Layout.preferredHeight: 32 * scaleFactor
                            radius: Appearance.rounding.small * scaleFactor
                            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "movie"
                                iconSize: 18 * scaleFactor
                                color: Appearance.colors.colPrimary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2 * scaleFactor

                            StyledText {
                                text: "Video Player"
                                font.pixelSize: (Appearance.font.pixelSize.large * scaleFactor)
                                font.weight: Font.Bold
                                color: Appearance.colors.colOnLayer0
                            }

                            StyledText {
                                text: "Set your default video player for playing video files and movies"
                                font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }

                    // Dropdown
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12 * scaleFactor

                        StyledText {
                            text: "Default Application:"
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                                font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer0
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44 * scaleFactor
                            radius: Appearance.rounding.normal * scaleFactor
                            color: Appearance.colors.colLayer2
                            border.width: 1
                            border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.18)

                            ComboBox {
                                id: videoPlayerComboBox
                                anchors.fill: parent
                                anchors.margins: 6 * scaleFactor
                                
                                property var availableApps: []
                                
                                model: availableApps.length > 0 ? availableApps : ["No apps found"]
                                currentIndex: 0
                                
                                background: Rectangle {
                                    color: "transparent"
                                }
                                
                                contentItem: Text {
                                    text: videoPlayerComboBox.displayText
                                    color: Appearance.colors.colOnLayer0
                                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                                
                                onCurrentIndexChanged: {
                                    if (availableApps.length > 0 && currentIndex >= 0 && currentIndex < availableApps.length) {
                                        const selectedApp = availableApps[currentIndex]
                                        DefaultApps.setDefaultApp("video", selectedApp)
                                        checkMediaTabChanges()
                                    }
                                }
                                
                                Component.onCompleted: {
                                    videoPlayerComboBox.availableApps = DefaultApps.getAvailableApps("video")
                                    videoPlayerComboBox.model = videoPlayerComboBox.availableApps.length > 0 ? videoPlayerComboBox.availableApps : ["No apps found"]
                                    
                                    const currentDefault = DefaultApps.getCurrentDefault("video")
                                    const index = videoPlayerComboBox.availableApps.indexOf(currentDefault)
                                    videoPlayerComboBox.currentIndex = index >= 0 ? index : 0
                                }
                                
                                Connections {
                                    target: DefaultApps
                                    function onAppsLoaded() {
                                        videoPlayerComboBox.availableApps = DefaultApps.getAvailableApps("video")
                                        videoPlayerComboBox.model = videoPlayerComboBox.availableApps.length > 0 ? videoPlayerComboBox.availableApps : ["No apps found"]
                                        
                                        const currentDefault = DefaultApps.getCurrentDefault("video")
                                        const index = videoPlayerComboBox.availableApps.indexOf(currentDefault)
                                        videoPlayerComboBox.currentIndex = index >= 0 ? index : 0
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Photo Viewer Setting
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: childrenRect.height + (32 * scaleFactor)
                radius: Appearance.rounding.large * scaleFactor
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)
                visible: !DefaultApps.isLoading

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 24 * scaleFactor
                    spacing: 20 * scaleFactor

                    // Section header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12 * scaleFactor

                        Rectangle {
                            Layout.preferredWidth: 32 * scaleFactor
                            Layout.preferredHeight: 32 * scaleFactor
                            radius: Appearance.rounding.small * scaleFactor
                            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "photo"
                                iconSize: 18 * scaleFactor
                                color: Appearance.colors.colPrimary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2 * scaleFactor

                            StyledText {
                                text: "Photo Viewer"
                                font.pixelSize: (Appearance.font.pixelSize.large * scaleFactor)
                                font.weight: Font.Bold
                                color: Appearance.colors.colOnLayer0
                            }

                            StyledText {
                                text: "Set your default photo viewer for viewing images and photos"
                                font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }

                    // Dropdown
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12 * scaleFactor

                        StyledText {
                            text: "Default Application:"
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer0
                        }

                            Rectangle {
                                Layout.fillWidth: true
                            Layout.preferredHeight: 44 * scaleFactor
                            radius: Appearance.rounding.normal * scaleFactor
                                color: Appearance.colors.colLayer2
                                border.width: 1
                                border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.18)

                                ComboBox {
                                id: photoViewerComboBox
                                    anchors.fill: parent
                                anchors.margins: 6 * scaleFactor
                                
                                property var availableApps: []
                                
                                model: availableApps.length > 0 ? availableApps : ["No apps found"]
                                    currentIndex: 0
                                
                                    background: Rectangle {
                                        color: "transparent"
                                }
                                
                                contentItem: Text {
                                    text: photoViewerComboBox.displayText
                                    color: Appearance.colors.colOnLayer0
                                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                                
                                onCurrentIndexChanged: {
                                    if (availableApps.length > 0 && currentIndex >= 0 && currentIndex < availableApps.length) {
                                        const selectedApp = availableApps[currentIndex]
                                        DefaultApps.setDefaultApp("photos", selectedApp)
                                        checkMediaTabChanges()
                                    }
                                }
                                
                                Component.onCompleted: {
                                    photoViewerComboBox.availableApps = DefaultApps.getAvailableApps("photos")
                                    photoViewerComboBox.model = photoViewerComboBox.availableApps.length > 0 ? photoViewerComboBox.availableApps : ["No apps found"]
                                    
                                    const currentDefault = DefaultApps.getCurrentDefault("photos")
                                    const index = photoViewerComboBox.availableApps.indexOf(currentDefault)
                                    photoViewerComboBox.currentIndex = index >= 0 ? index : 0
                                }
                                
                                Connections {
                                    target: DefaultApps
                                    function onAppsLoaded() {
                                        photoViewerComboBox.availableApps = DefaultApps.getAvailableApps("photos")
                                        photoViewerComboBox.model = photoViewerComboBox.availableApps.length > 0 ? photoViewerComboBox.availableApps : ["No apps found"]
                                        
                                        const currentDefault = DefaultApps.getCurrentDefault("photos")
                                        const index = photoViewerComboBox.availableApps.indexOf(currentDefault)
                                        photoViewerComboBox.currentIndex = index >= 0 ? index : 0
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Set Default button for Media tab
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60 * scaleFactor
                radius: Appearance.rounding.normal * scaleFactor
                color: Appearance.colors.colLayer2
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)
                visible: mediaTabHasChanges

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16 * scaleFactor
                    spacing: 12 * scaleFactor

                    MaterialSymbol {
                        text: "check_circle"
                        iconSize: 20 * scaleFactor
                        color: Appearance.colors.colPrimary
                    }

                    StyledText {
                        text: "Set Default Apps"
                        font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer0
                    }

                    StyledText {
                        text: "Apply your media app selections to the system"
                        font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                        color: Appearance.colors.colSubtext
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: 140 * scaleFactor
                        Layout.preferredHeight: 36 * scaleFactor
                        radius: Appearance.rounding.small * scaleFactor
                        color: Appearance.colors.colPrimary
                        opacity: mediaSetDefaultMouseArea.containsMouse ? 0.9 : 1.0

                        MouseArea {
                            id: mediaSetDefaultMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[AppsConfig] Setting media defaults...")
                                // Use a timer to ensure ComboBoxes are ready
                                mediaDefaultsTimer.start()
                            }
                        }

                        StyledText {
                            anchors.centerIn: parent
                            text: "Set Default"
                            font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                            font.weight: Font.Medium
                            color: "#000"
                        }
                    }
                }
            }
        }
    }

    // Productivity Apps tab content
    Component {
        id: productivityAppsComponent
        ColumnLayout {
            spacing: 24 * scaleFactor
            Layout.fillWidth: true

            // Text Editor Setting
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: childrenRect.height + (32 * scaleFactor)
                radius: Appearance.rounding.large * scaleFactor
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)
                visible: !DefaultApps.isLoading

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 24 * scaleFactor
                    spacing: 20 * scaleFactor

                    // Section header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12 * scaleFactor

                        Rectangle {
                            Layout.preferredWidth: 32 * scaleFactor
                            Layout.preferredHeight: 32 * scaleFactor
                            radius: Appearance.rounding.small * scaleFactor
                            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "edit"
                                iconSize: 18 * scaleFactor
                                color: Appearance.colors.colPrimary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2 * scaleFactor

                            StyledText {
                                text: "Text Editor"
                                font.pixelSize: (Appearance.font.pixelSize.large * scaleFactor)
                                font.weight: Font.Bold
                                color: Appearance.colors.colOnLayer0
                            }

                            StyledText {
                                text: "Set your default text editor for editing text files and code"
                                font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }

                    // Dropdown
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12 * scaleFactor

                        StyledText {
                            text: "Default Application:"
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer0
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44 * scaleFactor
                            radius: Appearance.rounding.normal * scaleFactor
                            color: Appearance.colors.colLayer2
                            border.width: 1
                            border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.18)

                            ComboBox {
                                id: textEditorComboBox
                                anchors.fill: parent
                                anchors.margins: 6 * scaleFactor
                                
                                property var availableApps: []
                                
                                model: availableApps.length > 0 ? availableApps : ["No apps found"]
                                currentIndex: 0
                                
                                background: Rectangle {
                                    color: "transparent"
                                }
                                
                                    contentItem: Text {
                                    text: textEditorComboBox.displayText
                                        color: Appearance.colors.colOnLayer0
                                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                }
                                
                                onCurrentIndexChanged: {
                                    if (availableApps.length > 0 && currentIndex >= 0 && currentIndex < availableApps.length) {
                                        const selectedApp = availableApps[currentIndex]
                                        DefaultApps.setDefaultApp("text_editor", selectedApp)
                                        checkProductivityTabChanges()
                                    }
                                }
                                
                                Component.onCompleted: {
                                    textEditorComboBox.availableApps = DefaultApps.getAvailableApps("text_editor")
                                    textEditorComboBox.model = textEditorComboBox.availableApps.length > 0 ? textEditorComboBox.availableApps : ["No apps found"]
                                    
                                    const currentDefault = DefaultApps.getCurrentDefault("text_editor")
                                    const index = textEditorComboBox.availableApps.indexOf(currentDefault)
                                    textEditorComboBox.currentIndex = index >= 0 ? index : 0
                                }
                                
                                Connections {
                                    target: DefaultApps
                                    function onAppsLoaded() {
                                        textEditorComboBox.availableApps = DefaultApps.getAvailableApps("text_editor")
                                        textEditorComboBox.model = textEditorComboBox.availableApps.length > 0 ? textEditorComboBox.availableApps : ["No apps found"]
                                        
                                        const currentDefault = DefaultApps.getCurrentDefault("text_editor")
                                        const index = textEditorComboBox.availableApps.indexOf(currentDefault)
                                        textEditorComboBox.currentIndex = index >= 0 ? index : 0
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // File Manager Setting
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: childrenRect.height + (32 * scaleFactor)
                radius: Appearance.rounding.large * scaleFactor
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)
                visible: !DefaultApps.isLoading

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 24 * scaleFactor
                    spacing: 20 * scaleFactor

                    // Section header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12 * scaleFactor

                        Rectangle {
                            Layout.preferredWidth: 32 * scaleFactor
                            Layout.preferredHeight: 32 * scaleFactor
                            radius: Appearance.rounding.small * scaleFactor
                            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "folder"
                                iconSize: 18 * scaleFactor
                                color: Appearance.colors.colPrimary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2 * scaleFactor

                            StyledText {
                                text: "File Manager"
                                font.pixelSize: (Appearance.font.pixelSize.large * scaleFactor)
                                font.weight: Font.Bold
                                color: Appearance.colors.colOnLayer0
                            }

                            StyledText {
                                text: "Set your default file manager for browsing files and folders"
                                font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }

                    // Dropdown
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12 * scaleFactor

                        StyledText {
                            text: "Default Application:"
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer0
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44 * scaleFactor
                            radius: Appearance.rounding.normal * scaleFactor
                            color: Appearance.colors.colLayer2
                            border.width: 1
                            border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.18)

                            ComboBox {
                                id: fileManagerComboBox
                    anchors.fill: parent
                                anchors.margins: 6 * scaleFactor
                                
                                property var availableApps: []
                                
                                model: availableApps.length > 0 ? availableApps : ["No apps found"]
                                currentIndex: 0
                                
                                background: Rectangle {
                                    color: "transparent"
                                }
                                
                                contentItem: Text {
                                    text: fileManagerComboBox.displayText
                                    color: Appearance.colors.colOnLayer0
                                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                                
                                onCurrentIndexChanged: {
                                    if (availableApps.length > 0 && currentIndex >= 0 && currentIndex < availableApps.length) {
                                        const selectedApp = availableApps[currentIndex]
                                        DefaultApps.setDefaultApp("file_manager", selectedApp)
                                        checkProductivityTabChanges()
                                    }
                                }
                                
                                Component.onCompleted: {
                                    fileManagerComboBox.availableApps = DefaultApps.getAvailableApps("file_manager")
                                    fileManagerComboBox.model = fileManagerComboBox.availableApps.length > 0 ? fileManagerComboBox.availableApps : ["No apps found"]
                                    
                                    const currentDefault = DefaultApps.getCurrentDefault("file_manager")
                                    const index = fileManagerComboBox.availableApps.indexOf(currentDefault)
                                    fileManagerComboBox.currentIndex = index >= 0 ? index : 0
                                }
                                
                                Connections {
                                    target: DefaultApps
                                    function onAppsLoaded() {
                                        fileManagerComboBox.availableApps = DefaultApps.getAvailableApps("file_manager")
                                        fileManagerComboBox.model = fileManagerComboBox.availableApps.length > 0 ? fileManagerComboBox.availableApps : ["No apps found"]
                                        
                                        const currentDefault = DefaultApps.getCurrentDefault("file_manager")
                                        const index = fileManagerComboBox.availableApps.indexOf(currentDefault)
                                        fileManagerComboBox.currentIndex = index >= 0 ? index : 0
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Set Default button for Productivity tab
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60 * scaleFactor
                radius: Appearance.rounding.normal * scaleFactor
                color: Appearance.colors.colLayer2
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)
                visible: productivityTabHasChanges

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16 * scaleFactor
                    spacing: 12 * scaleFactor

                    MaterialSymbol {
                        text: "check_circle"
                        iconSize: 20 * scaleFactor
                        color: Appearance.colors.colPrimary
                    }

                    StyledText {
                        text: "Set Default Apps"
                        font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer0
                    }

                    StyledText {
                        text: "Apply your productivity app selections to the system"
                        font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                        color: Appearance.colors.colSubtext
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: 140 * scaleFactor
                        Layout.preferredHeight: 36 * scaleFactor
                        radius: Appearance.rounding.small * scaleFactor
                        color: Appearance.colors.colPrimary
                        opacity: productivitySetDefaultMouseArea.containsMouse ? 0.9 : 1.0

                        MouseArea {
                            id: productivitySetDefaultMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[AppsConfig] Setting productivity defaults...")
                                // Use a timer to ensure ComboBoxes are ready
                                productivityDefaultsTimer.start()
                            }
                        }

                        StyledText {
                            anchors.centerIn: parent
                            text: "Set Default"
                            font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                            font.weight: Font.Medium
                            color: "#000"
                        }
                    }
                }
            }
        }
    }

    // System Apps tab content
    Component {
        id: systemAppsComponent
        ColumnLayout {
            spacing: 24 * scaleFactor
            Layout.fillWidth: true

            // Terminal Setting
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: childrenRect.height + (32 * scaleFactor)
                radius: Appearance.rounding.large * scaleFactor
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)
                visible: !DefaultApps.isLoading

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 24 * scaleFactor
                    spacing: 20 * scaleFactor

                    // Section header
                RowLayout {
                        Layout.fillWidth: true
                        spacing: 12 * scaleFactor

                        Rectangle {
                            Layout.preferredWidth: 32 * scaleFactor
                            Layout.preferredHeight: 32 * scaleFactor
                            radius: Appearance.rounding.small * scaleFactor
                            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.1)

                            MaterialSymbol {
                    anchors.centerIn: parent
                                text: "terminal"
                                iconSize: 18 * scaleFactor
                                color: Appearance.colors.colPrimary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2 * scaleFactor

                            StyledText {
                                text: "Terminal"
                                font.pixelSize: (Appearance.font.pixelSize.large * scaleFactor)
                                font.weight: Font.Bold
                                color: Appearance.colors.colOnLayer0
                            }

                            StyledText {
                                text: "Set your default terminal for command line operations"
                                font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }

                    // Dropdown
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12 * scaleFactor

                    StyledText {
                            text: "Default Application:"
                            font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                        font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer0
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44 * scaleFactor
                            radius: Appearance.rounding.normal * scaleFactor
                            color: Appearance.colors.colLayer2
                            border.width: 1
                            border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.18)

                            ComboBox {
                                id: terminalComboBox
                                anchors.fill: parent
                                anchors.margins: 6 * scaleFactor
                                
                                property var availableApps: []
                                
                                model: availableApps.length > 0 ? availableApps : ["No apps found"]
                                currentIndex: 0
                                
                                background: Rectangle {
                                    color: "transparent"
                                }
                                
                                contentItem: Text {
                                    text: terminalComboBox.displayText
                                    color: Appearance.colors.colOnLayer0
                                    font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                                
                                onCurrentIndexChanged: {
                                    if (availableApps.length > 0 && currentIndex >= 0 && currentIndex < availableApps.length) {
                                        const selectedApp = availableApps[currentIndex]
                                        DefaultApps.setDefaultApp("terminal", selectedApp)
                                        checkSystemTabChanges()
                                    }
                                }
                                
                                Component.onCompleted: {
                                    terminalComboBox.availableApps = DefaultApps.getAvailableApps("terminal")
                                    terminalComboBox.model = terminalComboBox.availableApps.length > 0 ? terminalComboBox.availableApps : ["No apps found"]
                                    
                                    const currentDefault = DefaultApps.getCurrentDefault("terminal")
                                    const index = terminalComboBox.availableApps.indexOf(currentDefault)
                                    terminalComboBox.currentIndex = index >= 0 ? index : 0
                                }
                                
                                Connections {
                                    target: DefaultApps
                                    function onAppsLoaded() {
                                        terminalComboBox.availableApps = DefaultApps.getAvailableApps("terminal")
                                        terminalComboBox.model = terminalComboBox.availableApps.length > 0 ? terminalComboBox.availableApps : ["No apps found"]
                                        
                                        const currentDefault = DefaultApps.getCurrentDefault("terminal")
                                        const index = terminalComboBox.availableApps.indexOf(currentDefault)
                                        terminalComboBox.currentIndex = index >= 0 ? index : 0
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Set Default button for System tab
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60 * scaleFactor
                radius: Appearance.rounding.normal * scaleFactor
                color: Appearance.colors.colLayer2
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.1)
                visible: systemTabHasChanges

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16 * scaleFactor
                    spacing: 12 * scaleFactor

                    MaterialSymbol {
                        text: "check_circle"
                        iconSize: 20 * scaleFactor
                        color: Appearance.colors.colPrimary
                    }

                    StyledText {
                        text: "Set Default Apps"
                        font.pixelSize: (Appearance.font.pixelSize.normal * scaleFactor)
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer0
                    }

                    StyledText {
                        text: "Apply your system app selections to the system"
                        font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                        color: Appearance.colors.colSubtext
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: 140 * scaleFactor
                        Layout.preferredHeight: 36 * scaleFactor
                        radius: Appearance.rounding.small * scaleFactor
                        color: Appearance.colors.colPrimary
                        opacity: systemSetDefaultMouseArea.containsMouse ? 0.9 : 1.0

                        MouseArea {
                            id: systemSetDefaultMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[AppsConfig] Setting system defaults...")
                                // Use a timer to ensure ComboBoxes are ready
                                systemDefaultsTimer.start()
                            }
                        }

                        StyledText {
                            anchors.centerIn: parent
                            text: "Set Default"
                            font.pixelSize: (Appearance.font.pixelSize.small * scaleFactor)
                            font.weight: Font.Medium
                            color: "#000"
                        }
                    }
                }
            }
        }
    }

    property string selectedSubTab: "web"

    // Change tracking properties for each tab
    property bool webTabHasChanges: false
    property bool mediaTabHasChanges: false
    property bool productivityTabHasChanges: false
    property bool systemTabHasChanges: false

    // Store original values for comparison
    property var originalDefaults: {
        "web": "",
        "mail": "",
        "calendar": "",
        "music": "",
        "video": "",
        "photos": "",
        "text_editor": "",
        "file_manager": "",
        "terminal": ""
    }

    // Initialize original defaults
    Component.onCompleted: {
        originalDefaults = {
            web: DefaultApps.getCurrentDefault("web") || "",
            mail: DefaultApps.getCurrentDefault("mail") || "",
            calendar: DefaultApps.getCurrentDefault("calendar") || "",
            music: DefaultApps.getCurrentDefault("music") || "",
            video: DefaultApps.getCurrentDefault("video") || "",
            photos: DefaultApps.getCurrentDefault("photos") || "",
            text_editor: DefaultApps.getCurrentDefault("text_editor") || "",
            file_manager: DefaultApps.getCurrentDefault("file_manager") || "",
            terminal: DefaultApps.getCurrentDefault("terminal") || ""
        }
    }

    // Function to check if web tab has changes
    function checkWebTabChanges() {
        if (!originalDefaults) return
        
        const currentWeb = DefaultApps.getCurrentDefault("web") || ""
        const currentMail = DefaultApps.getCurrentDefault("mail") || ""
        const currentCalendar = DefaultApps.getCurrentDefault("calendar") || ""
        
        webTabHasChanges = (currentWeb !== (originalDefaults.web || "") || 
                           currentMail !== (originalDefaults.mail || "") || 
                           currentCalendar !== (originalDefaults.calendar || ""))
    }

    // Function to check if media tab has changes
    function checkMediaTabChanges() {
        if (!originalDefaults) return
        
        const currentMusic = DefaultApps.getCurrentDefault("music") || ""
        const currentVideo = DefaultApps.getCurrentDefault("video") || ""
        const currentPhotos = DefaultApps.getCurrentDefault("photos") || ""
        
        mediaTabHasChanges = (currentMusic !== (originalDefaults.music || "") || 
                             currentVideo !== (originalDefaults.video || "") || 
                             currentPhotos !== (originalDefaults.photos || ""))
    }

    // Function to check if productivity tab has changes
    function checkProductivityTabChanges() {
        if (!originalDefaults) return
        
        const currentTextEditor = DefaultApps.getCurrentDefault("text_editor") || ""
        const currentFileManager = DefaultApps.getCurrentDefault("file_manager") || ""
        
        productivityTabHasChanges = (currentTextEditor !== (originalDefaults.text_editor || "") || 
                                    currentFileManager !== (originalDefaults.file_manager || ""))
    }

    // Function to check if system tab has changes
    function checkSystemTabChanges() {
        if (!originalDefaults) return
        
        const currentTerminal = DefaultApps.getCurrentDefault("terminal") || ""
        
        systemTabHasChanges = (currentTerminal !== (originalDefaults.terminal || ""))
    }

    // Function to set web defaults
    function setWebDefaults() {
        console.log("[AppsConfig] Setting web & email defaults...")
        
        // Safety checks for ComboBoxes
        if (!webBrowserComboBox || !emailClientComboBox || !calendarComboBox) {
            console.error("[AppsConfig] One or more ComboBoxes are not available")
            return
        }
        
        // Debug: Log ComboBox states
        console.log(`[AppsConfig] webBrowserComboBox.currentIndex: ${webBrowserComboBox.currentIndex}`)
        console.log(`[AppsConfig] webBrowserComboBox.availableApps:`, webBrowserComboBox.availableApps)
        console.log(`[AppsConfig] emailClientComboBox.currentIndex: ${emailClientComboBox.currentIndex}`)
        console.log(`[AppsConfig] emailClientComboBox.availableApps:`, emailClientComboBox.availableApps)
        console.log(`[AppsConfig] calendarComboBox.currentIndex: ${calendarComboBox.currentIndex}`)
        console.log(`[AppsConfig] calendarComboBox.availableApps:`, calendarComboBox.availableApps)
        
        // Get selected values from ComboBoxes
        const selectedWeb = webBrowserComboBox.availableApps && webBrowserComboBox.availableApps.length > 0 && webBrowserComboBox.currentIndex >= 0 ? 
                           webBrowserComboBox.availableApps[webBrowserComboBox.currentIndex] : ""
        const selectedMail = emailClientComboBox.availableApps && emailClientComboBox.availableApps.length > 0 && emailClientComboBox.currentIndex >= 0 ? 
                           emailClientComboBox.availableApps[emailClientComboBox.currentIndex] : ""
        const selectedCalendar = calendarComboBox.availableApps && calendarComboBox.availableApps.length > 0 && calendarComboBox.currentIndex >= 0 ? 
                               calendarComboBox.availableApps[calendarComboBox.currentIndex] : ""
        
        console.log(`[AppsConfig] Selected web: ${selectedWeb}`)
        console.log(`[AppsConfig] Selected mail: ${selectedMail}`)
        console.log(`[AppsConfig] Selected calendar: ${selectedCalendar}`)
        
        // Set the selected defaults
        if (selectedWeb && selectedWeb !== "") {
            console.log(`[AppsConfig] Setting web default: ${selectedWeb}`)
            DefaultApps.setDefaultApp("web", selectedWeb)
        }
        
        if (selectedMail && selectedMail !== "") {
            console.log(`[AppsConfig] Setting mail default: ${selectedMail}`)
            DefaultApps.setDefaultApp("mail", selectedMail)
        }
        
        if (selectedCalendar && selectedCalendar !== "") {
            console.log(`[AppsConfig] Setting calendar default: ${selectedCalendar}`)
            DefaultApps.setDefaultApp("calendar", selectedCalendar)
        }
        
        // Update original defaults and reset change flag
        if (originalDefaults) {
            originalDefaults.web = selectedWeb || ""
            originalDefaults.mail = selectedMail || ""
            originalDefaults.calendar = selectedCalendar || ""
        }
        webTabHasChanges = false
        
        console.log("[AppsConfig] Web & email defaults set successfully!")
    }

    // Function to set media defaults
    function setMediaDefaults() {
        console.log("[AppsConfig] Setting media defaults...")
        
        // Safety checks for ComboBoxes
        if (!musicPlayerComboBox || !videoPlayerComboBox || !photoViewerComboBox) {
            console.error("[AppsConfig] One or more media ComboBoxes are not available")
            return
        }
        
        // Get selected values from ComboBoxes
        const selectedMusic = musicPlayerComboBox.availableApps && musicPlayerComboBox.availableApps.length > 0 && musicPlayerComboBox.currentIndex >= 0 ? 
                             musicPlayerComboBox.availableApps[musicPlayerComboBox.currentIndex] : ""
        const selectedVideo = videoPlayerComboBox.availableApps && videoPlayerComboBox.availableApps.length > 0 && videoPlayerComboBox.currentIndex >= 0 ? 
                             videoPlayerComboBox.availableApps[videoPlayerComboBox.currentIndex] : ""
        const selectedPhotos = photoViewerComboBox.availableApps && photoViewerComboBox.availableApps.length > 0 && photoViewerComboBox.currentIndex >= 0 ? 
                              photoViewerComboBox.availableApps[photoViewerComboBox.currentIndex] : ""
        
        console.log(`[AppsConfig] Selected music: ${selectedMusic}`)
        console.log(`[AppsConfig] Selected video: ${selectedVideo}`)
        console.log(`[AppsConfig] Selected photos: ${selectedPhotos}`)
        
        // Set the selected defaults
        if (selectedMusic && selectedMusic !== "") {
            console.log(`[AppsConfig] Setting music default: ${selectedMusic}`)
            DefaultApps.setDefaultApp("music", selectedMusic)
        }
        
        if (selectedVideo && selectedVideo !== "") {
            console.log(`[AppsConfig] Setting video default: ${selectedVideo}`)
            DefaultApps.setDefaultApp("video", selectedVideo)
        }
        
        if (selectedPhotos && selectedPhotos !== "") {
            console.log(`[AppsConfig] Setting photos default: ${selectedPhotos}`)
            DefaultApps.setDefaultApp("photos", selectedPhotos)
        }
        
        // Update original defaults and reset change flag
        if (originalDefaults) {
            originalDefaults.music = selectedMusic || ""
            originalDefaults.video = selectedVideo || ""
            originalDefaults.photos = selectedPhotos || ""
        }
        mediaTabHasChanges = false
        
        console.log("[AppsConfig] Media defaults set successfully!")
    }

    // Function to set productivity defaults
    function setProductivityDefaults() {
        console.log("[AppsConfig] Setting productivity defaults...")
        
        // Safety checks for ComboBoxes
        if (!textEditorComboBox || !fileManagerComboBox) {
            console.error("[AppsConfig] One or more productivity ComboBoxes are not available")
            return
        }
        
        // Get selected values from ComboBoxes
        const selectedTextEditor = textEditorComboBox.availableApps && textEditorComboBox.availableApps.length > 0 && textEditorComboBox.currentIndex >= 0 ? 
                                  textEditorComboBox.availableApps[textEditorComboBox.currentIndex] : ""
        const selectedFileManager = fileManagerComboBox.availableApps && fileManagerComboBox.availableApps.length > 0 && fileManagerComboBox.currentIndex >= 0 ? 
                                   fileManagerComboBox.availableApps[fileManagerComboBox.currentIndex] : ""
        
        console.log(`[AppsConfig] Selected text editor: ${selectedTextEditor}`)
        console.log(`[AppsConfig] Selected file manager: ${selectedFileManager}`)
        
        // Set the selected defaults
        if (selectedTextEditor && selectedTextEditor !== "") {
            console.log(`[AppsConfig] Setting text editor default: ${selectedTextEditor}`)
            DefaultApps.setDefaultApp("text_editor", selectedTextEditor)
        }
        
        if (selectedFileManager && selectedFileManager !== "") {
            console.log(`[AppsConfig] Setting file manager default: ${selectedFileManager}`)
            DefaultApps.setDefaultApp("file_manager", selectedFileManager)
        }
        
        // Update original defaults and reset change flag
        if (originalDefaults) {
            originalDefaults.text_editor = selectedTextEditor || ""
            originalDefaults.file_manager = selectedFileManager || ""
        }
        productivityTabHasChanges = false
        
        console.log("[AppsConfig] Productivity defaults set successfully!")
    }

    // Function to set system defaults
    function setSystemDefaults() {
        console.log("[AppsConfig] Setting system defaults...")
        
        // Safety checks for ComboBoxes
        if (!terminalComboBox) {
            console.error("[AppsConfig] Terminal ComboBox is not available")
            return
        }
        
        // Get selected values from ComboBoxes
        const selectedTerminal = terminalComboBox.availableApps && terminalComboBox.availableApps.length > 0 && terminalComboBox.currentIndex >= 0 ? 
                                terminalComboBox.availableApps[terminalComboBox.currentIndex] : ""
        
        console.log(`[AppsConfig] Selected terminal: ${selectedTerminal}`)
        
        // Set the selected defaults
        if (selectedTerminal && selectedTerminal !== "") {
            console.log(`[AppsConfig] Setting terminal default: ${selectedTerminal}`)
            DefaultApps.setDefaultApp("terminal", selectedTerminal)
        }
        
        // Update original defaults and reset change flag
        if (originalDefaults) {
            originalDefaults.terminal = selectedTerminal || ""
        }
        systemTabHasChanges = false
        
        console.log("[AppsConfig] System defaults set successfully!")
    }

    // Function to save all default app changes (legacy function)
    function saveDefaultAppChanges() {
        console.log("[AppsConfig] Saving all default app changes...")
        
        const categories = ["web", "mail", "calendar", "music", "video", "photos", "text_editor", "file_manager", "terminal"]
        
        categories.forEach(category => {
            const currentDefault = DefaultApps.getCurrentDefault(category)
            if (currentDefault && currentDefault !== "") {
                console.log(`[AppsConfig] Saving ${category} default: ${currentDefault}`)
                DefaultApps.setDefaultApp(category, currentDefault)
            }
        })
        
        // Update all original defaults
        if (originalDefaults) {
            Object.keys(originalDefaults).forEach(key => {
                originalDefaults[key] = DefaultApps.getCurrentDefault(key) || ""
            })
        }
        
        // Reset all change flags
        webTabHasChanges = false
        mediaTabHasChanges = false
        productivityTabHasChanges = false
        systemTabHasChanges = false
        
        console.log("[AppsConfig] All default app changes saved successfully!")
    }

    // Timers for delayed execution to ensure ComboBoxes are ready
    Timer {
        id: webDefaultsTimer
        interval: 100
        repeat: false
        onTriggered: {
            console.log("[AppsConfig] Web defaults timer triggered")
            setWebDefaults()
        }
    }

    Timer {
        id: mediaDefaultsTimer
        interval: 100
        repeat: false
        onTriggered: {
            console.log("[AppsConfig] Media defaults timer triggered")
            setMediaDefaults()
        }
    }

    Timer {
        id: productivityDefaultsTimer
        interval: 100
        repeat: false
        onTriggered: {
            console.log("[AppsConfig] Productivity defaults timer triggered")
            setProductivityDefaults()
        }
    }

    Timer {
        id: systemDefaultsTimer
        interval: 100
        repeat: false
        onTriggered: {
            console.log("[AppsConfig] System defaults timer triggered")
            setSystemDefaults()
        }
    }
} 