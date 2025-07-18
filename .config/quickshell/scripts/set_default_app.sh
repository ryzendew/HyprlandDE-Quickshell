#!/bin/bash

# Script to set default applications using xdg-mime
# Usage: ./set_default_app.sh <category> <desktop_id>

CATEGORY="$1"
DESKTOP_ID="$2"

if [ -z "$CATEGORY" ] || [ -z "$DESKTOP_ID" ]; then
    echo "Usage: $0 <category> <desktop_id>"
    echo "Example: $0 web microsoft-edge-dev.desktop"
    exit 1
fi

echo "Setting default app for category: $CATEGORY"
echo "Desktop ID: $DESKTOP_ID"

# Define MIME types for each category
case "$CATEGORY" in
    "web")
        MIME_TYPES=("x-scheme-handler/http" "x-scheme-handler/https")
        ;;
    "mail")
        MIME_TYPES=("x-scheme-handler/mailto")
        ;;
    "calendar")
        MIME_TYPES=("text/calendar")
        ;;
    "music")
        MIME_TYPES=("audio/mpeg" "audio/mp3" "audio/wav" "audio/flac" "audio/ogg")
        ;;
    "video")
        MIME_TYPES=("video/mp4" "video/avi" "video/mkv" "video/webm" "video/ogg")
        ;;
    "photos")
        MIME_TYPES=("image/jpeg" "image/png" "image/gif" "image/bmp" "image/webp")
        ;;
    "text_editor")
        MIME_TYPES=("text/plain" "text/x-c" "text/x-c++" "text/x-python" "text/x-java")
        ;;
    "file_manager")
        MIME_TYPES=("inode/directory")
        ;;
    "terminal")
        MIME_TYPES=("application/x-terminal")
        ;;
    *)
        echo "Unknown category: $CATEGORY"
        exit 1
        ;;
esac

# Set defaults for each MIME type
for mime_type in "${MIME_TYPES[@]}"; do
    echo "Setting $mime_type to $DESKTOP_ID"
    xdg-mime default "$DESKTOP_ID" "$mime_type"
    
    # Verify the change
    current_default=$(xdg-mime query default "$mime_type")
    if [ "$current_default" = "$DESKTOP_ID" ]; then
        echo "✅ Successfully set $mime_type to $DESKTOP_ID"
    else
        echo "❌ Failed to set $mime_type. Current default: $current_default"
    fi
done

echo "Default app setting completed for category: $CATEGORY" 