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

    readonly property int barHeight: Appearance.sizes.barHeight
    readonly property int barCenterSideModuleWidth: Appearance.sizes.barCenterSideModuleWidth
    readonly property int osdHideMouseMoveThreshold: 20
    property bool showBarBackground: ConfigOptions.bar.showBackground
    property bool hyprlandAvailable: true

    // Helper function to safely dispatch Hyprland commands
    function safeDispatch(command) {
        if (!hyprlandAvailable) return;
        
        try {
            Hyprland.dispatch(command);
        } catch (e) {
            // Only warn if logging is enabled and Hyprland warnings are not suppressed
            if (ConfigOptions?.logging?.enabled && ConfigOptions?.logging?.warning && !ConfigOptions?.logging?.suppressHyprlandWarnings) {
                console.warn("Hyprland dispatch failed in Bar.qml:", command, e);
            }
            if (command.includes("setvar") && command.includes("decoration:blur")) {
                hyprlandAvailable = false;
                if (ConfigOptions?.logging?.enabled && ConfigOptions?.logging?.warning && !ConfigOptions?.logging?.suppressHyprlandWarnings) {
                    console.warn("Hyprland blur features disabled in Bar.qml due to errors");
                }
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
        // Check if Hyprland is available
        try {
            Hyprland.dispatch("keyword monitor,desc:dummy,disabled");
            if (ConfigOptions?.logging?.enabled && ConfigOptions?.logging?.info) {
                console.log("Hyprland integration available in Bar.qml");
            }
        } catch (e) {
            if (ConfigOptions?.logging?.enabled && ConfigOptions?.logging?.warning && !ConfigOptions?.logging?.suppressHyprlandWarnings) {
                console.warn("Hyprland integration not available in Bar.qml:", e);
            }
            hyprlandAvailable = false;
        }
        
        if (hyprlandAvailable) {
            AppearanceSettingsState.updateBarBlurSettings()
        }
    }

    component VerticalBarSeparator: Rectangle {
        Layout.topMargin: barHeight / 3
        Layout.bottomMargin: barHeight / 3
        Layout.fillHeight: true
        implicitWidth: 1
        color: Appearance.m3colors.m3outlineVariant
    }

    Variants {
        model: Quickshell.screens.filter(screen => screen.name === "DP-1")

        PanelWindow {
            id: barRoot

            property ShellScreen modelData
            property var brightnessMonitor: Brightness.getMonitorForScreen(modelData)
            property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen.width) ? 2 :
                (Appearance.sizes.barShortenScreenWidthThreshold >= screen.width) ? 1 : 0
            readonly property int centerSideModuleWidth: 
                (useShortenedForm == 2) ? Appearance.sizes.barCenterSideModuleWidthHellaShortened :
                (useShortenedForm == 1) ? Appearance.sizes.barCenterSideModuleWidthShortened : 
                    Appearance.sizes.barCenterSideModuleWidth

            screen: modelData
            implicitHeight: barHeight
            exclusiveZone: showBarBackground ? barHeight : (barHeight -4)
            mask: Region {
                item: barContent
            }
            color: "transparent"
            WlrLayershell.namespace: "quickshell:bar:blur"

            anchors {
                top: true
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
                color: showBarBackground ? Qt.rgba(
                    Appearance.colors.colLayer0.r,
                    Appearance.colors.colLayer0.g,
                    Appearance.colors.colLayer0.b,
                    0.55
                ) : "transparent"
                    
                Behavior on color {
                    ColorAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                    }
                }

                // Bottom border
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 3
                    color: "black"
                    opacity: 0.9
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
                            spacing: 10

                            Rectangle {
                                id: archLogoContainer
                                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                Layout.leftMargin: 2
                                Layout.fillWidth: false
                                
                                radius: Appearance.rounding.full
                                color: archMouseArea.containsMouse ? 
                                    Qt.rgba(Appearance.colors.colLayer1Active.r, Appearance.colors.colLayer1Active.g, Appearance.colors.colLayer1Active.b, 0.8) : 
                                    "transparent"
                                implicitWidth: archLogo.width + 10
                                implicitHeight: archLogo.height + 10

                                Image {
                                    id: archLogo
                                    anchors.centerIn: parent
                                    width: 22
                                    height: 22
                                    source: "root:/logo/Arch-linux-logo.png"
                                    fillMode: Image.PreserveAspectFit
                                }
                                
                                MouseArea {
                                    id: archMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton
                                    
                                    onClicked: {
                                        GlobalStates.hyprMenuOpen = !GlobalStates.hyprMenuOpen
                                    }
                                    
                                    onPressed: (event) => {
                                        if (event.button === Qt.LeftButton) {
                                            safeDispatch('global quickshell:sidebarLeftOpen')
                                        }
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
                    spacing: 8

                    RowLayout {
                        id: leftCenterGroup
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    RowLayout {
                        id: middleCenterGroup
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Workspaces {
                            bar: barRoot
                            Layout.alignment: Qt.AlignCenter
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
                    }
                }

                MouseArea {
                    id: barRightSideMouseArea
                    anchors.right: parent.right
                    implicitHeight: barHeight
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
                            layoutDirection: Qt.RightToLeft

                            RippleButton { // Right sidebar button (indicators)
                                id: rightSidebarButton
                                Layout.margins: 4
                                Layout.fillHeight: true
                                implicitWidth: indicatorsRowLayout.implicitWidth + 10*2
                                buttonRadius: Appearance.rounding.full
                                colBackground: barRightSideMouseArea.hovered ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
                                colBackgroundHover: Appearance.colors.colLayer1Hover
                                colRipple: Appearance.colors.colLayer1Active
                                colBackgroundToggled: Appearance.m3colors.m3secondaryContainer
                                colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                                colRippleToggled: Appearance.colors.colSecondaryContainerActive
                                toggled: GlobalStates.sidebarRightOpen
                                property color colText: toggled ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer0

                                Behavior on colText {
                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                }

                                onPressed: {
                                    safeDispatch('global quickshell:sidebarRightToggle')
                                }

                                RowLayout {
                                    id: indicatorsRowLayout
                                    anchors.centerIn: parent
                                    property real realSpacing: 15
                                    spacing: 0
                                    
                                    Revealer {
                                        reveal: Audio.sink?.audio?.muted ?? false
                                        Layout.fillHeight: true
                                        Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                                        Behavior on Layout.rightMargin {
                                            NumberAnimation {
                                                duration: Appearance.animation.elementMoveFast.duration
                                                easing.type: Appearance.animation.elementMoveFast.type
                                                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                                            }
                                        }
                                        MaterialSymbol {
                                            text: "volume_off"
                                            iconSize: Appearance.font.pixelSize.larger
                                            color: rightSidebarButton.colText
                                        }
                                    }
                                    Revealer {
                                        reveal: Audio.source?.audio?.muted ?? false
                                        Layout.fillHeight: true
                                        Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                                        Behavior on Layout.rightMargin {
                                            NumberAnimation {
                                                duration: Appearance.animation.elementMoveFast.duration
                                                easing.type: Appearance.animation.elementMoveFast.type
                                                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                                            }
                                        }
                                        MaterialSymbol {
                                            text: "mic_off"
                                            iconSize: Appearance.font.pixelSize.larger
                                            color: rightSidebarButton.colText
                                        }
                                    }
                                    MaterialSymbol {
                                        Layout.rightMargin: indicatorsRowLayout.realSpacing
                                        text: Network.materialSymbol
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: rightSidebarButton.colText
                                    }
                                    MaterialSymbol {
                                        text: Bluetooth.bluetoothConnected ? "bluetooth_connected" : Bluetooth.bluetoothEnabled ? "bluetooth" : "bluetooth_disabled"
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: rightSidebarButton.colText
                                    }
                                }
                            }

                            Item { width: 4 }

                            ClockWidget {}

                            Item { width: 4 }

                            Item {
                                width: 100 // Reserve more space for weather
                                BarComponents.Weather {
                                    anchors.centerIn: parent
                                    weatherLocation: "Halifax, Nova Scotia, Canada"
                                }
                            }

                            Item { width: 4 }

                            SysTray {
                                bar: barRoot
                                visible: barRoot.useShortenedForm === 0
                                Layout.fillWidth: false
                                Layout.fillHeight: true
                            }
                        }
                    }
                }
            }
        }
    }
}
