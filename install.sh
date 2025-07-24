#!/bin/bash

# Matt's Quickshell Hyprland Configuration Installer (Fix)
# Target: Fresh Arch Linux, no root, no Manjaro/Garuda

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status()   { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success()  { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning()  { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error()    { echo -e "${RED}[ERROR]${NC} $1"; }

# Prevent running as root
if [[ $EUID -eq 0 ]]; then
    print_error "Run this script as normal user (not root)."
    exit 1
fi

# Exit on any unhandled error
trap 'print_error "Script failed. Please review the log and fix errors."; exit 1' ERR

# Check Arch Linux (avoid Manjaro/Garuda)
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case $ID in
        arch|endeavouros|arcolinux|archcraft|artix|archlabs)
            ;;
        manjaro|garuda)
            print_error "Manjaro and Garuda are not supported."
            exit 1
            ;;
        *)
            if ! command -v pacman >/dev/null; then
                print_error "Not an Arch-based system."
                exit 1
            fi
            ;;
    esac
else
    print_error "Cannot detect distribution."
    exit 1
fi

print_status "Distribution check passed."

# Check internet connection (warn only)
if ! ping -c1 archlinux.org &>/dev/null; then
    print_warning "No internet connection detected."
fi

# Ensure yay installed
if ! command -v yay &>/dev/null; then
    print_status "Installing yay AUR helper..."
    cd /tmp
    rm -rf yay-bin
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/yay-bin
else
    print_status "yay already installed."
fi

# Check and install essential tools
for p in git curl wget; do
    if ! pacman -Qs $p >/dev/null; then
        print_status "Installing $p..."
        sudo pacman -S --needed --noconfirm $p
    fi
done

# Optional: Remove jack2, install pipewire-jack
if pacman -Qs jack2 >/dev/null; then
    print_status "Removing jack2 (incompatible)..."
    sudo pacman -Rd --nodeps --noconfirm jack2 || print_warning "Could not remove jack2"
fi
if ! pacman -Qs pipewire-jack >/dev/null; then
    print_status "Installing pipewire-jack..."
    sudo pacman -S --needed --noconfirm pipewire-jack
fi

# Clone config repo (always fresh Dotfiles dir)
cd ~
[ -d ~/Dotfiles ] && rm -rf ~/Dotfiles
print_status "Cloning HyprlandDE-Quickshell repo..."
git clone https://github.com/0xHexSec/HyprlandDE-Quickshell.git Dotfiles

cd ~/Dotfiles

# Back up old .config if present
if [ -d ~/.config ]; then
    backup=~/.config.backup.$(date +%Y%m%d_%H%M%S)
    print_status "Backing up your .config to $backup ..."
    cp -r ~/.config "$backup"
fi

# Install required packages (official + AUR)
print_status "Installing all required packages..."

# Load official packages (minimal, edit as needed)
official_packages=(
    hyprland wayland-protocols wayland-utils grim slurp wl-clipboard wtype
    pipewire wireplumber pipewire-alsa pipewire-pulse pipewire-jack
    pamixer playerctl pavucontrol alsa-utils
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-desktop-portal
    sddm qt6-base qt6-wayland qt6-svg qt6-imageformats
    networkmanager nm-connection-editor
    bluez bluez-utils
    firefox thunar btop fastfetch unzip zip
    ttf-dejavu noto-fonts ttf-font-awesome papirus-icon-theme adwaita-icon-theme
    git base-devel
)

for pkg in "${official_packages[@]}"; do
    sudo pacman -S --needed --noconfirm $pkg
done

# Load AUR packages
aur_packages=(
    quickshell hypridle hyprlock swww grimblast matugen-bin mpvpaper ttf-jetbrains-mono-nerd ttf-material-symbols-variable-git
)

for pkg in "${aur_packages[@]}"; do
    yay -S --needed --noconfirm $pkg
done

print_success "All required packages installed."

# ... (Pakete, yay, dotfiles, etc)

# ---- MicroTeX: Build and install from source ----
print_status "Installing MicroTeX (LaTeX-Editor)..."

MICROTEX_SRC="$HOME/MicroTeX"
MICROTEX_INSTALL_DIR="/opt/MicroTeX"

if [ ! -d "$MICROTEX_SRC" ]; then
    git clone https://github.com/NanoMichael/MicroTeX.git "$MICROTEX_SRC"
fi

cd "$MICROTEX_SRC"

sed -i 's/gtksourceviewmm-3.0/gtksourceviewmm-4.0/' CMakeLists.txt || true
sed -i 's/tinyxml2.so.10/tinyxml2.so.11/' CMakeLists.txt || true

cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
cmake --build build

sudo mkdir -p "$MICROTEX_INSTALL_DIR"
sudo cp build/LaTeX "$MICROTEX_INSTALL_DIR/"
sudo cp -r build/res "$MICROTEX_INSTALL_DIR/" 2>/dev/null || true
sudo mkdir -p /usr/share/licenses/microtex
sudo cp LICENSE /usr/share/licenses/microtex/

print_success "MicroTeX installed to $MICROTEX_INSTALL_DIR"
cd "$OLDPWD"

# ---- End of MicroTeX ----

# Install icon themes (example: Tela Circle)
print_status "Installing Tela Circle icon theme..."
tmp_icondir="/tmp/Tela-circle-icon-theme"
rm -rf "$tmp_icondir"
git clone --depth=1 https://github.com/vinceliuice/Tela-circle-icon-theme.git "$tmp_icondir"
(cd "$tmp_icondir" && sudo ./install.sh -a)
rm -rf "$tmp_icondir"

# Install OneUI4-Icons
print_status "Installing OneUI4-Icons..."
rm -rf /tmp/OneUI4-Icons
git clone https://github.com/end-4/OneUI4-Icons.git /tmp/OneUI4-Icons
sudo cp -r /tmp/OneUI4-Icons/OneUI* /usr/share/icons/
rm -rf /tmp/OneUI4-Icons

# Bibata cursor
print_status "Installing Bibata Modern Classic cursor theme..."
wget -O /tmp/Bibata-Modern-Classic.tar.xz https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.6/Bibata-Modern-Classic.tar.xz
sudo mkdir -p /usr/share/icons
sudo tar -xf /tmp/Bibata-Modern-Classic.tar.xz -C /usr/share/icons
rm /tmp/Bibata-Modern-Classic.tar.xz

# Copy config files to ~/.config
print_status "Copying dotfiles to ~/.config ..."
cp -r .config/* ~/.config/

# Enable services
print_status "Enabling essential services (NetworkManager, sddm, bluetooth)..."
sudo systemctl enable --now NetworkManager
sudo systemctl enable sddm
sudo systemctl enable bluetooth || print_warning "Bluetooth service could not be enabled (no hardware?)"

# Update caches
fc-cache -fv
gtk-update-icon-cache -f -t /usr/share/icons/hicolor
gtk-update-icon-cache -f -t /usr/share/icons/Papirus || true

print_success "Setup done! Please reboot and select Hyprland in your login manager (SDDM)."

echo -e "${GREEN}If something is missing, check logs above or https://github.com/0xHexSec/HyprlandDE-Quickshell/issues${NC}"
