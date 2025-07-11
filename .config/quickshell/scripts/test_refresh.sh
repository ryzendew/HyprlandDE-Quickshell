#!/bin/bash

echo "Testing Quickshell application refresh functionality..."

# Check if update-desktop-database is available
if command -v update-desktop-database &> /dev/null; then
    echo "✓ update-desktop-database found"
else
    echo "✗ update-desktop-database not found"
fi

# Check if quickshell-ipc is available
if command -v quickshell-ipc &> /dev/null; then
    echo "✓ quickshell-ipc found"
else
    echo "✗ quickshell-ipc not found"
fi

# Test the refresh script
echo ""
echo "Running refresh script..."
./scripts/refresh_apps.sh

echo ""
echo "Test completed!" 