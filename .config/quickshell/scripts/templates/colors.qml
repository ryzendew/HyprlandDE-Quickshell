pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "root:/modules/common/functions/color_utils.js" as ColorUtils

Singleton {
    id: root
    property QtObject m3colors
    property QtObject colors

    m3colors: QtObject {
        property bool darkmode: true
        property bool transparent: true
        property color m3background: "#161217"
        property color m3onBackground: "#EAE0E7"
        property color m3surface: "#161217"
        property color m3surfaceDim: "#161217"
        property color m3surfaceBright: "#3D373D"
        property color m3surfaceContainerLowest: "#110D12"
        property color m3surfaceContainerLow: "#1F1A1F"
        property color m3surfaceContainer: "#231E23"
        property color m3surfaceContainerHigh: "#2D282E"
        property color m3surfaceContainerHighest: "#383339"
        property color m3onSurface: "#EAE0E7"
        property color m3surfaceVariant: "#4C444D"
        property color m3onSurfaceVariant: "#CFC3CD"
        property color m3inverseSurface: "#EAE0E7"
        property color m3inverseOnSurface: "#342F34"
        property color m3outline: "#988E97"
        property color m3outlineVariant: "#4C444D"
        property color m3shadow: "#000000"
        property color m3scrim: "#000000"
        property color m3surfaceTint: "#E5B6F2"
        property color m3primary: "#E5B6F2"
        property color m3onPrimary: "#452152"
        property color m3primaryContainer: "#5D386A"
        property color m3onPrimaryContainer: "#F9D8FF"
        property color m3inversePrimary: "#775084"
        property color m3secondary: "#D5C0D7"
        property color m3onSecondary: "#392C3D"
        property color m3secondaryContainer: "#534457"
        property color m3onSecondaryContainer: "#F2DCF3"
        property color m3tertiary: "#F5B7B3"
        property color m3onTertiary: "#4C2523"
        property color m3tertiaryContainer: "#BA837F"
        property color m3onTertiaryContainer: "#000000"
        property color m3error: "#FFB4AB"
        property color m3onError: "#690005"
        property color m3errorContainer: "#93000A"
        property color m3onErrorContainer: "#FFDAD6"
        property color m3success: "#B5CCBA"
        property color m3onSuccess: "#213528"
        property color m3successContainer: "#374B3E"
        property color m3onSuccessContainer: "#D1E9D6"
    }

    colors: QtObject {
        property color colSubtext: m3colors.m3outline
        property color colLayer0: m3colors.m3background
        property color colOnLayer0: m3colors.m3onBackground
        property color colLayer0Hover: ColorUtils.mix(colLayer0, colOnLayer0, 0.9)
        property color colLayer0Active: ColorUtils.mix(colLayer0, colOnLayer0, 0.8)
        property color colLayer1: m3colors.m3surfaceContainerLow
        property color colOnLayer1: m3colors.m3onSurfaceVariant
        property color colOnLayer1Inactive: ColorUtils.mix(colOnLayer1, colLayer1, 0.45)
        property color colLayer2: ColorUtils.mix(m3colors.m3surfaceContainer, m3colors.m3surfaceContainerHigh, 0.55)
        property color colOnLayer2: m3colors.m3onSurface
        property color colOnLayer2Disabled: ColorUtils.mix(colOnLayer2, m3colors.m3background, 0.4)
        property color colLayer3: ColorUtils.mix(m3colors.m3surfaceContainerHigh, m3colors.m3onSurface, 0.96)
        property color colOnLayer3: m3colors.m3onSurface
        property color colLayer1Hover: ColorUtils.mix(colLayer1, colOnLayer1, 0.92)
        property color colLayer1Active: ColorUtils.mix(colLayer1, colOnLayer1, 0.85)
        property color colLayer2Hover: ColorUtils.mix(colLayer2, colOnLayer2, 0.90)
        property color colLayer2Active: ColorUtils.mix(colLayer2, colOnLayer2, 0.80)
        property color colLayer2Disabled: ColorUtils.mix(colLayer2, m3colors.m3background, 0.8)
        property color colLayer3Hover: ColorUtils.mix(colLayer3, colOnLayer3, 0.90)
        property color colLayer3Active: ColorUtils.mix(colLayer3, colOnLayer3, 0.80)
        property color colPrimaryHover: ColorUtils.mix(m3colors.m3primary, colLayer1Hover, 0.85)
    }

    readonly property color background: "#{{background}}"
    readonly property color error: "#{{error}}"
    readonly property color error_container: "#{{errorContainer}}"
    readonly property color inverse_on_surface: "#{{inverseOnSurface}}"
    readonly property color inverse_primary: "#{{inversePrimary}}"
    readonly property color inverse_surface: "#{{inverseSurface}}"
    readonly property color on_background: "#{{onBackground}}"
    readonly property color on_error: "#{{onError}}"
    readonly property color on_error_container: "#{{onErrorContainer}}"
    readonly property color on_primary: "#{{onPrimary}}"
    readonly property color on_primary_container: "#{{onPrimaryContainer}}"
    readonly property color on_primary_fixed: "#{{onPrimaryFixed}}"
    readonly property color on_primary_fixed_variant: "#{{onPrimaryFixedVariant}}"
    readonly property color on_secondary: "#{{onSecondary}}"
    readonly property color on_secondary_container: "#{{onSecondaryContainer}}"
    readonly property color on_secondary_fixed: "#{{onSecondaryFixed}}"
    readonly property color on_secondary_fixed_variant: "#{{onSecondaryFixedVariant}}"
    readonly property color on_surface: "#{{onSurface}}"
    readonly property color on_surface_variant: "#{{onSurfaceVariant}}"
    readonly property color on_tertiary: "#{{onTertiary}}"
    readonly property color on_tertiary_container: "#{{onTertiaryContainer}}"
    readonly property color on_tertiary_fixed: "#{{onTertiaryFixed}}"
    readonly property color on_tertiary_fixed_variant: "#{{onTertiaryFixedVariant}}"
    readonly property color outline: "#{{outline}}"
    readonly property color outline_variant: "#{{outlineVariant}}"
    readonly property color primary: "#{{primary}}"
    readonly property color primary_container: "#{{primaryContainer}}"
    readonly property color primary_fixed: "#{{primaryFixed}}"
    readonly property color primary_fixed_dim: "#{{primaryFixedDim}}"
    readonly property color scrim: "#{{scrim}}"
    readonly property color secondary: "#{{secondary}}"
    readonly property color secondary_container: "#{{secondaryContainer}}"
    readonly property color secondary_fixed: "#{{secondaryFixed}}"
    readonly property color secondary_fixed_dim: "#{{secondaryFixedDim}}"
    readonly property color shadow: "#{{shadow}}"
    readonly property color surface: "#{{surface}}"
    readonly property color surface_bright: "#{{surfaceBright}}"
    readonly property color surface_container: "#{{surfaceContainer}}"
    readonly property color surface_container_high: "#{{surfaceContainerHigh}}"
    readonly property color surface_container_highest: "#{{surfaceContainerHighest}}"
    readonly property color surface_container_low: "#{{surfaceContainerLow}}"
    readonly property color surface_container_lowest: "#{{surfaceContainerLowest}}"
    readonly property color surface_dim: "#{{surfaceDim}}"
    readonly property color surface_tint: "#{{surfaceTint}}"
    readonly property color surface_variant: "#{{surfaceVariant}}"
    readonly property color tertiary: "#{{tertiary}}"
    readonly property color tertiary_container: "#{{tertiaryContainer}}"
    readonly property color tertiary_fixed: "#{{tertiaryFixed}}"
    readonly property color tertiary_fixed_dim: "#{{tertiaryFixedDim}}"

    function withAlpha(color: color, alpha: real): color {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }
} 