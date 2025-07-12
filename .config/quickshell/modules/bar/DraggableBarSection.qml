import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "root:/modules/common"

RowLayout {
    id: barSection
    
    // --- Properties ---
    property string section: "left" // "left", "right", "center"
    property var moduleManager: null
    property var bar: null
    property bool enableDragAndDrop: ConfigOptions.bar?.modules?.enableDragAndDrop || false
    
    // Layout properties
    spacing: section === "center" ? 8 : 10
    layoutDirection: section === "right" ? Qt.RightToLeft : Qt.LeftToRight
    
    // --- Functions ---
    function refreshModules() {
        // Clear existing modules
        for (var i = repeater.count - 1; i >= 0; i--) {
            var item = repeater.itemAt(i)
            if (item) {
                item.destroy()
            }
        }
        
        // Force repeater to rebuild
        repeater.model = 0
        repeater.model = moduleManager ? moduleManager.getModuleOrder(section) : []
    }
    
    function handleModuleReorder(moduleId, fromIndex, toIndex) {
        if (moduleManager) {
            moduleManager.moveModule(section, fromIndex, toIndex)
        }
    }
    
    // --- Module Repeater ---
    Repeater {
        id: repeater
        model: {
            if (moduleManager) {
                var order = moduleManager.getModuleOrder(section)
                return order
            } else {
                return []
            }
        }
        
        delegate: BarModule {
            moduleId: modelData
            moduleIndex: index
            section: barSection.section
            isDraggable: enableDragAndDrop
            
            moduleComponent: Component {
                Loader {
                    source: {
                        var componentPath = moduleManager ? moduleManager.getModuleComponent(modelData) : ""
                        return componentPath
                    }
                    
                    // Pass bar reference to modules that need it
                    onLoaded: {
                        if (item && item.hasOwnProperty("bar")) {
                            item.bar = barSection.bar
                        }
                    }
                }
            }
            
            // Handle drag and drop
            onRequestReorder: (moduleId, fromIndex, toIndex) => {
                handleModuleReorder(moduleId, fromIndex, toIndex)
            }
            
            onDragStarted: (moduleId, index) => {
                // Drag started
            }
            
            onDragEnded: {
                // Drag ended
            }
        }
    }
    
    // --- Connections ---
    Connections {
        target: moduleManager
        function onModuleOrderChanged(changedSection) {
            if (changedSection === section || changedSection === "all") {
                refreshModules()
            }
        }
    }
    
    // --- Component Lifecycle ---
    Component.onCompleted: {
        // Component completed
    }
} 