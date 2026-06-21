#!/bin/bash
# Automated Multisim 14.3 installer (Wine)
# Authors: Giovanni De Rosa, Lorenzo Pappalardo
# Description: Downloads NI's official online installer for Multisim 14.3
#              (Educational or Professional) and sets it up under Wine.
#
# NOTE ON THIS VERSION:
#   - No patched installer folder needed anymore - this pulls the real
#     installer straight from NI's servers.
#   - Single unified method, no distro detection/branching.
#   - Wine, winetricks, cabextract, wget and git must already be installed.

set -e # Exit on errors

echo "============================================================================================"
echo "   'NI Multisim 14.3 for Linux'  Copyright (C)  2026  Giovanni De Rosa, Lorenzo Pappalardo"
echo "   This program comes with ABSOLUTELY NO WARRANTY; for details type 'show w'."
echo "   This is free software, and you are welcome to redistribute it"
echo "   under certain conditions; type 'show c' for details."
echo "============================================================================================"
echo

while true; do
  read -p "Do you wish to see the warranty or the license details [w/c; press Enter to skip]: " GPL_choice

  if [[ -z "$GPL_choice" ]]; then
    break

  elif [[ "$GPL_choice" =~ ^[Ww]$ ]]; then
    echo "THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY"
    echo "APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT"
    echo "HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM 'AS IS' WITHOUT WARRANTY"
    echo "OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,"
    echo "THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR"
    echo "PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM"
    echo "IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF"
    echo "ALL NECESSARY SERVICING, REPAIR OR CORRECTION."
    echo
    echo

  elif [[ "$GPL_choice" =~ ^[Cc]$ ]]; then
    echo "This program is free software: you can redistribute it and/or modify"
    echo "it under the terms of the GNU General Public License as published by"
    echo "the Free Software Foundation, either version 3 of the License, or"
    echo "(at your option) any later version."
    echo
    echo
    echo "You must provide source code and preserve this license when conveying"
    echo "modified or unmodified versions."
    echo
    echo

  else
    echo "Invalid input. Press Enter with no input to skip."
    echo
    echo
  fi
done

echo "=============================="
echo "  Multisim 14.3 Installer"
echo "=============================="
echo

# ──────────────────────────────────────────────
# CONFIG
# ──────────────────────────────────────────────
export WINEPREFIX="${WINEPREFIX:-$HOME/.multisim143}"
# No WINEARCH override: standard 64-bit prefix with WoW64 support.
# Dedicated prefix (not the default ~/.wine) so this never touches/depends
# on other Wine apps, and every run starts from known state.

# ──────────────────────────────────────────────
# PREREQUISITES
# (installing these is out of scope for this script)
# ──────────────────────────────────────────────
check_prerequisites() {
  local missing=()
  for cmd in wget git wine winetricks cabextract; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
  done

  if [ ${#missing[@]} -gt 0 ]; then
    echo "❌ Missing required tools: ${missing[*]}"
    echo "   Install them with your distro's package manager, then re-run this script."
    exit 1
  fi

  echo "✅ wget, git, wine, winetricks and cabextract are all available."
  echo
}

check_prerequisites

# ──────────────────────────────────────────────
# CREATE THE DEDICATED PREFIX
# ──────────────────────────────────────────────
echo "Creating Wine prefix for Multisim at $WINEPREFIX..."
wineboot
echo

# ──────────────────────────────────────────────
# WORKING DIRECTORY
# ──────────────────────────────────────────────
WORKDIR="$(mktemp -d /tmp/multisim143_install.XXXXXX)"
cd "$WORKDIR" || exit 1
echo "Working directory: $WORKDIR"
echo

# ──────────────────────────────────────────────
# CHOOSE EDITION & DOWNLOAD THE OFFICIAL ONLINE INSTALLER
# ──────────────────────────────────────────────
choose_edition() {
  echo "Which Multisim 14.3 edition would you like to install?"
  echo "  1) Educational"
  echo "  2) Professional"
  read -rp "Enter choice [1/2]: " edition_choice

  case "$edition_choice" in
  1)
    INSTALLER_URL="https://download.ni.com/support/nipkg/products/ni-c/ni-cds-educational/14.3/online/ni-cds-educational_14.3_online.exe"
    INSTALLER_FILE="ni-cds-educational_14.3_online.exe"
    ;;
  2)
    INSTALLER_URL="https://download.ni.com/support/nipkg/products/ni-c/ni-cds-professional/14.3/online/ni-cds-professional_14.3_online.exe"
    INSTALLER_FILE="ni-cds-professional_14.3_online.exe"
    ;;
  *)
    echo "❌ Invalid choice."
    exit 1
    ;;
  esac

  echo "Downloading $INSTALLER_FILE from NI..."
  wget -O "$INSTALLER_FILE" "$INSTALLER_URL"
  echo
}

