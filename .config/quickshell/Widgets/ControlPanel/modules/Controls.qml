import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/Data" as Data
import "." as Modules

// Dual-section control panel
Row {
    id: root
    spacing: 16
    visible: true
    height: 80

    required property bool isRecording
    required property var shell
    signal performanceActionRequested(string action)
    signal systemActionRequested(string action)
    signal mouseChanged(bool containsMouse)

    // Combined hover state from both sections
    property bool containsMouse: performanceSection.containsMouse || systemSection.containsMouse
    onContainsMouseChanged: mouseChanged(containsMouse)

    // Performance controls section (left half)
    Rectangle {
        id: performanceSection
        width: (parent.width - parent.spacing) / 2
        height: parent.height
        radius: 20
        color: Qt.darker(Data.Colors.bgColor, 1.15)
        visible: true

        // Hover tracking with coordination between background and content
        property bool containsMouse: performanceMouseArea.containsMouse || performanceControls.containsMouse

        MouseArea {
            id: performanceMouseArea
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            onContainsMouseChanged: {
                if (containsMouse) {
                    performanceSection.containsMouse = true
                } else if (!performanceControls.containsMouse) {
                    performanceSection.containsMouse = false
                }
            }
        }

        Modules.PerformanceControls {
            id: performanceControls
            anchors.fill: parent
            anchors.margins: 12
            shell: root.shell
            onPerformanceActionRequested: function(action) { root.performanceActionRequested(action) }
            onMouseChanged: function(containsMouse) {
                if (containsMouse) {
                    performanceSection.containsMouse = true
                } else if (!performanceMouseArea.containsMouse) {
                    performanceSection.containsMouse = false
                }
            }
        }
    }

    // System controls section (right half)
    Rectangle {
        id: systemSection
        width: (parent.width - parent.spacing) / 2
        height: parent.height
        radius: 20
        color: Qt.darker(Data.Colors.bgColor, 1.15)
        visible: true

        // Hover tracking with coordination between background and content
        property bool containsMouse: systemMouseArea.containsMouse || systemControls.containsMouse

        MouseArea {
            id: systemMouseArea
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            onContainsMouseChanged: {
                if (containsMouse) {
                    systemSection.containsMouse = true
                } else if (!systemControls.containsMouse) {
                    systemSection.containsMouse = false
                }
            }
        }

        Modules.SystemControls {
            id: systemControls
            anchors.fill: parent
            anchors.margins: 12
            shell: root.shell
            onSystemActionRequested: function(action) { root.systemActionRequested(action) }
            onMouseChanged: function(containsMouse) {
                if (containsMouse) {
                    systemSection.containsMouse = true
                } else if (!systemMouseArea.containsMouse) {
                    systemSection.containsMouse = false
                }
            }
        }
    }
} 