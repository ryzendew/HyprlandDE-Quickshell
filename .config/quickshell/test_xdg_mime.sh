#!/bin/bash

echo "Testing xdg-mime commands..."

# Test 1: Check current HTTP handler
echo "Current HTTP handler:"
xdg-mime query default x-scheme-handler/http

# Test 2: Set Microsoft Edge as default
echo "Setting Microsoft Edge as default browser..."
xdg-mime default microsoft-edge-dev.desktop x-scheme-handler/http
xdg-mime default microsoft-edge-dev.desktop x-scheme-handler/https

# Test 3: Verify the change
echo "New HTTP handler:"
xdg-mime query default x-scheme-handler/http

echo "Test completed!" 