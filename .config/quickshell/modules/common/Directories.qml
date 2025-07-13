pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common/functions/file_utils.js" as FileUtils
import Qt.labs.platform
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    // XDG Dirs, with "file://"
    readonly property string config: StandardPaths.writableLocation(StandardPaths.ConfigLocation)
    readonly property string state: StandardPaths.writableLocation(StandardPaths.StateLocation)
    readonly property string cache: StandardPaths.writableLocation(StandardPaths.CacheLocation)
    readonly property string pictures: StandardPaths.writableLocation(StandardPaths.PicturesLocation)
    readonly property string downloads: StandardPaths.writableLocation(StandardPaths.DownloadLocation)
    
    // Other dirs used by the shell, without "file://"
    property string favicons: FileUtils.trimFileProtocol(`${Directories.cache.replace(/Quickshell/, 'quickshell')}/media/favicons`)
    property string coverArt: FileUtils.trimFileProtocol(`${Directories.cache.replace(/Quickshell/, 'quickshell')}/media/coverart`)
    property string booruPreviews: FileUtils.trimFileProtocol(`${Directories.cache.replace(/Quickshell/, 'quickshell')}/media/boorus`)
    property string booruDownloads: FileUtils.trimFileProtocol(Directories.pictures  + "/homework")
    property string booruDownloadsNsfw: FileUtils.trimFileProtocol(Directories.pictures + "/homework/🌶️")
    property string latexOutput: FileUtils.trimFileProtocol(`${Directories.cache.replace(/Quickshell/, 'quickshell')}/media/latex`)
    property string shellConfig: FileUtils.trimFileProtocol(`${Directories.config}/illogical-impulse`)
    property string shellConfigName: "config.json"
    property string shellConfigPath: `${Directories.shellConfig}/${Directories.shellConfigName}`
    property string todoPath: FileUtils.trimFileProtocol(`${Directories.state.replace(/Quickshell/, 'quickshell')}/user/todo.conf`)
    property string notificationsPath: FileUtils.trimFileProtocol(`${Directories.cache.replace(/Quickshell/, 'quickshell')}/notifications/notifications.json`)
    property string generatedMaterialThemePath: FileUtils.trimFileProtocol(`${Directories.state.replace(/Quickshell/, 'quickshell')}/user/generated/colors.json`)
    property string cliphistDecode: FileUtils.trimFileProtocol(`/tmp/quickshell/media/cliphist`)
    property string wallpaperSwitchScriptPath: FileUtils.trimFileProtocol(`${Directories.config}/quickshell/scripts/switchwall.sh`)
    // Cleanup on init
    Component.onCompleted: {
        Hyprland.dispatch(`exec mkdir -p '${shellConfig}'`)
        Hyprland.dispatch(`exec mkdir -p '${favicons}'`)
        // Don't clear coverArt directory to preserve cached album art
        Hyprland.dispatch(`exec mkdir -p '${coverArt}'`)
        // Clean up old/corrupted cover art files (empty files)
        Hyprland.dispatch(`exec find '${coverArt}' -type f -empty -delete 2>/dev/null || true`)
        Hyprland.dispatch(`exec rm -rf '${booruPreviews}'; mkdir -p '${booruPreviews}'`)
        Hyprland.dispatch(`exec mkdir -p '${booruDownloads}' && mkdir -p '${booruDownloadsNsfw}'`)
        Hyprland.dispatch(`exec rm -rf '${latexOutput}'; mkdir -p '${latexOutput}'`)
        Hyprland.dispatch(`exec rm -rf '${cliphistDecode}'; mkdir -p '${cliphistDecode}'`)
    }
}
