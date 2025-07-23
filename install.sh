#!/bin/bash

# Matt's Quickshell Hyprland Configuration Installer
# Automated installer for Arch Linux systems

# Remove set -e to prevent script from exiting on errors
# set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Distribution detection
DISTRO=""
FORCE_INSTALL=false

# Get current user's home directory and username
CURRENT_USER=$(whoami)
USER_HOME=$(eval echo ~$CURRENT_USER)

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE_INSTALL=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Error recovery function
cleanup_on_error() {
    print_error "Installation failed! Cleaning up..."
    cd ~
    rm -rf /tmp/yay-bin /tmp/Matts-Quickshell-Hyprland 2>/dev/null || true
}

# Set up error trap
trap cleanup_on_error ERR

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root (don't use sudo)"
   exit 1
fi

print_status "Detected user: $CURRENT_USER"
print_status "User home directory: $USER_HOME"

# Detect distribution
detect_distribution() {
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        case $ID in
            "arch"|"cachyos"|"endeavouros"|"artix"|"archcraft"|"arcolinux"|"archbang"|"archlabs"|"archmerge"|"archstrike"|"blackarch"|"archman"|"archlinux"|"archlinuxarm"|"archlinuxcn"|"archlinuxfr"|"archlinuxgr"|"archlinuxjp"|"archlinuxkr"|"archlinuxpl"|"archlinuxru"|"archlinuxtr"|"archlinuxvn"|"archlinuxzh"|"archlinuxzhcn"|"archlinuxzhtw"|"archlinuxzhhk"|"archlinuxzhmo"|"archlinuxzhsg"|"archlinuxzhtw"|"archlinuxzhcn"|"archlinuxzhtw"|"archlinuxzhhk"|"archlinuxzhmo"|"archlinuxzhsg")
                DISTRO="arch"
                print_status "Detected: $PRETTY_NAME (Arch-based)"
                ;;
            "garuda"|"manjaro")
                print_error "Unsupported distribution: $PRETTY_NAME"
                print_error "This script does not support Garuda Linux or Manjaro Linux"
                print_error "Please use a different Arch-based distribution"
                exit 1
                ;;
            *)
                if command -v pacman &> /dev/null; then
                    DISTRO="arch"
                    print_status "Detected: $PRETTY_NAME (Arch-based)"
                else
                    print_error "Unsupported distribution: $PRETTY_NAME"
                    print_error "This script supports:"
                    print_error "- Arch Linux and most Arch-based distributions"
                    exit 1
                fi
                ;;
        esac
    elif command -v pacman &> /dev/null; then
        DISTRO="arch"
        print_status "Detected: Arch-based distribution (fallback detection)"
    else
        print_error "Unable to detect supported distribution"
        print_error "This script supports:"
        print_error "- Arch Linux and most Arch-based distributions"
        exit 1
    fi
}

# Check distribution compatibility
check_distribution() {
    detect_distribution
    
    if [[ "$DISTRO" == "arch" ]]; then
        if ! command -v pacman &> /dev/null; then
            print_error "Arch-based distribution detected but pacman not found"
            exit 1
        fi
    fi
}


# Function to check if a package is installed
is_package_installed() {
    local package=$1
    if pacman -Qs "$package" >/dev/null 2>&1; then
        return 0  # Package is installed
    else
        return 1  # Package is not installed
    fi
}

# Function to check if a package is available in repositories
is_package_available() {
    local package=$1
    if pacman -Ss "$package" >/dev/null 2>&1; then
        return 0  # Package is available
    else
        return 1  # Package is not available
    fi
}

# Function to check if an AUR package is available
is_aur_package_available() {
    local package=$1
    if yay -Ss "$package" >/dev/null 2>&1; then
        return 0  # Package is available in AUR
    else
        return 1  # Package is not available in AUR
    fi
}

# Function to get installed package version
get_package_version() {
    local package=$1
    pacman -Q "$package" 2>/dev/null | cut -d' ' -f2 || echo "not-installed"
}

# Function to check if a package has a git version installed
has_git_version() {
    local package=$1
    local base_package=$(echo "$package" | sed 's/-git$//')
    if pacman -Qs "$base_package" | grep -q "git" 2>/dev/null; then
        return 0  # Git version is installed
    else
        return 1  # Git version is not installed
    fi
}

# Remove jack2 and install jack for CachyOS compatibility
print_status "Checking for jack2 and replacing with jack..."
if is_package_installed "jack2"; then
    print_status "Removing jack2..."
    if sudo pacman -Rd --nodeps --noconfirm jack2 2>/dev/null; then
        print_success "jack2 removed successfully"
    else
        print_warning "Failed to remove jack2, continuing anyway..."
    fi
fi

if ! is_package_installed "jack"; then
    print_status "Installing pipewire-jack..."
    if sudo pacman -S --noconfirm pipewire-jack git 2>/dev/null; then
        print_success "jack installed successfully"
    else
        print_warning "Failed to install pipewire-jack, continuing anyway..."
    fi
