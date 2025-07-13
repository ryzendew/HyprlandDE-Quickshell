pragma Singleton

import "root:/modules/common"
import "root:/modules/common/functions/fuzzysort.js" as Fuzzy
import "root:/modules/common/functions/levendist.js" as Levendist
import Quickshell
import Quickshell.Io

/**
 * - Eases fuzzy searching for applications by name
 * - Guesses icon name for window class name
 */
Singleton {
    id: root
    property bool sloppySearch: ConfigOptions?.search.sloppy ?? false
    property real scoreThreshold: 0.2
    property var substitutions: ({
        "code-url-handler": "visual-studio-code",
        "Code": "visual-studio-code",
        "gnome-tweaks": "org.gnome.tweaks",
        "pavucontrol-qt": "pavucontrol",
        "wps": "wps-office2019-kprometheus",
        "wpsoffice": "wps-office2019-kprometheus",
        "footclient": "foot",
        "zen": "zen-browser",
        "better-control": "settings",
        "better_control.py": "settings",
    })
    property var regexSubstitutions: [
        {
            "regex": /^steam_app_(\\d+)$/,
            "replace": "steam_icon_$1"
        },
        {
            "regex": /Minecraft.*/,
            "replace": "minecraft"
        },
        {
            "regex": /.*polkit.*/,
            "replace": "system-lock-screen"
        },
        {
            "regex": /gcr.prompter/,
            "replace": "system-lock-screen"
        }
    ]

    readonly property list<DesktopEntry> list: Array.from(DesktopEntries.applications.values)
        .sort((a, b) => a.name.localeCompare(b.name))

    readonly property var preppedNames: list.map(a => ({
                name: Fuzzy.prepare(`${a.name} `),
                entry: a
            }))

    // Signal to notify when applications are refreshed
    signal applicationsRefreshed()



    // Function to refresh the desktop database
    function refresh() {
        return new Promise((resolve, reject) => {
            // For now, just trigger the signal to update the UI
            // The actual desktop database update would need to be done externally
        // console.log("[APPSEARCH] Refreshing application list...")
            root.applicationsRefreshed()
            
            // Small delay to ensure UI updates
            Qt.callLater(() => {
                resolve()
            })
        })
    }

    function fuzzyQuery(search: string): var { // Idk why list<DesktopEntry> doesn't work
        if (root.sloppySearch) {
            const results = list.map(obj => ({
                entry: obj,
                score: Levendist.computeScore(obj.name.toLowerCase(), search.toLowerCase())
            })).filter(item => item.score > root.scoreThreshold)
                .sort((a, b) => b.score - a.score)
            return results
                .map(item => item.entry)
        }

        return Fuzzy.go(search, preppedNames, {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry
        });
    }

    function iconExists(iconName) {
        var iconPath = Quickshell.iconPath(iconName, true);
        var exists = (iconPath.length > 0) && !iconName.includes("image-missing");
        return exists;
    }

    function guessIcon(str) {
        if (!str || str.length == 0) {
            return "settings";
        }

        // Normal substitutions
        if (substitutions[str]) {
            return substitutions[str];
        }

        // Regex substitutions
        for (let i = 0; i < regexSubstitutions.length; i++) {
            const substitution = regexSubstitutions[i];
            const replacedName = str.replace(
                substitution.regex,
                substitution.replace,
            );
            if (replacedName != str) {
                return replacedName;
            }
        }

        // If it gets detected normally, no need to guess
        if (iconExists(str)) {
            return str;
        }

        let guessStr = str;
        // Guess: Take only app name of reverse domain name notation
        guessStr = str.split('.').slice(-1)[0].toLowerCase();
        if (iconExists(guessStr)) {
            return guessStr;
        }
        
        // Guess: normalize to kebab case
        guessStr = str.toLowerCase().replace(/\s+/g, "-");
        if (iconExists(guessStr)) {
            return guessStr;
        }
        
        // Guess: First fuzzy desktop entry match
        const searchResults = root.fuzzyQuery(str);
        if (searchResults.length > 0) {
            const firstEntry = searchResults[0];
            guessStr = firstEntry.icon;
            if (iconExists(guessStr)) {
                return guessStr;
            }
        }

        // Give up: use settings cog as default
        return "settings";
    }
}
