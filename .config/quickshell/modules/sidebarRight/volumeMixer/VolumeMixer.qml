import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/sidebarRight/quickToggles"
import "root:/services"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Pipewire


Item {
    id: root
    property bool showDeviceSelector: false
    property bool deviceSelectorInput
    property int dialogMargins: 16
    property PwNode selectedDevice

    function showDeviceSelectorDialog(input) {
        root.selectedDevice = null
        root.showDeviceSelector = true
        root.deviceSelectorInput = input
    }

    Keys.onPressed: (event) => {
        // Close dialog on pressing Esc if open
        if (event.key === Qt.Key_Escape && root.showDeviceSelector) {
            root.showDeviceSelector = false
            event.accepted = true;
        }
    }

    // Track audio objects
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8
        
        // Main Audio Controls Section
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            radius: Appearance.rounding.large
            color: Qt.rgba(
                Appearance.colors.colLayer1.r,
                Appearance.colors.colLayer1.g,
                Appearance.colors.colLayer1.b,
                0.3
            )
            border.color: Qt.rgba(1, 1, 1, 0.1)
            border.width: 1
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12
                
                // Output Control
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        
                        MaterialSymbol {
                            text: "speaker"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                        }
                        
                        StyledText {
                            text: qsTr("Output")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        // Device selector button for output
                        Rectangle {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            radius: 10
                            color: outputCogMouseArea.containsMouse ? 
                                   Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, 0.1) : 
                                   "transparent"
                            
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "settings"
                                iconSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer1
                                opacity: 0.7
                            }
                            
                            MouseArea {
                                id: outputCogMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.showDeviceSelectorDialog(false) // false = output device
                                }
                            }
                        }
                        
                        StyledText {
                            text: Math.round((Pipewire.defaultAudioSink?.audio.volume ?? 0) * 100) + "%"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer1
                            opacity: 0.7
                        }
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        
                        StyledSlider {
                            Layout.fillWidth: true
                            from: 0
                            to: 1.0
                            value: Pipewire.defaultAudioSink?.audio.volume ?? 0
                            enabled: !(Pipewire.defaultAudioSink?.audio.muted ?? false)
                            opacity: (Pipewire.defaultAudioSink?.audio.muted ?? false) ? 0.5 : 1.0
                            onValueChanged: {
                                if (Pipewire.defaultAudioSink?.audio) {
                                    Pipewire.defaultAudioSink.audio.volume = value
                                }
                            }
                        }
                        
                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 16
                            color: (Pipewire.defaultAudioSink?.audio.muted ?? false) ? 
                                   "#e74c3c" : 
                                   Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, 0.1)
                            border.color: Qt.rgba(1, 1, 1, 0.15)
                            border.width: 1
                            
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: (Pipewire.defaultAudioSink?.audio.muted ?? false) ? "volume_off" : "volume_up"
                                iconSize: Appearance.font.pixelSize.small
                                color: (Pipewire.defaultAudioSink?.audio.muted ?? false) ? 
                                       "white" : 
                                       Appearance.colors.colOnLayer1
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (Pipewire.defaultAudioSink?.audio) {
                                        Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Separator
                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: Qt.rgba(1, 1, 1, 0.08)
                }
                
                // Input Control
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        
                        MaterialSymbol {
                            text: "mic"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                        }
                        
                        StyledText {
                            text: qsTr("Input")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        // Device selector button for input
                        Rectangle {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            radius: 10
                            color: inputCogMouseArea.containsMouse ? 
                                   Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, 0.1) : 
                                   "transparent"
                            
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "settings"
                                iconSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer1
                                opacity: 0.7
                            }
                            
                            MouseArea {
                                id: inputCogMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.showDeviceSelectorDialog(true) // true = input device
                                }
                            }
                        }
                        
                        StyledText {
                            text: Math.round((Pipewire.defaultAudioSource?.audio?.volume ?? 0) * 100) + "%"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer1
                            opacity: 0.7
                        }
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        
                        StyledSlider {
                            Layout.fillWidth: true
                            from: 0
                            to: 1.0
                            value: Pipewire.defaultAudioSource?.audio?.volume ?? 0
                            enabled: !(Pipewire.defaultAudioSource?.audio?.muted ?? false)
                            opacity: (Pipewire.defaultAudioSource?.audio?.muted ?? false) ? 0.5 : 1.0
                            onValueChanged: {
                                if (Pipewire.defaultAudioSource?.audio) {
                                    Pipewire.defaultAudioSource.audio.volume = value
                                }
                            }
                        }
                        
                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 16
                            color: (Pipewire.defaultAudioSource?.audio?.muted ?? false) ? 
                                   "#e74c3c" : 
                                   Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, 0.1)
                            border.color: Qt.rgba(1, 1, 1, 0.15)
                            border.width: 1
                            
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: (Pipewire.defaultAudioSource?.audio?.muted ?? false) ? "mic_off" : "mic"
                                iconSize: Appearance.font.pixelSize.small
                                color: (Pipewire.defaultAudioSource?.audio?.muted ?? false) ? 
                                       "white" : 
                                       Appearance.colors.colOnLayer1
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (Pipewire.defaultAudioSource?.audio) {
                                        Pipewire.defaultAudioSource.audio.muted = !Pipewire.defaultAudioSource.audio.muted
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Application Volume Mixer Section
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Appearance.rounding.large
            color: Qt.rgba(
                Appearance.colors.colLayer1.r,
                Appearance.colors.colLayer1.g,
                Appearance.colors.colLayer1.b,
                0.3
            )
            border.color: Qt.rgba(1, 1, 1, 0.1)
            border.width: 1
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6
                
                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    
                    MaterialSymbol {
                        text: "tune"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                    }
                    
                    StyledText {
                        text: qsTr("Application Volume")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    
                    Item { Layout.fillWidth: true }
                }
                
                // Scrollable content
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    Flickable {
                        id: flickable
                        anchors.fill: parent
                        contentHeight: volumeMixerColumnLayout.height
                        clip: true
                        
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: flickable.width
                                height: flickable.height
                                radius: Appearance.rounding.large
                            }
                        }

                        ColumnLayout {
                            id: volumeMixerColumnLayout
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 6
                            spacing: 6

                            // Get a list of nodes that output to the default sink
                            PwNodeLinkTracker {
                                id: linkTracker
                                node: Pipewire.defaultAudioSink
                            }

                            Repeater {
                                model: linkTracker.linkGroups

                                VolumeMixerEntry {
                                    Layout.fillWidth: true
                                    // Get links to the default sink
                                    required property PwLinkGroup modelData
                                    // Consider sources that output to the default sink
                                    node: modelData.source
                                    opacity: 0
                                    visible: opacity > 0

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: Appearance.animation.elementMoveFast.duration
                                            easing.type: Appearance.animation.elementMoveFast.type
                                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                                        }
                                    }

                                    Component.onCompleted: {
                                        opacity = 1
                                    }
                                }
                            }
                        }
                    }

                    // Placeholder when list is empty
                    Item {
                        anchors.fill: flickable
                        visible: opacity > 0
                        opacity: linkTracker.linkGroups.length === 0 ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Appearance.animation.elementMoveFast.duration
                                easing.type: Appearance.animation.elementMoveFast.type
                                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 10

                            MaterialSymbol {
                                Layout.alignment: Qt.AlignHCenter
                                text: "volume_up"
                                iconSize: 48
                                color: Appearance.colors.colOnLayer1
                                opacity: 0.3
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: qsTr("No audio applications")
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                                opacity: 0.6
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: qsTr("Start playing audio to see volume controls")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer1
                                opacity: 0.4
                            }
                        }
                    }
                }
            }
        }
    }

    // Device selector dialog
    Item {
        anchors.fill: parent
        z: 9999

        visible: opacity > 0
        opacity: root.showDeviceSelector ? 1 : 0
        Behavior on opacity {
            NumberAnimation { 
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
            }
        }

        Rectangle { // Scrim
            id: scrimOverlay
            anchors.fill: parent
            radius: Appearance.rounding.small
            color: Appearance.colors.colScrim
            MouseArea {
                hoverEnabled: true
                anchors.fill: parent
                preventStealing: true
                propagateComposedEvents: false
            }
        }

        Rectangle { // The dialog
            id: dialog
            color: Appearance.m3colors.m3surfaceContainerHigh
            radius: Appearance.rounding.large
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 30
            implicitHeight: dialogColumnLayout.implicitHeight
            
            transform: Scale {
                origin.x: dialog.width / 2
                origin.y: dialog.height / 2
                xScale: root.showDeviceSelector ? 1 : 0.9
                yScale: xScale

                Behavior on xScale {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }
            }
            
            ColumnLayout {
                id: dialogColumnLayout
                anchors.fill: parent
                spacing: 16

                StyledText {
                    id: dialogTitle
                    Layout.topMargin: dialogMargins
                    Layout.leftMargin: dialogMargins
                    Layout.rightMargin: dialogMargins
                    Layout.alignment: Qt.AlignLeft
                    color: Appearance.m3colors.m3onSurface
                    font.pixelSize: Appearance.font.pixelSize.larger
                    text: `Select ${root.deviceSelectorInput ? "input" : "output"} device`
                }

                Rectangle {
                    color: Appearance.m3colors.m3outline
                    implicitHeight: 1
                    Layout.fillWidth: true
                    Layout.leftMargin: dialogMargins
                    Layout.rightMargin: dialogMargins
                }

                Flickable {
                    id: dialogFlickable
                    Layout.fillWidth: true
                    clip: true
                    implicitHeight: Math.min(scrimOverlay.height - dialogMargins * 8 - dialogTitle.height - dialogButtonsRowLayout.height, devicesColumnLayout.implicitHeight)
                    
                    contentHeight: devicesColumnLayout.implicitHeight

                    ColumnLayout {
                        id: devicesColumnLayout
                        anchors.fill: parent
                        Layout.fillWidth: true
                        spacing: 0

                        Repeater {
                            model: Pipewire.nodes.values.filter(node => {
                                return !node.isStream && node.isSink !== root.deviceSelectorInput && node.audio
                            })

                            // This could and should be refractored, but all data becomes null when passed wtf
                            delegate: RadioButton {
                                id: radioButton
                                Layout.leftMargin: root.dialogMargins
                                Layout.rightMargin: root.dialogMargins
                                Layout.fillWidth: true
                                implicitHeight: 40
                                checked: modelData.id === Pipewire.defaultAudioSink?.id
                                opacity: 0
                                visible: opacity > 0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Appearance.animation.elementMoveFast.duration
                                        easing.type: Appearance.animation.elementMoveFast.type
                                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                                    }
                                }

                                Component.onCompleted: {
                                    opacity = 1
                                }

                                Connections {
                                    target: root
                                    function onShowDeviceSelectorChanged() {
                                        if(!root.showDeviceSelector) return;
                                        radioButton.checked = (modelData.id === Pipewire.defaultAudioSink?.id)
                                    }
                                }

                                PointingHandInteraction {}

                                onCheckedChanged: {
                                    if (checked) {
                                        root.selectedDevice = modelData
                                    }
                                }

                                indicator: Item{}
                                
                                contentItem: RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Rectangle {
                                        id: radio
                                        Layout.fillWidth: false
                                        Layout.alignment: Qt.AlignVCenter
                                        width: 20
                                        height: 20
                                        radius: Appearance.rounding.full
                                        border.color: checked ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurfaceVariant
                                        border.width: 2
                                        color: "transparent"

                                        // Checked indicator
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: checked ? 10 : 4
                                            height: checked ? 10 : 4
                                            radius: Appearance.rounding.full
                                            color: Appearance.m3colors.m3primary
                                            opacity: checked ? 1 : 0

                                            Behavior on opacity {
                                                NumberAnimation {
                                                    duration: Appearance.animation.elementMoveFast.duration
                                                    easing.type: Appearance.animation.elementMoveFast.type
                                                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                                                }
                                            }
                                            Behavior on width {
                                                NumberAnimation {
                                                    duration: Appearance.animation.elementMoveFast.duration
                                                    easing.type: Appearance.animation.elementMoveFast.type
                                                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                                                }
                                            }
                                            Behavior on height {
                                                NumberAnimation {
                                                    duration: Appearance.animation.elementMoveFast.duration
                                                    easing.type: Appearance.animation.elementMoveFast.type
                                                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                                                }
                                            }

                                        }

                                        // Hover
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: radioButton.hovered ? 40 : 20
                                            height: radioButton.hovered ? 40 : 20
                                            radius: Appearance.rounding.full
                                            color: Appearance.m3colors.m3onSurface
                                            opacity: radioButton.hovered ? 0.1 : 0

                                            Behavior on opacity {
                                                NumberAnimation {
                                                    duration: Appearance.animation.elementMoveFast.duration
                                                    easing.type: Appearance.animation.elementMoveFast.type
                                                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                                                }
                                            }
                                            Behavior on width {
                                                NumberAnimation {
                                                    duration: Appearance.animation.elementMoveFast.duration
                                                    easing.type: Appearance.animation.elementMoveFast.type
                                                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                                                }
                                            }
                                            Behavior on height {
                                                NumberAnimation {
                                                    duration: Appearance.animation.elementMoveFast.duration
                                                    easing.type: Appearance.animation.elementMoveFast.type
                                                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                                                }
                                            }
                                        }
                                    }
                                    StyledText {
                                        text: modelData.description
                                        Layout.alignment: Qt.AlignVCenter
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                        color: Appearance.m3colors.m3onSurface
                                    }
                                }
                            }
                        }
                        Item {
                            implicitHeight: dialogMargins
                        }
                    }
                }

                Rectangle {
                    color: Appearance.m3colors.m3outline
                    implicitHeight: 1
                    Layout.fillWidth: true
                    Layout.leftMargin: dialogMargins
                    Layout.rightMargin: dialogMargins
                }

                RowLayout {
                    id: dialogButtonsRowLayout
                    Layout.bottomMargin: dialogMargins
                    Layout.leftMargin: dialogMargins
                    Layout.rightMargin: dialogMargins
                    Layout.alignment: Qt.AlignRight

                    DialogButton {
                        buttonText: qsTr("Cancel")
                        onClicked: {
                            root.showDeviceSelector = false
                        }
                    }
                    DialogButton {
                        buttonText: qsTr("OK")
                        onClicked: {
                            root.showDeviceSelector = false
                            if (root.selectedDevice) {
                                if (root.deviceSelectorInput) {
                                    Pipewire.preferredDefaultAudioSource = root.selectedDevice
                                } else {
                                    Pipewire.preferredDefaultAudioSink = root.selectedDevice
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}