choose_edition

# ──────────────────────────────────────────────
# WINE PREFIX SETUP
# ──────────────────────────────────────────────
echo "Installing core Wine dependencies (corefonts, dotnet48)..."
winetricks -q corefonts dotnet48
echo

set_winver_win10() {
  echo "Setting Wine Windows version to 10 (winecfg -v, no GUI)..."
  wine winecfg -v win10
  echo
}

set_winver_win10

# ──────────────────────────────────────────────
# RUN THE NI ONLINE INSTALLER
# ──────────────────────────────────────────────
# Run through cmd's "start /wait" rather than invoking the exe directly:
# the installer's own "please reboot" prompt at the end otherwise leaves a
# Wine process sitting around forever and the script never gets control back.
echo "Running the Multisim 14.3 online installer..."
(
  WINEDEBUG=-all \
    wine cmd /c "start /wait \"\" $INSTALLER_FILE"
) >/tmp/multisim143-install.log 2>&1 || true

echo "Installer finished."
sleep 5

echo "Stopping Wine..."
wineserver -k || true
echo "Multisim installation stage complete."
echo

# ──────────────────────────────────────────────
# DATABASE ENGINE: MDAC 2.7 + JET 4.0
# (archived copies - Microsoft's original download links are dead)
# ──────────────────────────────────────────────
install_database_engine() {
  echo "Downloading MDAC 2.7 and Jet 4.0 redistributables..."
  wget -O MDAC_TYP.EXE \
    "https://web.archive.org/web/20060718123742/http://ftp.gunadarma.ac.id/pub/driver/itegno/USB%20Software/MDAC/MDAC_TYP.EXE"
  wget -O Jet40SP8_9xNT.exe \
    "https://web.archive.org/web/20210225171713/http://download.microsoft.com/download/4/3/9/4393c9ac-e69e-458d-9f6d-2fe191c51469/Jet40SP8_9xNT.exe"

  echo "Installing MDAC 2.7..."
  wine MDAC_TYP.EXE

  echo "Installing Jet 4.0..."
  wine Jet40SP8_9xNT.exe
  echo

  echo "Extracting Jet 4.0 DLLs with cabextract..."
  mkdir -p /tmp/jet40
  pushd /tmp/jet40 >/dev/null

  cabextract "$WORKDIR/Jet40SP8_9xNT.exe"
  cabextract jetsetup.exe
  cabextract jetsetup.cab

  mkdir -p "$WINEPREFIX/drive_c/windows/syswow64"
  mkdir -p "$WINEPREFIX/drive_c/Program Files/Common Files/Microsoft Shared/DAO"

  cp dao360.dll "$WINEPREFIX/drive_c/windows/syswow64/"
  cp msjet40.dll "$WINEPREFIX/drive_c/windows/syswow64/"
  cp msrd3x40.dll "$WINEPREFIX/drive_c/windows/syswow64/"

  echo "Registering DLLs..."
  wine regsvr32 'C:\windows\syswow64\dao360.dll'
  wine regsvr32 'C:\windows\syswow64\msjet40.dll'

  popd >/dev/null
  rm -rf /tmp/jet40
  echo "✅ Database engine setup complete."
  echo
}

install_database_engine

# ──────────────────────────────────────────────
# CLEANUP
# ──────────────────────────────────────────────
echo "Cleaning up downloaded installer files..."
cd "$HOME" || exit 1
rm -rf "$WORKDIR"

echo
echo "======================================="
echo "✅ Multisim 14.3 installation complete!"
echo "   WINEPREFIX: $WINEPREFIX"
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
