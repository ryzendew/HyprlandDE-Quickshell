import QtQuick 2.15
import Quickshell.Io

pragma Singleton

QtObject {
    function readFile(path) {
        try {
            var fileView = Qt.createQmlObject('import Quickshell.Io; FileView { }', Qt.application);
            fileView.path = path;
            var content = fileView.text();
            fileView.destroy();
            return content;
        } catch (e) {
            return '';
        }
    }
} 