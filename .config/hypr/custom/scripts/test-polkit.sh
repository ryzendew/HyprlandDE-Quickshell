#!/bin/bash

# Test script to verify polkit authentication is working
echo "Testing polkit authentication..."

# Test 1: Check if hyprpolkitagent is running
echo "1. Checking if hyprpolkitagent is running..."
if pgrep -f hyprpolkitagent > /dev/null; then
    echo "   ✓ hyprpolkitagent is running"
else
    echo "   ✗ hyprpolkitagent is not running"
fi

# Test 2: Check if lxpolkit is running
echo "2. Checking if lxpolkit is running..."
if pgrep -f lxpolkit > /dev/null; then
    echo "   ✓ lxpolkit is running"
else
    echo "   ✗ lxpolkit is not running"
fi

# Test 3: Test pkexec with a simple command
echo "3. Testing pkexec authentication..."
echo "   This should prompt for your password:"
pkexec --user root whoami

# Test 4: Check environment variables
echo "4. Checking polkit environment variables..."
echo "   POLKIT_AUTH_AGENT: $POLKIT_AUTH_AGENT"
echo "   POLKIT_AUTH_AGENT_PATH: $POLKIT_AUTH_AGENT_PATH"
echo "   XDG_CURRENT_DESKTOP: $XDG_CURRENT_DESKTOP"
echo "   XDG_SESSION_TYPE: $XDG_SESSION_TYPE"

echo "Test completed!" 