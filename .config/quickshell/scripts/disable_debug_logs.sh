#!/bin/bash

# Script to disable all debug logs in quickshell
# This script comments out all active console.log statements in QML files

echo "Disabling debug logs in quickshell..."

# Find all QML files with active console.log statements (not already commented)
find . -name "*.qml" -type f -exec grep -l "^[^/]*console\.log" {} \; | while read file; do
    echo "Processing: $file"
    
    # Create a backup
    cp "$file" "$file.backup"
    
    # Comment out active console.log statements (those not already commented)
    # This regex matches console.log at the start of a line (after whitespace) that's not already commented
    sed -i 's/^[[:space:]]*console\.log/\/\/ console.log/g' "$file"
    
    echo "  - Disabled debug logs in $file"
done

echo "Debug logs disabled. Backup files created with .backup extension."
echo "To restore, run: find . -name '*.qml.backup' -exec bash -c 'cp \"{}\" \"\${1%.backup}\"' _ {} \;" 