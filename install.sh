#!/bin/bash
# Automated Multisim 14.0 installer
# Authors: Giovanni De Rosa, Lorenzo Pappalardo
# Description: Installs Wine, sets up 32-bit prefix, and installs Multisim 14.0
# Supports: Arch Linux, Debian/Ubuntu/Mint, Fedora, openSUSE

set -e # Exit on errors

echo "============================================================================================"
echo '   "NI Multisim 14 for Linux"  Copyright (C)  2026  Giovanni De Rosa, Lorenzo Pappalardo'
echo "   This program comes with ABSOLUTELY NO WARRANTY; for details type `show w'."
echo "   This is free software, and you are welcome to redistribute it"
echo "   under certain conditions; type `show c' for details."
echo "============================================================================================"
echo

while true; do
  read -p "Do you wish to see the warranty or the license details [w/c; press Enter to skip]: " GPL_choice

  if [[ -z "$GPL_choice" ]]; then
    break

  elif [[ "$GPL_choice" =~ ^[Ww]$ ]]; then
    echo "THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY"
    echo "APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT"
    echo 'HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY'
    echo "OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,"
    echo "THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR"
    echo "PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM"
    echo "IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF"
    echo "ALL NECESSARY SERVICING, REPAIR OR CORRECTION."

  elif [[ "$GPL_choice" =~ ^[Cc]$ ]]; then
    echo "This program is free software: you can redistribute it and/or modify"
    echo "it under the terms of the GNU General Public License as published by"
    echo "the Free Software Foundation, either version 3 of the License, or"
    echo "(at your option) any later version."
    echo
    echo
    echo "You must provide source code and preserve this license when conveying"
    echo "modified or unmodified versions."

  else
    echo "Invalid input. Press Enter with no input to skip."
  fi
done

echo "=============================="
echo "  Multisim 14.0 Installer"
echo "=============================="
echo

# ──────────────────────────────────────────────
# DISTRO DETECTION
# ──────────────────────────────────────────────
detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID="${ID,,}" # lowercase
    DISTRO_ID_LIKE="${ID_LIKE,,}"
  else
    echo "❌ Cannot detect distribution (/etc/os-release not found)."
    exit 1
  fi

  if [[ "$DISTRO_ID" == "arch" || "$DISTRO_ID_LIKE" == *"arch"* ]]; then
    DISTRO_FAMILY="arch"
  elif [[ "$DISTRO_ID" == "debian" || "$DISTRO_ID" == "ubuntu" ||
    "$DISTRO_ID_LIKE" == *"debian"* || "$DISTRO_ID_LIKE" == *"ubuntu"* ||
    "$DISTRO_ID" == "linuxmint" ]]; then
    DISTRO_FAMILY="debian"
  elif [[ "$DISTRO_ID" == "fedora" || "$DISTRO_ID_LIKE" == *"fedora"* ||
    "$DISTRO_ID" == "rhel" || "$DISTRO_ID" == "centos" ]]; then
    DISTRO_FAMILY="fedora"
  elif [[ "$DISTRO_ID" == "opensuse"* || "$DISTRO_ID" == "sles" ||
    "$DISTRO_ID_LIKE" == *"suse"* ]]; then
    DISTRO_FAMILY="suse"
  else
    echo "❌ Unsupported distribution: $DISTRO_ID"
    echo "   This script supports: Arch, Debian/Ubuntu/Mint, Fedora, openSUSE"
    exit 1
  fi

  echo "✅ Detected distro family: $DISTRO_FAMILY ($DISTRO_ID)"
  echo
}

detect_distro