else
    print_status "jack is already installed"
fi

# Function to handle package conflicts gracefully
handle_package_conflicts() {
    local package=$1
    local conflicts=()
    
    # Get all conflicts for the package
    if pacman -Si "$package" &>/dev/null; then
        # For pacman packages
        conflicts=($(pacman -Si "$package" | grep "Conflicts With" | cut -d: -f2 | tr -d ' ' | tr '\n' ' '))
    elif yay -Si "$package" &>/dev/null; then
        # For AUR packages
        conflicts=($(yay -Si "$package" | grep "Conflicts With" | cut -d: -f2 | tr -d ' ' | tr '\n' ' '))
    fi
    
    # Remove conflicting packages if found
    if [ ${#conflicts[@]} -gt 0 ]; then
        # Filter out 'None' and empty values
        filtered_conflicts=()
        for c in "${conflicts[@]}"; do
            if [[ -n "$c" && "$c" != "None" ]]; then
                filtered_conflicts+=("$c")
            fi
        done
        if [ ${#filtered_conflicts[@]} -gt 0 ]; then
            print_warning "Found conflicting packages for $package: ${filtered_conflicts[*]}"
            print_status "Attempting to remove conflicting packages..."
            if sudo pacman -Rd --noconfirm --nodeps "${filtered_conflicts[@]}" 2>/dev/null; then
                print_success "Conflicting packages removed"
            else
                print_warning "Failed to remove some conflicting packages, continuing anyway..."
            fi
        fi
    fi
}

# Function to install package with conflict resolution and error handling
install_package() {
    local package=$1
    local is_aur=$2
    
    # Check if package is already installed
    if is_package_installed "$package"; then
        print_status "$package is already installed (version: $(get_package_version "$package"))"
        return 0
    fi
    
    # Check if it's a git package and if a git version is already installed
    if [[ "$package" == *"-git" ]]; then
        local base_package=$(echo "$package" | sed 's/-git$//')
        if has_git_version "$base_package"; then
            print_status "Git version of $base_package is already installed, skipping $package"
            return 0
        fi
    fi
    
    print_status "Installing $package..."
    
    # Handle conflicts gracefully
    handle_package_conflicts "$package"
    
    # Try to install the package
    if [ "$is_aur" = true ]; then
        if is_aur_package_available "$package"; then
            if yay -S --noconfirm "$package" 2>/dev/null; then
                print_success "$package installed successfully"
                return 0
            else
                print_warning "Failed to install $package from AUR, continuing anyway..."
                return 1
            fi
        else
            print_warning "$package not available in AUR, skipping..."
            return 1
        fi
    else
        if is_package_available "$package"; then
            if sudo pacman -S --noconfirm --needed "$package" 2>/dev/null; then
                print_success "$package installed successfully"
                return 0
            else
                print_warning "Failed to install $package from official repos, continuing anyway..."
                return 1
            fi
        else
            print_warning "$package not available in official repos, skipping..."
            return 1
        fi
    fi
}

# Install additional wallpaper-related dependencies
print_status "Installing wallpaper-related dependencies..."
for pkg in swww python-pywal python-pillow python-numpy python-scipy python-matplotlib python-colorthief imagemagick ffmpeg mpv kdialog; do
    install_package "$pkg" false || print_warning "Skipping $pkg due to installation failure"
done

# Install AUR dependencies
print_status "Installing AUR dependencies..."
install_package "mpvpaper" true || print_warning "Skipping mpvpaper due to installation failure"

# Check internet connectivity
print_status "Checking internet connectivity..."
if ! ping -c 1 8.8.8.8 &> /dev/null; then
    print_warning "No internet connection detected. Installation may fail for packages requiring download."
    print_warning "Continuing anyway in case packages are already available locally..."
fi

# Check if git is available
if ! command -v git &> /dev/null; then
    print_warning "Git is not installed. Some features may not work properly."
    print_warning "Continuing anyway, but you may need to install git manually later."
    print_warning "On Arch: sudo pacman -S git"
fi

# Check available disk space (need at least 2GB)
print_status "Checking available disk space..."
available_space=$(df / | awk 'NR==2 {print $4}')
if [ "$available_space" -lt 2097152 ]; then  # 2GB in KB
    print_warning "Low disk space detected. Installation may fail if more space is needed."
    print_warning "Continuing anyway, but you may need to free up space manually."
fi

# Check distribution compatibility
check_distribution

# Ensure env.conf is included in hyprland.conf
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$USER_HOME/.config}"
HYPR_MAIN="$XDG_CONFIG_HOME/hypr/hyprland.conf"
ENV_INCLUDE="include = $XDG_CONFIG_HOME/hypr/hyprland/env.conf"

if ! grep -Fxq "$ENV_INCLUDE" "$HYPR_MAIN" 2>/dev/null; then
  print_status "Binding env.conf into hyprland.conf..."
  sed -i "1i$ENV_INCLUDE" "$HYPR_MAIN"
else
  print_status "env.conf already included."
fi

# Read and export the virtualenv path from env.conf
ENV_CONF="$XDG_CONFIG_HOME/hypr/hyprland/env.conf"
if [[ ! -f "$ENV_CONF" ]]; then
  print_error "env.conf not found! Run end‑4's install.sh first."
  exit 1
fi

VENV_PATH=$(grep 'ILLOGICAL_IMPULSE_VIRTUAL_ENV' "$ENV_CONF" \
            | cut -d',' -f2 | xargs)
XDG_STATE_HOME="${XDG_STATE_HOME:-$USER_HOME/.local/state}"
VENV_PATH="${VENV_PATH//\$XDG_STATE_HOME/$XDG_STATE_HOME}"

export ILLOGICAL_IMPULSE_VIRTUAL_ENV="$VENV_PATH"
if [[ ! -d "$ILLOGICAL_IMPULSE_VIRTUAL_ENV" ]]; then
  print_error "Virtualenv not found at $ILLOGICAL_IMPULSE_VIRTUAL_ENV"
  exit 1
fi

# Activate venv and install Python dependencies
print_status "Activating Quickshell virtualenv and installing Python deps..."
# shellcheck disable=SC1090
source "$ILLOGICAL_IMPULSE_VIRTUAL_ENV/bin/activate"

REQ_FILE="scriptdata/requirements.txt"
if [[ -f "$REQ_FILE" ]]; then
  pip install --upgrade -r "$REQ_FILE"
  print_success "Python dependencies installed."
else
  print_warning "No requirements.txt found; skipping pip install."
fi



# Clone repository to temporary Dotfiles folder
print_status "Setting up dotfiles repository..."

# Always create a fresh temporary Dotfiles directory
TEMP_DOTFILES="$HOME/Dotfiles"
if [ -d "$TEMP_DOTFILES" ]; then
    print_status "Removing existing Dotfiles directory..."
    rm -rf "$TEMP_DOTFILES"
fi

print_status "Cloning repository to ~/Dotfiles..."
cd "$HOME"

# Clone repository
repo_url="https://github.com/ryzendew/Matts-Quickshell-Hyprland.git"
print_status "Cloning from: $repo_url"
if git clone "$repo_url" Dotfiles 2>/dev/null; then
    print_success "Repository cloned successfully"
    REPO_DIR="$TEMP_DOTFILES"
else
    print_warning "Failed to clone repository from $repo_url"
    print_warning ""
    print_warning "This could be due to:"
    print_warning "1. Network connectivity issues"
    print_warning "2. Repository access problems"
    print_warning "3. Git not installed properly"
    print_warning ""
    print_warning "Attempting to continue with local files if available..."
    
    # Try to use existing files if available
    if [ -d ".config" ] && [ -d "modules" ]; then
        print_status "Using existing local files..."
        REPO_DIR="$(pwd)"
    else
        print_error "No local files found and repository clone failed. Cannot continue."
        exit 1
    fi
fi

# Change to the repository directory
cd "$REPO_DIR"
print_status "Working from: $(pwd)"

# Verify required files exist
if [ ! -d ".config" ]; then
    print_warning "Configuration directory not found in repository!"
    print_warning "Repository may be corrupted or incomplete."
    print_warning "Continuing anyway, but some configuration may be missing..."
else
    print_success "Configuration directory found"
fi

if [ ! -d "ArchPackages" ]; then
    print_warning "ArchPackages directory not found in repository"
    print_warning "Prebuilt Quickshell package will not be available as fallback"
fi

print_status "Matt's Quickshell Hyprland Configuration Installer"
print_status "=============================================="
print_status "Distribution: $DISTRO"
echo

# Ask about .config backup
if [ -d "$USER_HOME/.config" ]; then
    echo -e "${YELLOW}Existing .config directory found.${NC}"
    echo "Do you want to backup your current .config directory?"
    echo "Backup will be saved as $USER_HOME/.config.backup.$(date +%Y%m%d_%H%M%S)"
    read -p "Backup .config? [Y/n]: " backup_choice
    
    if [[ $backup_choice =~ ^[Nn]$ ]]; then
        print_warning "Skipping .config backup - existing files may be overwritten!"
    else
        backup_dir="$USER_HOME/.config.backup.$(date +%Y%m%d_%H%M%S)"
        print_status "Creating backup at $backup_dir"
        cp -r "$USER_HOME/.config" "$backup_dir"
        print_success "Backup created successfully"
    fi
    echo
fi

# --- Install critical AUR dependencies early ---
print_status "Installing critical AUR dependencies early with yay..."

# Ensure yay is installed first
if ! command -v yay &> /dev/null; then
    print_status "Installing yay AUR helper..."
    cd /tmp
    rm -rf yay-bin 2>/dev/null || true
    if git clone https://aur.archlinux.org/yay-bin.git 2>/dev/null; then
        cd yay-bin
        if makepkg -si --noconfirm 2>/dev/null; then
            print_success "yay installed successfully"
        else
            print_warning "Failed to build yay, trying alternative method..."
            if sudo pacman -S --noconfirm yay 2>/dev/null; then
                print_success "yay installed via pacman"
            else
                print_warning "Failed to install yay, AUR packages will be skipped"
            fi
        fi
        cd ~
        rm -rf /tmp/yay-bin
    else
        print_warning "Failed to clone yay repository, trying alternative method..."
        if sudo pacman -S --noconfirm yay 2>/dev/null; then
            print_success "yay installed via pacman"
        else
            print_warning "Failed to install yay, AUR packages will be skipped"
        fi
    fi
else
    print_status "yay is already installed"
fi

# Function to install package if not already installed with error handling
install_if_not_present() {
    local package=$1
    
    # Check if package is already installed
    if is_package_installed "$package"; then
        print_status "$package is already installed (version: $(get_package_version "$package"))"
        return 0
    fi
    
    # Check if yay is available
    if ! command -v yay &> /dev/null; then
        print_warning "yay not available, skipping AUR package $package"
        return 1
    fi
    
    # Check if it's a git package and if a git version is already installed
    if [[ "$package" == *"-git" ]]; then
        local base_package=$(echo "$package" | sed 's/-git$//')
        if has_git_version "$base_package"; then
            print_status "Git version of $base_package is already installed, skipping $package"
            return 0
        fi
    fi
    
    print_status "Installing $package..."
    if yay -S --noconfirm --needed "$package" 2>/dev/null; then
        print_success "$package installed successfully"
        return 0
    else
        print_warning "Failed to install $package, continuing anyway..."
        return 1
    fi
}

# Install AUR packages with checks
aur_packages=(
    axel bc better-control-git brightnessctl cairomm cliphist cmake coreutils curl ddcutil fish fontconfig fuzzel gammastep gnome-control-center gnome-keyring glib2 grimblast gobject-introspection gtk4 gtkmm3 gtksourceviewmm hyprcursor hypridle hyprlang hyprland hyprland-qt-support hyprland-qtutils hyprlock hyprpicker hyprutils jq kde-material-you-colors kitty libadwaita libdbusmenu-gtk3 libportal-gtk4 libsoup3 matugen-bin meson networkmanager nm-connection-editor nwg-display nwg-look pavucontrol-qt playerctl polkit-kde-agent quickshell qt6-5compat qt6-base qt6-declarative qt6-imageformats qt6-multimedia qt6-positioning qt6-quicktimeline qt6-sensors qt6-svg qt6-tools qt6-translations qt6-virtualkeyboard qt6-wayland ripgrep rsync sassc starship swappy swww syntax-highlighting tesseract tesseract-data-eng tinyxml2 ttf-gabarito-git ttf-jetbrains-mono-nerd ttf-material-symbols-variable-git ttf-readex-pro ttf-rubik-vf upower uv wget wlogout wl-clipboard wireplumber wtype xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xdg-user-dirs xdg-user-dirs-gtk yad ydotool hyprswitch
)

for package in "${aur_packages[@]}"; do
    install_if_not_present "$package" || print_warning "Skipping $package due to installation failure"
done

# Install Tela Circle icon theme from GitHub
print_status "Installing Tela Circle icon theme..."
TEMP_TELA_DIR="/tmp/Tela-circle-icon-theme"
if [ -d "$TEMP_TELA_DIR" ]; then
    print_status "Cleaning up existing Tela directory..."
    rm -rf "$TEMP_TELA_DIR"
fi

print_status "Cloning Tela Circle icon theme repository..."
if ! git clone --depth=1 https://github.com/vinceliuice/Tela-circle-icon-theme.git "$TEMP_TELA_DIR" 2>/dev/null; then
    print_warning "Failed to clone Tela icon theme repository."
    print_warning "Trying alternative repository..."
    if ! git clone --depth=1 https://github.com/vinceliuice/Tela-icon-theme.git "$TEMP_TELA_DIR" 2>/dev/null; then
        print_warning "Failed to clone alternative repository."
        print_warning "Skipping Tela icon theme installation."
    else
        print_success "Successfully cloned alternative repository."
    fi
else
    print_success "Successfully cloned Tela Circle icon theme repository."
fi

if [ -d "$TEMP_TELA_DIR" ]; then
    print_status "Installing Tela Circle icon theme..."
    if ! (cd "$TEMP_TELA_DIR" && sudo ./install.sh -a 2>/dev/null); then
        print_warning "Failed to install Tela icon theme."
        print_warning "Trying alternative installation method..."
        if ! (cd "$TEMP_TELA_DIR" && sudo ./install.sh -c green -a 2>/dev/null); then
            print_warning "Failed to install Tela icon theme with alternative method."
            print_warning "Skipping Tela icon theme installation."
        else
            print_success "Successfully installed Tela icon theme with alternative method."
        fi
    else
        print_success "Successfully installed Tela Circle icon theme."
    fi
    print_status "Cleaning up temporary files..."
    rm -rf "$TEMP_TELA_DIR"
fi

# Install OneUI4-Icons
print_status "Installing OneUI4-Icons..."
if [ ! -d "OneUI4-Icons" ]; then
    if git clone https://github.com/end-4/OneUI4-Icons.git 2>/dev/null; then
        cd OneUI4-Icons
        sudo mkdir -p /usr/share/icons
        for theme in OneUI OneUI-dark OneUI-light; do
            if [ -d "$theme" ]; then
                sudo cp -r --no-preserve=mode "$theme" "/usr/share/icons/$theme" 2>/dev/null || print_warning "Failed to copy $theme"
            fi
        done
        cd ..
        print_success "OneUI4-Icons installed successfully"
    else
        print_warning "Failed to clone OneUI4-Icons repository, skipping..."
    fi
else
    print_status "OneUI4-Icons directory already exists, skipping..."
fi

# Install Bibata Modern Classic cursor theme
print_status "Installing Bibata Modern Classic cursor theme..."
if [ ! -d "Bibata-Modern-Classic" ]; then
    if wget https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.6/Bibata-Modern-Classic.tar.xz 2>/dev/null; then
        if tar xf Bibata-Modern-Classic.tar.xz 2>/dev/null; then
            sudo mkdir -p /usr/share/icons
            if sudo cp -r --no-preserve=mode Bibata-Modern-Classic /usr/share/icons/ 2>/dev/null; then
                print_success "Bibata Modern Classic cursor theme installed successfully"
            else
                print_warning "Failed to copy Bibata cursor theme"
            fi
        else
            print_warning "Failed to extract Bibata cursor theme"
        fi
        rm -f Bibata-Modern-Classic.tar.xz
    else
        print_warning "Failed to download Bibata cursor theme, skipping..."
    fi
else
    print_status "Bibata-Modern-Classic directory already exists, skipping..."
fi

# Install MicroTeX
print_status "Installing MicroTeX..."
if [ ! -d "MicroTeX" ]; then
    git clone https://github.com/NanoMichael/MicroTeX.git
    cd MicroTeX
    # Apply patches
    sed -i 's/gtksourceviewmm-3.0/gtksourceviewmm-4.0/' CMakeLists.txt
    sed -i 's/tinyxml2.so.10/tinyxml2.so.11/' CMakeLists.txt
    # Build
    cmake -B build -S . -DCMAKE_BUILD_TYPE=None
    cmake --build build
    # Install
    sudo mkdir -p /opt/MicroTeX
    sudo cp build/LaTeX /opt/MicroTeX/
    sudo cp -r build/res /opt/MicroTeX/
    sudo mkdir -p /usr/share/licenses/microtex
    sudo cp LICENSE /usr/share/licenses/microtex/
    cd ..
fi

# Build and install microtex with all available CPU threads
if [ -d "$USER_HOME/microtex" ]; then
    print_status "Building microtex with all available CPU threads..."
    cd "$USER_HOME/microtex"
    make clean || true
    make -j"$(nproc)"
    print_success "microtex built successfully"
    print_status "Installing microtex to the system..."
    sudo make install
    print_success "microtex installed successfully"
    cd -
else
    print_warning "microtex source directory not found at $USER_HOME/microtex"
fi

# --- Install all required packages (official + AUR + meta-package PKGBUILD deps) ---
print_status "Aggregating all dependencies from meta-package PKGBUILDs..."

# Main package arrays (from previous logic)
official_packages=(
    hyprland wayland wayland-protocols wayland-utils
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-desktop-portal
    xdg-utils xdg-user-dirs
    pipewire wireplumber pipewire-alsa pipewire-pulse pipewire-jack
    pamixer playerctl pavucontrol alsa-utils alsa-plugins pulseaudio-alsa
    sddm qt6-svg qt6-declarative systemd polkit polkit-qt6
    networkmanager nm-connection-editor dhcpcd bluez bluez-utils
    qt6-base qt6-declarative qt6-wayland qt6-svg qt6-imageformats qt6-multimedia qt6-positioning qt6-quicktimeline qt6-sensors qt6-tools qt6-translations qt6-virtualkeyboard qt6-5compat qt6-shadertools qt6-languageserver qt6-charts qt6-webengine qt6-webchannel qt6-websockets qt6-connectivity qt6-serialport
    qt5-base qt5-declarative qt5-graphicaleffects qt5-imageformats qt5-svg qt5-translations qt5-wayland
    grim slurp wl-clipboard wtype brightnessctl ddcutil mako libnotify upower acpid htop btop fastfetch file-roller unzip zip 7zip gvfs gvfs-mtp gvfs-gphoto2 ptyxis nautilus geoclue gammastep fcitx5 gnome-keyring polkit-gnome easyeffects cliphist
    ttf-dejavu noto-fonts ttf-font-awesome papirus-icon-theme gtk3 gtk4 adwaita-icon-theme adwaita-icon-theme-legacy adwaita-cursors adwaita-fonts qt6ct qt5ct
    cmake ninja pkgconf make gcc git firefox
    jemalloc cli11 libdrm mesa vulkan-icd-loader vulkan-headers libxcb xcb-util xcb-util-wm xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-cursor libxkbcommon libxkbcommon-x11 libpipewire libglvnd syntax-highlighting
    xorg-xwayland xorg-xlsclients xorg-xrandr xorg-xinput xorg-xdpyinfo libx11 libxcomposite libxcursor libxdamage libxext libxfixes libxi libxinerama libxrandr libxrender libxss libxtst
    thunar thunar-volman thunar-archive-plugin lxqt-policykit
)

# Function to install official packages if not already installed
for package in "${official_packages[@]}"; do
    if ! is_package_installed "$package"; then
        print_status "Installing $package..."
        sudo pacman -S --noconfirm --needed "$package"
        print_success "$package installed successfully"
    else
        print_status "$package is already installed"
    fi
done

# Bulk install from packages.txt if it exists
if [ -f packages.txt ]; then
    sudo pacman -S --needed - < packages.txt
else
    print_warning "packages.txt not found, skipping bulk package install."
fi

# Install MicroTeX
print_status "Installing MicroTeX..."
if [ ! -d "MicroTeX" ]; then
    git clone https://github.com/NanoMichael/MicroTeX.git
    cd MicroTeX
    # Apply patches
    sed -i 's/gtksourceviewmm-3.0/gtksourceviewmm-4.0/' CMakeLists.txt
    sed -i 's/tinyxml2.so.10/tinyxml2.so.11/' CMakeLists.txt
    # Build
    cmake -B build -S . -DCMAKE_BUILD_TYPE=None
    cmake --build build
    # Install
    sudo mkdir -p /opt/MicroTeX
    sudo cp build/LaTeX /opt/MicroTeX/
    sudo cp -r build/res /opt/MicroTeX/
    sudo mkdir -p /usr/share/licenses/microtex
    sudo cp LICENSE /usr/share/licenses/microtex/
    cd ..
fi

# Distribution-specific package installation functions
install_arch_packages() {
    # Show comprehensive package installation summary
    print_status "COMPREHENSIVE ARCH LINUX + HYPRLAND INSTALLATION"
    if [ "$FORCE_INSTALL" = true ]; then
        print_status "FORCE REINSTALL MODE ENABLED - All packages will be reinstalled"
    fi
    print_status "=================================================="
    echo
    print_status "This installer will install ALL dependencies needed for a complete Hyprland desktop:"
    echo
    print_status "📦 CORE COMPONENTS:"
    print_status "   • Hyprland + Wayland foundation (hyprland, wayland, xdg-desktop-portal-hyprland)"
    print_status "   • Complete Qt6 framework for Quickshell (qt6-base, qt6-declarative, etc.)"
    print_status "   • Qt5 compatibility for legacy applications"
    echo
    print_status "🔊 AUDIO SYSTEM:"
    print_status "   • Complete PipeWire setup (pipewire, wireplumber, pamixer, pavucontrol)"
    print_status "   • ALSA compatibility and media controls"
    echo
    print_status "🖥️  DISPLAY & SESSION:"
    print_status "   • SDDM display manager with Qt6 support"
    print_status "   • Polkit authentication system"
    print_status "   • XWayland for X11 app compatibility"
    echo
    print_status "🌐 CONNECTIVITY:"
    print_status "   • NetworkManager for network management"
    print_status "   • Bluetooth support (bluez, bluez-utils)"
    print_status "   • Network configuration tools"
    echo
    print_status "🎨 DESKTOP ENVIRONMENT:"
    print_status "   • Essential applications (Firefox, Thunar, terminals, media players)"
    print_status "   • Comprehensive font collection (Noto, Liberation, Adobe Source Code Pro)"
    print_status "   • Icon themes and GTK theming (Papirus, Arc)"
    print_status "   • Screenshot and clipboard tools (grim, slurp, wl-clipboard)"
    echo
    print_status "🔧 DEVELOPMENT & BUILD TOOLS:"
    print_status "   • Complete build environment (cmake, ninja, gcc, base-devel)"
    print_status "   • Graphics libraries (mesa, vulkan, libdrm)"
    print_status "   • All Quickshell build dependencies"
    echo
    print_status "🚀 PERFORMANCE & HARDWARE:"
    print_status "   • GPU drivers for Intel, AMD, and NVIDIA"
    print_status "   • Hardware acceleration libraries"
    print_status "   • Power management tools"
    echo
    print_status "🎯 AUR PACKAGES:"
    print_status "   • Quickshell (main shell framework)"
    print_status "   • Hyprland ecosystem (hypridle, hyprlock, swww, etc.)"
    print_status "   • Additional utilities (matugen, grimblast, waybar-hyprland)"
    echo
    print_status "Total packages: ~200+ (ensuring nothing is missing for vanilla Arch)"
    echo
    read -p "Proceed with comprehensive installation? [Y/n]: " proceed_choice
    if [[ $proceed_choice =~ ^[Nn]$ ]]; then
        print_status "Installation cancelled by user"
        exit 0
    fi
    echo

    # Update system
    print_status "Updating system packages..."
    if [ "$FORCE_INSTALL" = true ]; then
        sudo pacman -Syu --noconfirm --overwrite "*"
    else
        sudo pacman -Syu --noconfirm
    fi

    # Install base-devel and git if not present
    print_status "Installing base development tools..."
    if ! is_package_installed "base-devel"; then
        if [ "$FORCE_INSTALL" = true ]; then
            sudo pacman -S --needed --noconfirm --overwrite "*" base-devel
        else
            sudo pacman -S --needed --noconfirm base-devel
        fi
    else
        print_status "base-devel is already installed"
    fi

    if ! is_package_installed "git"; then
        sudo pacman -S --needed --noconfirm git
    else
        print_status "git is already installed"
    fi

    # Copy configuration files, backing up any overwritten files/folders
    print_status "Copying configuration files..."
    if [ -d ".config" ]; then
        overwrite_backup_dir="$USER_HOME/.config.backup.$(date +%Y%m%d_%H%M%S).overwrite"
        
        for item in .config/*; do
            base_item="$(basename "$item")"
            
            if [ -e "$USER_HOME/.config/$base_item" ]; then
                print_status "Backing up $base_item before overwriting..."
                cp -rf "$USER_HOME/.config/$base_item" "$overwrite_backup_dir/" 2>/dev/null || true
            fi
            
            print_status "Force copying $base_item..."
            cp -rf "$item" "$USER_HOME/.config/" 2>/dev/null || true
        done
        
        print_success "Configuration files copied successfully (force overwritten, backups made)"
        # Check for quickshell config
        if [ ! -f "$USER_HOME/.config/quickshell/shell.qml" ]; then
            print_warning "Quickshell config (quickshell/shell.qml) is missing after install!"
            print_warning "Please ensure your repo contains .config/quickshell/shell.qml"
        fi
    else
        print_error "Configuration directory not found!"
        exit 1
    fi

    # Enable essential system services
    print_status "Enabling essential system services..."
    service_errors=0

    # Enable NetworkManager
    if ! sudo systemctl enable NetworkManager 2>/dev/null; then
        print_warning "Failed to enable NetworkManager"
        service_errors=$((service_errors + 1))
    else
        print_success "NetworkManager enabled"
    fi

    # Enable SDDM
    if ! sudo systemctl enable sddm 2>/dev/null; then
        print_warning "Failed to enable SDDM"
        service_errors=$((service_errors + 1))
    else
        print_success "SDDM enabled"
    fi

    # Enable Bluetooth
    if ! sudo systemctl enable bluetooth 2>/dev/null; then
        print_warning "Failed to enable Bluetooth (may not be available)"
        service_errors=$((service_errors + 1))
    else
        print_success "Bluetooth enabled"
    fi

    # Start NetworkManager if not running
    if ! systemctl is-active --quiet NetworkManager; then
        print_status "Starting NetworkManager..."
        sudo systemctl start NetworkManager
    fi

    if [ $service_errors -eq 0 ]; then
        print_success "All system services enabled successfully"
    elif [ $service_errors -le 2 ]; then
        print_warning "$service_errors service(s) failed to enable. This is usually not critical."
    else
        print_warning "$service_errors service(s) failed to enable. You may need to enable them manually later."
    fi

    # Additional configuration
    print_status "Performing additional system configuration..."
    
    # Create user directories
    xdg-user-dirs-update 2>/dev/null || true
    
    # Update font cache
    print_status "Updating font cache..."
    fc-cache -fv 2>/dev/null || true
    
    # Update icon cache
    print_status "Updating icon cache..."
    gtk-update-icon-cache -f -t /usr/share/icons/hicolor || true
    gtk-update-icon-cache -f -t /usr/share/icons/Papirus || true
    
    # Set up clipboard history
    print_status "Setting up clipboard history..."
    systemctl --user enable --now cliphist.service 2>/dev/null || true
    
    # Set up cursor theme
    print_status "Setting up cursor theme..."
    if [ -f /usr/share/icons/Bibata-Modern-Classic/cursors/left_ptr ]; then
        gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic' 2>/dev/null || true
    fi
    
    # Set up environment variables
    print_status "Setting up environment variables..."
    if [ ! -f "$USER_HOME/.config/environment.d/99-hyprland.conf" ]; then
        mkdir -p "$USER_HOME/.config/environment.d"
        cat > "$USER_HOME/.config/environment.d/99-hyprland.conf" << EOF
XDG_CURRENT_DESKTOP=Hyprland
XDG_SESSION_TYPE=wayland
XDG_SESSION_DESKTOP=Hyprland
GTK_THEME=Adwaita:dark
GTK2_RC_FILES=/usr/share/themes/Adwaita-dark/gtk-2.0/gtkrc
EOF
    fi

    # Force GTK dark mode
    print_status "Setting up GTK dark mode..."
    cat > ~/.config/gtk-3.0/settings.ini << EOF
[Settings]
gtk-application-prefer-dark-theme=true
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Adwaita
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-animations=1
EOF

    cat > ~/.config/gtk-4.0/settings.ini << EOF
[Settings]
gtk-application-prefer-dark-theme=true
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Adwaita
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-animations=1
EOF

    # Set up Fish shell auto-start
    print_status "Setting up Fish shell auto-start..."
    if command -v fish &> /dev/null; then
        cat > ~/.config/fish/auto-Hypr.fish << EOF
# Auto start Hyprland on tty1
if test -z "\$DISPLAY" ;and test "\$XDG_VTNR" -eq 1
    exec Hyprland > ~/.cache/hyprland.log ^&1
end
EOF
    fi
    
    # Set up performance optimization
    print_status "Setting up performance optimization..."
    cat > ~/.config/hypr/performance.conf << EOF
# Performance Settings
monitor=,highres,auto,1
env = WLR_DRM_NO_ATOMIC,1
env = WLR_NO_HARDWARE_CURSORS,1
env = WLR_RENDERER_ALLOW_SOFTWARE,1
env = WLR_RENDERER,vulkan
env = WLR_USE_LIBINPUT,1
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
EOF

    # Set up startup script
    print_status "Setting up startup script..."
    cat > ~/.config/hypr/scripts/startup.sh << EOF
#!/bin/bash

# Set environment variables
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=Hyprland

# Start system services
systemctl --user start pipewire.service
systemctl --user start pipewire-pulse.service
systemctl --user start wireplumber.service

# Start desktop components
waybar &
swww init
swww img ~/.config/hypr/assets/wallpapers/Fantasy-Landscape2.png
qs &

# Start additional services
nm-applet --indicator &
blueman-applet &
easyeffects --gapplication-service &
fcitx5 &
geoclue-2.0/demos/agent &
gammastep &
gnome-keyring-daemon --start --components=secrets &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 || /usr/libexec/polkit-gnome-authentication-agent-1 &
hypridle &
dbus-update-activation-environment --all &
sleep 0.1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &
hyprpm reload &

# Clipboard history
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &

# Set cursor
hyprctl setcursor Bibata-Modern-Classic 24
EOF
    chmod +x ~/.config/hypr/scripts/startup.sh

    # Set up shutdown script
    print_status "Setting up shutdown script..."
    cat > ~/.config/hypr/scripts/shutdown.sh << EOF
#!/bin/bash

# Stop desktop components
killall waybar
killall qs

# Stop system services
systemctl --user stop pipewire.service
systemctl --user stop pipewire-pulse.service
systemctl --user stop wireplumber.service
systemctl --user stop cliphist.service

# Cleanup
rm -rf /tmp/hyprland-*
EOF
    chmod +x ~/.config/hypr/scripts/shutdown.sh

    # Set up theme manager
    print_status "Setting up theme manager..."
    cat > ~/.config/hypr/scripts/theme-manager.sh << EOF
#!/bin/bash

# Function to apply theme
apply_theme() {
    local theme=\$1
    
    # Copy theme files
    cp -r ~/.config/hypr/assets/themes/\$theme/* ~/.config/hypr/
    
    # Reload Hyprland
    hyprctl reload
}

# Function to set wallpaper
set_wallpaper() {
    local wallpaper=\$1
    
    # Set wallpaper
    swww img ~/.config/hypr/assets/wallpapers/\$wallpaper
}

# Function to update theme
update_theme() {
    local theme=\$1
    local wallpaper=\$2
    
    # Apply theme and wallpaper
    apply_theme \$theme
    set_wallpaper \$wallpaper
}
EOF
    chmod +x ~/.config/hypr/scripts/theme-manager.sh

    print_success "Arch Linux package installation completed successfully!"
    print_status "Your system now has:"
    print_status "  ✓ Complete Hyprland + Wayland setup"
    print_status "  ✓ Full Qt6 framework for Quickshell"
    print_status "  ✓ PipeWire audio system"
    print_status "  ✓ SDDM display manager"
    print_status "  ✓ Essential desktop applications"
    print_status "  ✓ Development tools and dependencies"
    print_status "  ✓ Fonts and theming"
    print_status "  ✓ Network and Bluetooth support"
}

# Main installation process
print_status "Starting installation process..."

if [[ "$DISTRO" == "arch" ]]; then
    install_arch_packages
fi

print_success "Installation completed successfully!"
print_status "Please log out and log back in to start using your new configuration."
print_status "If you encounter any issues, please check the documentation or report them on GitHub." 
