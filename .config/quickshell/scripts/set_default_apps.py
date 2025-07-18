#!/usr/bin/env python3
"""
Default Apps Setter for Quickshell
Reliably sets default applications using xdg-mime commands
"""

import json
import subprocess
import sys
import os
from pathlib import Path

class DefaultAppSetter:
    def __init__(self):
        self.mime_types = {
            "web": ["x-scheme-handler/http", "x-scheme-handler/https"],
            "mail": ["x-scheme-handler/mailto"],
            "calendar": ["text/calendar"],
            "music": ["audio/mpeg", "audio/mp3", "audio/wav", "audio/flac", "audio/ogg"],
            "video": ["video/mp4", "video/avi", "video/mkv", "video/webm", "video/ogg"],
            "photos": ["image/jpeg", "image/png", "image/gif", "image/bmp", "image/webp"],
            "text_editor": ["text/plain", "text/x-c", "text/x-c++", "text/x-python", "text/x-java"],
            "file_manager": ["inode/directory"],
            "terminal": ["application/x-terminal"]
        }
    
    def run_command(self, command):
        """Run a shell command and return the result"""
        try:
            result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=10)
            return result.returncode == 0, result.stdout.strip(), result.stderr.strip()
        except subprocess.TimeoutExpired:
            return False, "", "Command timed out"
        except Exception as e:
            return False, "", str(e)
    
    def set_default_app(self, category, desktop_file):
        """Set default app for a category"""
        if category not in self.mime_types:
            print(f"Error: Unknown category '{category}'")
            return False
        
        if not desktop_file:
            print(f"Error: No desktop file specified for category '{category}'")
            return False
        
        # Ensure desktop file has .desktop extension
        if not desktop_file.endswith('.desktop'):
            desktop_file = f"{desktop_file}.desktop"
        
        print(f"Setting {category} default to: {desktop_file}")
        
        success_count = 0
        total_count = len(self.mime_types[category])
        
        for mime_type in self.mime_types[category]:
            command = f"xdg-mime default '{desktop_file}' '{mime_type}'"
            success, stdout, stderr = self.run_command(command)
            
            if success:
                success_count += 1
                print(f"  ✓ Set {mime_type} -> {desktop_file}")
            else:
                print(f"  ✗ Failed to set {mime_type}: {stderr}")
        
        print(f"Result: {success_count}/{total_count} MIME types set successfully")
        return success_count > 0
    
    def get_current_default(self, category):
        """Get current default app for a category"""
        if category not in self.mime_types:
            return None
        
        # Use the first MIME type as representative
        mime_type = self.mime_types[category][0]
        command = f"xdg-mime query default '{mime_type}'"
        success, stdout, stderr = self.run_command(command)
        
        if success and stdout:
            return stdout.strip()
        return None
    
    def list_available_apps(self, category):
        """List available apps for a category"""
        if category not in self.mime_types:
            return []
        
        # Get all desktop files from standard locations
        desktop_dirs = [
            os.path.expanduser("~/.local/share/applications"),
            "/usr/share/applications",
            "/usr/local/share/applications"
        ]
        
        apps = []
        for desktop_dir in desktop_dirs:
            if os.path.exists(desktop_dir):
                for file in os.listdir(desktop_dir):
                    if file.endswith('.desktop'):
                        apps.append(file)
        
        return sorted(list(set(apps)))
    
    def test_setting(self, category="web", app="microsoft-edge-dev.desktop"):
        """Test setting a default app"""
        print(f"Testing default app setting...")
        print(f"Category: {category}")
        print(f"App: {app}")
        print("-" * 50)
        
        # Check current default
        current = self.get_current_default(category)
        print(f"Current default: {current}")
        
        # Set new default
        success = self.set_default_app(category, app)
        
        # Check new default
        new_default = self.get_current_default(category)
        print(f"New default: {new_default}")
        
        return success

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 set_default_apps.py <category> <desktop_file>")
        print("Categories: web, mail, calendar, music, video, photos, text_editor, file_manager, terminal")
        print("Example: python3 set_default_apps.py web microsoft-edge-dev.desktop")
        print("\nOr use --test to run a test:")
        print("python3 set_default_apps.py --test")
        return
    
    setter = DefaultAppSetter()
    
    if sys.argv[1] == "--test":
        setter.test_setting()
    elif len(sys.argv) >= 3:
        category = sys.argv[1]
        desktop_file = sys.argv[2]
        setter.set_default_app(category, desktop_file)
    else:
        print("Error: Missing arguments")
        print("Usage: python3 set_default_apps.py <category> <desktop_file>")

if __name__ == "__main__":
    main() 