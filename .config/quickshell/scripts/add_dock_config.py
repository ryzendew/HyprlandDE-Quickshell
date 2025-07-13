#!/usr/bin/env python3
import json
import os

# Path to the config file
config_path = os.path.expanduser("~/.config/quickshell/config.json")

# Default dock properties from ConfigOptions.qml
default_dock_config = {
    "height": 60,
    "hoverRegionHeight": 3,
    "pinnedOnStartup": False,
    "hoverToReveal": False,
    "enable": True,
    "radius": 12,
    "iconSize": 48,
    "spacing": 8,
    "autoHide": False,
    "hideDelay": 200,
    "showDelay": 50,
    "showPreviews": True,
    "showLabels": False,
    "transparency": 0.9,
    "pinnedApps": [
        "microsoft-edge-dev",
        "org.gnome.Nautilus",
        "vesktop",
        "cider",
        "steam-native",
        "lutris",
        "heroic",
        "obs",
        "org.gnome.Ptyxis"
    ]
}

def main():
    # Read existing config
    if os.path.exists(config_path):
        with open(config_path, 'r') as f:
            config = json.load(f)
    else:
        config = {}
    
    # Ensure dock section exists
    if "dock" not in config:
        config["dock"] = {}
    
    # Add missing properties
    added_properties = []
    for key, value in default_dock_config.items():
        if key not in config["dock"]:
            config["dock"][key] = value
            added_properties.append(key)
    
    # Write back to config file
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2)
    
    if added_properties:
        print(f"Added missing dock properties: {', '.join(added_properties)}")
        print("Icon size changes should now work in the settings!")
    else:
        print("All dock properties already exist in config.json")

if __name__ == "__main__":
    main() 