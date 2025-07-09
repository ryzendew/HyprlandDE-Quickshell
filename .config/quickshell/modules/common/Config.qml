pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string filePath: Directories.shellConfigPath
    property var options: ConfigOptions

    function setNestedValue(nestedKey, value) {
        let keys = nestedKey.split(".");
        let obj = root.options;

        // Traverse to the parent object
        for (let i = 0; i < keys.length - 1; ++i) {
            if (!obj[keys[i]]) {
                return;
            }
            obj = obj[keys[i]];
        }

        // Convert value to correct type using JSON.parse when safe
        let convertedValue = value;
        if (typeof value === "string") {
            let trimmed = value.trim();
            if (trimmed === "true" || trimmed === "false" || !isNaN(Number(trimmed))) {
                try {
                    convertedValue = JSON.parse(trimmed);
                } catch (e) {
                    convertedValue = value;
                }
            }
        }

        // Set the value
        const finalKey = keys[keys.length - 1];
        if (obj.hasOwnProperty(finalKey)) {
            obj[finalKey] = convertedValue;
        }
    }

    // Config persistence disabled - using ConfigOptions directly
    // FileView {
    //     path: root.filePath
    //     watchChanges: true
    //     onFileChanged: reload()
    //     onAdapterUpdated: writeAdapter()
    //     onLoadFailed: error => {
    //         if (error == FileViewError.FileNotFound) {
    //             writeAdapter();
    //         }
    //     }
    // }

    // JsonAdapter removed - using ConfigOptions directly
    QtObject {
        id: configOptionsJsonAdapter // Keep ID for compatibility - empty stub
    }

}
