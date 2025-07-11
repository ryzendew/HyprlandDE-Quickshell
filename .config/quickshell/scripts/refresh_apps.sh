#!/bin/bash

# Script to refresh the application list in Quickshell
# This can be called after installing new applications

echo "Refreshing Quickshell application list..."

# Update the desktop database
if command -v update-desktop-database &> /dev/null; then
    echo "Updating desktop database..."
    update-desktop-database ~/.local/share/applications
else
    echo "update-desktop-database not found, skipping database update"
fi

# Send IPC command to refresh HyprMenu (if Quickshell is running)
if command -v quickshell-ipc &> /dev/null; then
    echo "Sending refresh command to HyprMenu..."
    quickshell-ipc hyprmenu refresh
else
    echo "quickshell-ipc not found, manual refresh may be needed"
fi

echo "Application list refresh completed!"
echo "Note: If HyprMenu is open, you may need to close and reopen it to see new applications." 