# ──────────────────────────────────────────────
# REMOVE CONFLICTING WINE PACKAGES
# ──────────────────────────────────────────────
remove_conflicting_packages() {
  echo "Checking for conflicting Wine packages..."

  case "$DISTRO_FAMILY" in
  arch)
    packages_to_check=(wine wine-gecko wine-mono winetricks protontricks)
    packages_to_remove=()
    for pkg in "${packages_to_check[@]}"; do
      if pacman -Qq "$pkg" &>/dev/null; then
        packages_to_remove+=("$pkg")
      fi
    done
    if [ ${#packages_to_remove[@]} -gt 0 ]; then
      echo "Removing conflicting packages: ${packages_to_remove[*]}"
      sudo pacman -Rns --noconfirm "${packages_to_remove[@]}"
    else
      echo "No conflicting Wine packages found. Skipping removal."
    fi
    ;;
  debian)
    packages_to_check=(wine wine64 wine32 winetricks)
    packages_to_remove=()
    for pkg in "${packages_to_check[@]}"; do
      if dpkg -l "$pkg" &>/dev/null 2>&1 | grep -q "^ii"; then
        packages_to_remove+=("$pkg")
      fi
    done
    if [ ${#packages_to_remove[@]} -gt 0 ]; then
      echo "Removing conflicting packages: ${packages_to_remove[*]}"
      sudo apt-get remove --purge -y "${packages_to_remove[@]}"
    else
      echo "No conflicting Wine packages found. Skipping removal."
    fi
    ;;
  fedora)
    packages_to_check=(wine winetricks)
    for pkg in "${packages_to_check[@]}"; do
      if rpm -q "$pkg" &>/dev/null; then
        echo "Removing conflicting package: $pkg"
        sudo dnf remove -y "$pkg"
      fi
    done
    ;;
  suse)
    packages_to_check=(wine winetricks)
    for pkg in "${packages_to_check[@]}"; do
      if rpm -q "$pkg" &>/dev/null; then
        echo "Removing conflicting package: $pkg"
        sudo zypper remove -y "$pkg"
      fi
    done
    ;;
  esac
}

# ──────────────────────────────────────────────
# INSTALL WINE (per distro)
# ──────────────────────────────────────────────
install_wine_arch() {
  echo "Do you want to use Chaotic AUR for wine-stable (recommended, faster)?"
  echo "Y = Use Chaotic AUR"
  echo "N = Compile from AUR (slower)"
  read -p "Choice [Y/N]: " choice

  if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "Checking if Chaotic AUR is already installed..."
    if grep -q "^\[chaotic-aur\]" /etc/pacman.conf; then
      echo "✅ Chaotic AUR is already configured."
    else
      echo "Setting up Chaotic AUR..."
      sudo pacman-key --keyserver hkps://keyserver.ubuntu.com \
        --recv-key 3056513887B78AEB || {
        echo "❌ Failed to fetch Chaotic AUR key. Check your internet or keyserver settings."
        exit 1
      }
      sudo pacman-key --lsign-key 3056513887B78AEB
      sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm
      sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
      echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf
      echo "✅ Chaotic AUR has been added to pacman.conf."
    fi

    echo
    read -p "Do you want to update the system before installing Wine? [Y/N]: " update_choice
    if [[ "$update_choice" =~ ^[Yy]$ ]]; then
      echo "Updating system..."
      sudo pacman -Syu --noconfirm
    else
      echo "Skipping system update."
      sudo pacman -Sy
    fi

    remove_conflicting_packages
    echo "Installing wine-stable from Chaotic AUR..."
    sudo pacman -S --noconfirm wine-stable

  else
    echo "Using AUR to compile wine-stable (this may take a long time)..."
    if ! command -v yay &>/dev/null; then
      echo "Installing yay (AUR helper)..."
      sudo pacman -S --needed --noconfirm git base-devel
      git clone https://aur.archlinux.org/yay.git
      cd yay && makepkg -si --noconfirm && cd ..
      rm -rf yay
    fi
    remove_conflicting_packages
    yay -S --noconfirm wine-stable
  fi

  sudo pacman -S --noconfirm cabextract unzip
}

install_wine_debian() {
  echo "Installing Wine on Debian/Ubuntu/Mint..."

  # Enable 32-bit architecture
  sudo dpkg --add-architecture i386
  sudo apt-get update -y

  sudo apt-get update -y
  remove_conflicting_packages

  echo "Installing default Wine packages (wine, wine32, wine64, libwine)..."
  sudo apt-get install -y wine wine32 wine64 libwine

  # Ensure winetricks is installed
  sudo apt-get install -y winetricks
}

