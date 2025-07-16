import QtQuick // Import Qt Quick framework for UI components
import QtQuick.Layouts // Import layout management system
import "root:/modules/common/widgets" // Import custom widget components
import "root:/modules/common" // Import common styling and appearance

Item { // Main container item for the StatCircle component
    id: root // Unique identifier for this component
    property string label: "" // Property to store the main label text (e.g., "CPU", "GPU")
    property string subLabel: "" // Property to store the subtitle text (e.g., temperature, usage info)
    property real value: 0 // Property for progress value (0-1 range for circle fill)
    property string valueText: "" // Property for text displayed inside the circle (e.g., "45%")
    property color primaryColor: Appearance.colors.colAccent // Color for filled part of circle
    property color secondaryColor: Appearance.colors.colLayer1 // Color for unfilled part of circle
    property int size: 120 // Size of the circular progress indicator
    property int lineWidth: 8 // Width of the circle's stroke line
    property var history: [] // Array to store historical values for the graph
    property int historyLength: 60 // Number of history points to display in graph
    property int textOffset: 0 // Offset for text positioning (positive = down, negative = up)

    width: parent ? parent.width : size // Set width to parent width if available, otherwise use size
    height: size + 36 + 32 // Set height to accommodate circle, text, and history graph

    // Circle section - centered in the middle
    Item { // Container for the circle and history graph
        id: circleSection // Unique identifier for circle section
        width: parent.width // Take full width of parent
        height: size + 32 // Height for circle plus history graph
        anchors.horizontalCenter: parent.horizontalCenter // Center horizontally in parent
        anchors.top: parent.top // Anchor to top of parent
        anchors.topMargin: -80 // Move up 80 pixels from top (negative margin)
        
        // Main circle with progress
        Item { // Container for the circular progress indicator
            width: size // Set width to circle size
            height: size // Set height to circle size
            anchors.horizontalCenter: parent.horizontalCenter // Center horizontally in parent
            CircularProgress { // Custom circular progress component
                anchors.centerIn: parent // Center the progress circle in its container
                size: root.size // Use the size property from root
                lineWidth: root.lineWidth // Use the line width from root
                value: root.value // Use the progress value from root (0-1)
                primaryColor: root.primaryColor // Use primary color for filled part
                secondaryColor: root.secondaryColor // Use secondary color for unfilled part
            }
            Text { // Text displayed in center of circle
                anchors.centerIn: parent // Center text in the circle
                text: root.valueText // Display the value text (e.g., "45%")
                font.pixelSize: 28 // Set font size to 28 pixels
                font.bold: true // Make text bold
                color: "white" // Set text color to white
            }
        }
        
        // History Graph below circle
        Canvas { // Canvas element for drawing the history graph
            id: historyCanvas // Unique identifier for the canvas
            width: size // Set width to match circle size
            height: 32 // Set height to 32 pixels for the graph
            anchors.horizontalCenter: parent.horizontalCenter // Center horizontally
            anchors.top: parent.bottom // Position at bottom of circle container
            anchors.topMargin: -32 // Move up 32 pixels to overlap with circle bottom
            
            onPaint: { // Function called when canvas needs to be painted
                var ctx = getContext("2d") // Get 2D drawing context
                ctx.reset() // Clear the canvas
                
                if (root.history.length < 2) return // Don't draw if less than 2 data points
                
                var width = historyCanvas.width // Get canvas width
                var height = historyCanvas.height // Get canvas height
                var step = width / (root.historyLength - 1) // Calculate step size between points
                
                ctx.strokeStyle = Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.3) // Set line color with transparency
                ctx.lineWidth = 2 // Set line width to 2 pixels
                ctx.beginPath() // Start drawing path
                
                for (var i = 0; i < root.history.length; i++) { // Loop through history data
                    var x = i * step // Calculate x position for this point
                    var y = height - (root.history[i] * height) // Calculate y position (inverted for graph)
                    
                    if (i === 0) { // If first point
                        ctx.moveTo(x, y) // Move to starting position
                    } else { // For subsequent points
                        ctx.lineTo(x, y) // Draw line to this point
                    }
                }
                
                ctx.stroke() // Stroke the path to make it visible
            }
        }
        
        Connections { // Connection to listen for property changes
            target: root // Listen to changes on root component
            onHistoryChanged: historyCanvas.requestPaint() // Redraw canvas when history changes
        }
    }
    
    // Text section - centered below circles
    ColumnLayout { // Vertical layout for text elements
        anchors.top: parent.top // Position relative to parent top instead of circle section
        anchors.left: parent.left // Anchor to left edge of parent
        anchors.right: parent.right // Anchor to right edge of parent
        anchors.topMargin: -100 + textOffset // Position below the circle with custom offset
        spacing: 4 // Space between text elements
        
        StyledText { // Main label text (e.g., "CPU", "GPU", "Memory")
            text: root.label // Display the label text
            font.pixelSize: Appearance.font.pixelSize.normal // Use normal font size
            color: "white" // Set text color to white
            horizontalAlignment: Text.AlignHCenter // Center text horizontally
            Layout.alignment: Qt.AlignHCenter // Center the text element in layout
            Layout.fillWidth: true // Make text take full width of layout
        }
        StyledText { // Subtitle text (e.g., temperature, usage info)
            text: root.subLabel // Display the subtitle text
            font.pixelSize: Appearance.font.pixelSize.tiny // Use tiny font size
            color: "white" // Set text color to white
            horizontalAlignment: Text.AlignHCenter // Center text horizontally
            Layout.alignment: Qt.AlignHCenter // Center the text element in layout
            Layout.fillWidth: true // Make text take full width of layout
        }
    }
} 