#!/usr/bin/env python3
import os
import json
import configparser
from glob import glob

# Categories and common desktop file keywords
CATEGORIES = {
    "web": ["WebBrowser", "Network;WebBrowser;"],
    "mail": ["Email", "EmailClient", "Network;Email;"],
    "calendar": ["Calendar"],
    "music": ["Audio", "Music"],
    "video": ["Video", "Player"],
    "photos": ["Graphics", "ImageViewer", "Photography"],
    "text_editor": ["TextEditor", "Utility;TextEditor;"],
    "file_manager": ["FileManager", "System;FileTools;FileManager;"]
}

# Where to look for .desktop files
DESKTOP_DIRS = [
    "/usr/share/applications",
    os.path.expanduser("~/.local/share/applications")
]

def parse_desktop_file(path):
    cp = configparser.ConfigParser(interpolation=None)
    cp.read(path, encoding="utf-8")
    if "Desktop Entry" not in cp:
        return None
    entry = cp["Desktop Entry"]
    if entry.get("NoDisplay", "false").lower() == "true":
        return None
    return {
        "name": entry.get("Name", os.path.basename(path)),
        "icon": entry.get("Icon", ""),
        "exec": entry.get("Exec", ""),
        "categories": entry.get("Categories", "")
    }

def detect_apps():
    found = {k: [] for k in CATEGORIES}
    seen_execs = set()
    for ddir in DESKTOP_DIRS:
        for f in glob(os.path.join(ddir, "*.desktop")):
            app = parse_desktop_file(f)
            if not app:
                continue
            # Avoid duplicates by exec
            exec_cmd = app["exec"].split()[0]
            if exec_cmd in seen_execs:
                continue
            seen_execs.add(exec_cmd)
            for cat, keywords in CATEGORIES.items():
                for kw in keywords:
                    if kw in app["categories"]:
                        found[cat].append({
                            "name": app["name"],
                            "icon": app["icon"],
                            "exec": app["exec"]
                        })
                        break
    return found

def main():
    apps = detect_apps()
    with open("detected_default_apps.json", "w", encoding="utf-8") as f:
        json.dump(apps, f, indent=2, ensure_ascii=False)

if __name__ == "__main__":
    main() 