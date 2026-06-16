#!/bin/bash
# Uninstall script for NI Multisim 14.0
# Supports: Linux (Arch, Debian/Ubuntu, Fedora, openSUSE) and macOS
set -e

echo "========================================"
echo "  NI Multisim 14.0 Uninstaller"
echo "========================================"
echo

# ──────────────────────────────────────────────
# COLORS
# ──────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ──────────────────────────────────────────────
# DETECT OS
# ──────────────────────────────────────────────
OS_TYPE="$(uname -s)"

case "$OS_TYPE" in
    Darwin) OS_FAMILY="macos" ;;
    Linux)  OS_FAMILY="linux" ;;
    *)
        echo -e "${RED}❌ Unsupported OS: $OS_TYPE${NC}"
        exit 1
        ;;
esac

echo "Detected OS: $OS_TYPE"

# ──────────────────────────────────────────────
# DETECT LINUX DISTRO FAMILY (Linux only)
# ──────────────────────────────────────────────
DISTRO_FAMILY="unknown"

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO_ID="${ID,,}"
        DISTRO_ID_LIKE="${ID_LIKE,,}"
    else
        echo "⚠️  Cannot detect distribution."
        return
    fi

    if [[ "$DISTRO_ID" == "arch" || "$DISTRO_ID_LIKE" == *"arch"* ]]; then
        DISTRO_FAMILY="arch"
    elif [[ "$DISTRO_ID" == "debian" || "$DISTRO_ID" == "ubuntu" ||
        "$DISTRO_ID_LIKE" == *"debian"* || "$DISTRO_ID" == "linuxmint" ]]; then
        DISTRO_FAMILY="debian"
    elif [[ "$DISTRO_ID" == "fedora" || "$DISTRO_ID_LIKE" == *"fedora"* ]]; then
        DISTRO_FAMILY="fedora"
    elif [[ "$DISTRO_ID" == "opensuse"* || "$DISTRO_ID_LIKE" == *"suse"* ]]; then
        DISTRO_FAMILY="suse"
    fi
}

if [[ "$OS_FAMILY" == "linux" ]]; then
    detect_distro
    echo "Detected Linux distro family: $DISTRO_FAMILY"
fi

echo

# ──────────────────────────────────────────────
# CHECK IF MULTISIM IS INSTALLED
# ──────────────────────────────────────────────
WINEPREFIX="$HOME/.multisim32"

if [ ! -d "$WINEPREFIX" ]; then
    echo -e "${YELLOW}⚠️  Wine prefix not found at $WINEPREFIX${NC}"
    echo "Multisim may not be installed or was already removed."
    read -p "Continue cleaning any residual files? [y/N]: " continue_clean
    if [[ ! "$continue_clean" =~ ^[Yy]$ ]]; then
        echo "Exiting."
        exit 0
    fi
fi

# ──────────────────────────────────────────────
# CONFIRM REMOVAL
# ──────────────────────────────────────────────
echo -e "${YELLOW}This will remove:${NC}"
echo "  - Wine prefix: $WINEPREFIX"
if [[ "$OS_FAMILY" == "macos" ]]; then
    echo "  - Application bundle: ~/Applications/Multisim.app"
fi
echo "  - Desktop launchers for Multisim"
echo "  - Application menu entries"
echo "  - Download cache (if any)"
echo

read -p "Are you sure you want to uninstall NI Multisim 14.0? [y/N]: " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

echo

# ──────────────────────────────────────────────
# KILL ANY RUNNING WINE PROCESSES
# ──────────────────────────────────────────────
echo "Stopping any running Wine processes..."
if [ -d "$WINEPREFIX" ]; then
    WINEPREFIX="$WINEPREFIX" wineserver -k 2>/dev/null || true
fi
pkill -f "wine" 2>/dev/null || true
pkill -f "Multisim" 2>/dev/null || true
sleep 2

# ──────────────────────────────────────────────
# REMOVE WINE PREFIX
# ──────────────────────────────────────────────
if [ -d "$WINEPREFIX" ]; then
    echo "Removing Wine prefix directory..."
    rm -rf "$WINEPREFIX"
    echo -e "${GREEN}✅ Wine prefix removed.${NC}"
else
    echo "Wine prefix not found, skipping."
fi

# ──────────────────────────────────────────────
# REMOVE DESKTOP ENTRIES
# ──────────────────────────────────────────────
echo "Removing desktop launchers..."

