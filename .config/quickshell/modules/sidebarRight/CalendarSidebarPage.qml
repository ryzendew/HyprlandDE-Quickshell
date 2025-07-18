import "root:/modules/common"
import "root:/modules/common/widgets"
import "./calendar"
import "./calendar/calendar_layout.js" as CalendarLayout
import "./todo"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root
    
    property int monthShift: 0
    property var viewingDate: CalendarLayout.getDateInXMonthsTime(monthShift)
    property var calendarLayout: CalendarLayout.getCalendarLayout(viewingDate, monthShift === 0)
    
    Keys.onPressed: (event) => {
        if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp)
            && event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageDown) {
                monthShift++;
            } else if (event.key === Qt.Key_PageUp) {
                monthShift--;
            }
            event.accepted = true;
        }
    }
    
    // Remove or comment out the top-level MouseArea
    // MouseArea {
    //     anchors.fill: parent
    //     onWheel: (event) => {
    //         if (event.angleDelta.y > 0) {
    //             monthShift--;
    //         } else if (event.angleDelta.y < 0) {
    //             monthShift++;
    //         }
    //     }
    // }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.max(12, parent.width * 0.02) // Responsive margins
        spacing: Math.max(16, parent.height * 0.02) // Responsive spacing
        
        // Modern Header Card
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(70, parent.height * 0.08) // Responsive height
            radius: Appearance.rounding.large
            
            gradient: Gradient {
                GradientStop { 
                    position: 0.0
                    color: Qt.rgba(
                        Appearance.colors.colLayer1.r,
                        Appearance.colors.colLayer1.g,
                        Appearance.colors.colLayer1.b,
                        0.8
                    )
                }
                GradientStop { 
                    position: 1.0
                    color: Qt.rgba(
                        Appearance.colors.colLayer1.r,
                        Appearance.colors.colLayer1.g,
                        Appearance.colors.colLayer1.b,
                        0.6
                    )
                }
            }
            
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.15)
            
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.1)
                shadowVerticalOffset: 4
                shadowHorizontalOffset: 0
                shadowBlur: 12
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16
                
                // Calendar Icon
                Rectangle {
                    Layout.preferredWidth: Math.max(36, parent.height * 0.45) // Responsive width
                    Layout.preferredHeight: Math.max(36, parent.height * 0.45) // Responsive height
                    radius: Appearance.rounding.medium
                    color: Appearance.m3colors.m3primary
                    
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "calendar_month"
                        iconSize: Math.max(20, parent.height * 0.3) // Responsive icon size
                        color: Appearance.m3colors.m3onPrimary
                        fill: 1
                    }
                }
                
                // Month and Year
                Column {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    StyledText {
                        text: viewingDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                        font.pixelSize: Math.max(Appearance.font.pixelSize.large + 4, parent.height * 0.15) // Responsive font size
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer1
                    }
                    
                    StyledText {
                        text: monthShift === 0 ? qsTr("Current month") : 
                              monthShift > 0 ? qsTr("%1 months ahead").arg(monthShift) :
                              qsTr("%1 months ago").arg(-monthShift)
                        font.pixelSize: Math.max(Appearance.font.pixelSize.small, parent.height * 0.1) // Responsive font size
                        color: Appearance.colors.colOnLayer1
                        opacity: 0.7
                    }
                }
                
                // Navigation Buttons
                RowLayout {
                    spacing: 8
                    
                    // Previous Month
                    Rectangle {
                        Layout.preferredWidth: Math.max(32, parent.height * 0.4) // Responsive width
                        Layout.preferredHeight: Math.max(32, parent.height * 0.4) // Responsive height
                        radius: Appearance.rounding.full
                        color: monthNavPrev.pressed ? Qt.rgba(1, 1, 1, 0.2) : 
                               monthNavPrev.hovered ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                        
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "chevron_left"
                            iconSize: Math.max(18, parent.height * 0.25) // Responsive icon size
                            color: Appearance.colors.colOnLayer1
                        }
                        
                        MouseArea {
                            id: monthNavPrev
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: monthShift--
                        }
                    }
                    
                    // Reset to Current Month
                    Rectangle {
                        Layout.preferredWidth: Math.max(32, parent.height * 0.4) // Responsive width
                        Layout.preferredHeight: Math.max(32, parent.height * 0.4) // Responsive height
                        radius: Appearance.rounding.full
                        color: monthNavReset.pressed ? Qt.rgba(1, 1, 1, 0.2) : 
                               monthNavReset.hovered ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                        visible: monthShift !== 0
                        
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "today"
                            iconSize: Math.max(16, parent.height * 0.22) // Responsive icon size
                            color: Appearance.colors.colOnLayer1
                        }
                        
                        MouseArea {
                            id: monthNavReset
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: monthShift = 0
                        }
                    }
                    
                    // Next Month
                    Rectangle {
                        Layout.preferredWidth: Math.max(32, parent.height * 0.4) // Responsive width
                        Layout.preferredHeight: Math.max(32, parent.height * 0.4) // Responsive height
                        radius: Appearance.rounding.full
                        color: monthNavNext.pressed ? Qt.rgba(1, 1, 1, 0.2) : 
                               monthNavNext.hovered ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                        
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "chevron_right"
                            iconSize: Math.max(18, parent.height * 0.25) // Responsive icon size
                            color: Appearance.colors.colOnLayer1
                        }
                        
                        MouseArea {
                            id: monthNavNext
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: monthShift++
                        }
                    }
                }
            }
        }
        
        // Content area with calendar and todo list
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
                spacing: Math.max(16, parent.height * 0.02) // Responsive spacing
            
            // Calendar Section (top 45%)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: parent.height * 0.45
                radius: Appearance.rounding.large
                color: Qt.rgba(
                    Appearance.colors.colLayer1.r,
                    Appearance.colors.colLayer1.g,
                    Appearance.colors.colLayer1.b,
                    0.4
                )
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.1)
                // Add MouseArea here for month scrolling
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton // Only handle wheel
                    onWheel: (event) => {
                        if (event.angleDelta.y > 0) {
                            monthShift--;
                        } else if (event.angleDelta.y < 0) {
                            monthShift++;
                        }
                    }
                }
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Math.max(16, parent.width * 0.03) // Responsive margins
                spacing: Math.max(12, parent.height * 0.015) // Responsive spacing
                
                // Week Days Header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(35, parent.height * 0.04) // Responsive height
                    radius: Appearance.rounding.medium
                    color: Qt.rgba(
                        Appearance.colors.colLayer2.r,
                        Appearance.colors.colLayer2.g,
                        Appearance.colors.colLayer2.b,
                        0.6
                    )
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 0
                        
                        Repeater {
                            model: CalendarLayout.weekDays
                            delegate: Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                
                                StyledText {
                                    anchors.centerIn: parent
                                    text: modelData.day
                                    font.pixelSize: Math.max(Appearance.font.pixelSize.small, parent.height * 0.3) // Responsive font size
                                    font.weight: Font.DemiBold
                                    color: Appearance.colors.colOnLayer1
                                    opacity: 0.8
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }
                }
                
                // Calendar Days Grid
                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 7
                    rowSpacing: Math.max(3, parent.height * 0.004) // Responsive row spacing
                    columnSpacing: Math.max(3, parent.width * 0.005) // Responsive column spacing
                    
                    Repeater {
                        model: 42 // 6 weeks × 7 days
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: Math.max(28, parent.height * 0.03) // Responsive minimum height
                            
                            property int weekIndex: Math.floor(index / 7)
                            property int dayIndex: index % 7
                            property var dayData: weekIndex < calendarLayout.length ? 
                                                 calendarLayout[weekIndex][dayIndex] : null
                            property bool isToday: dayData ? dayData.today === 1 : false
                            property bool hasDay: dayData && dayData.day !== ""
                            property bool isCurrentMonth: dayData ? dayData.today >= 0 : false
                            property bool isDisabled: hasDay && !isCurrentMonth
                            
                            radius: Appearance.rounding.full
                            
                            color: isToday ? "#E53E3E" :
                                   isDisabled ? Qt.rgba(0, 0, 0, 0.4) :
                                   isCurrentMonth ? (dayMouseArea.pressed ? Qt.rgba(0.8, 0.8, 0.8, 0.9) :
                                                    dayMouseArea.hovered ? Qt.rgba(0.9, 0.9, 0.9, 0.9) :
                                                    "#B0B0B0") :
                                   "transparent"
                            
                            border.width: isToday ? 2 : 0
                            border.color: isToday ? "#FF6B6B" : "transparent"
                            
                            StyledText {
                                anchors.centerIn: parent
                                text: hasDay ? dayData.day : ""
                                font.pixelSize: Math.max(Appearance.font.pixelSize.normal, parent.height * 0.25) // Responsive font size
                                font.weight: isToday ? Font.Bold : Font.Normal
                                color: isToday ? "#FFFFFF" : 
                                       isDisabled ? "#FFFFFF" :
                                       isCurrentMonth ? "#FFFFFF" :
                                       "transparent"
                                opacity: hasDay ? 1.0 : 0.0
                                horizontalAlignment: Text.AlignHCenter
                            }
                            
                            MouseArea {
                                id: dayMouseArea
                                anchors.fill: parent
                                hoverEnabled: hasDay
                                cursorShape: hasDay ? Qt.PointingHandCursor : Qt.ArrowCursor
                                enabled: hasDay
                                
                                onClicked: {
                                    // Future: Add day selection functionality
                                }
                            }
                            
                            // Subtle animation for today indicator
                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }
            }
            }
            
            // Enhanced Todo List Section (bottom 55%)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: parent.height * 0.55
                radius: 12
                
                color: Qt.rgba(1, 1, 1, 0.05)
                
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.1)
                
                // Use the enhanced TodoWidget
                TodoWidget {
                    anchors.fill: parent
                    anchors.margins: 8
                }
            }
        }
    }
    

} 