install_wine_fedora() {
  echo "Installing Wine on Fedora..."

  # Wine on Fedora requires enabling the winehq COPR or RPM Fusion
  read -p "Enable RPM Fusion repos for Wine? (recommended) [Y/N]: " rpm_choice
  if [[ "$rpm_choice" =~ ^[Yy]$ ]]; then
    FEDORA_VER=$(rpm -E %fedora)
    sudo dnf install -y \
      "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm" \
      "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm"
  fi

  remove_conflicting_packages
  
  sudo dnf remove -y 'wine*'
  sudo dnf install -y --allowerasing wine wine-core.i686 cabextract

  wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
  chmod +x winetricks
  sudo mv winetricks /usr/local/bin/
}

install_wine_suse() {
  echo "Installing Wine on openSUSE..."

  # Add the Emulators repo which provides up-to-date Wine builds
  SUSE_VER=$(
    . /etc/os-release
    echo "$VERSION_ID"
  )
  #read -p "Add the openSUSE Emulators OBS repo for latest Wine? (recommended) [Y/N]: " obs_choice
  
  remove_conflicting_packages
  sudo zypper install -y wine winetricks

  # Get the directory where THIS script is located
  SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
  
  # Execute the other script located in the same directory
  sudo chmod +x "$SCRIPT_DIR/forceClosewinedbg.sh"
  bash "$SCRIPT_DIR/forceClosewinedbg.sh" &
}

# ──────────────────────────────────────────────
# INSTALL WINETRICKS (if not bundled above)
# ──────────────────────────────────────────────
ensure_winetricks() {
  if ! command -v winetricks &>/dev/null; then
    echo "Installing winetricks manually..."
    sudo wget -O /usr/local/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
    sudo chmod +x /usr/local/bin/winetricks
  fi
}

# ──────────────────────────────────────────────
# INSTALL WINE — dispatch
# ──────────────────────────────────────────────
case "$DISTRO_FAMILY" in
arch) install_wine_arch ;;
debian) install_wine_debian ;;
fedora) install_wine_fedora ;;
suse) install_wine_suse ;;
esac

ensure_winetricks

# ──────────────────────────────────────────────
# DISTRO-SPECIFIC MULTISIM INSTALL
# ──────────────────────────────────────────────

