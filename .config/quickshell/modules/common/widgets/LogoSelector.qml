import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services/"

Rectangle {
    id: logoSelector
    width: parent.width
    height: parent.height
    radius: 12
    color: "#2a2a2a"
    border.width: 1
    border.color: "#404040"
    
    property string selectedLogo: ConfigOptions.appearance.logo || "distro-nobara-symbolic.svg"
    
    property var iconModel: [
        // Distribution logos
        "distro-nobara-symbolic.svg",
        "distro-arch-symbolic.svg",
        "distro-cachyos-symbolic.svg",
        "distro-debian-symbolic.svg",
        "distro-endeavour-symbolic.svg",
        "distro-fedora-symbolic.svg",
        "distro-gentoo-symbolic.svg",
        "distro-kali-linux-symbolic.svg",
        "distro-manjaro-symbolic.svg",
        "distro-mx-symbolic.svg",
        "distro-nixos-symbolic.svg",
        "distro-opensuse-symbolic.svg",
        "distro-oreon-symbolic.svg",
        "distro-pardus-symbolic.svg",
        "distro-pop-os-symbolic.svg",
        "distro-pureos-symbolic.svg",
        "distro-raspbian-symbolic.svg",
        "distro-redhat-symbolic.svg",
        "distro-solus-symbolic.svg",
        "distro-ubuntu-symbolic.svg",
        "distro-voyager-symbolic.svg",
        "distro-zorin-symbolic.svg",
        "distro-budgie-symbolic.svg",
        "distro-gnome-symbolic.svg",
        // App launcher icons
        "icon-app-launcher-symbolic.svg",
        "icon-apps-symbolic.svg",
        "icon-launcher-symbolic.svg",
        "icon-arcmenu-logo-symbolic.svg",
        "icon-arcmenu-logo-alt-symbolic.svg",
        "icon-arcmenu-old-symbolic.svg",
        "icon-arcmenu-old-alt-symbolic.svg",
        "icon-arcmenu-oldest-symbolic.svg",
        // Menu styles
        "menustyle-modern-symbolic.svg",
        "menustyle-traditional-symbolic.svg",
        "menustyle-touch-symbolic.svg",
        "menustyle-launcher-symbolic.svg",
        "menustyle-alternative-symbolic.svg",
        // Gaming icons
        "icon-dota-symbolic.svg",
        "icon-dragon-symbolic.svg",
        "icon-dragonheart-symbolic.svg",
        "icon-football-symbolic.svg",
        "icon-football2-symbolic.svg",
        "icon-helmet-symbolic.svg",
        "icon-pacman-symbolic.svg",
        "icon-pac-symbolic.svg",
        // Creative icons
        "icon-paint-palette-symbolic.svg",
        "icon-3d-symbolic.svg",
        "icon-dolphin-symbolic.svg",
        "icon-eclipse-symbolic.svg",
        "icon-record-symbolic.svg",
        "icon-rewind-symbolic.svg",
        "icon-time-symbolic.svg",
        // Abstract icons
        "icon-a-symbolic.svg",
        "icon-alien-symbolic.svg",
        "icon-arrow-symbolic.svg",
        "icon-bat-symbolic.svg",
        "icon-bug-symbolic.svg",
        "icon-cloud-symbolic.svg",
        "icon-curved-a-symbolic.svg",
        "icon-diamond-square-symbolic.svg",
        "icon-dimond-win-symbolic.svg",
        "icon-dra-symbolic.svg",
        "icon-equal-symbolic.svg",
        "icon-fly-symbolic.svg",
        "icon-focus-symbolic.svg",
        "icon-gnacs-symbolic.svg",
        "icon-groove-symbolic.svg",
        "icon-heddy-symbolic.svg",
        "icon-kaaet-symbolic.svg",
        "icon-lins-symbolic.svg",
        "icon-loveheart-symbolic.svg",
        "icon-octo-maze-symbolic.svg",
        "icon-peaks-symbolic.svg",
        "icon-peeks-symbolic.svg",
        "icon-pie-symbolic.svg",
        "icon-pointer-symbolic.svg",
        "icon-pyrimid-symbolic.svg",
        "icon-robots-symbolic.svg",
        "icon-round-symbolic.svg",
        "icon-saucer-symbolic.svg",
        "icon-search-glass-symbolic.svg",
        "icon-sheild-symbolic.svg",
        "icon-snap-symbolic.svg",
        "icon-somnia-symbolic.svg",
        "icon-start-box-symbolic.svg",
        "icon-step-symbolic.svg",
        "icon-sums-symbolic.svg",
        "icon-swirl-symbolic.svg",
        "icon-toxic-symbolic.svg",
        "icon-toxic2-symbolic.svg",
        "icon-transform-symbolic.svg",
        "icon-tree-symbolic.svg",
        "icon-triple-dash-symbolic.svg",
        "icon-utool-symbolic.svg",
        "icon-vancer-symbolic.svg",
        "icon-vibe-symbolic.svg",
        "icon-whirl-circle-symbolic.svg",
        "icon-whirl-symbolic.svg",
        "icon-zegon-symbolic.svg",
        "icon-cita-symbolic.svg"
    ]
    
    signal logoSelected(string logoName)
    
    // Fixed header at the top
    RowLayout {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        spacing: 12
        
        Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: 8
            color: "#4a4a4a"
            
            Text {
                anchors.centerIn: parent
                text: "🖼️"
                font.pixelSize: 18
                color: "#ffffff"
            }
        }
        
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            
            Text {
                text: "Logo Selection"
                font.pixelSize: 18
                font.weight: Font.Bold
                color: "#ffffff"
            }
            
            Text {
                text: "Choose your system logo from available icons"
                font.pixelSize: 12
                color: "#cccccc"
            }
        }
    }
    
    // Scrollable content area
    ScrollView {
        id: gridView
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 16
        anchors.margins: 16
        clip: true
        
        GridLayout {
            width: gridView.width
            columns: Math.floor(gridView.width / 100)
            rowSpacing: 12
            columnSpacing: 12
            
            Repeater {
                model: iconModel
                
                delegate: Rectangle {
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 100
                    radius: 8
                    color: selectedLogo === modelData ? "#4a4a4a" : "#3a3a3a"
                    border.width: selectedLogo === modelData ? 2 : 1
                    border.color: selectedLogo === modelData ? "#ffffff" : "#505050"
                    clip: true
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onEntered: {
                            if (selectedLogo !== modelData) {
                                parent.color = "#454545"
                            }
                        }
                        
                        onExited: {
                            if (selectedLogo !== modelData) {
                                parent.color = "#3a3a3a"
                            }
                        }
                        
                        onClicked: {
                            selectedLogo = modelData
                            logoSelected(modelData)
                        }
                    }
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6
                        
                        Image {
                            Layout.preferredWidth: 50
                            Layout.preferredHeight: 50
                            Layout.alignment: Qt.AlignHCenter
                            source: "root:/assets/icons/" + modelData
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                            clip: true
                        }
                        
                        Text {
                            text: modelData.replace(/\.(svg|png|jpg|jpeg|gif)$/i, '').replace(/[-_]/g, ' ')
                            font.pixelSize: 11
                            color: selectedLogo === modelData ? "#ffffff" : "#cccccc"
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                            elide: Text.ElideMiddle
                        }
                    }
                    
                    // Selection indicator
                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 6
                        width: 18
                        height: 18
                        radius: 8
                        color: selectedLogo === modelData ? "#ffffff" : "transparent"
                        border.width: selectedLogo === modelData ? 0 : 1
                        border.color: "#505050"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "✓"
                            font.pixelSize: 11
                            color: selectedLogo === modelData ? "#000000" : "transparent"
                        }
                    }
                }
            }
        }
    }
} 