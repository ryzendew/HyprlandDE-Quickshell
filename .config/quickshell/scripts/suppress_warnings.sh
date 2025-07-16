#!/bin/bash

# Environment variables to suppress Qt warnings and debug logs
export QT_LOGGING_RULES="*.debug=false;qt.qpa.*=false;qt.svg.*=false;qt.scenegraph.*=false;qt.quick.*=false;qt.qml.*=false;*.info=false;qt.scene.*=false;qt.quick.scene.*=false"
export QT_QUICK_CONTROLS_STYLE=Basic
export QT_QUICK_CONTROLS2_STYLE=Basic

# Suppress QML scene warnings and other specific warnings
export QT_WARNING_PATTERNS=""
export QT_QUICK_WARNING_PATTERNS=""

# Additional environment variables to suppress warnings
export QT_LOGGING_RULES="$QT_LOGGING_RULES;qt.quick.scene.*=false;qt.scene.*=false;*.warning=false"

# Suppress specific warning categories
export QT_QUICK_WARNING_PATTERNS="*anchors*layout*;*MultiEffect*;*lerp*;*Unable to assign*;*FileView*failed*;*QSettings*failed*"

# Launch quickshell with suppressed warnings
exec quickshell "$@" 