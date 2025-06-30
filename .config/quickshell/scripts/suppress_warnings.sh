#!/bin/bash

# Environment variables to suppress Qt warnings
export QT_LOGGING_RULES="*.debug=false;qt.qpa.*=false;qt.svg.*=false;qt.scenegraph.*=false;qt.quick.*=false;qt.qml.*=false"
export QT_QUICK_CONTROLS_STYLE=Basic
export QT_QUICK_CONTROLS2_STYLE=Basic

# Suppress specific warnings
export QT_WARNING_PATTERNS=""

# Launch quickshell with suppressed warnings
exec quickshell "$@" 