DESKTOP_ENTRY="$HOME/.local/share/applications/wine/Programs/National Instruments/Circuit Design Suite 14.0/Multisim 14.0.desktop"

if [[ "$OS_FAMILY" == "linux" ]]; then
    find ~/.local/share/applications -name "*Multisim*"          -type f -delete 2>/dev/null || true
    find ~/.local/share/applications -name "*Circuit Design*"    -type f -delete 2>/dev/null || true
    find ~/.local/share/applications -name "*National Instruments*" -type f -delete 2>/dev/null || true
    find ~/.local/share/applications -name "*NI*Multisim*"       -type f -delete 2>/dev/null || true
    rm -rf ~/.local/share/applications/wine/Programs/National\ Instruments 2>/dev/null || true
    rm -rf ~/.local/share/applications/wine/Programs/NI\ Multisim* 2>/dev/null || true
    update-desktop-database ~/.local/share/applications 2>/dev/null || true
elif [[ "$OS_FAMILY" == "macos" ]]; then
    rm -f "$DESKTOP_ENTRY" 2>/dev/null || true
fi

echo -e "${GREEN}✅ Desktop entries removed.${NC}"

# ──────────────────────────────────────────────
# REMOVE ICONS / CACHE
# ──────────────────────────────────────────────
echo "Removing icons and cache..."
rm -rf ~/.local/share/icons/hicolor/*/apps/*multisim* 2>/dev/null || true
rm -rf ~/.cache/wine 2>/dev/null || true
rm -f  /tmp/multisim-install.log 2>/dev/null || true
rm -f  /tmp/activator.log 2>/dev/null || true

# ──────────────────────────────────────────────
# MACOS: REMOVE APPLICATION BUNDLE
# ──────────────────────────────────────────────
if [[ "$OS_FAMILY" == "macos" ]]; then
    if [ -d "$HOME/Applications/Multisim.app" ]; then
        echo "Removing application bundle..."
        rm -rf "$HOME/Applications/Multisim.app"
        echo -e "${GREEN}✅ Application bundle removed.${NC}"
    else
        echo "Application bundle not found, skipping."
    fi
fi

# ──────────────────────────────────────────────
# OPTIONAL: REMOVE WINE PACKAGES
# ──────────────────────────────────────────────
echo
read -p "Do you also want to remove Wine and winetricks packages? [y/N]: " remove_wine
if [[ "$remove_wine" =~ ^[Yy]$ ]]; then
    echo "Removing Wine packages..."

    if [[ "$OS_FAMILY" == "macos" ]]; then
        brew uninstall --cask wine-stable 2>/dev/null || true
        brew uninstall winetricks            2>/dev/null || true
        brew uninstall cabextract            2>/dev/null || true
    elif [[ "$OS_FAMILY" == "linux" ]]; then
        case "$DISTRO_FAMILY" in
            arch)
                sudo pacman -Rns --noconfirm wine-stable wine winetricks 2>/dev/null || true
                ;;
            debian)
                sudo apt-get remove --purge -y wine wine32 wine64 winetricks 2>/dev/null || true
                sudo apt-get autoremove -y
                ;;
            fedora)
                sudo dnf remove -y wine winetricks 2>/dev/null || true
                ;;
            suse)
                sudo zypper remove -y wine winetricks 2>/dev/null || true
                ;;
            *)
                echo "Unknown distro. Skipping Wine removal."
                ;;
        esac
    fi

    echo -e "${GREEN}✅ Wine packages removed.${NC}"
else
    echo "Skipping Wine removal."
fi

# ──────────────────────────────────────────────
# DONE
# ──────────────────────────────────────────────
echo
echo "========================================"
echo -e "${GREEN}✅ NI Multisim 14.0 has been uninstalled!${NC}"
echo "========================================"
echo
echo "Residual files (if any):"
echo "  - $WINEPREFIX (already removed if it existed)"
echo "  - ~/.wine (other Wine prefixes remain untouched)"
echo

if [[ "$OS_FAMILY" == "linux" ]]; then
    echo "A reboot is recommended to complete cleanup."
    echo
    read -rp "Do you want to restart the machine now? [y/N]: " reboot_choice
    case "$reboot_choice" in
        [Yy] | [Yy][Ee][Ss])
            echo "Restarting system..."
            sudo reboot
            ;;
        *)
            echo "Restart skipped. You can reboot later manually."
            ;;
    esac
elif [[ "$OS_FAMILY" == "macos" ]]; then
    echo "You may want to restart your Mac to complete cleanup."
fi
