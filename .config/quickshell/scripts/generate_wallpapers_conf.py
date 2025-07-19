#!/usr/bin/env python3
import os
import glob
from pathlib import Path

def generate_wallpapers_conf():
    """Generate Wallpapers.conf file with all wallpapers from ~/Pictures/Wallpapers/"""
    
    # Paths - use XDG state directory
    wallpaper_dir = os.path.expanduser("~/Pictures/Wallpapers/")
    
    # Use ~ for home directory
    conf_file = os.path.expanduser("~/.local/state/Quickshell/Wallpapers/wallpapers.conf")
    
    # Ensure the directory exists
    os.makedirs(os.path.dirname(conf_file), exist_ok=True)
    
    # Find all image files
    image_extensions = ['*.jpg', '*.jpeg', '*.png', '*.bmp', '*.webp', '*.svg']
    wallpapers = []
    
    for ext in image_extensions:
        pattern = os.path.join(wallpaper_dir, ext)
        wallpapers.extend(glob.glob(pattern))
        # Also check for uppercase extensions
        pattern = os.path.join(wallpaper_dir, ext.upper())
        wallpapers.extend(glob.glob(pattern))
    
    # Sort wallpapers alphabetically
    wallpapers.sort()
    
    # Write to config file
    with open(conf_file, 'w') as f:
        f.write("# Wallpapers configuration file\n")
        f.write("# Generated automatically from ~/Pictures/Wallpapers/\n")
        f.write(f"# Total wallpapers found: {len(wallpapers)}\n\n")
        
        for wallpaper in wallpapers:
            f.write(f"{wallpaper}\n")
    
    print(f"Generated {conf_file} with {len(wallpapers)} wallpapers")
    print("First 5 wallpapers:")
    for wallpaper in wallpapers[:5]:
        print(f"  {os.path.basename(wallpaper)}")
    
    return len(wallpapers)

if __name__ == "__main__":
    count = generate_wallpapers_conf()
    print(f"\nTotal wallpapers found: {count}") 