if [[ "$DISTRO_FAMILY" == "debian" || "$DISTRO_FAMILY" == "fedora" ]]; then

  # ──────────────────────────────────────────────
  # DEBIAN / FEDORA METHOD
  # ──────────────────────────────────────────────

  export WINEPREFIX="$HOME/.multisim32"
  export WINEARCH=win32

  echo "Creating pure 32-bit Wine prefix..."
  WINEPREFIX="$HOME/.multisim32" wine32 winecfg -v winxp || true

  echo "Installing core Wine dependencies (corefonts, mdac27, jet40)..."
  WINE=wine32 WINEPREFIX="$HOME/.multisim32" \
    winetricks -q corefonts mdac27 jet40

  # DOWNLOAD MULTISIM
  echo "Downloading Multisim 14.0..."
  wget -O NI_Circuit_Design_Suite_14_0.zip \
    https://download.ni.com/support/softlib/Core/Circuit_Design_Suite/14.0/14.0/NI_Circuit_Design_Suite_14_0.zip

  echo "Unzipping Multisim installer..."
  unzip -q NI_Circuit_Design_Suite_14_0.zip -d multisim_installer

  cd multisim_installer || exit 1

  echo "Setting Wine Windows version to XP..."
  WINEPREFIX="$HOME/.multisim32" wine32 winecfg -v winxp || true

  # RUN INSTALLER
  echo "Running Multisim installer via Wine..."

  (
    WINEPREFIX="$HOME/.multisim32" \
      WINEDEBUG=-all \
      wine32 cmd /c 'start /wait "" setup.exe'
  ) >/tmp/multisim-install.log 2>&1 || true

  echo "Installer finished."

  sleep 5

  echo "Stopping Wine..."
  WINEPREFIX="$HOME/.multisim32" wineserver -k || true

  echo "Multisim installation stage complete."

  # FIX DESKTOP FILE
  #if [ -f /etc/debian_version ]; then
    echo "Debian-based/RHEL-based distro detected. Fixing desktop launcher..."

    DESKTOP_FILE="$HOME/.local/share/applications/wine/Programs/National Instruments/Circuit Design Suite 14.0/Multisim 14.0.desktop"

    if [ -f "$DESKTOP_FILE" ]; then

      NEW_EXEC='Exec=sh -c '\''WINEPREFIX="$HOME/.multisim32" wine32 "$HOME/.multisim32/drive_c/Program Files/National Instruments/Circuit Design Suite 14.0/Multisim.exe"'\'''

      sed -i "s|^Exec=.*|$NEW_EXEC|" "$DESKTOP_FILE"

      update-desktop-database ~/.local/share/applications || true

      echo "Desktop launcher fixed."
    else
      echo "Desktop file not found."
    fi

    if [ -f "$HOME/.local/share/applications/wine/Programs/NI Multisim 14.0.desktop" ]; then

      rm $HOME/.local/share/applications/wine/Programs/NI\ Multisim\ 14.0.desktop
      update-desktop-database ~/.local/share/applications || true
      
    fi
  #fi

elif [[ "$DISTRO_FAMILY" == "arch" || "$DISTRO_FAMILY" == "suse" ]]; then

  # ──────────────────────────────────────────────
  # ARCH / OPENSUSE METHOD
  # ──────────────────────────────────────────────

  echo
  echo "Creating 32-bit Wine prefix for Multisim..."

  WINEARCH=win32 WINEPREFIX="$HOME/.multisim32" \
    winecfg -v winxp || true

  echo "Installing core Wine dependencies (corefonts, mdac27, jet40)..."

  WINEPREFIX="$HOME/.multisim32" \
    winetricks nocrashdialog -q corefonts mdac27 jet40

  # DOWNLOAD MULTISIM
  echo
  echo "Downloading Multisim 14.0..."

  wget -O NI_Circuit_Design_Suite_14_0.zip \
    https://download.ni.com/support/softlib/Core/Circuit_Design_Suite/14.0/14.0/NI_Circuit_Design_Suite_14_0.zip

  echo "Unzipping Multisim installer..."

  unzip -q NI_Circuit_Design_Suite_14_0.zip -d multisim_installer

  cd multisim_installer || exit 1

  WINEPREFIX="$HOME/.multisim32" \
    winecfg -v winxp || true

  # RUN INSTALLER PROPERLY
  echo
  echo "Running Multisim installer..."

  (
    WINEPREFIX="$HOME/.multisim32" \
      WINEDEBUG=-all \
      wine cmd /c 'start /wait "" setup.exe'
  ) >/tmp/multisim-install.log 2>&1 || true

  echo "Installer finished."

  sleep 5

  echo "Stopping Wine..."

  WINEPREFIX="$HOME/.multisim32" \
    wineserver -k || true

  echo "Multisim installation stage complete."

fi

# ──────────────────────────────────────────────
# CLEANUP
# ──────────────────────────────────────────────
echo "Cleaning up installation files..."
cd ..
sudo rm -rf multisim_installer NI_Circuit_Design_Suite_14_0.zip

echo
echo "======================================="
echo "✅ Multisim 14.0 installation complete!"
echo "A reboot of your machine is recommended"
echo "======================================="

read -rp "Do you want to restart the machine now? [y/N]: " answer

case "$answer" in
[Yy] | [Yy][Ee][Ss])
  echo "Restarting system..."
  sudo reboot
  ;;
*)
  echo "Restart skipped. You can reboot later manually."
  ;;
esac
