import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import "root:/Data" as Data

// Screen border with shadows
Shape {
    id: borderShape

    // Border geometry calculations
    property real borderWidth: Data.Settings.borderWidth
    property real radius: Data.Settings.cornerRadius
    property real innerX: borderWidth
    property real innerY: borderWidth
    property real innerWidth: borderShape.width - (borderWidth * 2)
    property real innerHeight: borderShape.height - (borderWidth * 2)
    
    // Widget references
    property var workspaceIndicator: null
    property var volumeOSD: null
    property var clockWidget: null

    // Composite shadow source
    Item {
        id: shadowSource
        anchors.fill: parent
        visible: false
        
        // Main border shadow
        Shape {
            id: borderShadowShape
            anchors.fill: parent
        
        ShapePath {
            fillColor: "black"
            strokeWidth: 0
            fillRule: ShapePath.OddEvenFill

            // Outer rectangle (full screen)
            PathMove { x: 0; y: 0 }
            PathLine { x: shadowSource.width; y: 0 }
            PathLine { x: shadowSource.width; y: shadowSource.height }
            PathLine { x: 0; y: shadowSource.height }
            PathLine { x: 0; y: 0 }

            // Inner rounded cutout (creates border effect)
            PathMove { 
                x: borderShape.innerX + borderShape.radius
                y: borderShape.innerY
            }
            
            PathLine {
                x: borderShape.innerX + borderShape.innerWidth - borderShape.radius
                y: borderShape.innerY
            }
            
            PathArc {
                x: borderShape.innerX + borderShape.innerWidth
                y: borderShape.innerY + borderShape.radius
                radiusX: borderShape.radius
                radiusY: borderShape.radius
                direction: PathArc.Clockwise
            }
            
            PathLine {
                x: borderShape.innerX + borderShape.innerWidth
                y: borderShape.innerY + borderShape.innerHeight - borderShape.radius
            }
            
            PathArc {
                x: borderShape.innerX + borderShape.innerWidth - borderShape.radius
                y: borderShape.innerY + borderShape.innerHeight
                radiusX: borderShape.radius
                radiusY: borderShape.radius
                direction: PathArc.Clockwise
            }
            
            PathLine {
                x: borderShape.innerX + borderShape.radius
                y: borderShape.innerY + borderShape.innerHeight
            }
            
            PathArc {
                x: borderShape.innerX
                y: borderShape.innerY + borderShape.innerHeight - borderShape.radius
                radiusX: borderShape.radius
                radiusY: borderShape.radius
                direction: PathArc.Clockwise
            }
            
            PathLine {
                x: borderShape.innerX
                y: borderShape.innerY + borderShape.radius
            }
            
            PathArc {
                x: borderShape.innerX + borderShape.radius
                y: borderShape.innerY
                radiusX: borderShape.radius
                radiusY: borderShape.radius
                direction: PathArc.Clockwise
            }
        }
        }
        
        // Workspace indicator shadow
        Shape {
            id: workspaceShadowShape
            visible: borderShape.workspaceIndicator !== null
            x: borderShape.workspaceIndicator ? borderShape.workspaceIndicator.x - 12 : 0
            y: borderShape.workspaceIndicator ? borderShape.workspaceIndicator.y : 0
            width: borderShape.workspaceIndicator ? borderShape.workspaceIndicator.width + 12 : 0
            height: borderShape.workspaceIndicator ? borderShape.workspaceIndicator.height : 0
            preferredRendererType: Shape.CurveRenderer
            
            ShapePath {
                strokeWidth: 0
                fillColor: "black"
                strokeColor: "transparent"
                
                startX: 12
                startY: 0
                
                // Standard rounded corners on right side
                PathLine { x: workspaceShadowShape.width - 16; y: 0 }
                
                PathArc {
                    x: workspaceShadowShape.width; y: 16
                    radiusX: 16; radiusY: 16
                    direction: PathArc.Clockwise
                }
                
                PathLine { x: workspaceShadowShape.width; y: workspaceShadowShape.height - 16 }
                
                PathArc {
                    x: workspaceShadowShape.width - 16; y: workspaceShadowShape.height
                    radiusX: 16; radiusY: 16
                    direction: PathArc.Clockwise
                }
                
                PathLine { x: 12; y: workspaceShadowShape.height }
                
                // Concave curves on left side
                PathLine { x: 0; y: workspaceShadowShape.height - 12 }
                PathArc {
                    x: 12; y: workspaceShadowShape.height - 24
                    radiusX: 12; radiusY: 12
                    direction: PathArc.Clockwise
                }
                
                PathLine { x: 12; y: 24 }
                
                PathArc {
                    x: 0; y: 12
                    radiusX: 12; radiusY: 12
                    direction: PathArc.Clockwise
                }
                PathLine { x: 12; y: 0 }
            }
        }
        
        // Volume OSD shadow aligned to right border
        Rectangle {
            id: volumeOsdShadowShape
            visible: borderShape.volumeOSD !== null && borderShape.volumeOSD.visible
            x: shadowSource.width - 45
            y: (shadowSource.height - 250) / 2
            width: 45
            height: 250
            color: "black"
            topLeftRadius: 20
            bottomLeftRadius: 20
            topRightRadius: 0
            bottomRightRadius: 0
        }
        
        // Clock shadow
        Rectangle {
            id: clockShadowShape
            visible: borderShape.clockWidget !== null
            x: borderShape.clockWidget ? borderShape.clockWidget.x : 0
            y: borderShape.clockWidget ? borderShape.clockWidget.y : 0
            width: borderShape.clockWidget ? borderShape.clockWidget.width : 0
            height: borderShape.clockWidget ? borderShape.clockWidget.height : 0
            color: "black"
            topLeftRadius: 0
            topRightRadius: borderShape.clockWidget ? borderShape.clockWidget.height / 2 : 16
            bottomLeftRadius: 0
            bottomRightRadius: 0
        }
    }

    // Composite shadow effect
    DropShadow {
        anchors.fill: shadowSource
        source: shadowSource
        transparentBorder: true
        horizontalOffset: 0
        verticalOffset: 0
        radius: 24
        samples: 30
        color: Qt.rgba(0, 0, 0, 0.95)
        cached: false
        spread: 0.4
        z: -10
    }

    // Main border shape
    ShapePath {
        fillColor: Data.Colors.bgColor
        strokeWidth: 0
        fillRule: ShapePath.OddEvenFill

        // Outer rectangle
        PathMove { x: 0; y: 0 }
        PathLine { x: borderShape.width; y: 0 }
        PathLine { x: borderShape.width; y: borderShape.height }
        PathLine { x: 0; y: borderShape.height }
        PathLine { x: 0; y: 0 }

        // Inner rounded cutout
        PathMove { 
            x: borderShape.innerX + borderShape.radius
            y: borderShape.innerY
        }
        
        PathLine {
            x: borderShape.innerX + borderShape.innerWidth - borderShape.radius
            y: borderShape.innerY
        }
        
        PathArc {
            x: borderShape.innerX + borderShape.innerWidth
            y: borderShape.innerY + borderShape.radius
            radiusX: borderShape.radius
            radiusY: borderShape.radius
            direction: PathArc.Clockwise
        }
        
        PathLine {
            x: borderShape.innerX + borderShape.innerWidth
            y: borderShape.innerY + borderShape.innerHeight - borderShape.radius
        }
        
        PathArc {
            x: borderShape.innerX + borderShape.innerWidth - borderShape.radius
            y: borderShape.innerY + borderShape.innerHeight
            radiusX: borderShape.radius
            radiusY: borderShape.radius
            direction: PathArc.Clockwise
        }
        
        PathLine {
            x: borderShape.innerX + borderShape.radius
            y: borderShape.innerY + borderShape.innerHeight
        }
        
        PathArc {
            x: borderShape.innerX
            y: borderShape.innerY + borderShape.innerHeight - borderShape.radius
            radiusX: borderShape.radius
            radiusY: borderShape.radius
            direction: PathArc.Clockwise
        }
        
        PathLine {
            x: borderShape.innerX
            y: borderShape.innerY + borderShape.radius
        }
        
        PathArc {
            x: borderShape.innerX + borderShape.radius
            y: borderShape.innerY
            radiusX: borderShape.radius
            radiusY: borderShape.radius
            direction: PathArc.Clockwise
        }
    }
} 