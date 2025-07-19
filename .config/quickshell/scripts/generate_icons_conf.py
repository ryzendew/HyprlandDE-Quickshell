#!/usr/bin/env python3
import os
import glob
from pathlib import Path

def generate_icons_config():
    """Generate a config file listing all available icons in the assets/icons directory."""
    
    # Get the home directory
    home_dir = os.path.expanduser("~")
    
    # Define paths
    icons_dir = os.path.join(home_dir, ".config/quickshell/assets/icons")
    config_dir = os.path.join(home_dir, ".local/state/Quickshell/Icons")
    config_file = os.path.join(config_dir, "icons.conf")
    
    # Create config directory if it doesn't exist
    os.makedirs(config_dir, exist_ok=True)
    
    # Supported icon file extensions
    icon_extensions = ["*.svg", "*.png", "*.jpg", "*.jpeg", "*.gif"]
    
    # Find all icon files
    icons = []
    for extension in icon_extensions:
        pattern = os.path.join(icons_dir, extension)
        icons.extend(glob.glob(pattern))
    
    # Extract just the filenames and sort them
    icon_names = [os.path.basename(icon) for icon in icons]
    icon_names.sort()
    
    # Write to config file
    with open(config_file, 'w') as f:
        for icon_name in icon_names:
            f.write(f"{icon_name}\n")
    
    print(f"Generated icons config with {len(icon_names)} icons")
    print(f"Config file: {config_file}")
    
    # Print first few icons as preview
    print("\nFirst 10 icons:")
    for icon in icon_names[:10]:
        print(f"  {icon}")
    
    if len(icon_names) > 10:
        print(f"  ... and {len(icon_names) - 10} more")

if __name__ == "__main__":
    generate_icons_config() 