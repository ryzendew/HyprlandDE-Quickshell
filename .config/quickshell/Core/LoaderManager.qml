import QtQuick

QtObject {
    id: root

    // Keep track of loaded components
    property var activeLoaders: ({})
    
    // Dynamically load a QML component
    function load(componentUrl, parent, properties) {
        if (!activeLoaders[componentUrl]) {
            var loader = Qt.createQmlObject(`
                import QtQuick
                Loader {
                    active: false
                    asynchronous: true
                    visible: false
                }
            `, parent);
            
            loader.source = componentUrl
            loader.active = true
            
            if (properties) {
                for (var prop in properties) {
                    loader[prop] = properties[prop]
                }
            }
            
            activeLoaders[componentUrl] = loader
        }
        return activeLoaders[componentUrl]
    }
    
    // Destroy and remove a loaded component
    function unload(componentUrl) {
        if (activeLoaders[componentUrl]) {
            activeLoaders[componentUrl].active = false
            activeLoaders[componentUrl].destroy()
            delete activeLoaders[componentUrl]
        }
    }
    
    // Check if a component is loaded
    function isLoaded(componentUrl) {
        return !!activeLoaders[componentUrl]
    }
} 