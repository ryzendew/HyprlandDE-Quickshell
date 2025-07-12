import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "./notification_utils.js" as NotificationUtils
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

Rectangle {
    id: root
    property var notificationObject
    property var iconCache: ({})
    property string iconName: notificationObject ? notificationObject.appIcon : ""
    property string fallbackIcon: "notifications"
    property var summary: ""
    property var urgency: NotificationUrgency.Normal
    property var image: ""
    property real scale: 1
    property real size: 45 * scale
    property real materialIconScale: 0.57
    property real appIconScale: 0.7
    property real smallAppIconScale: 0.49
    property real materialIconSize: size * materialIconScale
    property real appIconSize: size * appIconScale
    property real smallAppIconSize: size * smallAppIconScale

    implicitWidth: size
    implicitHeight: size
    radius: Appearance.rounding.full
    color: Appearance.m3colors.m3secondaryContainer

    Image {
        id: icon
        anchors.centerIn: parent
        width: parent.width * 0.8
        height: parent.height * 0.8
        source: "image://icon/" + (root.iconName || root.fallbackIcon)
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }

    Loader {
        id: materialSymbolLoader
        active: notificationObject.appIcon == ""
        anchors.fill: parent
        sourceComponent: MaterialSymbol {
            text: {
                const defaultIcon = "notifications"
                const guessedIcon = "notifications"
                return (notificationObject.urgency == NotificationUrgency.Critical) ?
                    "release_alert" : guessedIcon
            }
            anchors.fill: parent
            color: Appearance.m3colors.m3onSecondaryContainer
            iconSize: 27
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    Loader {
        id: appIconLoader
        active: notificationObject.image == "" && notificationObject.appIcon != ""
        anchors.centerIn: parent
        sourceComponent: IconImage {
            implicitSize: 33
            asynchronous: true
            source: {
                const iconPath = Quickshell.iconPath(notificationObject.appIcon, "image-missing")
                if (!iconCache[iconPath]) {
                    iconCache[iconPath] = true
                }
                return iconPath
            }
        }
    }

    Loader {
        id: notifImageLoader
        active: notificationObject.image != ""
        anchors.fill: parent
        sourceComponent: Item {
            anchors.fill: parent
            property string originalSource: notificationObject.image
            property string fallbackIconSource: Quickshell.iconPath("image-missing", "dialog-error")

            Image {
                id: notificationActualImage
                anchors.fill: parent
                asynchronous: true
                source: parent.originalSource
                smooth: true
                mipmap: true

                onStatusChanged: {
                    if (status === Image.Error) {
                        root.iconCache[parent.originalSource] = { failed: true }
                        source = parent.fallbackIconSource
                    } else if (status === Image.Ready) {
                        root.iconCache[parent.originalSource] = { failed: false, path: source }
                    }
                }

                Component.onCompleted: {
                    if (root.iconCache[parent.originalSource] && root.iconCache[parent.originalSource].failed) {
                        source = parent.fallbackIconSource
                    }
                }
            }
        }
    }
}