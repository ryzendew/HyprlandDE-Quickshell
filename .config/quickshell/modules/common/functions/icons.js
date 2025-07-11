const substitutions = {
    "code-url-handler": "visual-studio-code",
    "Code": "visual-studio-code",
    "GitHub Desktop": "github-desktop",
    "Minecraft* 1.20.1": "minecraft",
    "gnome-tweaks": "org.gnome.tweaks",
    "pavucontrol-qt": "pavucontrol",
    "wps": "wps-office2019-kprometheus",
    "wpsoffice": "wps-office2019-kprometheus",
    "footclient": "foot",
    "zen": "zen-browser",
    "better-control": "settings",
    "better_control.py": "settings",
    "ptyxis": () => {
        const homeDir = StandardPaths.writableLocation(StandardPaths.HomeLocation);
        return `${homeDir}/.local/share/icons/scalable/apps/org.gnome.Ptyxis.svg`;
    },
    "AffinityPhoto.desktop": () => {
        const homeDir = StandardPaths.writableLocation(StandardPaths.HomeLocation);
        return `${homeDir}/.local/share/icons/AffinityPhoto.png`;
    },
    "steam-native": () => {
        const homeDir = StandardPaths.writableLocation(StandardPaths.HomeLocation);
        return `${homeDir}/.local/share/icons/scalable/apps/steam.svg`;
    },
    "lutris": () => {
        const homeDir = StandardPaths.writableLocation(StandardPaths.HomeLocation);
        return `${homeDir}/.local/share/icons/scalable/apps/lutris.svg`;
    },
    "com.blackmagicdesign.resolve.desktop": () => {
        const homeDir = StandardPaths.writableLocation(StandardPaths.HomeLocation);
        return `${homeDir}/.local/share/icons/scalable/apps/resolve.svg`;
    },
    "cider": () => {
        const homeDir = StandardPaths.writableLocation(StandardPaths.HomeLocation);
        return `${homeDir}/.local/share/icons/scalable/apps/cider.svg`;
    },
    "vesktop": () => {
        const homeDir = StandardPaths.writableLocation(StandardPaths.HomeLocation);
        return `${homeDir}/.local/share/icons/scalable/apps/vesktop.svg`;
    },
    "obs": () => {
        const configDir = StandardPaths.writableLocation(StandardPaths.ConfigLocation);
        return `${configDir}/quickshell/assets/icons/obs.svg`;
    },
    "heroic": () => {
        const homeDir = StandardPaths.writableLocation(StandardPaths.HomeLocation);
        return `${homeDir}/.local/share/icons/scalable/apps/heroic.svg`;
    },
    "microsoft-edge-dev": () => {
        const homeDir = StandardPaths.writableLocation(StandardPaths.HomeLocation);
        return `${homeDir}/.local/share/icons/scalable/apps/microsoft-edge-dev.svg`;
    },
    "org.gnome.Nautilus": () => {
        const homeDir = StandardPaths.writableLocation(StandardPaths.HomeLocation);
        return `${homeDir}/.local/share/icons/scalable/apps/nautilus.svg`;
    },
    "": "image-missing"
}

const regexSubstitutions = [
    {
        "regex": "/^steam_app_(\\d+)$/",
        "replace": "steam_icon_$1"
    },
    {
        "regex": "/Minecraft.*$/",
        "replace": "minecraft"
    }
]

function iconExists(iconName) {
    return false; // TODO: Make this work without Gtk
}

function substitute(str) {
    // Normal substitutions
    if (substitutions[str]) {
        // If it's a function, call it to get dynamic path
        if (typeof substitutions[str] === 'function') {
            return substitutions[str]();
        }
        return substitutions[str];
    }

    // Regex substitutions
    for (let i = 0; i < regexSubstitutions.length; i++) {
        const substitution = regexSubstitutions[i];
        const replacedName = str.replace(
            substitution.regex,
            substitution.replace,
        );
        if (replacedName != str) return replacedName;
    }

    // Guess: convert to kebab case
    if (!iconExists(str)) str = str.toLowerCase().replace(/\s+/g, "-");

    // Original string
    return str;
}

function noKnowledgeIconGuess(str) {
    if (!str) return "image-missing";

    // Normal substitutions
    if (substitutions[str]) {
        // If it's a function, call it to get dynamic path
        if (typeof substitutions[str] === 'function') {
            return substitutions[str]();
        }
        return substitutions[str];
    }

    // Regex substitutions
    for (let i = 0; i < regexSubstitutions.length; i++) {
        const substitution = regexSubstitutions[i];
        const replacedName = str.replace(
            substitution.regex,
            substitution.replace,
        );
        if (replacedName != str) return replacedName;
    }

    // Guess: convert to kebab case if it's not reverse domain name notation
    if (!str.includes('.')) {
        str = str.toLowerCase().replace(/\s+/g, "-");
    }

    // Original string
    return str;
}
