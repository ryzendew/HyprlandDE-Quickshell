import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.UPower
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils

ColumnLayout {
    anchors.fill: parent
    spacing: 0
    Layout.margins: 0
    Layout.fillHeight: false

    // Header with outline, flush to the top (no radius)
    Rectangle {
        Layout.fillWidth: true
        height: 48
        color: Qt.rgba(
            Appearance.colors.colLayer2.r,
            Appearance.colors.colLayer2.g,
            Appearance.colors.colLayer2.b,
            0.55
        )
        border.color: Appearance.colors.colOnLayer0
        border.width: 1
        RowLayout {
            anchors.fill: parent
            anchors.margins: 0
            StyledText {
                Layout.fillWidth: true
                text: qsTr("Power Profile")
                font.pixelSize: Appearance.font.pixelSize.large
                font.bold: true
                color: Appearance.colors.colOnLayer1
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    // Button stack in a ColumnLayout, aligned to top, no gap
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: false
        Layout.alignment: Qt.AlignTop
        spacing: 4

        // Performance Mode
        Rectangle {
            Layout.fillWidth: true
            height: 54
            color: PowerProfiles.profile === PowerProfile.Performance ? Appearance.m3colors.m3primary : Appearance.colors.colLayer1
            border.color: Appearance.colors.colOnLayer0
            border.width: 1
            radius: Appearance.rounding.medium
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                spacing: 12
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Item { Layout.fillWidth: true }
                MaterialSymbol {
                    iconSize: 28
                    fill: PowerProfiles.profile === PowerProfile.Performance ? 1 : 0
                    text: "speed"
                    color: PowerProfiles.profile === PowerProfile.Performance ? "#FFFFFF" : "#FFFFFF"
                }
                StyledText {
                    text: qsTr("Performance")
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.bold: true
                    color: PowerProfiles.profile === PowerProfile.Performance ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer0
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                Item { Layout.fillWidth: true }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    PowerProfiles.profile = PowerProfile.Performance
                    console.log("Performance button clicked")
                }
            }
        }

        // Balanced Mode
        Rectangle {
            Layout.fillWidth: true
            height: 54
            color: PowerProfiles.profile === PowerProfile.Balanced ? Appearance.m3colors.m3primary : Appearance.colors.colLayer1
            border.color: Appearance.colors.colOnLayer0
            border.width: 1
            radius: Appearance.rounding.medium
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                spacing: 12
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Item { Layout.fillWidth: true }
                MaterialSymbol {
                    iconSize: 28
                    fill: PowerProfiles.profile === PowerProfile.Balanced ? 1 : 0
                    text: "balance"
                    color: PowerProfiles.profile === PowerProfile.Balanced ? "#FFFFFF" : "#FFFFFF"
                }
                StyledText {
                    text: qsTr("Balanced")
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.bold: true
                    color: PowerProfiles.profile === PowerProfile.Balanced ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer0
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                Item { Layout.fillWidth: true }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    PowerProfiles.profile = PowerProfile.Balanced
                    console.log("Balanced button clicked")
                }
            }
        }

        // Power Saver Mode
        Rectangle {
            Layout.fillWidth: true
            height: 54
            color: PowerProfiles.profile === PowerProfile.PowerSaver ? Appearance.m3colors.m3primary : Appearance.colors.colLayer1
            border.color: Appearance.colors.colOnLayer0
            border.width: 1
            radius: Appearance.rounding.medium
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                spacing: 12
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Item { Layout.fillWidth: true }
                MaterialSymbol {
                    iconSize: 28
                    fill: PowerProfiles.profile === PowerProfile.PowerSaver ? 1 : 0
                    text: "battery_saver"
                    color: PowerProfiles.profile === PowerProfile.PowerSaver ? "#FFFFFF" : "#FFFFFF"
                }
                StyledText {
                    text: qsTr("Power Saver")
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.bold: true
                    color: PowerProfiles.profile === PowerProfile.PowerSaver ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer0
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                Item { Layout.fillWidth: true }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    PowerProfiles.profile = PowerProfile.PowerSaver
                    console.log("Power Saver button clicked")
                }
            }
        }
    }
} 