#!/bin/bash

# Script to enable debug logs in quickshell
# This script restores console.log statements from backup files

echo "Enabling debug logs in quickshell..."

# Check if backup files exist
if ! find . -name "*.qml.backup" -type f | grep -q .; then
    echo "No backup files found. Debug logs may already be enabled or no backups were created."
    exit 1
fi

# Restore from backup files
find . -name "*.qml.backup" -type f | while read backup_file; do
    original_file="${backup_file%.backup}"
    echo "Restoring: $original_file"
    cp "$backup_file" "$original_file"
    echo "  - Restored debug logs in $original_file"
done

echo "Debug logs enabled from backup files."
echo "To disable again, run: ./scripts/disable_debug_logs.sh" 