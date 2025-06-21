import QtQuick
import QtQuick.Shapes
import "root:/Data" as Settings

// Concave corner shape component for rounded panel edges
Shape {
    id: root
    
    property string position: "topleft"  // Corner position: topleft/topright/bottomleft/bottomright
    property real size: 1.0              // Scale multiplier for entire corner
    property int concaveWidth: 100 * size
    property int concaveHeight: 60 * size
    property int offsetX: -20
    property int offsetY: -20
    property color fillColor: Settings.Colors.bgColor
    property int arcRadius: 20 * size
    
    // Position flags derived from position string
    property bool _isTop: position.includes("top")
    property bool _isLeft: position.includes("left")
    property bool _isRight: position.includes("right")
    property bool _isBottom: position.includes("bottom")
    
    // Base coordinates for left corner shape
    property real _baseStartX: 30 * size
    property real _baseStartY: _isTop ? 20 * size : 0
    property real _baseLineX: 30 * size  
    property real _baseLineY: _isTop ? 0 : 20 * size
    property real _baseArcX: 50 * size
    property real _baseArcY: _isTop ? 20 * size : 0
    
    // Mirror coordinates for right corners
    property real _startX: _isRight ? (concaveWidth - _baseStartX) : _baseStartX
    property real _startY: _baseStartY
    property real _lineX: _isRight ? (concaveWidth - _baseLineX) : _baseLineX
    property real _lineY: _baseLineY
    property real _arcX: _isRight ? (concaveWidth - _baseArcX) : _baseArcX
    property real _arcY: _baseArcY
    
    // Arc direction varies by corner to maintain proper concave shape
    property int _arcDirection: {
        if (_isTop && _isLeft) return PathArc.Counterclockwise
        if (_isTop && _isRight) return PathArc.Clockwise
        if (_isBottom && _isLeft) return PathArc.Clockwise
        if (_isBottom && _isRight) return PathArc.Counterclockwise
        return PathArc.Counterclockwise
    }
    
    width: concaveWidth
    height: concaveHeight
    // Position relative to parent based on corner type
    x: _isLeft ? offsetX : (parent ? parent.width - width + offsetX : 0)
    y: _isTop ? offsetY : (parent ? parent.height - height + offsetY : 0)
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeWidth: 0
        fillColor: root.fillColor
        strokeColor: "transparent"

        startX: root._startX
        startY: root._startY

        PathLine { 
            x: root._lineX
            y: root._lineY 
        }

        PathArc {
            x: root._arcX
            y: root._arcY
            radiusX: root.arcRadius
            radiusY: root.arcRadius
            useLargeArc: false
            direction: root._arcDirection
        }
    }
} 