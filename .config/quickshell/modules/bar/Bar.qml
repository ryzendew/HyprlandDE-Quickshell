import "root:/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Io
import Quickshell.Services.Mpris
import "." as BarComponents


Scope {
    id: bar

    readonly property int barHeight: ConfigOptions.bar.height ?? 40
    readonly property int barCenterSideModuleWidth: Appearance.sizes.barCenterSideModuleWidth
    readonly property int osdHideMouseMoveThreshold: 20
    property bool hyprlandAvailable: true
    readonly property int barIconSize: ConfigOptions.getIconSize()
    readonly property int indicatorIconSize: ConfigOptions.getIndicatorIconSize()
    readonly property int logoIconSize: ConfigOptions.getLogoIconSize()

    // Helper function to safely dispatch Hyprland commands
    function safeDispatch(command) {
        if (!hyprlandAvailable) return;
        
        try {
            Hyprland.dispatch(command);
        } catch (e) {
            if (command.includes("setvar") && command.includes("decoration:blur")) {
                hyprlandAvailable = false;
            }
        }
    }

    // Watch for changes in blur settings
    Connections {
        target: AppearanceSettingsState
        function onBarBlurAmountChanged() {
            if (AppearanceSettingsState.blurEnabled) {
                safeDispatch(`setvar decoration:blur:size ${AppearanceSettingsState.barBlurAmount}`)
            }
            safeDispatch("exec killall -SIGUSR2 quickshell")
        }
        function onBarBlurPassesChanged() {
            if (AppearanceSettingsState.blurEnabled) {
                safeDispatch(`setvar decoration:blur:passes ${AppearanceSettingsState.barBlurPasses}`)
            }
            safeDispatch("exec killall -SIGUSR2 quickshell")
        }
        function onBarXrayChanged() {
            AppearanceSettingsState.updateBarBlurSettings()
            safeDispatch("exec killall -SIGUSR2 quickshell")
        }
        function onBlurEnabledChanged() {
            AppearanceSettingsState.updateBarBlurSettings()
            safeDispatch("exec killall -SIGUSR2 quickshell")
        }
    }

    // Initial blur setup
    Component.onCompleted: {
        // Skip Hyprland availability test since it causes warnings
        // The blur settings are already configured in Hyprland config files
        hyprlandAvailable = true; // Assume available since config is set up
    }

    component VerticalBarSeparator: Rectangle {
        Layout.topMargin: barHeight / 3
        Layout.bottomMargin: barHeight / 3
        Layout.fillHeight: true
        implicitWidth: 1
        color: Appearance.m3colors.m3outlineVariant
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barRoot
            implicitHeight: barHeight
            exclusiveZone: barHeight

            property ShellScreen modelData
            property var brightnessMonitor: Brightness.getMonitorForScreen(modelData)
            property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen.width) ? 2 :
                (Appearance.sizes.barShortenScreenWidthThreshold >= screen.width) ? 1 : 0
            readonly property int centerSideModuleWidth: 
                (useShortenedForm == 2) ? Appearance.sizes.barCenterSideModuleWidthHellaShortened :
                (useShortenedForm == 1) ? Appearance.sizes.barCenterSideModuleWidthShortened : 
                    Appearance.sizes.barCenterSideModuleWidth

            screen: modelData
            mask: Region {
                item: barContent
            }
            color: "transparent"
            WlrLayershell.namespace: "quickshell:bar:blur"

            anchors {
                top: (ConfigOptions.bar?.bottom ?? false) ? false : true
                bottom: (ConfigOptions.bar?.bottom ?? false) ? true : false
                left: true
                right: true
            }

            Rectangle {
                id: barContent
                anchors.right: parent.right
                anchors.left: parent.left
                anchors.top: parent.top
                height: barHeight
                radius: 0
                color: Qt.rgba(
                    (Appearance.colors?.colLayer0?.r ?? 0) * (ConfigOptions.bar?.brightness ?? 1.0),
                    (Appearance.colors?.colLayer0?.g ?? 0) * (ConfigOptions.bar?.brightness ?? 1.0),
                    (Appearance.colors?.colLayer0?.b ?? 0) * (ConfigOptions.bar?.brightness ?? 1.0),
                    ConfigOptions.bar?.transparency ?? 0.3
                )
                anchors.margins: 0
                layer.enabled: true
                layer.smooth: true
                    
                Behavior on color {
                    ColorAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                    }
                }

                // Individual borders - top, left, right, bottom
                Rectangle {
                    id: topBorder
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 3
                    visible: ConfigOptions.bar?.borderTop ?? false
                    z: 10
                    
                    color: {
                        let colorStr = ConfigOptions.bar?.borderColor || "#ffffff"
                        let opacity = ConfigOptions.bar?.borderOpacity || 0.12
                        let color = Qt.color(colorStr)
                        return Qt.rgba(color.r, color.g, color.b, opacity)
                    }
                    
                    layer.enabled: true
                    layer.smooth: true
                }

                Rectangle {
                    id: leftBorder
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 3
                    visible: ConfigOptions.bar?.borderLeft ?? false
                    z: 10
                    
                    color: {
                        let colorStr = ConfigOptions.bar?.borderColor || "#ffffff"
                        let opacity = ConfigOptions.bar?.borderOpacity || 0.12
                        let color = Qt.color(colorStr)
                        return Qt.rgba(color.r, color.g, color.b, opacity)
                    }
                    
                    layer.enabled: true
                    layer.smooth: true
                }

                Rectangle {
                    id: rightBorder
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 3
                    visible: ConfigOptions.bar?.borderRight ?? false
                    z: 10
                    
                    color: {
                        let colorStr = ConfigOptions.bar?.borderColor || "#ffffff"
                        let opacity = ConfigOptions.bar?.borderOpacity || 0.12
                        let color = Qt.color(colorStr)
                        return Qt.rgba(color.r, color.g, color.b, opacity)
                    }
                    
                    layer.enabled: true
                    layer.smooth: true
                }

                Rectangle {
                    id: bottomBorder
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 3
                    visible: ConfigOptions.bar?.borderBottom ?? true
                    z: 10
                    
                    color: {
                        let colorStr = ConfigOptions.bar?.borderColor || "#ffffff"
                        let opacity = ConfigOptions.bar?.borderOpacity || 0.12
                        let color = Qt.color(colorStr)
                        return Qt.rgba(color.r, color.g, color.b, opacity)
                    }
                    
                    layer.enabled: true
                    layer.smooth: true
                }
                
                MouseArea {
                    id: barLeftSideMouseArea
                    anchors.left: parent.left
                    implicitHeight: barHeight
                    width: (barRoot.width - middleSection.width) / 2
                    property bool hovered: false
                    property real lastScrollX: 0
                    property real lastScrollY: 1
                    property bool trackingScroll: false
                    acceptedButtons: Qt.NoButton
                    hoverEnabled: false
                    propagateComposedEvents: true
                    
                    WheelHandler {
                        onWheel: (event) => {
                            if (event.angleDelta.y < 0)
                                barRoot.brightnessMonitor.setBrightness(barRoot.brightnessMonitor.brightness - 0.05);
                            else if (event.angleDelta.y > 0)
                                barRoot.brightnessMonitor.setBrightness(barRoot.brightnessMonitor.brightness + 0.05);
                            
                            // Trigger brightness OSD
                            safeDispatch('global quickshell:osdBrightness:trigger');
                            
                            barLeftSideMouseArea.lastScrollX = event.x;
                            barLeftSideMouseArea.lastScrollY = event.y;
                            barLeftSideMouseArea.trackingScroll = true;
                        }
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    }
                    onPositionChanged: (mouse) => {
                        if (barLeftSideMouseArea.trackingScroll) {
                            const dx = mouse.x - barLeftSideMouseArea.lastScrollX;
                            const dy = mouse.y - barLeftSideMouseArea.lastScrollY;
                            if (Math.sqrt(dx*dx + dy*dy) > osdHideMouseMoveThreshold) {
                                safeDispatch('global quickshell:osdBrightnessHide')
                                barLeftSideMouseArea.trackingScroll = false;
                            }
                        }
                    }
                    Item {
                        anchors.fill: parent
                        implicitHeight: leftSectionRowLayout.implicitHeight
                        implicitWidth: leftSectionRowLayout.implicitWidth
                        
                        RowLayout {
                            id: leftSectionRowLayout
                            anchors.fill: parent
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10

                            Rectangle {
                                id: archLogoContainer
                                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                Layout.leftMargin: 4
                                Layout.fillWidth: false
                                Layout.fillHeight: true
                                
                                radius: Appearance.rounding.full
                                color: archMouseArea.containsMouse ? 
                                    Qt.rgba(
                                        (Appearance.colors?.colLayer1Active?.r ?? 0) * (ConfigOptions.bar?.brightness ?? 1.0),
                                        (Appearance.colors?.colLayer1Active?.g ?? 0) * (ConfigOptions.bar?.brightness ?? 1.0),
                                        (Appearance.colors?.colLayer1Active?.b ?? 0) * (ConfigOptions.bar?.brightness ?? 1.0),
                                        0.8
                                    ) : 
                                    "transparent"
                                implicitWidth: archLogo.width + 10
                                implicitHeight: barHeight

                                antialiasing: true
                                Item {
                                    anchors.centerIn: parent
                                    width: logoIconSize
                                    height: logoIconSize
                                    
                                    Image {
                                        id: archLogo
                                        anchors.fill: parent
                                        source: "root:/assets/icons/" + (ConfigOptions.appearance.logo || "distro-nobara-symbolic.svg")
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        antialiasing: true
                                        sourceSize.width: logoIconSize
                                        sourceSize.height: logoIconSize
                                        layer.enabled: true
                                        layer.smooth: true
                                        
                                        layer.effect: DropShadow {
                                            horizontalOffset: 0
                                            verticalOffset: 2
                                            radius: 4.0
                                            samples: 9
                                            color: Qt.rgba(0, 0, 0, 0.3)
                                        }
                                    }
                                    
                                    ColorOverlay {
                                        anchors.fill: archLogo
                                        source: archLogo
                                        color: ConfigOptions.appearance.logoColor || "#ffffff"
                                    }
                                }
                                
                                MouseArea {
                                    id: archMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton
                                    
                                    onClicked: {
                                        GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                RowLayout {
                    id: middleSection
                    anchors.centerIn: parent
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    RowLayout {
                        id: leftCenterGroup
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    RowLayout {
                        id: middleCenterGroup
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignVCenter
                        Workspaces {
                            bar: barRoot
                            Layout.alignment: Qt.AlignCenter | Qt.AlignVCenter
                            Layout.fillWidth: false  // Don't fill width to keep centered
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.RightButton
                                onPressed: (event) => {
                                    if (event.button === Qt.RightButton) {
                                        safeDispatch('global quickshell:overviewToggle')
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        id: rightCenterGroup
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: barRightSideMouseArea
                    anchors.right: parent.right
                    implicitHeight: barHeight
                    width: rightSectionRowLayout.implicitWidth
                    acceptedButtons: Qt.NoButton
                    hoverEnabled: false
                    propagateComposedEvents: true
                    


                    Item {
                        anchors.fill: parent
                        implicitHeight: rightSectionRowLayout.implicitHeight
                        implicitWidth: rightSectionRowLayout.implicitWidth

                        RowLayout {
                            id: rightSectionRowLayout
                            anchors.fill: parent
                            anchors.verticalCenter: parent.verticalCenter
                            layoutDirection: Qt.RightToLeft
                            spacing: 2

                            RippleButton { // Right sidebar button (indicators)
                                id: rightSidebarButton
                                Layout.margins: 0
                                Layout.fillHeight: true
                                Layout.alignment: Qt.AlignCenter | Qt.AlignVCenter
                                implicitWidth: indicatorsRowLayout.implicitWidth + 6*2
                                buttonRadius: Appearance.rounding.full
                                colBackground: barRightSideMouseArea.hovered ? 
                                    Qt.rgba(
                                        (Appearance.colors?.colLayer1Hover?.r ?? 0) * (ConfigOptions.bar?.brightness ?? 1.0),
                                        (Appearance.colors?.colLayer1Hover?.g ?? 0) * (ConfigOptions.bar?.brightness ?? 1.0),
                                        (Appearance.colors?.colLayer1Hover?.b ?? 0) * (ConfigOptions.bar?.brightness ?? 1.0),
                                        0.1
                                    ) : 
                                    ColorUtils.transparentize(
                                        Qt.rgba(
                                            (Appearance.colors?.colLayer1Hover?.r ?? 0) * (ConfigOptions.bar?.brightness ?? 1.0),
                                            (Appearance.colors?.colLayer1Hover?.g ?? 0) * (ConfigOptions.bar?.brightness ?? 1.0),
                                            (Appearance.colors?.colLayer1Hover?.b ?? 0) * (ConfigOptions.bar?.brightness ?? 1.0),
                                            0.1
                                        ), 1
                                    )
                                colBackgroundHover: Qt.rgba(
                                    (Appearance.colors?.colLayer1Hover?.r ?? 0) * (ConfigOptions.bar?.brightness ?? 1.0),
                                    (Appearance.colors?.colLayer1Hover?.g ?? 0) * (ConfigOptions.bar?.brightness ?? 1.0),
                                    (Appearance.colors?.colLayer1Hover?.b ?? 0) * (ConfigOptions.bar?.brightness ?? 1.0),
                                    0.1
                                )
                                colRipple: Qt.rgba(
                                    (Appearance.colors?.colLayer1Active?.r ?? 0) * (ConfigOptions.bar?.brightness ?? 1.0),
                                    (Appearance.colors?.colLayer1Active?.g ?? 0) * (ConfigOptions.bar?.brightness ?? 1.0),
                                    (Appearance.colors?.colLayer1Active?.b ?? 0) * (ConfigOptions.bar?.brightness ?? 1.0),
                                    0.2
                                )
                                colBackgroundToggled: Appearance.m3colors.m3secondaryContainer
                                colBackgroundToggledHover: Qt.rgba(
                                    (Appearance.colors?.colSecondaryContainerHover?.r ?? 0) * (ConfigOptions.bar?.brightness ?? 1.0),
                                    (Appearance.colors?.colSecondaryContainerHover?.g ?? 0) * (ConfigOptions.bar?.brightness ?? 1.0),
                                    (Appearance.colors?.colSecondaryContainerHover?.b ?? 0) * (ConfigOptions.bar?.brightness ?? 1.0),
                                    0.1
                                )
                                colRippleToggled: Qt.rgba(
                                    (Appearance.colors?.colSecondaryContainerActive?.r ?? 0) * (ConfigOptions.bar?.brightness ?? 1.0),
                                    (Appearance.colors?.colSecondaryContainerActive?.g ?? 0) * (ConfigOptions.bar?.brightness ?? 1.0),
                                    (Appearance.colors?.colSecondaryContainerActive?.b ?? 0) * (ConfigOptions.bar?.brightness ?? 1.0),
                                    0.2
                                )
                                toggled: GlobalStates.sidebarRightOpen
                                property color colText: toggled ? (Appearance.m3colors?.m3onSecondaryContainer ?? "#000000") : (Appearance.colors?.colOnLayer0 ?? "#000000")

                                Behavior on colText {
                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                }

                                onPressed: {
                                    safeDispatch('global quickshell:sidebarRightToggle')
                                }

                                RowLayout {
                                    id: indicatorsRowLayout
                                    anchors.centerIn: parent
                                    property real realSpacing: 8
                                    spacing: 0
                                    Layout.alignment: Qt.AlignVCenter
                                    
                                    // Volume muted indicator
                                    MaterialSymbol {
                                        Layout.rightMargin: 4
                                        text: "volume_off"
                                        iconSize: indicatorIconSize
                                        color: rightSidebarButton.colText
                                        visible: Audio.sink?.audio?.muted ?? false
                                        
                                        layer.enabled: true
                                        layer.smooth: true
                                        
                                        layer.effect: DropShadow {
                                            horizontalOffset: 0
                                            verticalOffset: 2
                                            radius: 4.0
                                            samples: 9
                                            color: Qt.rgba(0, 0, 0, 0.3)
                                        }
                                        
                                        MouseArea {
                                            anchors.fill: parent
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                                            onClicked: (mouse) => {
                                                if (mouse.button === Qt.LeftButton) {
                                                    if (Audio.sink?.audio) {
                                                        Audio.sink.audio.muted = false
                                                    }
                                                } else if (mouse.button === Qt.RightButton) {
                                                    // Right-click toggles mute
                                                    if (Audio.sink?.audio) {
                                                        Audio.sink.audio.muted = !Audio.sink.audio.muted
                                                    }
                                                }
                                            }
                                            
                                            onWheel: function(wheel) {
                                                // console.log("Volume scroll detected:", wheel.angleDelta.y)
                                                if (Audio.sink?.audio) {
                                                    var currentVolume = Audio.sink.audio.volume;
                                                    // console.log("Current volume before change:", currentVolume)
                                                    
                                                    var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05  // 5% steps
                                                    var newVolume = Math.max(0, Math.min(1, currentVolume + delta))
                                                    
                                                    // console.log("Calculated new volume:", newVolume)
                                                    // console.log("Setting Audio.sink.audio.volume to:", newVolume)
                                                    
                                                    // Try different methods to set volume
                                                    if (typeof Audio.sink.audio.setVolume === 'function') {
                                                        // console.log("Using setVolume method")
                                                        Audio.sink.audio.setVolume(newVolume)
                                                    } else {
                                                        // console.log("Using direct property assignment")
                                                        Audio.sink.audio.volume = newVolume
                                                    }
                                                    
                                                    // Check if it actually changed
                                                    Qt.callLater(() => {
                                                        // console.log("Volume after setting:", Audio.sink.audio.volume)
                                                    })
                                                } else {
                                                    // console.log("No audio sink available")
                                            }
                                        }
                                        }
                                    }
                                    
                                    // Volume level indicator
                                        MaterialSymbol {
                                        Layout.rightMargin: 4
                                        text: {
                                            var volume = Audio.sink?.audio?.volume ?? 0
                                            if (volume > 0.6) return "volume_up"
                                            else if (volume > 0.3) return "volume_down"
                                            else return "volume_mute"
                                        }
                                        iconSize: indicatorIconSize
                                            color: rightSidebarButton.colText
                                        visible: !(Audio.sink?.audio?.muted ?? false)
                                        
                                        layer.enabled: true
                                        layer.smooth: true
                                        
                                        layer.effect: DropShadow {
                                            horizontalOffset: 0
                                            verticalOffset: 2
                                            radius: 4.0
                                            samples: 9
                                            color: Qt.rgba(0, 0, 0, 0.3)
                                        }
                                        
                                        MouseArea {
                                            anchors.fill: parent
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                                            onClicked: (mouse) => {
                                                if (mouse.button === Qt.LeftButton) {
                                                    if (Audio.sink?.audio) {
                                                        Audio.sink.audio.muted = true
                                                    }
                                                } else if (mouse.button === Qt.RightButton) {
                                                    // Right-click toggles mute
                                                    if (Audio.sink?.audio) {
                                                        Audio.sink.audio.muted = !Audio.sink.audio.muted
                                                    }
                                                }
                                            }
                                            
                                            onWheel: function(wheel) {
                                                // console.log("Volume scroll detected:", wheel.angleDelta.y)
                                                if (Audio.sink?.audio) {
                                                    var currentVolume = Audio.sink.audio.volume;
                                                    // console.log("Current volume before change:", currentVolume)
                                                    
                                                    var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05  // 5% steps
                                                    var newVolume = Math.max(0, Math.min(1, currentVolume + delta))
                                                    
                                                    // console.log("Calculated new volume:", newVolume)
                                                    // console.log("Setting Audio.sink.audio.volume to:", newVolume)
                                                    
                                                    // Try different methods to set volume
                                                    if (typeof Audio.sink.audio.setVolume === 'function') {
                                                        // console.log("Using setVolume method")
                                                        Audio.sink.audio.setVolume(newVolume)
                                                    } else {
                                                        // console.log("Using direct property assignment")
                                                        Audio.sink.audio.volume = newVolume
                                                    }
                                                    
                                                    // Check if it actually changed
                                                    Qt.callLater(() => {
                                                        // console.log("Volume after setting:", Audio.sink.audio.volume)
                                                    })
                                                } else {
                                                    // console.log("No audio sink available")
                                                }
                                            }
                                        }
                                    }
                                    
                                                                            // Microphone muted indicator
                                    MaterialSymbol {
                                        Layout.rightMargin: 4
                                        text: "mic_off"
                                        iconSize: indicatorIconSize
                                        color: rightSidebarButton.colText
                                        visible: Audio.source?.audio?.muted ?? false
                                        
                                        layer.enabled: true
                                        layer.smooth: true
                                        
                                        layer.effect: DropShadow {
                                            horizontalOffset: 0
                                            verticalOffset: 2
                                            radius: 4.0
                                            samples: 9
                                            color: Qt.rgba(0, 0, 0, 0.3)
                                        }
                                        
                                        MouseArea {
                                            anchors.fill: parent
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                                            onClicked: (mouse) => {
                                                if (mouse.button === Qt.LeftButton) {
                                                    if (Audio.source?.audio) {
                                                        Audio.source.audio.muted = false
                                                    }
                                                } else if (mouse.button === Qt.RightButton) {
                                                    // Right-click toggles mute
                                                    if (Audio.source?.audio) {
                                                        Audio.source.audio.muted = !Audio.source.audio.muted
                                                    }
                                                }
                                            }
                                            
                                            onWheel: function(wheel) {
                                                // console.log("=== MIC MUTED SCROLL ===")
                                                if (Audio.source?.audio) {
                                                    var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                                                    var newVol = Math.max(0, Math.min(1, Audio.source.audio.volume + delta))
                                                    // console.log("Setting mic volume to:", newVol)
                                                    Audio.source.audio.volume = newVol
                                                    
                                                    // Trigger microphone OSD
                                                    Hyprland.dispatch("global quickshell:osdMicrophone:trigger")
                                                } else {
                                                    // console.log("No mic")
                                            }
                                        }
                                        }
                                    }
                                    
                                    // Microphone active indicator
                                        MaterialSymbol {
                                        Layout.rightMargin: 4
                                        text: "mic"
                                        iconSize: indicatorIconSize
                                            color: rightSidebarButton.colText
                                        visible: !(Audio.source?.audio?.muted ?? false)
                                        
                                        layer.enabled: true
                                        layer.smooth: true
                                        
                                        layer.effect: DropShadow {
                                            horizontalOffset: 0
                                            verticalOffset: 2
                                            radius: 4.0
                                            samples: 9
                                            color: Qt.rgba(0, 0, 0, 0.3)
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                                            onClicked: (mouse) => {
                                                if (mouse.button === Qt.LeftButton) {
                                                    if (Audio.source?.audio) {
                                                        Audio.source.audio.muted = true
                                                    }
                                                } else if (mouse.button === Qt.RightButton) {
                                                    // Right-click toggles mute
                                                    if (Audio.source?.audio) {
                                                        Audio.source.audio.muted = !Audio.source.audio.muted
                                            }
                                        }
                                            }
                                            
                                            onWheel: function(wheel) {
                                                // console.log("=== MIC ACTIVE SCROLL ===")
                                                if (Audio.source?.audio) {
                                                    var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                                                    var newVol = Math.max(0, Math.min(1, Audio.source.audio.volume + delta))
                                                    // console.log("Setting mic volume to:", newVol)
                                                    Audio.source.audio.volume = newVol
                                                    
                                                    // Trigger microphone OSD
                                                    Hyprland.dispatch("global quickshell:osdMicrophone:trigger")
                                                } else {
                                                    // console.log("No mic")
                                        }
                                    }
                                        }
                                    }
                                    
                                    // Brightness indicator
                                    MaterialSymbol {
                                        Layout.rightMargin: 4
                                        text: "light_mode"
                                        iconSize: indicatorIconSize
                                        color: rightSidebarButton.colText
                                        
                                        layer.enabled: true
                                        layer.smooth: true
                                        
                                        layer.effect: DropShadow {
                                            horizontalOffset: 0
                                            verticalOffset: 2
                                            radius: 4.0
                                            samples: 9
                                            color: Qt.rgba(0, 0, 0, 0.3)
                                        }
                                        
                                        MouseArea {
                                            anchors.fill: parent
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                                            onClicked: (mouse) => {
                                                if (mouse.button === Qt.LeftButton) {
                                                    // Left-click toggles brightness OSD
                                                    safeDispatch('global quickshell:osdBrightness:toggle')
                                                } else if (mouse.button === Qt.RightButton) {
                                                    // Right-click opens brightness settings or sidebar
                                                    safeDispatch('global quickshell:sidebarRightOpen')
                                                }
                                            }
                                            
                                            onWheel: function(wheel) {
                                                // console.log("Brightness scroll detected:", wheel.angleDelta.y)
                                                if (barRoot.brightnessMonitor?.ready) {
                                                    var currentBrightness = barRoot.brightnessMonitor.brightness;
                                                    // console.log("Current brightness before change:", currentBrightness)
                                                    
                                                    var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05  // 5% steps
                                                    var newBrightness = Math.max(0.01, Math.min(1, currentBrightness + delta))
                                                    
                                                    // console.log("Calculated new brightness:", newBrightness)
                                                    // console.log("Setting brightness to:", newBrightness)
                                                    
                                                    barRoot.brightnessMonitor.setBrightness(newBrightness)
                                                    
                                                    // Trigger brightness OSD
                                                    safeDispatch('global quickshell:osdBrightness:trigger')
                                                    
                                                    // Check if it actually changed
                                                    Qt.callLater(() => {
                                                        // console.log("Brightness after setting:", barRoot.brightnessMonitor.brightness)
                                                    })
                                                } else {
                                                    // console.log("No brightness monitor available")
                                                }
                                            }
                                        }
                                    }
                                    
                                    MaterialSymbol {
                                        Layout.rightMargin: indicatorsRowLayout.realSpacing
                                        text: Network.materialSymbol
                                        iconSize: indicatorIconSize
                                        color: rightSidebarButton.colText
                                        
                                        layer.enabled: true
                                        layer.smooth: true
                                        
                                        layer.effect: DropShadow {
                                            horizontalOffset: 0
                                            verticalOffset: 2
                                            radius: 4.0
                                            samples: 9
                                            color: Qt.rgba(0, 0, 0, 0.3)
                                        }
                                    }
                                    MaterialSymbol {
                                        text: Bluetooth.bluetoothConnected ? "bluetooth_connected" : Bluetooth.bluetoothEnabled ? "bluetooth" : "bluetooth_disabled"
                                        iconSize: indicatorIconSize
                                        color: rightSidebarButton.colText
                                        
                                        layer.enabled: true
                                        layer.smooth: true
                                        
                                        layer.effect: DropShadow {
                                            horizontalOffset: 0
                                            verticalOffset: 2
                                            radius: 4.0
                                            samples: 9
                                            color: Qt.rgba(0, 0, 0, 0.3)
                                        }
                                    }

                                }
                            }

                            ClockWidget {
                                Layout.alignment: Qt.AlignCenter | Qt.AlignVCenter
                            }

                            Item { width: 12 }

                            Item {
                                width: 120 // Reserve more space for weather
                                height: 40 // Ensure proper height
                                Layout.alignment: Qt.AlignCenter | Qt.AlignVCenter
                                visible: ConfigOptions.bar?.weather?.enable ?? false
                                BarComponents.Weather {
                                    anchors.centerIn: parent
                                    weatherLocation: "Halifax"
                                }
                            }

                            Item { width: 12 }

                            SysTray {
                                bar: barRoot
                                visible: barRoot.useShortenedForm === 0
                                Layout.fillWidth: false
                                Layout.fillHeight: true
                                Layout.alignment: Qt.AlignCenter | Qt.AlignVCenter
                            }
                        }
                    }
                }
            }
        }
    }

    // Audio Control Popup - standalone component



}
